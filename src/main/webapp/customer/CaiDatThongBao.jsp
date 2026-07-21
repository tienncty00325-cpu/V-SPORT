<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <title>Cài đặt thông báo - V-SPORT</title>
    <link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        /* ===== Full-bleed notification settings page (V-SPORT navy/cyan) ===== */
        :root {
            --notification-bg: #0B2D4D;
            --notification-bg-2: #0A3F63;
            --notification-bg-dark: #0E7490;
            --notification-text: #FFFFFF;
            --notification-muted: rgba(255, 255, 255, 0.68);
            --notification-divider: rgba(255, 255, 255, 0.22);
            --notification-toggle-on: #22D3EE;
            --notification-toggle-off: rgba(255, 255, 255, 0.28);
            --notification-knob: #FFFFFF;
        }

        * { box-sizing: border-box; }

        html, body {
            margin: 0;
            padding: 0;
            width: 100%;
        }

        body {
            min-height: 100vh;
            min-height: 100dvh;
            font-family: 'Be Vietnam Pro', 'Inter', system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            color: var(--notification-text);
            background: linear-gradient(180deg, var(--notification-bg) 0%, var(--notification-bg-2) 45%, var(--notification-bg-dark) 100%);
            background-attachment: fixed;
            -webkit-font-smoothing: antialiased;
            -webkit-tap-highlight-color: transparent;
        }

        /* Press effect: nhấn thì lún xuống rõ ràng, không hover bay lên */
        .vs-pressable {
            transition:
                transform 120ms ease,
                box-shadow 120ms ease,
                background-color 120ms ease,
                filter 120ms ease;
            will-change: transform;
        }
        .vs-pressable:active {
            transform: translateY(2px) scale(0.985);
            box-shadow: inset 0 2px 8px rgba(0, 0, 0, 0.18);
            filter: brightness(0.96);
        }

        /* ===== Header (full width) ===== */
        .ns-header {
            position: sticky;
            top: 0;
            z-index: 10;
            width: 100%;
            height: 72px;
            display: flex;
            align-items: center;
            padding: 0 12px;
            padding-top: env(safe-area-inset-top, 0px);
            background: var(--notification-bg);
        }
        .ns-back {
            width: 44px;
            height: 44px;
            flex: 0 0 44px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            border: none;
            border-radius: 999px;
            background: transparent;
            color: var(--notification-text);
            cursor: pointer;
            padding: 0;
        }
        .ns-back svg { width: 26px; height: 26px; }
        .ns-title {
            flex: 1 1 auto;
            text-align: center;
            font-size: 18px;
            font-weight: 700;
            color: var(--notification-text);
            /* cân bằng với nút back 44px bên trái để title thật sự nằm giữa */
            margin-right: 44px;
        }

        /* ===== Content (full width, không centered / không max-width) ===== */
        .ns-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            width: 100%;
            min-height: 64px;
            padding: 0 16px;
        }
        .ns-row__label {
            font-size: 16px;
            font-weight: 500;
            color: var(--notification-text);
        }

        .ns-note {
            width: 100%;
            text-align: center;
            font-size: 12.5px;
            font-style: italic;
            color: var(--notification-muted);
            line-height: 1.5;
            padding: 0 16px;
            margin: 6px 0 0;
        }

        .ns-divider {
            width: 100%;
            height: 0;
            border-top: 1px solid var(--notification-divider);
            margin: 14px 0 0;
        }

        .ns-section-title {
            width: 100%;
            text-align: center;
            font-size: 18px;
            font-weight: 700;
            color: var(--notification-text);
            margin: 16px 0 0;
            padding: 0 16px;
        }

        .ns-empty {
            width: 100%;
            text-align: center;
            font-size: 13px;
            color: var(--notification-muted);
            margin: 16px 0 0;
            padding: 0 16px;
        }

        /* ===== Toggle switch ===== */
        .notification-switch {
            position: relative;
            flex: 0 0 auto;
            display: inline-flex;
            align-items: center;
            justify-content: flex-start;
            width: 48px;
            height: 28px;
            border-radius: 999px;
            background: var(--notification-toggle-off);
            padding: 2px;
            border: none;
            cursor: pointer;
            transition: transform 120ms ease, box-shadow 120ms ease, background 180ms ease;
        }
        .notification-switch:active {
            transform: translateY(2px) scale(0.97);
            box-shadow: inset 0 2px 8px rgba(0, 0, 0, 0.22);
        }
        .notification-switch.is-on {
            background: var(--notification-toggle-on);
        }
        .notification-switch__knob {
            display: block;
            flex: 0 0 auto;
            width: 24px;
            height: 24px;
            border-radius: 50%;
            background: var(--notification-knob);
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.25);
            transition: transform 180ms ease;
        }
        .notification-switch.is-on .notification-switch__knob {
            transform: translateX(20px);
        }
        .notification-switch:focus-visible {
            outline: 2px solid #fff;
            outline-offset: 2px;
        }
    </style>
</head>
<body>
    <header class="ns-header">
        <button type="button" class="ns-back vs-pressable" onclick="goBack()" aria-label="Quay lại">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"/></svg>
        </button>
        <h1 class="ns-title">Cài đặt thông báo</h1>
    </header>

    <main>
        <div class="ns-row">
            <span class="ns-row__label">Thông báo từ chủ sân</span>
            <button type="button" class="notification-switch is-on" id="ownerNotifSwitch"
                    role="switch" aria-checked="true" aria-label="Thông báo từ chủ sân" onclick="toggleOwnerNotif(this)">
                <span class="notification-switch__knob"></span>
            </button>
        </div>

        <p class="ns-note">Lưu ý: Các thông báo này chỉ là thông báo khuyến mãi của chủ sân</p>

        <div class="ns-divider"></div>

        <h2 class="ns-section-title">Danh sách các sân tắt thông báo</h2>
        <p class="ns-note">Lưu ý: Muốn nhận lại thông báo vui lòng xoá chi nhánh cần mở thông báo</p>

        <p class="ns-empty">Không có dữ liệu</p>
    </main>

    <script>
        var CTX = '${pageContext.request.contextPath}';
        var STORAGE_KEY = 'vsport_owner_notif';

        // ---- Back: ưu tiên history.back(), fallback về trang Cài đặt ----
        function goBack() {
            var fallback = CTX + '/customer/tai-khoan#caidat';
            if (window.history.length > 1 && document.referrer) {
                window.history.back();
                // nếu history.back() không điều hướng (referrer khác origin), fallback sau 400ms
                setTimeout(function () {
                    window.location.href = fallback;
                }, 400);
            } else {
                window.location.href = fallback;
            }
        }

        // ---- Công tắc "Thông báo từ chủ sân": lưu trên thiết bị (chưa có backend) ----
        function applySwitchState(el, on) {
            el.classList.toggle('is-on', on);
            el.setAttribute('aria-checked', on ? 'true' : 'false');
        }
        function toggleOwnerNotif(el) {
            var on = !el.classList.contains('is-on');
            applySwitchState(el, on);
            try { localStorage.setItem(STORAGE_KEY, on ? '1' : '0'); } catch (e) { /* ignore */ }
        }
        (function initSwitch() {
            var el = document.getElementById('ownerNotifSwitch');
            var saved;
            try { saved = localStorage.getItem(STORAGE_KEY); } catch (e) { saved = null; }
            // mặc định bật nếu chưa có lựa chọn lưu trước đó
            applySwitchState(el, saved !== '0');
        })();
    </script>
</body>
</html>
