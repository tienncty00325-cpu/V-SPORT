<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%
    if (request.getAttribute("email") == null && request.getParameter("email") != null) {
        request.setAttribute("email", request.getParameter("email"));
    }
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1.0" name="viewport"/>
    <title>Xác minh OTP - V-SPORT</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet"/>
    <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" rel="stylesheet"/>
    <style>
        body { font-family: 'Inter', sans-serif; }
        .otp-input {
            text-align: center;
            font-size: 1.5rem;
            letter-spacing: 0.35em;
            font-weight: 700;
        }
        .live-dot { animation: pulse-dot 1.6s ease-in-out infinite; }
        @keyframes pulse-dot { 0%,100%{box-shadow:0 0 0 0 rgba(220,38,38,.4);} 50%{box-shadow:0 0 0 6px rgba(220,38,38,0);} }
    </style>
</head>
<c:set var="isDashboardFlow" value="${sessionScope.authType eq 'ADMIN_ADD' or sessionScope.authType eq 'ADMIN_EDIT' or sessionScope.authType eq 'MANAGER_EDIT'}" />
<c:set var="isAdminFlow" value="${sessionScope.authType eq 'ADMIN_ADD' or sessionScope.authType eq 'ADMIN_EDIT'}" />
<c:set var="isManagerFlow" value="${sessionScope.authType eq 'MANAGER_EDIT'}" />

<body class="${isDashboardFlow ? (isAdminFlow ? 'bg-zinc-50 text-zinc-900 min-h-screen' : 'bg-violet-50/20 text-zinc-900 min-h-screen') : 'min-h-screen flex items-center justify-center p-4 relative overflow-hidden bg-slate-900/60 backdrop-blur-sm'}">

    <c:choose>
        <c:when test="${isDashboardFlow}">
            <!-- Show Dashboard Sidebar and Header -->
            <c:choose>
                <c:when test="${isAdminFlow}">
                    <jsp:include page="/admin/common/sidebar.jsp" />
                    <header class="h-[64px] fixed top-0 right-0 left-0 lg:left-[248px] bg-white/80 backdrop-blur-lg border-b border-zinc-200 z-20 flex items-center justify-between px-4 lg:px-6">
                      <div class="flex items-center gap-3">
                        <button id="mobileMenuBtn" class="lg:hidden p-2 rounded-lg hover:bg-zinc-100 text-zinc-500"><span class="material-symbols-outlined text-[20px]">menu</span></button>
                        <div>
                          <h1 class="text-sm font-bold text-zinc-900 tracking-tight">Quản lý nhân sự cấp cao</h1>
                          <p class="text-xs text-zinc-500 flex items-center gap-1.5"><span class="material-symbols-outlined text-[12px]">security</span>Quyền hạn Admin</p>
                        </div>
                      </div>
                      <div class="flex items-center gap-1.5">
                        <button onclick="location.href='${pageContext.request.contextPath}/admin/HoTro.jsp'" class="hidden sm:flex items-center gap-1.5 h-9 px-3 rounded-lg border border-zinc-200 hover:bg-zinc-50 text-zinc-600 text-xs font-medium">
                          <span class="material-symbols-outlined text-[15px]">help</span>Hỗ trợ
                        </button>
                        <button class="relative p-2 rounded-lg hover:bg-zinc-100 text-zinc-500">
                          <span class="material-symbols-outlined text-[20px]">notifications</span>
                          <span class="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-red-500 live-dot"></span>
                        </button>
                        <div class="w-px h-6 bg-zinc-200 mx-1"></div>
                        <jsp:include page="/admin/common/profile_dropdown.jsp" />
                      </div>
                    </header>
                </c:when>
                <c:when test="${isManagerFlow}">
                    <jsp:include page="/manager/common/sidebar.jsp" />
                    <header class="h-[64px] fixed top-0 right-0 left-0 lg:left-[248px] bg-white/80 backdrop-blur-lg border-b border-violet-100 z-20 flex items-center justify-between px-4 lg:px-6">
                      <div class="flex items-center gap-3">
                        <button id="mobileMenuBtn" class="lg:hidden p-2 rounded-lg hover:bg-violet-50 text-violet-700"><span class="material-symbols-outlined text-[20px]">menu</span></button>
                        <div>
                          <h1 class="text-sm font-bold text-violet-900 tracking-tight">Quản lý nhân sự cơ sở</h1>
                          <p class="text-xs text-violet-500 flex items-center gap-1.5"><span class="material-symbols-outlined text-[12px]">security</span>Quyền hạn Quản lý · Cơ sở CS${sessionScope.user.coSoId}</p>
                        </div>
                      </div>
                      <div class="flex items-center gap-1.5">
                        <button class="relative p-2 rounded-lg hover:bg-violet-50 text-violet-500">
                          <span class="material-symbols-outlined text-[20px]">notifications</span>
                          <span class="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-violet-600 live-dot"></span>
                        </button>
                        <div class="w-px h-6 bg-violet-100 mx-1"></div>
                        <jsp:include page="/manager/common/profile_dropdown.jsp" />
                      </div>
                    </header>
                </c:when>
            </c:choose>

            <!-- Centered OTP Card within main workspace -->
            <main class="lg:ml-[248px] mt-[64px] p-6 min-h-[calc(100vh-64px)] flex items-center justify-center">
                <div class="bg-white rounded-3xl w-full max-w-[460px] p-8 shadow-xl border border-zinc-200/80 flex flex-col relative">
                    <!-- Close Button -->
                    <a href="${pageContext.request.contextPath}/${isAdminFlow ? 'admin/nhan-su' : 'manager/nhan-su'}" class="absolute top-5 right-5 text-slate-400 hover:text-slate-650 transition-colors z-[130] w-8 h-8 rounded-full flex items-center justify-center bg-slate-50 hover:bg-slate-100">
                        <span class="material-symbols-outlined text-[20px]">close</span>
                    </a>

                    <!-- Header -->
                    <div class="mb-6">
                        <div class="inline-flex items-center gap-2 bg-white border border-[#378b76]/30 text-[#378b76] rounded-full py-1 px-3.5 text-[11px] font-bold w-fit shadow-sm mb-3">
                            <div class="w-1.5 h-1.5 rounded-full bg-[#1677D2] animate-pulse"></div>
                            <span>Xác minh danh tính</span>
                        </div>
                        <h2 class="text-xl font-bold tracking-tight text-slate-900 mb-1">Xác thực OTP</h2>
                        <p class="text-[13px] text-slate-400 font-medium leading-relaxed">
                            Vui lòng kiểm tra email và nhập mã xác thực OTP 6 chữ số gửi tới <b class="text-slate-800">${email}</b>.
                        </p>
                    </div>

                    <!-- Error Banner -->
                    <c:if test="${not empty loi}">
                        <div id="error-banner" class="mb-5 p-4 bg-red-50 text-red-650 border border-red-100 rounded-xl text-xs font-semibold flex items-center gap-3 shadow-sm">
                            <span class="material-symbols-outlined text-[18px] shrink-0">error</span>
                            <span>${loi}</span>
                        </div>
                    </c:if>

                    <!-- Success Banner -->
                    <c:if test="${not empty thongbao}">
                        <div id="success-banner" class="mb-5 p-4 bg-emerald-50 text-emerald-600 border border-emerald-100 rounded-xl text-xs font-semibold flex items-center gap-3 shadow-sm">
                            <span class="material-symbols-outlined text-[18px] shrink-0">check_circle</span>
                            <span>${thongbao}</span>
                        </div>
                    </c:if>

                    <!-- Form -->
                    <form id="otp-form-dashboard" action="${pageContext.request.contextPath}/nhapma" method="POST" class="flex flex-col" autocomplete="off">
                        <input type="hidden" name="email" value="${email}">
                        <div class="mb-5">
                            <label class="text-[12px] font-bold text-slate-700 mb-1.5 block">Nhập mã OTP 6 chữ số</label>
                            <div class="relative">
                                <input type="text" name="otp" required maxlength="6" placeholder="••••••" 
                                       class="w-full h-14 border border-slate-300 rounded-xl otp-input focus:border-[#378b76] focus:ring-4 focus:ring-[#378b76]/10 transition-all outline-none" 
                                       style="border-width: 1.5px;">
                            </div>
                        </div>
                        <button type="submit" id="submit-btn-dashboard" class="w-full h-12 bg-[#FF8A24] hover:bg-[#F97316] text-white rounded-xl font-bold text-[14px] flex items-center justify-center gap-2 transition-all relative overflow-hidden shadow-md shadow-orange-100">
                            <span class="btn-text flex items-center gap-1.5">
                                Xác minh OTP
                                <span class="material-symbols-outlined text-[18px]">verified_user</span>
                            </span>
                            <div class="loading-spinner hidden absolute inset-0 bg-[#F97316] flex items-center justify-center">
                                <div class="w-5 h-5 border-2 border-white/20 border-t-white rounded-full animate-spin"></div>
                            </div>
                        </button>
                    </form>

                    <!-- Footer -->
                    <div class="mt-6 text-center border-t border-slate-100 pt-4">
                        <p class="text-[12px] text-slate-500 font-medium">
                            Không nhận được mã? 
                            <a href="${pageContext.request.contextPath}/resend-otp" class="font-bold text-[#378b76] hover:underline ml-1">
                                Gửi lại ngay
                            </a>
                        </p>
                    </div>
                </div>
            </main>
        </c:when>
        
        <c:otherwise>
            <!-- Show Original Guest Overlay Layout -->
            <div class="absolute inset-0 bg-cover bg-center opacity-25 blur-[8px] scale-105 pointer-events-none z-0" 
                 style="background-image: url('https://images.unsplash.com/photo-1508098682722-e99c43a406b2?q=80&w=2000&auto=format&fit=crop');"></div>
            
            <div class="bg-white rounded-3xl w-full max-w-[460px] p-8 shadow-2xl relative border border-slate-100 flex flex-col z-10">
                <a href="javascript:history.back()" class="absolute top-5 right-5 text-slate-400 hover:text-slate-650 transition-colors z-[130] w-8 h-8 rounded-full flex items-center justify-center bg-slate-50 hover:bg-slate-100">
                    <span class="material-symbols-outlined text-[20px]">close</span>
                </a>

                <div class="mb-6">
                    <div class="inline-flex items-center gap-2 bg-white border border-[#378b76]/30 text-[#378b76] rounded-full py-1 px-3.5 text-[11px] font-bold w-fit shadow-sm mb-3">
                        <div class="w-1.5 h-1.5 rounded-full bg-[#1677D2] animate-pulse"></div>
                        <span>Xác minh danh tính</span>
                    </div>
                    <h2 class="text-xl font-bold tracking-tight text-slate-900 mb-1">Xác thực OTP</h2>
                    <p class="text-[13px] text-slate-400 font-medium leading-relaxed">
                        Vui lòng kiểm tra email và nhập mã xác thực OTP 6 chữ số gửi tới <b class="text-slate-800">${email}</b>.
                    </p>
                </div>

                <c:if test="${not empty loi}">
                    <div id="error-banner" class="mb-5 p-4 bg-red-50 text-red-650 border border-red-100 rounded-xl text-xs font-semibold flex items-center gap-3 shadow-sm">
                        <span class="material-symbols-outlined text-[18px] shrink-0">error</span>
                        <span>${loi}</span>
                    </div>
                </c:if>

                <c:if test="${not empty thongbao}">
                    <div id="success-banner" class="mb-5 p-4 bg-emerald-50 text-emerald-600 border border-emerald-100 rounded-xl text-xs font-semibold flex items-center gap-3 shadow-sm">
                        <span class="material-symbols-outlined text-[18px] shrink-0">check_circle</span>
                        <span>${thongbao}</span>
                    </div>
                </c:if>

                <form id="otp-form" action="${pageContext.request.contextPath}/nhapma" method="POST" class="flex flex-col" autocomplete="off">
                    <input type="hidden" name="email" value="${email}">
                    <div class="mb-5">
                        <label class="text-[12px] font-bold text-slate-700 mb-1.5 block">Nhập mã OTP 6 chữ số</label>
                        <div class="relative">
                            <input type="text" name="otp" required maxlength="6" placeholder="••••••" 
                                   class="w-full h-14 border border-slate-300 rounded-xl otp-input focus:border-[#378b76] focus:ring-4 focus:ring-[#378b76]/10 transition-all outline-none" 
                                   style="border-width: 1.5px;">
                        </div>
                    </div>
                    <button type="submit" id="submit-btn" class="w-full h-12 bg-[#FF8A24] hover:bg-[#F97316] text-white rounded-xl font-bold text-[14px] flex items-center justify-center gap-2 transition-all relative overflow-hidden shadow-md shadow-orange-100">
                        <span class="btn-text flex items-center gap-1.5">
                            Xác minh OTP
                            <span class="material-symbols-outlined text-[18px]">verified_user</span>
                        </span>
                        <div class="loading-spinner hidden absolute inset-0 bg-[#F97316] flex items-center justify-center">
                            <div class="w-5 h-5 border-2 border-white/20 border-t-white rounded-full animate-spin"></div>
                        </div>
                    </button>
                </form>

                <div class="mt-6 text-center border-t border-slate-100 pt-4">
                    <p class="text-[12px] text-slate-500 font-medium">
                        Không nhận được mã? 
                        <a href="${pageContext.request.contextPath}/resend-otp" class="font-bold text-[#378b76] hover:underline ml-1">
                            Gửi lại ngay
                        </a>
                    </p>
                </div>
            </div>
        </c:otherwise>
    </c:choose>

    <script>
        const setupForm = (formId, btnId) => {
            const form = document.getElementById(formId);
            const btn = document.getElementById(btnId);
            if (form && btn) {
                form.addEventListener('submit', () => {
                    const spinner = btn.querySelector('.loading-spinner');
                    const btnText = btn.querySelector('.btn-text');
                    if (spinner && btnText) {
                        spinner.classList.remove('hidden');
                        btnText.style.opacity = '0';
                        btn.style.pointerEvents = 'none';
                    }
                });
            }
        };
        setupForm('otp-form', 'submit-btn');
        setupForm('otp-form-dashboard', 'submit-btn-dashboard');
    </script>
</body>
</html>