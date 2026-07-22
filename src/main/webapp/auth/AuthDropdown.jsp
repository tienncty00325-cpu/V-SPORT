<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<style>
    .auth-dropdown-wrapper {
        position: relative;
        display: inline-flex;
        align-items: center;
        gap: 12px;
    }
    .auth-dropdown {
        position: absolute;
        top: calc(100% + 10px);
        right: 0;
        width: 360px;
        max-width: calc(100vw - 24px);
        background: #ffffff;
        border: 1px solid #e5e7eb;
        border-radius: 16px;
        box-shadow: 0 12px 32px rgba(0, 0, 0, 0.08);
        padding: 20px;
        opacity: 0;
        visibility: hidden;
        transform: translateY(8px) scale(0.98);
        transition: opacity .2s ease, transform .2s ease, visibility .2s ease;
        z-index: 3000;
        text-align: left;
        color: #111827;
        font-family: 'Poppins', sans-serif;
    }
    .auth-dropdown.is-open {
        opacity: 1;
        visibility: visible;
        transform: translateY(0) scale(1);
    }
    
    .auth-dropdown-header {
        margin-bottom: 16px;
        display: flex;
        flex-direction: column;
        align-items: center;
        text-align: center;
    }
    .auth-dropdown-logo {
        font-size: 14px;
        font-weight: 800;
        color: #111;
        margin-bottom: 12px;
    }
    .auth-dropdown-logo span {
        color: #2563eb;
    }
    .auth-dropdown-header h3 {
        font-size: 16px;
        font-weight: 700;
        margin: 0 0 4px 0;
        color: #111111;
    }
    .auth-dropdown-header p {
        font-size: 12px;
        color: #6b7280;
        margin: 0;
    }
    .authdd-tabs {
        display: flex;
        background: #f3f4f6;
        border-radius: 10px;
        padding: 4px;
        gap: 4px;
        margin-bottom: 20px;
    }
    .authdd-tab {
        flex: 1;
        background: transparent;
        border: none;
        border-radius: 8px;
        padding: 8px 0;
        font-size: 13px;
        font-weight: 600;
        color: #6b7280;
        cursor: pointer;
        transition: all 0.2s ease;
        text-align: center;
    }
    .authdd-tab.authdd-tab-active {
        background: #fff;
        color: #2563eb;
        box-shadow: 0 2px 4px rgba(0,0,0,0.05);
    }
    .authdd-panel {
        display: none;
    }
    .authdd-panel.active {
        display: block;
    }
    .authdd-field {
        margin-bottom: 14px;
    }
    .authdd-label {
        display: block;
        font-size: 12px;
        font-weight: 600;
        color: #111827;
        margin-bottom: 4px;
    }
    .authdd-input {
        width: 100%;
        height: 42px;
        padding: 0 14px;
        border: 1px solid #e5e7eb;
        border-radius: 10px;
        font-size: 13px;
        background: #f9fafb;
        outline: none;
        transition: border-color 0.2s;
        box-sizing: border-box;
    }
    .authdd-input:focus {
        border-color: #2563eb;
    }
    .authdd-input-group {
        position: relative;
    }
    .authdd-input-group .toggle-password {
        position: absolute;
        right: 14px;
        top: 50%;
        transform: translateY(-50%);
        cursor: pointer;
        color: #6b7280;
        font-size: 14px;
    }
    .authdd-btn {
        width: 100%;
        height: 42px;
        background: #2563eb;
        color: #fff;
        border: none;
        border-radius: 10px;
        font-size: 14px;
        font-weight: 600;
        cursor: pointer;
        transition: background 0.2s;
        margin-top: 4px;
    }
    .authdd-btn:hover {
        background: #d91624;
    }
    .authdd-footer-link {
        display: block;
        text-align: center;
        font-size: 12px;
        color: #6b7280;
        margin-top: 14px;
        text-decoration: none;
    }
    .authdd-footer-link span {
        color: #2563eb;
        font-weight: 600;
    }
    .authdd-flex-between {
        display: flex;
        justify-content: space-between;
        align-items: center;
        font-size: 12px;
        margin-bottom: 16px;
    }
    .authdd-flex-between a {
        color: #2563eb;
        text-decoration: none;
        font-weight: 500;
    }
    .authdd-checkbox {
        display: flex;
        align-items: center;
        gap: 6px;
        color: #6b7280;
        cursor: pointer;
    }
    @media (max-width: 768px) {
        .auth-dropdown {
            position: fixed;
            top: 60px;
            right: 12px;
            left: 12px;
            width: auto;
        }
    }
</style>

<div class="auth-dropdown" id="authDropdown">
    <div class="auth-dropdown-header">
        <div class="auth-dropdown-logo">V<span>⚡</span>SPORT Account</div>
        <h3 id="authdd-title">Đăng nhập</h3>
        <p id="authdd-subtitle">Tiếp tục đặt sân và ghép trận.</p>
    </div>

    <div class="authdd-tabs">
        <button type="button" class="authdd-tab authdd-tab-active" onclick="switchAuthTab('login')" id="tab-login">Đăng nhập</button>
        <button type="button" class="authdd-tab" onclick="switchAuthTab('register')" id="tab-register">Đăng ký</button>
    </div>

    <!-- Login Form -->
    <div class="authdd-panel active" id="panel-login">
        <form action="${pageContext.request.contextPath}/dangnhap" method="post">
            <div class="authdd-field">
                <label class="authdd-label">Email hoặc số điện thoại</label>
                <input type="text" name="username" class="authdd-input" required placeholder="Nhập email hoặc số điện thoại">
            </div>
            <div class="authdd-field">
                <label class="authdd-label">Mật khẩu</label>
                <div class="authdd-input-group">
                    <input type="password" name="password" class="authdd-input" required placeholder="Nhập mật khẩu">
                    <i class="fa-regular fa-eye toggle-password" onclick="togglePasswordVisibility(this)"></i>
                </div>
            </div>
            <div class="authdd-flex-between">
                <label class="authdd-checkbox">
                    <input type="checkbox" name="remember" value="true"> Ghi nhớ 7 ngày
                </label>
                <a href="${pageContext.request.contextPath}/forgot-password">Quên mật khẩu?</a>
            </div>
            <button type="submit" class="authdd-btn">Đăng nhập</button>
            <a href="javascript:void(0)" onclick="switchAuthTab('register')" class="authdd-footer-link">
                Chưa có tài khoản? <span>Tạo tài khoản</span>
            </a>
        </form>
    </div>

    <!-- Register Form -->
    <div class="authdd-panel" id="panel-register" style="max-height: calc(100vh - 280px); overflow-y: auto; padding-right: 4px;">
        <form action="${pageContext.request.contextPath}/dangky" method="post">
            <div class="authdd-field">
                <label class="authdd-label">Họ và tên</label>
                <input type="text" name="fullname" class="authdd-input" required placeholder="Nguyễn Văn A">
            </div>

            <div class="authdd-field">
                <label class="authdd-label">Email</label>
                <input type="email" name="email" class="authdd-input" required placeholder="example@gmail.com">
            </div>
            <div class="authdd-field">
                <label class="authdd-label">Số điện thoại</label>
                <input type="text" name="phone" class="authdd-input" required placeholder="09xxxx">
            </div>
            <div class="authdd-field">
                <label class="authdd-label">Mật khẩu</label>
                <div class="authdd-input-group">
                    <input type="password" name="password" class="authdd-input" required placeholder="Tối thiểu 6 ký tự">
                    <i class="fa-regular fa-eye toggle-password" onclick="togglePasswordVisibility(this)"></i>
                </div>
            </div>
            <div class="authdd-field">
                <label class="authdd-label">Xác nhận mật khẩu</label>
                <div class="authdd-input-group">
                    <input type="password" name="confirm_password" class="authdd-input" required placeholder="Nhập lại mật khẩu">
                    <i class="fa-regular fa-eye toggle-password" onclick="togglePasswordVisibility(this)"></i>
                </div>
            </div>
            <button type="submit" class="authdd-btn">Tạo tài khoản</button>
            <a href="javascript:void(0)" onclick="switchAuthTab('login')" class="authdd-footer-link">
                Đã có tài khoản? <span>Đăng nhập</span>
            </a>
        </form>
    </div>
</div>

<script>
    const dropdown = document.getElementById('authDropdown');

    function toggleAuthDropdown(tab) {
        if (dropdown.classList.contains('is-open')) {
            dropdown.classList.remove('is-open');
        } else {
            dropdown.classList.add('is-open');
            switchAuthTab(tab);
        }
    }

    function switchAuthTab(tab) {
        document.getElementById('tab-login').classList.remove('authdd-tab-active');
        document.getElementById('tab-register').classList.remove('authdd-tab-active');
        document.getElementById('panel-login').classList.remove('active');
        document.getElementById('panel-register').classList.remove('active');
        
        if (tab === 'login') {
            document.getElementById('tab-login').classList.add('authdd-tab-active');
            document.getElementById('panel-login').classList.add('active');
            document.getElementById('authdd-title').innerText = 'Đăng nhập';
            document.getElementById('authdd-subtitle').innerText = 'Tiếp tục đặt sân và ghép trận.';
        } else {
            document.getElementById('tab-register').classList.add('authdd-tab-active');
            document.getElementById('panel-register').classList.add('active');
            document.getElementById('authdd-title').innerText = 'Tạo tài khoản';
            document.getElementById('authdd-subtitle').innerText = 'Tạo tài khoản để bắt đầu chơi.';
        }
    }

    function togglePasswordVisibility(icon) {
        const input = icon.previousElementSibling;
        if (input.type === 'password') {
            input.type = 'text';
            icon.classList.remove('fa-eye');
            icon.classList.add('fa-eye-slash');
        } else {
            input.type = 'password';
            icon.classList.remove('fa-eye-slash');
            icon.classList.add('fa-eye');
        }
    }

    // Close when clicking outside
    document.addEventListener('click', function(event) {
        const wrapper = document.getElementById('authDropdownWrapper');
        if (wrapper && !wrapper.contains(event.target)) {
            dropdown.classList.remove('is-open');
        }
    });

    // Close on ESC
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            dropdown.classList.remove('is-open');
        }
    });

    window.openAuthModal = function(tab) {
        const wrapper = document.getElementById('authDropdownWrapper');
        if(wrapper) {
            dropdown.classList.add('is-open');
            switchAuthTab(tab);
        }
    };
</script>
