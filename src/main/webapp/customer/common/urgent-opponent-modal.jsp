<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%--
  Component: Modal "Tìm đối thủ gấp" (demo, chưa có backend ghép kèo thật).
  Cần include cùng script openUrgentOpponentModal()/closeUrgentOpponentModal() ở dưới.
--%>
<div id="urgentOpponentModal" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[70] hidden flex items-center justify-center opacity-0 transition-opacity duration-300 px-4">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md scale-95 transition-transform duration-300">
        <div class="bg-gradient-to-r from-amber-500 to-orange-500 rounded-t-2xl px-6 py-4 flex items-center justify-between">
            <h3 class="text-white font-bold text-sm flex items-center gap-2">
                <span class="material-symbols-outlined text-[18px]">bolt</span> Tìm đối thủ gấp
            </h3>
            <button type="button" onclick="closeUrgentOpponentModal()" class="text-white/80 hover:text-white transition-colors p-1">
                <span class="material-symbols-outlined text-[20px]">close</span>
            </button>
        </div>
        <form id="urgentOpponentForm" onsubmit="return submitUrgentOpponentRequest(event)" class="p-6 space-y-4">
            <p class="text-xs text-slate-500 leading-relaxed">Dùng khi lịch sắp diễn ra và bạn cần thêm người chơi gấp (ví dụ có người bùng kèo). Yêu cầu này sẽ ưu tiên người chơi có điểm uy tín tốt và ở gần bạn.</p>
            <div>
                <label class="block text-[11px] font-bold text-slate-500 uppercase tracking-wide mb-1.5">Môn thể thao</label>
                <select class="acc-input" name="monTheThao">
                    <option>Bóng đá</option>
                    <option>Cầu lông</option>
                    <option>Tennis</option>
                    <option>Bóng rổ</option>
                    <option>Pickleball</option>
                </select>
            </div>
            <div class="grid grid-cols-2 gap-3">
                <div>
                    <label class="block text-[11px] font-bold text-slate-500 uppercase tracking-wide mb-1.5">Số người cần tìm</label>
                    <input type="number" class="acc-input" name="soNguoi" min="1" max="20" value="2">
                </div>
                <div>
                    <label class="block text-[11px] font-bold text-slate-500 uppercase tracking-wide mb-1.5">Trình độ</label>
                    <select class="acc-input" name="trinhDo">
                        <option>Không yêu cầu</option>
                        <option>Mới chơi</option>
                        <option>Trung bình</option>
                        <option>Khá</option>
                        <option>Giỏi</option>
                    </select>
                </div>
            </div>
            <div>
                <label class="block text-[11px] font-bold text-slate-500 uppercase tracking-wide mb-1.5">Bán kính tìm kiếm</label>
                <select class="acc-input" name="banKinh">
                    <option>Trong vòng 2km</option>
                    <option>Trong vòng 5km</option>
                    <option>Trong vòng 10km</option>
                    <option>Toàn thành phố</option>
                </select>
            </div>
            <div class="flex items-center justify-end gap-3 pt-2">
                <button type="button" onclick="closeUrgentOpponentModal()" class="px-5 py-2.5 rounded-xl font-bold text-slate-600 bg-slate-100 hover:bg-slate-200 transition-colors text-sm">Đóng</button>
                <button type="submit" class="px-5 py-2.5 rounded-xl font-bold text-white bg-amber-600 hover:bg-amber-700 transition-colors text-sm">Gửi yêu cầu tìm đối thủ</button>
            </div>
        </form>
    </div>
</div>

<script>
    function openUrgentOpponentModal() {
        var modal = document.getElementById('urgentOpponentModal');
        if (!modal) return;
        modal.classList.remove('hidden');
        modal.classList.add('flex');
        requestAnimationFrame(function () {
            modal.classList.remove('opacity-0');
            modal.querySelector('.bg-white').classList.remove('scale-95');
        });
    }
    function closeUrgentOpponentModal() {
        var modal = document.getElementById('urgentOpponentModal');
        if (!modal) return;
        modal.classList.add('opacity-0');
        modal.querySelector('.bg-white').classList.add('scale-95');
        setTimeout(function () {
            modal.classList.add('hidden');
            modal.classList.remove('flex');
        }, 300);
    }
    function submitUrgentOpponentRequest(evt) {
        evt.preventDefault();
        closeUrgentOpponentModal();
        if (typeof showToast === 'function') {
            showToast('Đã gửi yêu cầu', 'Chức năng ghép đối thủ tự động đang được phát triển. Chúng tôi sẽ sớm ra mắt sớm nhất có thể.');
        } else {
            alert('Chức năng tìm đối thủ gấp đang được phát triển. Yêu cầu của bạn sẽ được ưu tiên người chơi có điểm uy tín tốt và ở gần bạn.');
        }
        return false;
    }
</script>
