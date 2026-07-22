package org.example.service.matchmaking;

import org.example.dao.GhepKeoDAO;
import org.example.dao.LichDatSanDAO;
import org.example.dao.TaiKhoanDAO;
import org.example.dao.impl.GhepKeoDAOImpl;
import org.example.dao.impl.LichDatSanDAOImpl;
import org.example.dao.impl.TaiKhoanDAOImpl;
import org.example.model.GhepKeo;
import org.example.model.Lichdatsan;
import org.example.model.TaiKhoan;

import java.time.LocalDate;

/**
 * Nghiệp vụ Ghép kèo: tạo kèo dựa trên booking sẵn có, xin tham gia (có tôn trọng
 * hình thức duyệt auto/manual), duyệt/từ chối, hủy kèo.
 * Không tính giá riêng — mọi thông tin tiền lấy từ pricing service của luồng đặt sân.
 */
public class GhepKeoService {

    private final GhepKeoDAO ghepKeoDAO;
    private final LichDatSanDAO lichDatSanDAO;
    private final TaiKhoanDAO taiKhoanDAO;

    public GhepKeoService() {
        this(new GhepKeoDAOImpl(), new LichDatSanDAOImpl(), new TaiKhoanDAOImpl());
    }

    public GhepKeoService(GhepKeoDAO ghepKeoDAO, LichDatSanDAO lichDatSanDAO) {
        this(ghepKeoDAO, lichDatSanDAO, new TaiKhoanDAOImpl());
    }

    public GhepKeoService(GhepKeoDAO ghepKeoDAO, LichDatSanDAO lichDatSanDAO, TaiKhoanDAO taiKhoanDAO) {
        this.ghepKeoDAO = ghepKeoDAO;
        this.lichDatSanDAO = lichDatSanDAO;
        this.taiKhoanDAO = taiKhoanDAO;
    }

    public static class CreateRequest {
        public int accountId;
        public int datSanId;
        public Integer monTheThaoId;
        public int soNguoiCanTim;
        public String trinhDo;
        public String hinhThucDuyet; // "auto" | "manual"
        public String note;
        /** Điểm uy tín tối thiểu bắt buộc để tham gia kèo (0 = không yêu cầu). Phải trong [0, 100]. */
        public int minReputation;
    }

    public static class Result {
        public final boolean success;
        public final String message;
        public final Integer keoId;
        public final Integer chiTietKeoId;
        public Result(boolean success, String message, Integer keoId, Integer chiTietKeoId) {
            this.success = success; this.message = message; this.keoId = keoId; this.chiTietKeoId = chiTietKeoId;
        }
        public static Result ok(String msg, Integer keoId) { return new Result(true, msg, keoId, null); }
        public static Result okJoin(String msg, Integer chiTietId) { return new Result(true, msg, null, chiTietId); }
        public static Result fail(String msg) { return new Result(false, msg, null, null); }
    }

    /**
     * Tạo kèo mới. Chủ kèo phải chọn một booking hợp lệ (Chờ xác nhận / Đã xác nhận / Chờ thanh toán)
     * do chính mình đặt, ngày+giờ chưa qua.
     */
    public Result createMatch(CreateRequest req) {
        if (req == null) return Result.fail("Yêu cầu không hợp lệ.");
        if (req.accountId <= 0) return Result.fail("Vui lòng đăng nhập.");
        if (req.datSanId <= 0) return Result.fail("Vui lòng chọn một ca đặt sân của bạn để gắn kèo.");
        if (req.soNguoiCanTim < 1 || req.soNguoiCanTim > 20) return Result.fail("Số người cần tìm phải trong khoảng 1–20.");

        Lichdatsan booking = lichDatSanDAO.getLichById(req.datSanId);
        if (booking == null) return Result.fail("Ca đặt sân không tồn tại.");
        if (booking.getAccountId() == null || booking.getAccountId() != req.accountId) {
            return Result.fail("Bạn chỉ có thể gắn kèo cho ca đặt sân của chính mình.");
        }
        String tt = booking.getTrangThai();
        if (!"Chờ xác nhận".equals(tt) && !"Đã xác nhận".equals(tt) && !"Chờ thanh toán".equals(tt)) {
            return Result.fail("Ca đặt sân không còn hiệu lực để tạo kèo (trạng thái: " + tt + ").");
        }
        if (booking.getNgayDat() != null && booking.getNgayDat().isBefore(LocalDate.now())) {
            return Result.fail("Ca đặt sân đã diễn ra, không thể tạo kèo mới.");
        }

        GhepKeo keo = new GhepKeo();
        keo.setDatSanId(req.datSanId);
        keo.setAccountIdNguoiTao(req.accountId);
        keo.setMonTheThaoId(req.monTheThaoId);
        keo.setTrinhDo(req.trinhDo == null ? "Không yêu cầu" : req.trinhDo);
        keo.setTrangThai(GhepKeoDAOImpl.STATUS_OPEN);
        int minRep = Math.max(0, Math.min(100, req.minReputation));
        keo.setMoTa(GhepKeoDAOImpl.encodeMoTa(
                req.soNguoiCanTim,
                (req.hinhThucDuyet == null || req.hinhThucDuyet.isBlank()) ? "auto" : req.hinhThucDuyet,
                req.note == null ? "" : req.note.trim(),
                minRep));

        int keoId = ghepKeoDAO.create(keo);
        if (keoId <= 0) return Result.fail("Không thể tạo kèo. Vui lòng thử lại.");
        return Result.ok("Đã tạo kèo thành công.", keoId);
    }

    /**
     * Xin tham gia. Nếu kèo cấu hình auto → thẳng tay JOINED. Nếu manual → PENDING.
     * Chống double-join, self-join, capacity qua transaction bên trong DAO.
     */
    public Result joinMatch(int keoId, int accountId) {
        if (accountId <= 0) return Result.fail("Vui lòng đăng nhập.");
        GhepKeoDAO.GhepKeoView view = ghepKeoDAO.getViewById(keoId);
        if (view == null) return Result.fail("Kèo không tồn tại.");
        if (view.accountIdNguoiTao == accountId) return Result.fail("Bạn là chủ kèo, không cần xin tham gia.");
        if (!GhepKeoDAOImpl.STATUS_OPEN.equals(view.trangThai)) return Result.fail("Kèo hiện không nhận thêm người.");

        // Kiểm tra điểm uy tín tối thiểu
        if (view.minReputation > 0) {
            TaiKhoan player = taiKhoanDAO.getAccountById(accountId);
            int playerRep = (player != null) ? player.getDiemUyTin() : 0;
            if (playerRep < view.minReputation) {
                return Result.fail("Bạn cần có ít nhất " + view.minReputation + " điểm uy tín để tham gia kèo này (hiện tại bạn có " + playerRep + " điểm).");
            }
        }

        String desiredStatus = "manual".equalsIgnoreCase(view.hinhThucDuyet)
                ? GhepKeoDAOImpl.P_STATUS_PENDING
                : GhepKeoDAOImpl.P_STATUS_JOINED;
        try {
            int chiTietId = ghepKeoDAO.addParticipant(keoId, accountId, desiredStatus, "");
            return Result.okJoin(
                    GhepKeoDAOImpl.P_STATUS_PENDING.equals(desiredStatus)
                            ? "Đã gửi yêu cầu tham gia. Chờ chủ kèo duyệt."
                            : "Tham gia kèo thành công.",
                    chiTietId);
        } catch (IllegalStateException ise) {
            return Result.fail(ise.getMessage());
        } catch (Exception e) {
            return Result.fail("Không thể tham gia lúc này. Vui lòng thử lại.");
        }
    }

    /** Chủ kèo duyệt yêu cầu tham gia. */
    public Result approveParticipant(int chiTietKeoId, int ownerAccountId) {
        boolean ok = ghepKeoDAO.updateParticipantStatus(chiTietKeoId, GhepKeoDAOImpl.P_STATUS_JOINED, ownerAccountId, true);
        return ok ? Result.ok("Đã duyệt yêu cầu.", null) : Result.fail("Không thể duyệt (bạn có thể không phải chủ kèo hoặc yêu cầu không còn hợp lệ).");
    }

    /** Chủ kèo từ chối. */
    public Result rejectParticipant(int chiTietKeoId, int ownerAccountId) {
        boolean ok = ghepKeoDAO.updateParticipantStatus(chiTietKeoId, GhepKeoDAOImpl.P_STATUS_REJECTED, ownerAccountId, true);
        return ok ? Result.ok("Đã từ chối yêu cầu.", null) : Result.fail("Không thể từ chối.");
    }

    /** Người chơi tự rời kèo. */
    public Result leaveMatch(int chiTietKeoId, int accountId) {
        boolean ok = ghepKeoDAO.updateParticipantStatus(chiTietKeoId, GhepKeoDAOImpl.P_STATUS_LEFT, accountId, false);
        return ok ? Result.ok("Bạn đã rời kèo.", null) : Result.fail("Không thể rời kèo.");
    }

    /** Chủ kèo huỷ kèo. */
    public Result cancelMatch(int keoId, int ownerAccountId) {
        boolean ok = ghepKeoDAO.updateStatusIfOwner(keoId, GhepKeoDAOImpl.STATUS_CANCELLED, ownerAccountId);
        return ok ? Result.ok("Đã hủy kèo.", null) : Result.fail("Không thể hủy (bạn có thể không phải chủ kèo).");
    }

    /** Chủ kèo đóng nhận người (chuyển sang "Đã đủ người" thủ công). */
    public Result closeMatch(int keoId, int ownerAccountId) {
        boolean ok = ghepKeoDAO.updateStatusIfOwner(keoId, GhepKeoDAOImpl.STATUS_FULL, ownerAccountId);
        return ok ? Result.ok("Đã dừng nhận thêm người.", null) : Result.fail("Không thể cập nhật.");
    }
}
