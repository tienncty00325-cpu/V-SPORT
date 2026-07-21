<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<style>
    :root {
        --vs-red: #ff2433;
        --vs-red-hover: #d91b26;
        --vs-text-main: #111827;
        --vs-text-sub: #6b7280;
        --vs-border: #e5e7eb;
        --vs-bg-input: #f9fafb;
    }

    #authdd-root, #authdd-root * { box-sizing: border-box; }
    
    #authdd-root {
        position: fixed;
        inset: 0;
        z-index: 9999;
        display: none;
        font-family: 'Poppins', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    }
    #authdd-root.is-open { display: block; }
    #authdd-root [hidden] { display: none !important; }

    .auth-overlay {
        position: fixed;
        inset: 0;
        background: rgba(10, 10, 10, 0.65);
        backdrop-filter: blur(4px);
        opacity: 0;
        transition: opacity 0.3s ease;
        z-index: 1000;
    }
    .auth-overlay.is-visible { opacity: 1; }

    .auth-drawer {
        position: fixed;
        top: 0;
        right: 0;
        width: min(460px, 100%);
        height: 100vh;
        background: #fff;
        transform: translateX(100%);
        transition: transform 0.4s cubic-bezier(0.25, 0.8, 0.25, 1);
        z-index: 1001;
        box-shadow: -10px 0 40px rgba(0,0,0,0.25);
        display: flex;
        flex-direction: column;
        border-radius: 24px 0 0 24px;
    }
    
    @media (max-width: 767px) {
        .auth-drawer {
            border-radius: 0;
        }
    }

    .auth-drawer.is-visible { transform: translateX(0); }

    /* Header Drawer */
    .auth-drawer-header {
        padding: 24px 32px;
        border-bottom: 1px solid var(--vs-border);
        display: flex;
        justify-content: space-between;
        align-items: center;
        flex-shrink: 0;
    }
    .auth-logo {
        font-size: 24px;
        font-weight: 800;
        letter-spacing: 1px;
        color: var(--vs-text-main);
        display: flex;
        align-items: center;
        text-decoration: none;
    }
    .auth-logo .logo-icon { color: var(--vs-red); margin: 0 4px; display: inline-flex; }
    
    .authdd-close {
        width: 36px;
        height: 36px;
        border-radius: 50%;
        border: none;
        background: #f3f4f6;
        color: var(--vs-text-sub);
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: background 0.2s, color 0.2s;
    }
    .authdd-close:hover { background: #e5e7eb; color: var(--vs-text-main); }

    /* Segmented Tabs */
    .authdd-tabs-container {
        padding: 24px 32px 0;
        flex-shrink: 0;
    }
    .authdd-tabs {
        display: flex;
        background: #f3f4f6;
        border-radius: 12px;
        padding: 4px;
        gap: 4px;
    }
    .authdd-tab {
        flex: 1;
        background: transparent;
        border: none;
        border-radius: 8px;
        padding: 12px 0;
        font-size: 14px;
        font-weight: 600;
        color: var(--vs-text-sub);
        cursor: pointer;
        transition: all 0.2s ease;
    }
    .authdd-tab.authdd-tab-active {
        background: #fff;
        color: var(--vs-red);
        box-shadow: 0 2px 4px rgba(0,0,0,0.05);
    }

    /* Body */
    .authdd-body { 
        padding: 24px 32px; 
        overflow-y: auto; 
        flex: 1;
        display: flex;
        flex-direction: column;
    }
    .authdd-body::-webkit-scrollbar { width: 6px; }
    .authdd-body::-webkit-scrollbar-thumb { background-color: #d1d5db; border-radius: 10px; }

    .authdd-panel { display: flex; flex-direction: column; flex: 1; }
    
    .authdd-heading { font-size: 24px; font-weight: 700; color: var(--vs-text-main); margin: 0 0 8px; }
    .authdd-subtext { font-size: 14px; color: var(--vs-text-sub); margin: 0 0 24px; line-height: 1.5; }

    .authdd-field { margin-bottom: 18px; }
    .authdd-label { display: block; font-size: 13px; font-weight: 600; color: var(--vs-text-main); margin-bottom: 8px; }
    
    .authdd-input {
        width: 100%; height: 48px; padding: 0 16px;
        border: 1px solid var(--vs-border); border-radius: 12px;
        font-size: 14px; font-weight: 500; color: var(--vs-text-main);
        background: var(--vs-bg-input); outline: none;
        transition: all 0.2s ease;
    }
    .authdd-input:focus { border-color: var(--vs-red); background: #fff; box-shadow: 0 0 0 3px rgba(255, 36, 51, 0.1); }
    .authdd-input::placeholder { color: #9ca3af; }

    .authdd-pass-wrap { position: relative; }
    .authdd-pass-wrap .authdd-input { padding-right: 44px; }
    .authdd-pass-toggle {
        position: absolute; right: 12px; top: 50%; transform: translateY(-50%);
        background: none; border: none; cursor: pointer; color: #9ca3af;
        display: flex; align-items: center; justify-content: center; padding: 4px;
    }
    .authdd-pass-toggle:hover { color: var(--vs-text-main); }

    .authdd-row-between { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; }
    .authdd-checkbox-label { display: flex; align-items: center; gap: 8px; font-size: 13px; color: var(--vs-text-sub); cursor: pointer; user-select: none; }
    .authdd-checkbox-label input { width: 16px; height: 16px; accent-color: var(--vs-red); }

    .authdd-link-btn { background: none; border: none; padding: 0; cursor: pointer; font-size: 13px; font-weight: 600; color: var(--vs-red); }
    .authdd-link-btn:hover { text-decoration: underline; }

    .authdd-btn {
        width: 100%; height: 50px; border: none; border-radius: 12px;
        background: var(--vs-red); color: #fff; font-size: 15px; font-weight: 700;
        cursor: pointer; position: relative; overflow: hidden;
        display: flex; align-items: center; justify-content: center; gap: 8px;
        transition: all 0.2s ease;
        box-shadow: 0 4px 12px rgba(255, 36, 51, 0.25);
    }
    .authdd-btn:hover { background: var(--vs-red-hover); box-shadow: 0 6px 16px rgba(255, 36, 51, 0.35); transform: translateY(-2px); }
    .authdd-btn:active { transform: translateY(0); }
    .authdd-btn:disabled { cursor: wait; opacity: 0.7; transform: none; box-shadow: none; }
    
    .authdd-btn-loading {
        position: absolute; inset: 0; background: var(--vs-red-hover); color: #fff;
        display: none; align-items: center; justify-content: center; gap: 8px;
    }
    .authdd-btn-loading.authdd-show { display: flex; }
    .authdd-spinner {
        width: 18px; height: 18px; border-radius: 50%;
        border: 2px solid rgba(255, 255, 255, 0.3); border-top-color: #fff;
        animation: authdd-spin 0.7s linear infinite;
    }
    @keyframes authdd-spin { to { transform: rotate(360deg); } }

    .authdd-agree { display: flex; align-items: flex-start; gap: 10px; margin-bottom: 24px; }
    .authdd-agree input { width: 18px; height: 18px; margin-top: 2px; accent-color: var(--vs-red); }
    .authdd-agree span { font-size: 13px; color: var(--vs-text-sub); line-height: 1.5; }
    .authdd-agree a { color: var(--vs-red); font-weight: 600; text-decoration: none; }
    .authdd-agree a:hover { text-decoration: underline; }

    .authdd-footnote { text-align: center; margin-top: 24px; font-size: 14px; color: var(--vs-text-sub); }

    /* Branding mini */
    .auth-branding {
        background: rgba(255, 36, 51, 0.04);
        border: 1px solid rgba(255, 36, 51, 0.1);
        border-radius: 12px;
        padding: 16px;
        margin-top: auto;
        margin-bottom: 20px;
    }
    .auth-branding p { font-size: 13px; font-weight: 700; color: var(--vs-text-main); margin-bottom: 12px; }
    .auth-branding ul { list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 10px; }
    .auth-branding li { font-size: 13px; color: var(--vs-text-sub); display: flex; align-items: center; gap: 10px; }
    .auth-branding li svg { color: var(--vs-red); width: 16px; height: 16px; flex-shrink: 0; }

    /* Banners & password strength */
    .authdd-banner {
        display: flex; align-items: center; gap: 10px;
        padding: 12px; border-radius: 8px; font-size: 13px; font-weight: 500;
        margin-bottom: 20px;
    }
    .authdd-banner-error { background: #fef2f2; border: 1px solid #fecaca; color: #dc2626; }
    .authdd-banner-success { background: #f0fdf4; border: 1px solid #bbf7d0; color: #16a34a; }

    .authdd-strength { display: flex; gap: 6px; margin-top: 10px; }
    .authdd-strength div { height: 4px; flex: 1; border-radius: 2px; background: #e5e7eb; transition: background-color 250ms ease; }
    .authdd-hint { font-size: 12px; color: #9ca3af; line-height: 1.4; margin-top: 8px; }

    .authdd-otp-input {
        width: 100%; height: 52px; text-align: center; font-size: 24px; font-weight: 700; letter-spacing: 0.4em;
        border: 1px solid var(--vs-border); border-radius: 12px; outline: none; color: var(--vs-text-main);
        background: var(--vs-bg-input);
    }
    .authdd-otp-input:focus { border-color: var(--vs-red); background: #fff; box-shadow: 0 0 0 3px rgba(255, 36, 51, 0.1); }
    
    .authdd-back-link { display: flex; align-items: center; justify-content: center; gap: 4px; margin-top: 12px; }

    /* Redirect overlay */
    #authdd-redirect-overlay {
        position: fixed; inset: 0; z-index: 99999;
        background: rgba(255,255,255,0.96); backdrop-filter: blur(6px);
        display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 20px;
        opacity: 0; pointer-events: none; transition: opacity 280ms ease;
    }
    #authdd-redirect-overlay.authdd-redir-show { opacity: 1; pointer-events: all; }
    .authdd-redir-circle { width: 72px; height: 72px; border-radius: 50%; background: #16A36A; display: flex; align-items: center; justify-content: center; transform: scale(0.4); opacity: 0; transition: transform 380ms cubic-bezier(0.34,1.56,0.64,1), opacity 280ms ease; }
    #authdd-redirect-overlay.authdd-redir-show .authdd-redir-circle { transform: scale(1); opacity: 1; }
    .authdd-redir-circle svg { width: 36px; height: 36px; stroke: #fff; }
    .authdd-redir-checkpath { stroke-dasharray: 52; stroke-dashoffset: 52; transition: stroke-dashoffset 420ms ease 320ms; }
    #authdd-redirect-overlay.authdd-redir-show .authdd-redir-checkpath { stroke-dashoffset: 0; }
    .authdd-redir-title { font-size: 20px; font-weight: 700; color: #111827; opacity: 0; transform: translateY(8px); transition: opacity 300ms ease 200ms, transform 300ms ease 200ms; }
    #authdd-redirect-overlay.authdd-redir-show .authdd-redir-title { opacity: 1; transform: translateY(0); }
    .authdd-redir-sub { font-size: 14px; color: #6b7280; margin-top: 4px; opacity: 0; transform: translateY(6px); transition: opacity 300ms ease 350ms, transform 300ms ease 350ms; }
    #authdd-redirect-overlay.authdd-redir-show .authdd-redir-sub { opacity: 1; transform: translateY(0); }
    .authdd-redir-bar { width: 160px; height: 4px; background: #e5e7eb; border-radius: 99px; overflow: hidden; opacity: 0; transition: opacity 200ms ease 400ms; }
    #authdd-redirect-overlay.authdd-redir-show .authdd-redir-bar { opacity: 1; }
    .authdd-redir-bar-fill { height: 100%; width: 0; background: #16A36A; border-radius: 99px; transition: width 900ms cubic-bezier(0.4,0,0.2,1) 450ms; }
    #authdd-redirect-overlay.authdd-redir-show .authdd-redir-bar-fill { width: 100%; }
</style>
<!-- Redirect success overlay -->
<div id="authdd-redirect-overlay">
    <div class="authdd-redir-circle">
        <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <polyline class="authdd-redir-checkpath" points="4,13 9,18 20,7"
                stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
    </div>
    <div class="authdd-redir-texts">
        <p class="authdd-redir-title">Đăng nhập thành công!</p>
        <p class="authdd-redir-sub">Đang chuyển trang cho bạn...</p>
    </div>
    <div class="authdd-redir-bar"><div class="authdd-redir-bar-fill"></div></div>
</div>

<div id="authdd-root">
    <div class="auth-overlay" id="authdd-overlay" onclick="closeAuthModal()"></div>
    <div id="authdd-card" class="auth-drawer">
        <div class="auth-drawer-header">
            <a href="#" class="auth-logo">V<span class="logo-icon"><svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 320 512" fill="currentColor"><path d="M296 160H180.6l42.6-129.8C227.2 15 215.7 0 200 0H56C44 0 33.8 8.9 32.2 20.8l-32 240C-.9 273.6 8 288 24 288h118.7L96.6 482.5c-3.6 15.2 8 29.5 23.3 29.5 8.4 0 16.4-4.4 20.8-12l176-304c9.3-15.9-2.2-36-20.7-36z"/></svg></span>SPORT</a>
            <button type="button" class="authdd-close" onclick="closeAuthModal()" aria-label="Đóng">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
            </button>
        </div>

        <div id="authdd-tabs" class="authdd-tabs-container">
            <div class="authdd-tabs">
                <button type="button" id="authdd-tab-login" class="authdd-tab authdd-tab-active" onclick="switchAuthTab('login')">Đăng nhập</button>
                <button type="button" id="authdd-tab-register" class="authdd-tab" onclick="switchAuthTab('register')">Đăng ký</button>
            </div>
        </div>

        <div class="authdd-body">
            <!-- LOGIN -->
            <div id="modal-login-panel" class="authdd-panel">
                <h2 class="authdd-heading">Chào mừng quay lại</h2>
                <p class="authdd-subtext">Đăng nhập để đặt sân, ghép trận và theo dõi lịch trình.</p>
                <div id="login-error-banner" class="authdd-banner authdd-banner-error" hidden><span class="error-msg"></span></div>
                <div id="login-success-banner" class="authdd-banner authdd-banner-success" hidden><span class="success-msg"></span></div>

                <form id="modal-login-form" action="${pageContext.request.contextPath}/dangnhap" method="POST" autocomplete="off" onsubmit="submitLoginForm(event)">
                    <input type="hidden" name="loginType" value="customer">
                    <div class="authdd-field">
                        <label class="authdd-label">Tên đăng nhập hoặc email</label>
                        <input type="text" name="username" id="modal-login-username" required placeholder="Nhập tên đăng nhập hoặc email" class="authdd-input">
                    </div>
                    <div class="authdd-field">
                        <label class="authdd-label">Mật khẩu</label>
                        <div class="authdd-pass-wrap">
                            <input type="password" name="password" id="modal-login-pass" required placeholder="Nhập mật khẩu" class="authdd-input">
                            <button type="button" class="authdd-pass-toggle" onclick="togglePassField('modal-login-pass', this)">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                            </button>
                        </div>
                    </div>
                    <div class="authdd-row-between">
                        <label class="authdd-checkbox-label"><input type="checkbox" name="rememberMe"> Ghi nhớ 7 ngày</label>
                        <button type="button" class="authdd-link-btn" onclick="switchAuthTab('forgot-password')">Quên mật khẩu?</button>
                    </div>
                    <button type="submit" id="modal-login-btn" class="authdd-btn">
                        <span class="btn-text">Đăng nhập</span>
                        <span class="btn-loading authdd-btn-loading"><span class="authdd-spinner"></span><span class="btn-loading-text">Đang đăng nhập...</span></span>
                    </button>
                </form>

                <div class="authdd-footnote">Chưa có tài khoản? <button type="button" class="authdd-link-btn" onclick="switchAuthTab('register')">Tạo tài khoản</button></div>
                
                <div class="auth-branding">
                    <p>Một tài khoản cho hệ sinh thái V-SPORT</p>
                    <ul>
                        <li><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg> Đặt sân nhanh chóng</li>
                        <li><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg> Theo dõi lịch sử cá nhân</li>
                        <li><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg> Ghép trận thể thao uy tín</li>
                    </ul>
                </div>
            </div>

            <!-- REGISTER -->
            <div id="modal-register-panel" class="authdd-panel" hidden>
                <h2 class="authdd-heading">Tạo tài khoản</h2>
                <p class="authdd-subtext">Đăng ký để trải nghiệm toàn bộ tiện ích của V-SPORT.</p>
                <div id="register-error-banner" class="authdd-banner authdd-banner-error" hidden><span class="error-msg"></span></div>

                <form id="modal-register-form" action="${pageContext.request.contextPath}/dangky" method="POST" autocomplete="off" onsubmit="submitRegisterForm(event)">
                    <input type="hidden" name="gender" value="Khác">

                    <div class="authdd-field">
                        <label class="authdd-label">Họ và tên</label>
                        <input type="text" name="fullname" required placeholder="Nhập họ và tên" class="authdd-input">
                    </div>
                    <div class="authdd-field">
                        <label class="authdd-label">Email</label>
                        <input type="email" name="email" required placeholder="Địa chỉ email" class="authdd-input">
                    </div>
                    <div class="authdd-field">
                        <label class="authdd-label">Số điện thoại</label>
                        <input type="tel" name="phone" required placeholder="Nhập số điện thoại" class="authdd-input">
                    </div>
                    <div class="authdd-field">
                        <label class="authdd-label">Mật khẩu</label>
                        <div class="authdd-pass-wrap">
                            <input type="password" name="password" id="modal-reg-pass" required placeholder="Tạo mật khẩu" oninput="updateModalPwStrength(this)" class="authdd-input">
                            <button type="button" class="authdd-pass-toggle" onclick="togglePassField('modal-reg-pass', this)">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                            </button>
                        </div>
                        <div class="authdd-strength">
                            <div id="modalRegStr1"></div><div id="modalRegStr2"></div><div id="modalRegStr3"></div><div id="modalRegStr4"></div>
                        </div>
                        <p class="authdd-hint">Tối thiểu 8 ký tự, gồm chữ hoa, thường, số và ký tự đặc biệt.</p>
                    </div>
                    <div class="authdd-field">
                        <label class="authdd-label">Xác nhận mật khẩu</label>
                        <div class="authdd-pass-wrap">
                            <input type="password" name="confirm_password" id="modal-reg-confirm" required placeholder="Nhập lại mật khẩu" class="authdd-input">
                            <button type="button" class="authdd-pass-toggle" onclick="togglePassField('modal-reg-confirm', this)">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                            </button>
                        </div>
                    </div>

                    <div class="authdd-agree">
                        <input type="checkbox" name="agree" value="Đồng ý" required>
                        <span>Tôi đồng ý với <a href="#">điều khoản</a> và <a href="#">chính sách bảo mật</a>.</span>
                    </div>
                    <button type="submit" id="modal-register-btn" class="authdd-btn">
                        <span class="btn-text">Tạo tài khoản</span>
                        <span class="loading-spinner authdd-btn-loading"><span class="authdd-spinner"></span><span>Đang gửi OTP...</span></span>
                    </button>
                </form>

                <div class="authdd-footnote">Đã có tài khoản? <button type="button" class="authdd-link-btn" onclick="switchAuthTab('login')">Đăng nhập ngay</button></div>
            </div>

            <!-- FORGOT PASSWORD -->
            <div id="modal-forgot-password-panel" class="authdd-panel" hidden>
                <h2 class="authdd-heading">Quên mật khẩu?</h2>
                <p class="authdd-subtext">Nhập email đã đăng ký để khôi phục mật khẩu.</p>
                <div id="forgot-password-error-banner" class="authdd-banner authdd-banner-error" hidden><span class="error-msg"></span></div>
                <form id="modal-forgot-password-form" action="${pageContext.request.contextPath}/quenmatkhau" method="POST" autocomplete="off" onsubmit="submitForgotPasswordForm(event)">
                    <div class="authdd-field">
                        <label class="authdd-label">Email đã đăng ký</label>
                        <input type="email" name="email" required placeholder="Nhập địa chỉ email" class="authdd-input">
                    </div>
                    <button type="submit" id="modal-forgot-password-btn" class="authdd-btn">
                        <span class="btn-text">Gửi mã xác thực</span>
                        <span class="loading-spinner authdd-btn-loading"><span class="authdd-spinner"></span><span>Đang gửi mã...</span></span>
                    </button>
                </form>
                <div class="authdd-footnote">Nhớ lại mật khẩu? <button type="button" class="authdd-link-btn" onclick="switchAuthTab('login')">Đăng nhập</button></div>
            </div>

            <!-- OTP -->
            <div id="modal-otp-panel" class="authdd-panel" hidden>
                <h2 class="authdd-heading">Xác thực OTP</h2>
                <p class="authdd-subtext">Nhập mã 6 chữ số đã gửi tới <b id="otp-email-display" style="color:var(--vs-text-main)"></b>.</p>
                <div id="otp-error-banner" class="authdd-banner authdd-banner-error" hidden><span class="error-msg"></span></div>
                <div id="otp-success-banner" class="authdd-banner authdd-banner-success" hidden><span class="success-msg"></span></div>
                <form id="modal-otp-form" action="${pageContext.request.contextPath}/nhapma" method="POST" autocomplete="off" onsubmit="submitOtpForm(event)">
                    <input type="hidden" name="email" id="otp-hidden-email">
                    <div class="authdd-field">
                        <label class="authdd-label">Mã OTP 6 chữ số</label>
                        <input type="text" name="otp" required maxlength="6" placeholder="••••••" class="authdd-otp-input">
                    </div>
                    <button type="submit" id="modal-otp-btn" class="authdd-btn">
                        <span class="btn-text">Xác minh OTP</span>
                        <span class="loading-spinner authdd-btn-loading"><span class="authdd-spinner"></span><span>Đang xác thực...</span></span>
                    </button>
                </form>
                <div class="authdd-footnote" style="display:flex;flex-direction:column;gap:16px;">
                    <div>Không nhận được mã? <button type="button" class="authdd-link-btn" onclick="resendOtp()">Gửi lại</button></div>
                    <button type="button" class="authdd-link-btn authdd-back-link" onclick="goBackFromOtp()">← Quay lại</button>
                </div>
            </div>

            <!-- RESET PASSWORD -->
            <div id="modal-reset-password-panel" class="authdd-panel" hidden>
                <h2 class="authdd-heading">Mật khẩu mới</h2>
                <p class="authdd-subtext">Tạo mật khẩu mới cho tài khoản của bạn.</p>
                <div id="reset-password-error-banner" class="authdd-banner authdd-banner-error" hidden><span class="error-msg"></span></div>
                <form id="modal-reset-password-form" action="${pageContext.request.contextPath}/nhapmatkhaumoi" method="POST" onsubmit="submitResetPasswordForm(event)">
                    <div class="authdd-field">
                        <label class="authdd-label">Mật khẩu mới</label>
                        <div class="authdd-pass-wrap">
                            <input type="password" name="password" id="modal-new-pass" required placeholder="••••••••" oninput="updateModalResetPwStrength(this)" class="authdd-input">
                            <button type="button" class="authdd-pass-toggle" onclick="togglePassField('modal-new-pass', this)">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                            </button>
                        </div>
                        <div class="authdd-strength">
                            <div id="modalResetStr1"></div><div id="modalResetStr2"></div><div id="modalResetStr3"></div><div id="modalResetStr4"></div>
                        </div>
                    </div>
                    <div class="authdd-field">
                        <label class="authdd-label">Xác nhận mật khẩu mới</label>
                        <div class="authdd-pass-wrap">
                            <input type="password" name="confirm_password" id="modal-new-confirm" required placeholder="••••••••" class="authdd-input">
                            <button type="button" class="authdd-pass-toggle" onclick="togglePassField('modal-new-confirm', this)">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                            </button>
                        </div>
                    </div>
                    <button type="submit" id="modal-reset-password-btn" class="authdd-btn">
                        <span class="btn-text">Lưu mật khẩu mới</span>
                        <span class="loading-spinner authdd-btn-loading"><span class="authdd-spinner"></span><span>Đang cập nhật...</span></span>
                    </button>
                </form>
            </div>

        </div>
    </div>
</div>

<script>
    let otpSourceTab = 'login';
    let authTriggerEl = null;

    function resolveDefaultTrigger() {
        return document.getElementById('header-user-btn') || document.querySelector('.btn-register-shimmer');
    }

    function openAuthModal(tab, triggerEl) {
        if (!tab) tab = 'login';
        const root = document.getElementById('authdd-root');
        const card = document.getElementById('authdd-card');
        const overlay = document.getElementById('authdd-overlay');
        if (!root || !card || !overlay) return;
        
        authTriggerEl = triggerEl || resolveDefaultTrigger();
        clearModalAlerts();
        
        root.classList.add('is-open');
        // Prevent body scroll
        document.body.style.overflow = 'hidden';
        
        requestAnimationFrame(() => { 
            card.classList.add('is-visible'); 
            overlay.classList.add('is-visible');
            
            // Focus first input
            setTimeout(() => {
                const activePanelId = AUTHDD_PANEL_MAP[tab];
                if (activePanelId) {
                    const activePanel = document.getElementById(activePanelId);
                    if (activePanel) {
                        const firstInput = activePanel.querySelector('input:not([type="hidden"])');
                        if (firstInput) firstInput.focus();
                    }
                }
            }, 300);
        });
        showAuthTabPanel(tab);
    }

    function closeAuthModal() {
        setLoginFormLoading(false);
        const root = document.getElementById('authdd-root');
        const card = document.getElementById('authdd-card');
        const overlay = document.getElementById('authdd-overlay');
        if (!root || !card || !overlay) return;
        
        card.classList.remove('is-visible');
        overlay.classList.remove('is-visible');
        
        setTimeout(() => { 
            root.classList.remove('is-open'); 
            document.body.style.overflow = '';
        }, 400);
    }

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            const root = document.getElementById('authdd-root');
            if (root && root.classList.contains('is-open')) closeAuthModal();
        }
    });

    const AUTHDD_PANEL_MAP = {
        'login': 'modal-login-panel',
        'register': 'modal-register-panel',
        'forgot-password': 'modal-forgot-password-panel',
        'otp': 'modal-otp-panel',
        'reset-password': 'modal-reset-password-panel'
    };

    function showAuthTabPanel(tab) {
        Object.values(AUTHDD_PANEL_MAP).forEach(id => {
            const el = document.getElementById(id);
            if (el) el.hidden = true;
        });
        const target = document.getElementById(AUTHDD_PANEL_MAP[tab]);
        if (target) target.hidden = false;

        const tabs = document.getElementById('authdd-tabs');
        const tabLogin = document.getElementById('authdd-tab-login');
        const tabRegister = document.getElementById('authdd-tab-register');
        if (tab === 'login' || tab === 'register') {
            if (tabs) tabs.style.display = 'block';
            if (tabLogin) tabLogin.classList.toggle('authdd-tab-active', tab === 'login');
            if (tabRegister) tabRegister.classList.toggle('authdd-tab-active', tab === 'register');
        } else {
            if (tabs) tabs.style.display = 'none';
        }
    }

    function switchAuthTab(tab) {
        if (tab === 'otp') {
            const current = Object.entries(AUTHDD_PANEL_MAP).find(([k, id]) => {
                const el = document.getElementById(id);
                return el && !el.hidden;
            });
            if (current && (current[0] === 'forgot-password' || current[0] === 'register')) {
                otpSourceTab = current[0];
            }
        }
        clearModalAlerts();
        showAuthTabPanel(tab);
    }

    function goBackFromOtp() { switchAuthTab(otpSourceTab); }

    function clearModalAlerts() {
        ['login-error-banner','login-success-banner','register-error-banner','forgot-password-error-banner','otp-error-banner','otp-success-banner','reset-password-error-banner'].forEach(id => {
            const el = document.getElementById(id);
            if (el) el.hidden = true;
        });
    }

    function togglePassField(id, btn) {
        const input = document.getElementById(id);
        if (input) input.type = input.type === 'password' ? 'text' : 'password';
    }

    function computeStrength(v) {
        let s = 0;
        if (v.length >= 8) s++; if (/[A-Z]/.test(v)) s++; if (/[a-z]/.test(v)) s++;
        if (/[0-9]/.test(v)) s++; if (/[^A-Za-z0-9]/.test(v)) s++;
        let strength = 0;
        if (v.length > 0) strength = 1; if (s >= 3) strength = 2; if (s >= 4) strength = 3; if (s >= 5) strength = 4;
        return strength;
    }

    function paintStrength(prefix, strength) {
        const cols = ['#f43f5e','#f59e0b','#8b5cf6','#10b981'];
        for (let i = 1; i <= 4; i++) {
            const el = document.getElementById(prefix + i);
            if (el) el.style.backgroundColor = i <= strength ? cols[strength-1] : '#e2e8f0';
        }
    }

    function updateModalPwStrength(inp) { paintStrength('modalRegStr', computeStrength(inp.value)); }
    function updateModalResetPwStrength(inp) { paintStrength('modalResetStr', computeStrength(inp.value)); }

    function setLoginFormLoading(isLoading, message) {
        if (!message) message = 'Đang đăng nhập...';
        const form = document.getElementById('modal-login-form');
        const btn = document.getElementById('modal-login-btn');
        const btnText = btn ? btn.querySelector('.btn-text') : null;
        const btnLoading = btn ? btn.querySelector('.btn-loading') : null;
        const btnLoadingText = btn ? btn.querySelector('.btn-loading-text') : null;
        if (btnLoadingText) btnLoadingText.textContent = message;

        if (isLoading) {
            if (btn) { btn.disabled = true; }
            if (btnText) btnText.style.visibility = 'hidden';
            if (btnLoading) btnLoading.classList.add('authdd-show');
            if (form) {
                form.querySelectorAll('button[type="button"]').forEach(el => { el.disabled = true; });
            }
        } else {
            if (btn) { btn.disabled = false; }
            if (btnText) btnText.style.visibility = 'visible';
            if (btnLoading) btnLoading.classList.remove('authdd-show');
            if (form) {
                form.querySelectorAll('button[type="button"]').forEach(el => { el.disabled = false; });
            }
        }
    }

    function submitLoginForm(event) {
        event.preventDefault();
        const form = document.getElementById('modal-login-form');
        const errorBanner = document.getElementById('login-error-banner');
        const successBanner = document.getElementById('login-success-banner');
        if (errorBanner) errorBanner.hidden = true;
        if (successBanner) successBanner.hidden = true;

        const searchParams = new URLSearchParams(new FormData(form));
        setLoginFormLoading(true, 'Đang đăng nhập...');

        fetch(form.action, {
            method: 'POST',
            headers: { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest', 'Content-Type': 'application/x-www-form-urlencoded' },
            body: searchParams
        })
        .then(res => res.json())
        .then(data => {
            if (data.success) {
                setLoginFormLoading(false);
                closeAuthModal();
                const overlay = document.getElementById('authdd-redirect-overlay');
                if (overlay) {
                    overlay.classList.add('authdd-redir-show');
                }
                setTimeout(() => { window.location.href = data.redirectUrl; }, 1200);
            } else {
                setLoginFormLoading(false);
                if (errorBanner) { errorBanner.querySelector('.error-msg').textContent = data.loi || 'Đăng nhập không thành công.'; errorBanner.hidden = false; }
            }
        })
        .catch(err => {
            console.error('Lỗi login AJAX:', err);
            setLoginFormLoading(false);
            if (errorBanner) { errorBanner.querySelector('.error-msg').textContent = 'Có lỗi mạng xảy ra. Vui lòng thử lại!'; errorBanner.hidden = false; }
        });
    }

    function submitRegisterForm(event) {
        event.preventDefault();
        const form = document.getElementById('modal-register-form');
        const btn = document.getElementById('modal-register-btn');
        const btnText = btn.querySelector('.btn-text');
        const spinner = btn.querySelector('.loading-spinner');
        const errorBanner = document.getElementById('register-error-banner');
        if (errorBanner) errorBanner.hidden = true;

        const email = form.email.value.trim();
        const phone = form.phone.value.trim();
        const password = document.getElementById('modal-reg-pass').value;
        const confirmPassword = document.getElementById('modal-reg-confirm').value;

        function showError(msg) {
            if (errorBanner) { errorBanner.querySelector('.error-msg').textContent = msg; errorBanner.hidden = false; }
        }

        if (email.indexOf(' ') >= 0) { showError("Email không được chứa khoảng trắng!"); return; }
        if (!/^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/.test(email)) { showError("Định dạng Email không hợp lệ!"); return; }
        if (!/^(0|\+84)[35789][0-9]{8}$/.test(phone)) { showError("Số điện thoại không hợp lệ (Phải bắt đầu bằng 0 hoặc +84 và có 10 số)!"); return; }
        if (password !== confirmPassword) { showError("Mật khẩu xác nhận không khớp!"); return; }
        if (!/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$/.test(password)) { showError("Mật khẩu không đủ mạnh! Phải có tối thiểu 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt."); return; }

        if (spinner) spinner.classList.add('authdd-show');
        if (btnText) btnText.style.visibility = 'hidden';
        if (btn) btn.disabled = true;

        fetch(form.action, {
            method: 'POST',
            headers: { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest', 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams(new FormData(form))
        })
        .then(res => res.json())
        .then(data => {
            if (data.success) {
                if (data.step === 'otp') {
                    const displayEl = document.getElementById('otp-email-display');
                    const hiddenEmailEl = document.getElementById('otp-hidden-email');
                    if (displayEl) displayEl.textContent = data.email;
                    if (hiddenEmailEl) hiddenEmailEl.value = data.email;
                    if (spinner) spinner.classList.remove('authdd-show');
                    if (btnText) btnText.style.visibility = 'visible';
                    if (btn) btn.disabled = false;
                    const otpSuccessBanner = document.getElementById('otp-success-banner');
                    if (otpSuccessBanner) { otpSuccessBanner.querySelector('.success-msg').textContent='Đăng ký thông tin thành công! Vui lòng nhập mã OTP để kích hoạt.'; otpSuccessBanner.hidden = false; }
                    switchAuthTab('otp');
                } else {
                    window.location.href = data.redirectUrl;
                }
            } else {
                if (spinner) spinner.classList.remove('authdd-show');
                if (btnText) btnText.style.visibility = 'visible';
                if (btn) btn.disabled = false;
                if (errorBanner) { errorBanner.querySelector('.error-msg').textContent = data.loi || 'Đăng ký không thành công.'; errorBanner.hidden = false; }
            }
        })
        .catch(err => {
            console.error('Lỗi register AJAX:', err);
            if (spinner) spinner.classList.remove('authdd-show');
            if (btnText) btnText.style.visibility = 'visible';
            if (btn) btn.disabled = false;
            if (errorBanner) { errorBanner.querySelector('.error-msg').textContent='Có lỗi mạng xảy ra. Vui lòng thử lại!'; errorBanner.hidden = false; }
        });
    }

    function submitForgotPasswordForm(event) {
        event.preventDefault();
        const form = document.getElementById('modal-forgot-password-form');
        const btn = document.getElementById('modal-forgot-password-btn');
        const btnText = btn.querySelector('.btn-text');
        const spinner = btn.querySelector('.loading-spinner');
        const errorBanner = document.getElementById('forgot-password-error-banner');
        if (errorBanner) errorBanner.hidden = true;
        const formData = new FormData(form);
        const email = formData.get('email');
        if (spinner) spinner.classList.add('authdd-show');
        if (btnText) btnText.style.visibility = 'hidden';
        if (btn) btn.disabled = true;
        fetch(form.action, {
            method: 'POST',
            headers: { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest', 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams(formData)
        })
        .then(res => res.json())
        .then(data => {
            if (spinner) spinner.classList.remove('authdd-show');
            if (btnText) btnText.style.visibility = 'visible';
            if (btn) btn.disabled = false;
            if (data.success) {
                const displayEl = document.getElementById('otp-email-display');
                const hiddenEmailEl = document.getElementById('otp-hidden-email');
                if (displayEl) displayEl.textContent = email;
                if (hiddenEmailEl) hiddenEmailEl.value = email;
                const otpSuccessBanner = document.getElementById('otp-success-banner');
                if (otpSuccessBanner) { otpSuccessBanner.querySelector('.success-msg').textContent='Mã OTP đã được gửi đến email của bạn!'; otpSuccessBanner.hidden = false; }
                switchAuthTab('otp');
            } else {
                if (errorBanner) { errorBanner.querySelector('.error-msg').textContent=data.loi||'Có lỗi xảy ra.'; errorBanner.hidden = false; }
            }
        })
        .catch(err => {
            console.error('Lỗi Forgot Password AJAX:', err);
            if (spinner) spinner.classList.remove('authdd-show');
            if (btnText) btnText.style.visibility = 'visible';
            if (btn) btn.disabled = false;
            if (errorBanner) { errorBanner.querySelector('.error-msg').textContent='Có lỗi mạng xảy ra. Vui lòng thử lại!'; errorBanner.hidden = false; }
        });
    }

    function submitOtpForm(event) {
        event.preventDefault();
        const form = document.getElementById('modal-otp-form');
        const btn = document.getElementById('modal-otp-btn');
        const btnText = btn.querySelector('.btn-text');
        const spinner = btn.querySelector('.loading-spinner');
        const errorBanner = document.getElementById('otp-error-banner');
        const successBanner = document.getElementById('otp-success-banner');
        if (errorBanner) errorBanner.hidden = true;
        if (successBanner) successBanner.hidden = true;
        if (spinner) spinner.classList.add('authdd-show');
        if (btnText) btnText.style.visibility = 'hidden';
        if (btn) btn.disabled = true;
        fetch(form.action, {
            method: 'POST',
            headers: { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest', 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams(new FormData(form))
        })
        .then(res => res.json())
        .then(data => {
            if (spinner) spinner.classList.remove('authdd-show');
            if (btnText) btnText.style.visibility = 'visible';
            if (btn) btn.disabled = false;
            if (data.success) {
                if (data.step === 'reset-password') { switchAuthTab('reset-password'); }
                else if (data.step === 'register-success') {
                    switchAuthTab('login');
                    const loginSuccessBanner = document.getElementById('login-success-banner');
                    if (loginSuccessBanner) { loginSuccessBanner.querySelector('.success-msg').textContent=data.thongbao||'Đăng ký thành công! Vui lòng đăng nhập.'; loginSuccessBanner.hidden = false; }
                }
            } else {
                if (errorBanner) { errorBanner.querySelector('.error-msg').textContent=data.loi||'Mã xác thực không đúng.'; errorBanner.hidden = false; }
            }
        })
        .catch(err => {
            console.error('Lỗi Verify OTP AJAX:', err);
            if (spinner) spinner.classList.remove('authdd-show');
            if (btnText) btnText.style.visibility = 'visible';
            if (btn) btn.disabled = false;
            if (errorBanner) { errorBanner.querySelector('.error-msg').textContent='Có lỗi mạng xảy ra. Vui lòng thử lại!'; errorBanner.hidden = false; }
        });
    }

    function resendOtp() {
        const errorBanner = document.getElementById('otp-error-banner');
        const successBanner = document.getElementById('otp-success-banner');
        const emailInput = document.getElementById('otp-hidden-email');
        if (errorBanner) errorBanner.hidden = true;
        if (successBanner) successBanner.hidden = true;
        
        fetch('${pageContext.request.contextPath}/nhapma?action=resend&email=' + encodeURIComponent(emailInput.value))
        .then(res => res.json())
        .then(data => {
            if (data.success) {
                if (successBanner) { successBanner.querySelector('.success-msg').textContent='Đã gửi lại mã OTP!'; successBanner.hidden = false; }
            } else {
                if (errorBanner) { errorBanner.querySelector('.error-msg').textContent=data.loi||'Gửi lại OTP thất bại.'; errorBanner.hidden = false; }
            }
        }).catch(err => {
            console.error('Lỗi Resend OTP AJAX:', err);
            if (errorBanner) { errorBanner.querySelector('.error-msg').textContent='Có lỗi mạng xảy ra. Vui lòng thử lại!'; errorBanner.hidden = false; }
        });
    }

    function submitResetPasswordForm(event) {
        event.preventDefault();
        const form = document.getElementById('modal-reset-password-form');
        const btn = document.getElementById('modal-reset-password-btn');
        const btnText = btn.querySelector('.btn-text');
        const spinner = btn.querySelector('.loading-spinner');
        const errorBanner = document.getElementById('reset-password-error-banner');
        if (errorBanner) errorBanner.hidden = true;
        
        const password = document.getElementById('modal-new-pass').value;
        const confirmPassword = document.getElementById('modal-new-confirm').value;
        if (password !== confirmPassword) {
            if (errorBanner) { errorBanner.querySelector('.error-msg').textContent="Mật khẩu xác nhận không khớp!"; errorBanner.hidden = false; }
            return;
        }
        
        if (spinner) spinner.classList.add('authdd-show');
        if (btnText) btnText.style.visibility = 'hidden';
        if (btn) btn.disabled = true;
        fetch(form.action, {
            method: 'POST',
            headers: { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest', 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams(new FormData(form))
        })
        .then(res => res.json())
        .then(data => {
            if (spinner) spinner.classList.remove('authdd-show');
            if (btnText) btnText.style.visibility = 'visible';
            if (btn) btn.disabled = false;
            if (data.success) {
                switchAuthTab('login');
                const loginSuccessBanner = document.getElementById('login-success-banner');
                if (loginSuccessBanner) { loginSuccessBanner.querySelector('.success-msg').textContent='Cập nhật mật khẩu thành công. Vui lòng đăng nhập lại.'; loginSuccessBanner.hidden = false; }
            } else {
                if (errorBanner) { errorBanner.querySelector('.error-msg').textContent=data.loi||'Có lỗi xảy ra.'; errorBanner.hidden = false; }
            }
        })
        .catch(err => {
            console.error('Lỗi Reset Password AJAX:', err);
            if (spinner) spinner.classList.remove('authdd-show');
            if (btnText) btnText.style.visibility = 'visible';
            if (btn) btn.disabled = false;
            if (errorBanner) { errorBanner.querySelector('.error-msg').textContent='Có lỗi mạng xảy ra. Vui lòng thử lại!'; errorBanner.hidden = false; }
        });
    }
</script>
