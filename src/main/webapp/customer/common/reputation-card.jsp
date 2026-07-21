<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%--
  Component: Thẻ điểm uy tín khách hàng.
  Yêu cầu biến scope "request" đã có sẵn: account (org.example.model.TaiKhoan).
  Ngôn ngữ hiển thị luôn nhẹ nhàng, không dùng từ nặng nề (không có "rủi ro cao"/"khách xấu").
  Styling: dùng các class .rep-* định nghĩa trong TaiKhoan.jsp (trang duy nhất include file này).
--%>
<c:set var="repScore" value="${account.diemUyTin}" />
<c:choose>
    <c:when test="${repScore >= 80}">
        <c:set var="repLabel" value="Uy tín tốt" />
        <c:set var="repColorBg" value="#EDF3EC" />
        <c:set var="repColorText" value="#346538" />
        <c:set var="repBarColor" value="#10b981" />
    </c:when>
    <c:when test="${repScore >= 50}">
        <c:set var="repLabel" value="Cần theo dõi" />
        <c:set var="repColorBg" value="#FBF3DB" />
        <c:set var="repColorText" value="#956400" />
        <c:set var="repBarColor" value="#d99a1b" />
    </c:when>
    <c:otherwise>
        <c:set var="repLabel" value="Cần cải thiện" />
        <c:set var="repColorBg" value="#FDEBEC" />
        <c:set var="repColorText" value="#9F2F2D" />
        <c:set var="repBarColor" value="#e15a5a" />
    </c:otherwise>
</c:choose>

<div class="rep-card" id="uyTinCuaToi">
    <div class="flex items-start justify-between gap-4 mb-5 flex-wrap">
        <h3 class="text-[15px] font-extrabold flex items-center gap-2" style="color:var(--ink-green);">
            <svg class="lci" style="color:var(--primary-mid);" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1 1 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/><path d="m9 12 2 2 4-4"/></svg>
            Điểm uy tín của bạn
        </h3>
        <span class="rep-chip" style="background-color: ${repColorBg}; color: ${repColorText};">
            <span class="w-1.5 h-1.5 rounded-full inline-block" style="background-color: ${repBarColor};"></span>
            ${repLabel}
        </span>
    </div>

    <div class="flex items-end gap-3 mb-3">
        <span class="rep-score-big">${repScore}</span>
        <span class="text-sm font-bold mb-1" style="color:var(--muted-green);">/ 100</span>
    </div>
    <div class="rep-bar mb-6" role="progressbar" aria-valuenow="${repScore}" aria-valuemin="0" aria-valuemax="100" aria-label="Điểm uy tín">
        <div class="h-full rounded-full" style="width: ${repScore}%; background-color: ${repBarColor};"></div>
    </div>

    <div class="rep-counts mb-6">
        <div class="rep-count">
            <b>${account.completedBookingCount}</b>
            <span>Đã hoàn thành</span>
        </div>
        <div class="rep-count">
            <b>${account.lateCancelCount}</b>
            <span>Hủy sát giờ</span>
        </div>
        <div class="rep-count">
            <b>${account.noShowCount}</b>
            <span>Không đến</span>
        </div>
    </div>

    <div class="rep-how">
        <p style="font-size:12px;font-weight:800;color:var(--muted-green);text-transform:uppercase;letter-spacing:.04em;">Điểm uy tín được tính thế nào?</p>
        <p><svg class="lci text-emerald-600" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/></svg> Hủy sớm (trước 6 tiếng) không bị trừ điểm.</p>
        <p><svg class="lci text-amber-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 20h16a2 2 0 0 0 1.73-2"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg> Hủy sát giờ có thể ảnh hưởng điểm uy tín.</p>
        <p><svg class="lci text-rose-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" x2="12" y1="8" y2="12"/><line x1="12" x2="12.01" y1="16" y2="16"/></svg> Không đến sân bị trừ điểm nhiều hơn hủy sát giờ.</p>
        <p><svg class="lci text-emerald-600" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="M8 12h8"/><path d="M12 8v8"/></svg> Hoàn thành trận đấu sẽ được cộng điểm.</p>
    </div>

    <a href="${pageContext.request.contextPath}/customer/lich-su-dat-san" class="mt-4 inline-flex items-center gap-1.5 text-[13px] font-bold hover:underline" style="color:var(--primary-dark);">
        <svg class="lci" style="width:16px;height:16px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l4 2"/></svg>
        Xem lịch sử uy tín
    </a>
</div>
