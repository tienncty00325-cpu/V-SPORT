import re

with open('src/main/webapp/customer/TaiKhoan.jsp', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Fix soDienThoai
content = content.replace('account.soDienThoai', 'account.phoneNumber')

# 2. Extract Main Content to use jsp:include with param
# First, find the <main> block
main_start = content.find('<main class="account-main">')
main_end = content.find('</main>') + len('</main>')

new_main = '''<main class="account-main">
            <c:choose>
                <c:when test="${empty param.tab or param.tab == 'overview'}">
                    <jsp:include page="/customer/fragments/overview.jsp" />
                </c:when>
                <c:when test="${param.tab == 'bookings'}">
                    <jsp:include page="/customer/fragments/bookings.jsp" />
                </c:when>
                <c:when test="${param.tab == 'matches'}">
                    <jsp:include page="/customer/fragments/matches.jsp" />
                </c:when>
                <c:when test="${param.tab == 'groups'}">
                    <jsp:include page="/customer/fragments/groups.jsp" />
                </c:when>
                <c:when test="${param.tab == 'opponents'}">
                    <jsp:include page="/customer/fragments/opponents.jsp" />
                </c:when>
                <c:when test="${param.tab == 'reputation'}">
                    <jsp:include page="/customer/fragments/reputation.jsp" />
                </c:when>
                <c:when test="${param.tab == 'profile'}">
                    <jsp:include page="/customer/fragments/profile.jsp" />
                </c:when>
                <c:when test="${param.tab == 'password'}">
                    <jsp:include page="/customer/fragments/password.jsp" />
                </c:when>
                <c:when test="${param.tab == 'notifications'}">
                    <jsp:include page="/customer/fragments/notifications.jsp" />
                </c:when>
                <c:when test="${param.tab == 'policies'}">
                    <jsp:include page="/customer/fragments/policies.jsp" />
                </c:when>
                <c:otherwise>
                    <jsp:include page="/customer/fragments/overview.jsp" />
                </c:otherwise>
            </c:choose>
        </main>'''

content = content[:main_start] + new_main + content[main_end:]

# 3. Update active classes in sidebar based on param.tab
sidebar_content = '''
            <div class="menu-card">
                <a href="${pageContext.request.contextPath}/customer/tai-khoan?tab=overview" class="menu-item ${empty param.tab or param.tab == 'overview' ? 'active' : ''}">
                    <i class="fas fa-home"></i> Tổng quan
                </a>
                <a href="${pageContext.request.contextPath}/customer/tai-khoan?tab=bookings" class="menu-item ${param.tab == 'bookings' ? 'active' : ''}">
                    <i class="fas fa-calendar-alt"></i> Lịch đặt sân
                </a>
                <a href="${pageContext.request.contextPath}/customer/tai-khoan?tab=matches" class="menu-item ${param.tab == 'matches' ? 'active' : ''}">
                    <i class="fas fa-futbol"></i> Kèo của tôi
                </a>
                <a href="${pageContext.request.contextPath}/customer/tai-khoan?tab=groups" class="menu-item ${param.tab == 'groups' ? 'active' : ''}">
                    <i class="fas fa-users"></i> Nhóm của tôi
                </a>
                <a href="${pageContext.request.contextPath}/customer/tai-khoan?tab=opponents" class="menu-item ${param.tab == 'opponents' ? 'active' : ''}">
                    <i class="fas fa-search"></i> Tìm đối thủ
                </a>
                <a href="${pageContext.request.contextPath}/customer/tai-khoan?tab=reputation" class="menu-item ${param.tab == 'reputation' ? 'active' : ''}">
                    <i class="fas fa-shield-alt"></i> Điểm uy tín
                </a>
                <a href="${pageContext.request.contextPath}/customer/tai-khoan?tab=profile" class="menu-item ${param.tab == 'profile' ? 'active' : ''}">
                    <i class="fas fa-user"></i> Thông tin cá nhân
                </a>
                <a href="${pageContext.request.contextPath}/customer/tai-khoan?tab=password" class="menu-item ${param.tab == 'password' ? 'active' : ''}">
                    <i class="fas fa-lock"></i> Đổi mật khẩu
                </a>
                <a href="${pageContext.request.contextPath}/customer/tai-khoan?tab=notifications" class="menu-item ${param.tab == 'notifications' ? 'active' : ''}">
                    <i class="fas fa-bell"></i> Cài đặt thông báo
                </a>
                <a href="${pageContext.request.contextPath}/customer/tai-khoan?tab=policies" class="menu-item ${param.tab == 'policies' ? 'active' : ''}">
                    <i class="fas fa-file-contract"></i> Điều khoản và chính sách
                </a>
                <a href="${pageContext.request.contextPath}/logout" class="menu-item danger">
                    <i class="fas fa-sign-out-alt"></i> Đăng xuất
                </a>
            </div>
'''
menu_start = content.find('<div class="menu-card">')
menu_end = content.find('</aside>')
content = content[:menu_start] + sidebar_content + content[menu_end:]

# 4. Write back
with open('src/main/webapp/customer/TaiKhoan.jsp', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated TaiKhoan.jsp")
