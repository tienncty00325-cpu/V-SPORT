<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1.0" name="viewport"/>
    <title>Mật khẩu mới - V-SPORT</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet"/>
    <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" rel="stylesheet"/>
    <style>
        body { font-family: 'Inter', sans-serif; }
        .btn-spinner { display: none; }
        .is-loading .btn-text { visibility: hidden; }
        .is-loading .btn-spinner {
            position: absolute; inset: 0;
            display: flex; align-items: center; justify-content: center;
        }
        .btn-spinner::after {
            content: '';
            width: 24px; height: 24px; border-radius: 50%;
            border: 3px solid rgba(255,255,255,.35);
            border-top-color: #fff;
            animation: vs-rotate .8s linear infinite;
        }
        @keyframes vs-rotate { to { transform: rotate(360deg); } }
        @media (prefers-reduced-motion: reduce) { .btn-spinner::after { animation-duration: 2.4s; } }
    </style>
</head>
<body class="min-h-screen flex items-center justify-center p-4 relative overflow-hidden bg-slate-900/60 backdrop-blur-sm">
    
    <!-- Blurred Background Stadium Image -->
    <div class="absolute inset-0 bg-cover bg-center opacity-25 blur-[8px] scale-105 pointer-events-none z-0" 
         style="background-image: url('https://images.unsplash.com/photo-1508098682722-e99c43a406b2?q=80&w=2000&auto=format&fit=crop');"></div>

    <!-- Modal Card (Centered popup, identical layout to login modal) -->
    <div class="bg-white rounded-3xl w-full max-w-[460px] p-8 shadow-2xl relative border border-slate-100 flex flex-col z-10">
        
        <!-- Header -->
        <div class="mb-6">
            <div class="inline-flex items-center gap-2 bg-white border border-[#378b76]/30 text-[#378b76] rounded-full py-1 px-3.5 text-[11px] font-bold w-fit shadow-sm mb-3">
                <div class="w-1.5 h-1.5 rounded-full bg-[#1677D2] animate-pulse"></div>
                <span>Thiết lập mật khẩu</span>
            </div>
            <h2 class="text-xl font-bold tracking-tight text-slate-900 mb-1">Mật khẩu mới</h2>
            <p class="text-[13px] text-slate-400 font-medium leading-relaxed">
                Đã xác minh danh tính thành công. Vui lòng tạo mật khẩu mới an toàn cho tài khoản của bạn.
            </p>
        </div>

        <!-- Error Banner -->
        <c:if test="${not empty loi}">
            <div id="error-banner" class="mb-5 p-4 bg-red-50 text-red-600 border border-red-100 rounded-xl text-xs font-semibold flex items-center gap-3 shadow-sm">
                <span class="material-symbols-outlined text-[18px] shrink-0">error</span>
                <span>${loi}</span>
            </div>
        </c:if>

        <!-- Form -->
        <form action="${pageContext.request.contextPath}/nhapmatkhaumoi" method="POST" id="newPasswordForm" class="flex flex-col gap-4">
            
            <!-- New Password -->
            <div>
                <label class="text-[12px] font-bold text-slate-700 mb-1.5 block">Mật khẩu mới</label>
                <div class="relative">
                    <input type="password" name="password" id="password" required placeholder="••••••••" 
                           class="w-full h-12 pl-12 pr-12 border border-slate-300 rounded-xl text-[13px] font-medium text-slate-900 focus:border-[#378b76] focus:ring-4 focus:ring-[#378b76]/10 transition-all outline-none" 
                           style="border-width: 1.5px;">
                    <span class="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none text-[20px]">key</span>
                    <button type="button" onclick="togglePass('password', this)" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-[#378b76]">
                        <span class="material-symbols-outlined text-[20px]">visibility</span>
                    </button>
                </div>
            </div>

            <!-- Confirm Password -->
            <div class="mb-4">
                <label class="text-[12px] font-bold text-slate-700 mb-1.5 block">Xác nhận mật khẩu mới</label>
                <div class="relative">
                    <input type="password" name="confirm_password" id="confirm_password" required placeholder="••••••••" 
                           class="w-full h-12 pl-12 pr-12 border border-slate-300 rounded-xl text-[13px] font-medium text-slate-900 focus:border-[#378b76] focus:ring-4 focus:ring-[#378b76]/10 transition-all outline-none" 
                           style="border-width: 1.5px;">
                    <span class="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none text-[20px]">key</span>
                    <button type="button" onclick="togglePass('confirm_password', this)" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-[#378b76]">
                        <span class="material-symbols-outlined text-[20px]">visibility</span>
                    </button>
                </div>
            </div>
            
            <!-- Submit Button -->
            <button type="submit" id="newPwSubmit" aria-busy="false" class="w-full h-12 bg-[#FF8A24] hover:bg-[#F97316] text-white rounded-xl font-bold text-[14px] flex items-center justify-center gap-2 transition-all relative overflow-hidden shadow-md shadow-orange-100">
                <span class="btn-text flex items-center gap-1.5">
                    Lưu mật khẩu mới
                    <span class="material-symbols-outlined text-[18px]">save</span>
                </span>
                <span class="btn-spinner" aria-hidden="true"></span>
            </button>
        </form>
    </div>

    <script>
        function togglePass(id, btn) {
            const input = document.getElementById(id);
            const icon = btn.querySelector('span');
            input.type = input.type === 'password' ? 'text' : 'password';
            icon.textContent = input.type === 'password' ? 'visibility' : 'visibility_off';
        }

        const form = document.getElementById('newPasswordForm');
        const submitBtn = document.getElementById('newPwSubmit');
        function setLoading(on) {
            submitBtn.classList.toggle('is-loading', on);
            submitBtn.disabled = on;
            submitBtn.setAttribute('aria-busy', on ? 'true' : 'false');
            if (!on) form.dataset.submitted = '';
        }
        form.addEventListener('submit', function(e) {
            if (form.dataset.submitted === 'true') { e.preventDefault(); return; }
            const p1 = document.getElementById('password').value;
            const p2 = document.getElementById('confirm_password').value;

            if (p1.trim() === '') {
                e.preventDefault();
                alert('Mật khẩu không được để trống hoặc chỉ chứa khoảng trắng!');
                return;
            }

            if (p1 !== p2) {
                e.preventDefault();
                alert('Mật khẩu xác nhận chưa trùng khớp!');
                return;
            }
            form.dataset.submitted = 'true';
            setLoading(true);
        });
        window.addEventListener('pageshow', function () { setLoading(false); });
    </script>
</body>
</html>
