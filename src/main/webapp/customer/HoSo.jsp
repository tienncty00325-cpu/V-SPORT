<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="vi" class="scroll-smooth">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hồ sơ cá nhân - V-SPORT</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <jsp:include page="/common/head.jsp" />
    <jsp:include page="/customer/common/vsport-theme.jsp" />
    <link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Be Vietnam Pro', 'Inter', system-ui, -apple-system, sans-serif !important;
            background-color: #00783E !important;
            color: #063B24 !important;
            margin: 0;
        }
        /* Full-screen green profile page (ALO-style layout). NO max-width / NO
           centered desktop container. The --vs-* overrides below recolor the
           shared navy/cyan tokens to green for THIS page only. */
        .customer-profile-page {
            min-height: 100vh;
            width: 100%;
            background: #00783E;
            color: #063B24;
            overflow-x: hidden;
            padding-bottom: 24px;
            --vs-primary-900: #00532B;
            --vs-primary-800: #00633A;
            --vs-primary-700: #00693A;
            --vs-primary-600: #00783E;
            --vs-primary-500: #08A24C;
            --vs-cyan-500: #12B15A;
        }
        .customer-profile-hero {
            position: relative;
            width: 100%;
            height: 150px;
            background: linear-gradient(135deg, #00532B 0%, #00783E 55%, #12B15A 100%);
            border-radius: 0;
            overflow: hidden;
        }
        .customer-profile-hero-img { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; }
        .customer-profile-hero-overlay { position: absolute; inset: 0; background: rgba(0, 40, 20, 0.25); }
        .customer-profile-icon-btn {
            position: absolute; top: 12px; width: 36px; height: 36px; border-radius: 50%;
            background: rgba(0, 45, 22, 0.45); color: #fff; display: flex; align-items: center; justify-content: center;
            border: none; cursor: pointer; z-index: 2;
        }
        .customer-profile-icon-btn:hover { background: rgba(0, 45, 22, 0.68); }
        .customer-profile-icon-btn .lci { width: 18px; height: 18px; }
        #chpBackBtn { left: 12px; }
        #chpCoverBtn { right: 12px; }

        .customer-profile-card {
            position: relative; z-index: 3;
            margin: -46px 12px 0;
            background: rgba(255, 255, 255, 0.10);
            backdrop-filter: blur(6px);
            border: 1px solid rgba(255, 255, 255, 0.22);
            border-radius: 14px;
            min-height: 100px;
            padding: 16px 20px;
            display: flex; align-items: center; gap: 20px; flex-wrap: wrap;
        }
        .customer-profile-avatar-wrap { position: relative; flex-shrink: 0; }
        .customer-profile-avatar {
            width: 56px; height: 56px; border-radius: 50%; object-fit: cover;
            background: #00532B; color: #fff;
            display: flex; align-items: center; justify-content: center;
            font-size: 20px; font-weight: 800; border: 2px solid rgba(255, 255, 255, 0.85);
        }
        .customer-profile-avatar-cam {
            position: absolute; bottom: -2px; right: -2px; width: 22px; height: 22px; border-radius: 50%;
            background: #00783E; color: #fff; border: 2px solid #fff;
            display: flex; align-items: center; justify-content: center; cursor: pointer;
        }
        .customer-profile-avatar-cam .lci { width: 12px; height: 12px; }
        .customer-profile-identity { min-width: 0; }
        .customer-profile-name { font-size: 20px; font-weight: 700; color: #fff; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 260px; }
        .customer-profile-email-pill {
            display: inline-flex; align-items: center; gap: 5px; margin-top: 4px;
            background: rgba(255, 255, 255, 0.16); border-radius: 999px; padding: 3px 10px;
            font-size: 10.5px; color: rgba(255, 255, 255, 0.92); max-width: 240px;
        }
        .customer-profile-email-pill span { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .customer-profile-email-pill .lci { width: 12px; height: 12px; flex-shrink: 0; }
        .customer-profile-facts { display: flex; gap: 28px; margin-left: auto; flex-wrap: wrap; }
        .customer-profile-fact { text-align: center; min-width: 72px; }
        .customer-profile-fact .lci { width: 15px; height: 15px; color: #fff; }
        .customer-profile-fact-label { font-size: 10.5px; font-weight: 700; color: rgba(255, 255, 255, 0.72); text-transform: uppercase; letter-spacing: .03em; margin-top: 2px; }
        .customer-profile-fact-value { font-size: 13px; font-weight: 700; color: #fff; margin-top: 1px; }
        .customer-profile-edit-btn {
            display: inline-flex; align-items: center; gap: 6px; padding: 7px 12px;
            background: rgba(255, 255, 255, 0.14); border: 1px solid rgba(255, 255, 255, 0.5); color: #fff;
            border-radius: 8px; font-size: 12.5px; font-weight: 700; cursor: pointer; font-family: inherit;
        }
        .customer-profile-edit-btn:hover { background: rgba(255, 255, 255, 0.24); }
        .customer-profile-edit-btn .lci { width: 14px; height: 14px; }

        .customer-profile-tabs {
            display: flex; margin: 14px 12px 0; background: transparent;
            border-radius: 10px; padding: 0; gap: 10px; height: 44px;
        }
        .customer-profile-tab {
            flex: 1; border: 2px solid rgba(255,255,255,.55); background: rgba(255,255,255,.10); color: #fff;
            font-family: inherit; font-size: 14px; font-weight: 700; border-radius: 10px; cursor: pointer;
            transition: background 140ms ease, color 140ms ease, border-color 140ms ease;
        }
        .customer-profile-tab.is-active { background: #fff; color: #00783E; border-color: #fff; }

        .customer-profile-section-wrap { margin: 12px; background: #fff; border-radius: 12px; padding: 22px; min-height: 320px; }
        .customer-profile-section + .customer-profile-section { margin-top: 26px; }
        .customer-profile-section-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; }
        .customer-profile-section-title { font-size: 14.5px; font-weight: 700; color: #00783E; flex: 1; }
        .customer-profile-section-edit { background: none; border: none; cursor: pointer; color: #829AB1; padding: 4px; }
        .customer-profile-section-edit .lci { width: 16px; height: 16px; }
        .customer-profile-divider { border: none; border-top: 1px solid #EEF1F5; margin: 10px 0 16px; }

        .customer-profile-physical-row { display: flex; }
        .customer-profile-physical-col { flex: 1; text-align: center; padding: 10px 0; }
        .customer-profile-physical-col + .customer-profile-physical-col { border-left: 1px solid #EEF1F5; }
        .customer-profile-physical-label { font-size: 11px; color: #829AB1; font-weight: 700; }
        .customer-profile-physical-value { font-size: 18px; font-weight: 700; color: #102A43; margin-top: 4px; }

        .customer-profile-note-row { display: flex; align-items: flex-start; gap: 10px; padding: 4px 0; }
        .customer-profile-note-row .lci { width: 17px; height: 17px; color: var(--vs-primary-600, #1677D2); margin-top: 2px; flex-shrink: 0; }
        .customer-profile-note-text { font-size: 13px; color: #33544a; }
        .customer-profile-note-placeholder { font-size: 13px; color: #829AB1; }

        .customer-profile-perso-row { display: flex; align-items: center; gap: 12px; padding: 9px 0; border-bottom: 1px solid #F6F8FA; }
        .customer-profile-perso-row:last-child { border-bottom: none; }
        .customer-profile-perso-row .lci { width: 17px; height: 17px; color: var(--vs-primary-600, #1677D2); flex-shrink: 0; }
        .customer-profile-perso-label { font-size: 13px; color: #33544a; flex: 1; }
        .customer-profile-perso-value { font-size: 13px; font-weight: 600; color: #102A43; }

        .customer-profile-team-item { display: flex; align-items: center; gap: 12px; padding: 12px; border: 1px solid #EEF1F5; border-radius: 10px; }
        .customer-profile-team-item + .customer-profile-team-item { margin-top: 10px; }
        .customer-profile-team-avatar { width: 40px; height: 40px; border-radius: 50%; object-fit: cover; background: var(--vs-primary-600, #1677D2); color: #fff; display: flex; align-items: center; justify-content: center; font-weight: 700; flex-shrink: 0; }
        .customer-profile-team-name { font-size: 13.5px; font-weight: 700; color: #102A43; }
        .customer-profile-team-meta { font-size: 11.5px; color: #829AB1; }
        .customer-profile-empty { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 48px 0; color: #829AB1; }
        .customer-profile-empty .lci { width: 40px; height: 40px; margin-bottom: 10px; }
        .customer-profile-empty p { font-size: 13.5px; }

        @media (max-width: 767px) {
            .customer-profile-hero { height: 200px; }
            .customer-profile-card { flex-direction: column; align-items: flex-start; margin-top: -70px; }
            .customer-profile-facts { margin-left: 0; width: 100%; justify-content: space-between; }
        }

        /* Relocated from TaiKhoan.jsp: base-info view/edit form styling */
        .info-card { background: #fff; border-radius: 0; padding: 0; }
        .acc-field-view dt { font-size: 12px; font-weight: 700; color: #829AB1; text-transform: uppercase; letter-spacing: .03em; margin-bottom: 4px; }
        .acc-field-view dd { font-size: 14.5px; font-weight: 600; color: #102A43; }
        .acc-input {
            width: 100%; height: 44px; padding: 0 14px; border-radius: 8px;
            border: 1px solid #DCE5EF; background: #fff; font-size: 14px; color: #102A43;
            font-family: inherit;
        }
        .acc-input:focus { outline: none; border-color: #18C8E8; box-shadow: 0 0 0 3px rgba(24, 200, 232, .22); }
        .acc-label { display: block; font-size: 12.5px; font-weight: 700; color: #33544a; margin-bottom: 6px; }
        .btn-primary {
            display: inline-flex; align-items: center; justify-content: center; gap: 7px;
            background: var(--vs-primary-600, #1677D2); color: #fff; font-weight: 700; font-size: 14px;
            padding: 11px 18px; border-radius: 8px; text-decoration: none; cursor: pointer;
            font-family: inherit; border: none;
        }
        .btn-primary:hover { background: var(--vs-primary-700, #185A9D); }
        .btn-primary:disabled { opacity: .6; cursor: not-allowed; }
        .btn-secondary {
            display: inline-flex; align-items: center; justify-content: center; gap: 7px;
            background: #fff; color: #33544a; font-weight: 700; font-size: 14px;
            padding: 11px 18px; border-radius: 8px; border: 1px solid #DCE5EF;
            cursor: pointer; font-family: inherit;
        }
        .btn-secondary:hover { background: #f8fbf9; }
    </style>
</head>
<body class="antialiased">

<div class="customer-profile-page">

    <div class="customer-profile-hero">
        <c:if test="${not empty profileExtra.coverImageUrl}">
            <img class="customer-profile-hero-img" src="${pageContext.request.contextPath}${profileExtra.coverImageUrl}" alt="Ảnh bìa">
        </c:if>
        <div class="customer-profile-hero-overlay"></div>
        <button type="button" id="chpBackBtn" class="customer-profile-icon-btn" aria-label="Quay lại tài khoản" onclick="location.href = CTX + '/customer/tai-khoan';">
            <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"/></svg>
        </button>
        <button type="button" id="chpCoverBtn" class="customer-profile-icon-btn" aria-label="Đổi ảnh bìa" onclick="document.getElementById('chpCoverInput').click();">
            <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"/><circle cx="12" cy="13" r="3"/></svg>
        </button>
        <input id="chpCoverInput" type="file" accept="image/jpeg,image/png,image/webp" class="hidden">
    </div>

    <div class="customer-profile-card">
        <div class="customer-profile-avatar-wrap">
            <c:choose>
                <c:when test="${not empty account.avatarUrl}">
                    <img id="chpAvatarPreview" class="customer-profile-avatar js-avatar-img" src="${pageContext.request.contextPath}${account.avatarUrl}" alt="Ảnh đại diện">
                </c:when>
                <c:otherwise>
                    <span id="chpAvatarInitial" class="customer-profile-avatar js-avatar-initial" aria-hidden="true"><c:choose><c:when test="${not empty account.fullName}">${fn:escapeXml(fn:substring(account.fullName, 0, 1))}</c:when><c:otherwise>${fn:escapeXml(fn:substring(account.username, 0, 1))}</c:otherwise></c:choose></span>
                    <img id="chpAvatarPreview" class="customer-profile-avatar js-avatar-img" src="" alt="Ảnh đại diện" hidden>
                </c:otherwise>
            </c:choose>
            <label for="accAvatarInput" class="customer-profile-avatar-cam" aria-label="Đổi ảnh đại diện">
                <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"/><circle cx="12" cy="13" r="3"/></svg>
            </label>
            <input id="accAvatarInput" type="file" accept="image/jpeg,image/png,image/webp,image/gif" class="hidden">
        </div>
        <div class="customer-profile-identity">
            <div id="chpName" class="customer-profile-name">${fn:escapeXml(not empty account.fullName ? account.fullName : account.username)}</div>
            <div class="customer-profile-email-pill">
                <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>
                <span id="chpEmail">${not empty account.email ? fn:escapeXml(account.email) : 'Chưa cập nhật email'}</span>
            </div>
        </div>
        <div class="customer-profile-facts">
            <div class="customer-profile-fact">
                <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M13.832 16.568a1 1 0 0 0 1.213-.303l.355-.465A2 2 0 0 1 17 15h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2A18 18 0 0 1 2 4a2 2 0 0 1 2-2h3a2 2 0 0 1 2 2v3a2 2 0 0 1-.8 1.6l-.468.351a1 1 0 0 0-.292 1.233 14 14 0 0 0 6.392 6.384"/></svg>
                <div class="customer-profile-fact-label">Điện thoại</div>
                <div id="chpPhone" class="customer-profile-fact-value">${not empty account.phoneNumber ? fn:escapeXml(account.phoneNumber) : '-'}</div>
            </div>
            <div class="customer-profile-fact">
                <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/></svg>
                <div class="customer-profile-fact-label">Năm sinh</div>
                <div id="chpBirthYear" class="customer-profile-fact-value">
                    <c:choose>
                        <c:when test="${account.ngaySinh != null}"><fmt:formatDate value="${account.ngaySinh}" pattern="yyyy"/></c:when>
                        <c:otherwise>-</c:otherwise>
                    </c:choose>
                </div>
            </div>
            <div class="customer-profile-fact">
                <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="8" r="5"/><path d="M20 21a8 8 0 0 0-16 0"/></svg>
                <div class="customer-profile-fact-label">Giới tính</div>
                <div id="chpGender" class="customer-profile-fact-value">${not empty account.gioiTinh ? fn:escapeXml(account.gioiTinh) : '-'}</div>
            </div>
        </div>
        <button type="button" class="customer-profile-edit-btn" onclick="openBaseInfoEdit()">
            <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"/></svg>
            Chỉnh sửa
        </button>
    </div>

    <div class="customer-profile-tabs" role="tablist">
        <button type="button" class="customer-profile-tab is-active" id="chpTabOverviewBtn" role="tab" aria-selected="true" onclick="chpSwitchTab('overview')">Tổng quan</button>
        <button type="button" class="customer-profile-tab" id="chpTabLinksBtn" role="tab" aria-selected="false" onclick="chpSwitchTab('links')">Liên kết</button>
    </div>

    <div id="chpTabOverview" class="customer-profile-tab-panel">
        <div class="customer-profile-section-wrap">

            <div class="customer-profile-section">
                <div class="customer-profile-section-header">
                    <span class="customer-profile-section-title">Thông tin thể chất</span>
                    <button type="button" class="customer-profile-section-edit" aria-label="Chỉnh sửa thông tin thể chất" onclick="openModal('chpPhysicalModal')">
                        <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"/></svg>
                    </button>
                </div>
                <hr class="customer-profile-divider">
                <div class="customer-profile-physical-row">
                    <div class="customer-profile-physical-col">
                        <div class="customer-profile-physical-label">CHIỀU CAO (CM)</div>
                        <div id="chpHeightValue" class="customer-profile-physical-value">${not empty profileExtra.heightCm ? profileExtra.heightCm : '-'}</div>
                    </div>
                    <div class="customer-profile-physical-col">
                        <div class="customer-profile-physical-label">CÂN NẶNG (KG)</div>
                        <div id="chpWeightValue" class="customer-profile-physical-value">${not empty profileExtra.weightKg ? profileExtra.weightKg : '-'}</div>
                    </div>
                </div>
            </div>

            <div class="customer-profile-section">
                <div class="customer-profile-section-header">
                    <span class="customer-profile-section-title">Ghi chú đặc biệt</span>
                    <button type="button" class="customer-profile-section-edit" aria-label="Chỉnh sửa ghi chú đặc biệt" onclick="openNoteEdit()">
                        <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"/></svg>
                    </button>
                </div>
                <hr class="customer-profile-divider">
                <div class="customer-profile-note-row">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><rect width="8" height="4" x="8" y="2" rx="1"/></svg>
                    <c:choose>
                        <c:when test="${not empty profileExtra.specialNote}">
                            <span id="chpNoteText" class="customer-profile-note-text">${fn:escapeXml(profileExtra.specialNote)}</span>
                        </c:when>
                        <c:otherwise>
                            <span id="chpNoteText" class="customer-profile-note-placeholder">Chưa có ghi chú</span>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>

            <div class="customer-profile-section">
                <div class="customer-profile-section-header">
                    <span class="customer-profile-section-title">Cá nhân hoá</span>
                    <button type="button" class="customer-profile-section-edit" aria-label="Chỉnh sửa cá nhân hóa" onclick="openModal('chpPersoModal')">
                        <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"/></svg>
                    </button>
                </div>
                <hr class="customer-profile-divider">
                <div class="customer-profile-perso-row">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0"/><circle cx="12" cy="10" r="3"/></svg>
                    <span class="customer-profile-perso-label">Vị trí yêu thích</span>
                    <span id="chpLocationValue" class="customer-profile-perso-value">${not empty profileExtra.preferredLocation ? fn:escapeXml(profileExtra.preferredLocation) : '-'}</span>
                </div>
                <div class="customer-profile-perso-row">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="8" r="6"/><path d="M15.477 12.89 17 22l-5-3-5 3 1.523-9.11"/></svg>
                    <span class="customer-profile-perso-label">Môn thể thao và trình độ</span>
                    <span id="chpSportLevelValue" class="customer-profile-perso-value">
                        <c:choose>
                            <c:when test="${not empty profileExtra.favoriteSportName}">${fn:escapeXml(profileExtra.favoriteSportName)}<c:if test="${not empty profileExtra.skillLevel}"> - ${fn:escapeXml(profileExtra.skillLevel)}</c:if></c:when>
                            <c:otherwise>-</c:otherwise>
                        </c:choose>
                    </span>
                </div>
                <div class="customer-profile-perso-row">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/></svg>
                    <span class="customer-profile-perso-label">Mục tiêu</span>
                    <span id="chpGoalValue" class="customer-profile-perso-value">${not empty profileExtra.goal ? fn:escapeXml(profileExtra.goal) : '-'}</span>
                </div>
                <div class="customer-profile-perso-row">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/></svg>
                    <span class="customer-profile-perso-label">Tần suất chơi</span>
                    <span id="chpFrequencyValue" class="customer-profile-perso-value">${not empty profileExtra.playFrequency ? fn:escapeXml(profileExtra.playFrequency) : '-'}</span>
                </div>
            </div>

        </div>
    </div>

    <div id="chpTabLinks" class="customer-profile-tab-panel hidden">
        <div class="customer-profile-section-wrap">
            <c:choose>
                <c:when test="${not empty myTeams}">
                    <c:forEach var="team" items="${myTeams}">
                        <div class="customer-profile-team-item">
                            <c:choose>
                                <c:when test="${not empty team.avatarPath}">
                                    <img class="customer-profile-team-avatar" src="${pageContext.request.contextPath}${team.avatarPath}" alt="${fn:escapeXml(team.teamName)}">
                                </c:when>
                                <c:otherwise>
                                    <span class="customer-profile-team-avatar">${fn:escapeXml(fn:substring(team.teamName, 0, 1))}</span>
                                </c:otherwise>
                            </c:choose>
                            <div>
                                <div class="customer-profile-team-name">${fn:escapeXml(team.teamName)}</div>
                                <div class="customer-profile-team-meta">${fn:escapeXml(team.myRole)} &middot; ${team.memberCount}/${team.maxMembers} thành viên</div>
                            </div>
                        </div>
                    </c:forEach>
                </c:when>
                <c:otherwise>
                    <div class="customer-profile-empty">
                        <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
                        <p>Bạn chưa tham gia đội nhóm nào.</p>
                    </div>
                </c:otherwise>
            </c:choose>
        </div>
    </div>

</div>

<!-- Base info edit modal (relocated from TaiKhoan.jsp #thongtin section) -->
<div id="chpBaseInfoModal" class="hidden fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[300] flex items-center justify-center p-4">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-[560px] border border-slate-200 max-h-[90vh] overflow-y-auto">
        <div class="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
            <h3 class="text-sm font-extrabold" style="color:#102A43;">Chỉnh sửa thông tin cá nhân</h3>
            <button type="button" onclick="closeModal('chpBaseInfoModal')" class="w-8 h-8 rounded-full hover:bg-slate-100 flex items-center justify-center" aria-label="Đóng">
                <svg class="lci text-slate-500" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
            </button>
        </div>
        <form id="infoEditForm" class="px-6 py-5 grid grid-cols-1 sm:grid-cols-2 gap-4" onsubmit="return false;" autocomplete="off">
            <div>
                <label class="acc-label" for="editFullName">Họ và tên</label>
                <input id="editFullName" type="text" class="acc-input" value="${fn:escapeXml(account.fullName)}" maxlength="100">
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="fullName"></p>
            </div>
            <div>
                <label class="acc-label" for="editEmail">Email</label>
                <input id="editEmail" type="email" class="acc-input" value="${fn:escapeXml(account.email)}">
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="email"></p>
            </div>
            <div>
                <label class="acc-label" for="editPhone">Số điện thoại</label>
                <input id="editPhone" type="tel" class="acc-input" value="${fn:escapeXml(account.phoneNumber)}">
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="phone"></p>
            </div>
            <div>
                <label class="acc-label" for="editBirthday">Ngày sinh</label>
                <input id="editBirthday" type="date" class="acc-input" value="<c:if test="${account.ngaySinh != null}"><fmt:formatDate value="${account.ngaySinh}" pattern="yyyy-MM-dd"/></c:if>">
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="birthday"></p>
            </div>
            <div>
                <label class="acc-label" for="editGender">Giới tính</label>
                <select id="editGender" class="acc-input">
                    <option value="" ${empty account.gioiTinh ? 'selected' : ''}>-- Không chọn --</option>
                    <option value="Nam" ${account.gioiTinh == 'Nam' ? 'selected' : ''}>Nam</option>
                    <option value="Nữ" ${account.gioiTinh == 'Nữ' ? 'selected' : ''}>Nữ</option>
                    <option value="Khác" ${account.gioiTinh == 'Khác' ? 'selected' : ''}>Khác</option>
                </select>
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="gender"></p>
            </div>
            <div class="sm:col-span-2 flex justify-end gap-3 pt-2">
                <button type="button" onclick="closeModal('chpBaseInfoModal')" class="btn-secondary">Hủy</button>
                <button type="button" id="saveInfoBtn" onclick="saveProfileInfo()" class="btn-primary">Lưu thay đổi</button>
            </div>
        </form>
    </div>
</div>

<!-- Email OTP modal (relocated from TaiKhoan.jsp) -->
<div id="emailOtpModal" class="hidden fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[300] flex items-center justify-center p-4">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-[400px] border border-slate-200">
        <div class="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
            <h3 class="text-sm font-extrabold flex items-center gap-2" style="color:#102A43;">
                <svg class="lci" style="color:#1677D2;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M22 13V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v12c0 1.1.9 2 2 2h8"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/><path d="m16 19 2 2 4-4"/></svg>
                Xác thực email mới
            </h3>
            <button type="button" onclick="closeModal('emailOtpModal')" class="w-8 h-8 rounded-full hover:bg-slate-100 flex items-center justify-center" aria-label="Đóng">
                <svg class="lci text-slate-500" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
            </button>
        </div>
        <div class="px-6 py-5">
            <p class="text-sm text-slate-600">Mã OTP đã được gửi đến <strong id="otpTargetEmail" class="text-slate-900"></strong>. Nhập mã để hoàn tất thay đổi.</p>
            <input id="otpInput" type="text" maxlength="6" inputmode="numeric" placeholder="••••••" class="acc-input mt-4 text-center text-xl font-black tracking-[0.3em]">
            <p id="otpError" class="hidden mt-2 text-[12px] font-semibold text-red-600"></p>
        </div>
        <div class="px-6 pb-5 flex justify-end gap-3">
            <button type="button" onclick="closeModal('emailOtpModal')" class="btn-secondary">Hủy</button>
            <button type="button" id="otpConfirmBtn" onclick="verifyEmailOtp()" class="btn-primary">Xác thực</button>
        </div>
    </div>
</div>

<!-- Toast (relocated from TaiKhoan.jsp) -->
<div id="accToast" class="hidden fixed bottom-6 right-6 z-[999] max-w-sm bg-white border border-slate-200 shadow-lg rounded-xl px-4 py-3 flex items-start gap-3 opacity-0 translate-y-3">
    <span id="accToastIconOk" class="mt-0.5 text-emerald-600"><svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/></svg></span>
    <span id="accToastIconErr" class="mt-0.5 text-red-500 hidden"><svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" x2="12" y1="8" y2="12"/><line x1="12" x2="12.01" y1="16" y2="16"/></svg></span>
    <div>
        <p id="accToastTitle" class="text-sm font-bold" style="color:#102A43;">Thành công</p>
        <p id="accToastMessage" class="text-xs mt-0.5" style="color:#829AB1;"></p>
    </div>
</div>

<!-- Physical info edit modal -->
<div id="chpPhysicalModal" class="hidden fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[300] flex items-center justify-center p-4">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-[400px] border border-slate-200">
        <div class="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
            <h3 class="text-sm font-extrabold" style="color:#102A43;">Chỉnh sửa thông tin thể chất</h3>
            <button type="button" onclick="closeModal('chpPhysicalModal')" class="w-8 h-8 rounded-full hover:bg-slate-100 flex items-center justify-center" aria-label="Đóng">
                <svg class="lci text-slate-500" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
            </button>
        </div>
        <form id="chpPhysicalForm" class="px-6 py-5 flex flex-col gap-4" onsubmit="return false;">
            <div>
                <label class="acc-label" for="chpHeightInput">Chiều cao (cm)</label>
                <input id="chpHeightInput" type="number" min="50" max="260" class="acc-input" value="${profileExtra.heightCm}">
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="heightCm"></p>
            </div>
            <div>
                <label class="acc-label" for="chpWeightInput">Cân nặng (kg)</label>
                <input id="chpWeightInput" type="number" min="20" max="300" class="acc-input" value="${profileExtra.weightKg}">
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="weightKg"></p>
            </div>
            <div class="flex justify-end gap-3 pt-2">
                <button type="button" onclick="closeModal('chpPhysicalModal')" class="btn-secondary">Hủy</button>
                <button type="button" id="chpPhysicalSaveBtn" onclick="chpSavePhysical()" class="btn-primary">Lưu thay đổi</button>
            </div>
        </form>
    </div>
</div>

<!-- Special note edit modal -->
<div id="chpNoteModal" class="hidden fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[300] flex items-center justify-center p-4">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-[440px] border border-slate-200">
        <div class="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
            <h3 class="text-sm font-extrabold" style="color:#102A43;">Chỉnh sửa ghi chú đặc biệt</h3>
            <button type="button" onclick="closeModal('chpNoteModal')" class="w-8 h-8 rounded-full hover:bg-slate-100 flex items-center justify-center" aria-label="Đóng">
                <svg class="lci text-slate-500" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
            </button>
        </div>
        <form id="chpNoteForm" class="px-6 py-5 flex flex-col gap-4" onsubmit="return false;">
            <div>
                <label class="acc-label" for="chpNoteInput">Ghi chú đặc biệt</label>
                <textarea id="chpNoteInput" maxlength="500" rows="4" class="acc-input" style="height:auto;padding:10px 14px;">${fn:escapeXml(profileExtra.specialNote)}</textarea>
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="note"></p>
            </div>
            <div class="flex justify-end gap-3 pt-2">
                <button type="button" onclick="closeModal('chpNoteModal')" class="btn-secondary">Hủy</button>
                <button type="button" id="chpNoteSaveBtn" onclick="chpSaveNote()" class="btn-primary">Lưu thay đổi</button>
            </div>
        </form>
    </div>
</div>

<!-- Personalization edit modal -->
<div id="chpPersoModal" class="hidden fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[300] flex items-center justify-center p-4">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-[460px] border border-slate-200 max-h-[90vh] overflow-y-auto">
        <div class="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
            <h3 class="text-sm font-extrabold" style="color:#102A43;">Chỉnh sửa cá nhân hoá</h3>
            <button type="button" onclick="closeModal('chpPersoModal')" class="w-8 h-8 rounded-full hover:bg-slate-100 flex items-center justify-center" aria-label="Đóng">
                <svg class="lci text-slate-500" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
            </button>
        </div>
        <form id="chpPersoForm" class="px-6 py-5 flex flex-col gap-4" onsubmit="return false;">
            <div>
                <label class="acc-label" for="chpLocationInput">Vị trí yêu thích</label>
                <input id="chpLocationInput" type="text" maxlength="255" class="acc-input" value="${fn:escapeXml(profileExtra.preferredLocation)}">
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="location"></p>
            </div>
            <div>
                <label class="acc-label" for="chpSportInput">Môn thể thao yêu thích</label>
                <select id="chpSportInput" class="acc-input">
                    <option value="">-- Không chọn --</option>
                    <c:forEach var="mon" items="${dsMon}">
                        <option value="${mon.monTheThaoID}" ${mon.monTheThaoID == profileExtra.favoriteSportId ? 'selected' : ''}>${fn:escapeXml(mon.tenMon)}</option>
                    </c:forEach>
                </select>
            </div>
            <div>
                <label class="acc-label" for="chpLevelInput">Trình độ</label>
                <select id="chpLevelInput" class="acc-input">
                    <option value="">-- Không chọn --</option>
                    <option value="Mới chơi" ${profileExtra.skillLevel == 'Mới chơi' ? 'selected' : ''}>Mới chơi</option>
                    <option value="Cơ bản" ${profileExtra.skillLevel == 'Cơ bản' ? 'selected' : ''}>Cơ bản</option>
                    <option value="Trung bình" ${profileExtra.skillLevel == 'Trung bình' ? 'selected' : ''}>Trung bình</option>
                    <option value="Khá" ${profileExtra.skillLevel == 'Khá' ? 'selected' : ''}>Khá</option>
                    <option value="Nâng cao" ${profileExtra.skillLevel == 'Nâng cao' ? 'selected' : ''}>Nâng cao</option>
                </select>
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="level"></p>
            </div>
            <div>
                <label class="acc-label" for="chpGoalInput">Mục tiêu</label>
                <input id="chpGoalInput" type="text" maxlength="255" class="acc-input" value="${fn:escapeXml(profileExtra.goal)}">
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="goal"></p>
            </div>
            <div>
                <label class="acc-label" for="chpFrequencyInput">Tần suất chơi</label>
                <select id="chpFrequencyInput" class="acc-input">
                    <option value="">-- Không chọn --</option>
                    <option value="1 lần/tuần" ${profileExtra.playFrequency == '1 lần/tuần' ? 'selected' : ''}>1 lần/tuần</option>
                    <option value="2-3 lần/tuần" ${profileExtra.playFrequency == '2-3 lần/tuần' ? 'selected' : ''}>2-3 lần/tuần</option>
                    <option value="4+ lần/tuần" ${profileExtra.playFrequency == '4+ lần/tuần' ? 'selected' : ''}>4+ lần/tuần</option>
                    <option value="Không cố định" ${profileExtra.playFrequency == 'Không cố định' ? 'selected' : ''}>Không cố định</option>
                </select>
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="frequency"></p>
            </div>
            <div class="flex justify-end gap-3 pt-2">
                <button type="button" onclick="closeModal('chpPersoModal')" class="btn-secondary">Hủy</button>
                <button type="button" id="chpPersoSaveBtn" onclick="chpSavePersonalization()" class="btn-primary">Lưu thay đổi</button>
            </div>
        </form>
    </div>
</div>

<script>
    const CTX = '${pageContext.request.contextPath}';
    const birthdayInput = document.getElementById('editBirthday');
    if (birthdayInput) birthdayInput.max = new Date().toISOString().split('T')[0];

    function chpSwitchTab(tab) {
        document.getElementById('chpTabOverviewBtn').classList.toggle('is-active', tab === 'overview');
        document.getElementById('chpTabOverviewBtn').setAttribute('aria-selected', tab === 'overview');
        document.getElementById('chpTabLinksBtn').classList.toggle('is-active', tab === 'links');
        document.getElementById('chpTabLinksBtn').setAttribute('aria-selected', tab === 'links');
        document.getElementById('chpTabOverview').classList.toggle('hidden', tab !== 'overview');
        document.getElementById('chpTabLinks').classList.toggle('hidden', tab !== 'links');
    }

    function openModal(id) { document.getElementById(id).classList.remove('hidden'); }
    function closeModal(id) { document.getElementById(id).classList.add('hidden'); }
    document.querySelectorAll('#chpBaseInfoModal, #emailOtpModal, #chpPhysicalModal, #chpNoteModal, #chpPersoModal').forEach(overlay => {
        overlay.addEventListener('click', (e) => { if (e.target === overlay) closeModal(overlay.id); });
    });
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') { closeModal('chpBaseInfoModal'); closeModal('emailOtpModal'); closeModal('chpPhysicalModal'); closeModal('chpNoteModal'); closeModal('chpPersoModal'); }
    });

    function openBaseInfoEdit() { openModal('chpBaseInfoModal'); }

    // ---- Toast ----
    function showToast(title, message, isError) {
        const toast = document.getElementById('accToast');
        document.getElementById('accToastTitle').textContent = title;
        document.getElementById('accToastMessage').textContent = message || '';
        document.getElementById('accToastIconOk').classList.toggle('hidden', !!isError);
        document.getElementById('accToastIconErr').classList.toggle('hidden', !isError);
        toast.classList.remove('hidden');
        requestAnimationFrame(() => { toast.classList.remove('opacity-0', 'translate-y-3'); });
        clearTimeout(window.__accToastTimer);
        window.__accToastTimer = setTimeout(() => {
            toast.classList.add('opacity-0', 'translate-y-3');
            setTimeout(() => toast.classList.add('hidden'), 250);
        }, 4000);
    }

    function clearFieldErrors(scopeEl) {
        scopeEl.querySelectorAll('[data-error-for]').forEach(el => { el.textContent = ''; el.classList.add('hidden'); });
    }
    function showFieldErrors(scopeEl, fieldErrors) {
        clearFieldErrors(scopeEl);
        if (!fieldErrors) return;
        Object.keys(fieldErrors).forEach(key => {
            const el = scopeEl.querySelector('[data-error-for="' + key + '"]');
            if (el) { el.textContent = fieldErrors[key]; el.classList.remove('hidden'); }
        });
    }

    function formatDateVn(iso) {
        const parts = iso.split('-');
        return parts.length === 3 ? (parts[2] + '/' + parts[1] + '/' + parts[0]) : iso;
    }

    // ---- Save base profile info (relocated from TaiKhoan.jsp saveProfileInfo) ----
    function saveProfileInfo() {
        const fullName = document.getElementById('editFullName').value;
        const email = document.getElementById('editEmail').value;
        const phone = document.getElementById('editPhone').value;
        const birthday = document.getElementById('editBirthday').value;
        const gender = document.getElementById('editGender').value;

        const btn = document.getElementById('saveInfoBtn');
        btn.disabled = true;
        const originalText = btn.textContent;
        btn.textContent = 'Đang lưu...';

        const params = new URLSearchParams();
        params.append('action', 'updateInfo');
        params.append('fullName', fullName);
        params.append('email', email);
        params.append('phoneNumber', phone);
        params.append('birthday', birthday);
        params.append('gender', gender);

        fetch(CTX + '/account/update-profile', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
            body: params
        })
            .then(r => r.json())
            .then(data => {
                btn.disabled = false;
                btn.textContent = originalText;
                if (data.success) {
                    if (data.requiresOtp) {
                        document.getElementById('otpTargetEmail').textContent = data.email || email;
                        document.getElementById('otpInput').value = '';
                        document.getElementById('otpError').classList.add('hidden');
                        openModal('emailOtpModal');
                        showToast('Đã gửi mã OTP', data.message);
                        return;
                    }
                    syncProfileUi(data);
                    closeModal('chpBaseInfoModal');
                    showToast('Thành công', 'Đã cập nhật thông tin cá nhân.');
                } else if (data.code === 'VALIDATION_ERROR') {
                    showFieldErrors(document.getElementById('infoEditForm'), data.fieldErrors);
                } else {
                    showToast('Không thể cập nhật', data.message, true);
                }
            })
            .catch(() => {
                btn.disabled = false;
                btn.textContent = originalText;
                showToast('Lỗi kết nối', 'Không thể kết nối máy chủ. Vui lòng thử lại.', true);
            });
    }

    function verifyEmailOtp() {
        const otp = document.getElementById('otpInput').value.trim();
        const err = document.getElementById('otpError');
        if (!/^\d{6}$/.test(otp)) {
            err.textContent = 'Vui lòng nhập mã OTP gồm 6 chữ số.';
            err.classList.remove('hidden');
            return;
        }
        const btn = document.getElementById('otpConfirmBtn');
        btn.disabled = true;

        const params = new URLSearchParams();
        params.append('action', 'verifyEmailOtp');
        params.append('otp', otp);

        fetch(CTX + '/account/update-profile', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
            body: params
        })
            .then(r => r.json())
            .then(data => {
                btn.disabled = false;
                if (data.success) {
                    syncProfileUi(data);
                    closeModal('emailOtpModal');
                    closeModal('chpBaseInfoModal');
                    showToast('Thành công', 'Đã cập nhật thông tin cá nhân.');
                } else {
                    err.textContent = data.message || 'Không thể xác thực OTP.';
                    err.classList.remove('hidden');
                }
            })
            .catch(() => {
                btn.disabled = false;
                err.textContent = 'Lỗi kết nối. Vui lòng thử lại.';
                err.classList.remove('hidden');
            });
    }

    function syncProfileUi(data) {
        document.getElementById('chpName').textContent = data.fullName || '-';
        document.getElementById('chpEmail').textContent = data.email || 'Chưa cập nhật email';
        document.getElementById('chpPhone').textContent = data.phoneNumber || '-';
        document.getElementById('chpBirthYear').textContent = data.birthday ? data.birthday.split('-')[0] : '-';
        document.getElementById('chpGender').textContent = data.gender || '-';

        document.getElementById('editFullName').value = data.fullName || '';
        document.getElementById('editEmail').value = data.email || '';
        document.getElementById('editPhone').value = data.phoneNumber || '';
        document.getElementById('editBirthday').value = data.birthday || '';
        document.getElementById('editGender').value = data.gender || '';
    }

    // ---- Avatar upload (relocated from TaiKhoan.jsp) ----
    document.getElementById('accAvatarInput').addEventListener('change', function () {
        const file = this.files && this.files[0];
        if (!file) return;

        if (file.size > 2 * 1024 * 1024) {
            showToast('Ảnh quá lớn', 'Vui lòng chọn ảnh dưới 2MB.', true);
            this.value = '';
            return;
        }
        if (!['image/jpeg', 'image/png', 'image/webp', 'image/gif'].includes(file.type)) {
            showToast('Định dạng không hỗ trợ', 'Chỉ hỗ trợ định dạng JPG, PNG, WEBP hoặc GIF.', true);
            this.value = '';
            return;
        }

        const fd = new FormData();
        fd.append('action', 'updateAvatar');
        fd.append('avatar', file);

        fetch(CTX + '/account/update-profile', { method: 'POST', body: fd })
            .then(r => r.json())
            .then(data => {
                if (data.success) {
                    document.querySelectorAll('.js-avatar-img').forEach(img => { img.src = data.avatarUrl; img.hidden = false; img.classList.remove('hidden'); });
                    document.querySelectorAll('.js-avatar-initial').forEach(el => { el.hidden = true; });
                    showToast('Thành công', 'Đã cập nhật ảnh đại diện.');
                } else {
                    showToast('Không thể tải ảnh lên', data.message, true);
                }
            })
            .catch(() => {
                showToast('Lỗi kết nối', 'Không thể tải ảnh lên. Vui lòng thử lại.', true);
            });
    });

    // ---- Physical info ----
    function chpSavePhysical() {
        const heightVal = document.getElementById('chpHeightInput').value.trim();
        const weightVal = document.getElementById('chpWeightInput').value.trim();
        const form = document.getElementById('chpPhysicalForm');
        clearFieldErrors(form);

        const btn = document.getElementById('chpPhysicalSaveBtn');
        btn.disabled = true;
        const originalText = btn.textContent;
        btn.textContent = 'Đang lưu...';

        const params = new URLSearchParams();
        if (heightVal) params.append('heightCm', heightVal);
        if (weightVal) params.append('weightKg', weightVal);

        fetch(CTX + '/customer/ho-so/cap-nhat-the-chat', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
            body: params
        })
            .then(r => r.json())
            .then(data => {
                btn.disabled = false;
                btn.textContent = originalText;
                if (data.success) {
                    document.getElementById('chpHeightValue').textContent = heightVal || '-';
                    document.getElementById('chpWeightValue').textContent = weightVal || '-';
                    closeModal('chpPhysicalModal');
                    showToast('Thành công', 'Đã cập nhật thông tin thể chất.');
                } else {
                    showToast('Không thể cập nhật', data.message, true);
                }
            })
            .catch(() => {
                btn.disabled = false;
                btn.textContent = originalText;
                showToast('Lỗi kết nối', 'Không thể kết nối máy chủ. Vui lòng thử lại.', true);
            });
    }

    // ---- Special note ----
    function openNoteEdit() { openModal('chpNoteModal'); }

    function chpSaveNote() {
        const note = document.getElementById('chpNoteInput').value;
        const form = document.getElementById('chpNoteForm');
        clearFieldErrors(form);

        const btn = document.getElementById('chpNoteSaveBtn');
        btn.disabled = true;
        const originalText = btn.textContent;
        btn.textContent = 'Đang lưu...';

        const params = new URLSearchParams();
        params.append('note', note);

        fetch(CTX + '/customer/ho-so/cap-nhat-ghi-chu', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
            body: params
        })
            .then(r => r.json())
            .then(data => {
                btn.disabled = false;
                btn.textContent = originalText;
                if (data.success) {
                    const textEl = document.getElementById('chpNoteText');
                    if (note.trim()) {
                        textEl.textContent = note.trim();
                        textEl.className = 'customer-profile-note-text';
                    } else {
                        textEl.textContent = 'Chưa có ghi chú';
                        textEl.className = 'customer-profile-note-placeholder';
                    }
                    closeModal('chpNoteModal');
                    showToast('Thành công', 'Đã cập nhật ghi chú.');
                } else {
                    showToast('Không thể cập nhật', data.message, true);
                }
            })
            .catch(() => {
                btn.disabled = false;
                btn.textContent = originalText;
                showToast('Lỗi kết nối', 'Không thể kết nối máy chủ. Vui lòng thử lại.', true);
            });
    }

    // ---- Personalization ----
    function chpSavePersonalization() {
        const location = document.getElementById('chpLocationInput').value;
        const sportId = document.getElementById('chpSportInput').value;
        const sportName = sportId ? document.getElementById('chpSportInput').selectedOptions[0].textContent : '';
        const level = document.getElementById('chpLevelInput').value;
        const goal = document.getElementById('chpGoalInput').value;
        const frequency = document.getElementById('chpFrequencyInput').value;
        const form = document.getElementById('chpPersoForm');
        clearFieldErrors(form);

        const btn = document.getElementById('chpPersoSaveBtn');
        btn.disabled = true;
        const originalText = btn.textContent;
        btn.textContent = 'Đang lưu...';

        const params = new URLSearchParams();
        params.append('location', location);
        if (sportId) params.append('sportId', sportId);
        params.append('level', level);
        params.append('goal', goal);
        params.append('frequency', frequency);

        fetch(CTX + '/customer/ho-so/cap-nhat-ca-nhan-hoa', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
            body: params
        })
            .then(r => r.json())
            .then(data => {
                btn.disabled = false;
                btn.textContent = originalText;
                if (data.success) {
                    document.getElementById('chpLocationValue').textContent = location.trim() || '-';
                    document.getElementById('chpSportLevelValue').textContent = sportId ? (sportName + (level ? ' - ' + level : '')) : '-';
                    document.getElementById('chpGoalValue').textContent = goal.trim() || '-';
                    document.getElementById('chpFrequencyValue').textContent = frequency || '-';
                    closeModal('chpPersoModal');
                    showToast('Thành công', 'Đã cập nhật cá nhân hoá.');
                } else if (data.code === 'VALIDATION_ERROR') {
                    showFieldErrors(form, data.fieldErrors);
                } else {
                    showToast('Không thể cập nhật', data.message, true);
                }
            })
            .catch(() => {
                btn.disabled = false;
                btn.textContent = originalText;
                showToast('Lỗi kết nối', 'Không thể kết nối máy chủ. Vui lòng thử lại.', true);
            });
    }

    // ---- Cover upload ----
    document.getElementById('chpCoverInput').addEventListener('change', function () {
        const file = this.files && this.files[0];
        if (!file) return;
        if (file.size > 5 * 1024 * 1024) {
            showToast('Ảnh quá lớn', 'Vui lòng chọn ảnh dưới 5MB.', true);
            this.value = '';
            return;
        }
        if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
            showToast('Định dạng không hỗ trợ', 'Chỉ hỗ trợ định dạng JPG, PNG hoặc WEBP.', true);
            this.value = '';
            return;
        }
        const btn = document.getElementById('chpCoverBtn');
        btn.disabled = true;
        const fd = new FormData();
        fd.append('cover', file);
        fetch(CTX + '/customer/ho-so/doi-cover', { method: 'POST', body: fd })
            .then(r => r.json())
            .then(data => {
                btn.disabled = false;
                if (data.success) {
                    let img = document.querySelector('.customer-profile-hero-img');
                    if (!img) {
                        img = document.createElement('img');
                        img.className = 'customer-profile-hero-img';
                        document.querySelector('.customer-profile-hero').prepend(img);
                    }
                    img.src = CTX + data.coverUrl;
                    showToast('Thành công', 'Đã cập nhật ảnh bìa.');
                } else {
                    showToast('Không thể tải ảnh lên', data.message, true);
                }
            })
            .catch(() => {
                btn.disabled = false;
                showToast('Lỗi kết nối', 'Không thể tải ảnh lên. Vui lòng thử lại.', true);
            });
    });
</script>

</body>
</html>
