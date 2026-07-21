<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tài liệu sơ đồ hệ thống - V-SPORT</title>
    <link rel="stylesheet" href="${ctx}/resources/css/diagram-viewer.css">
    <link rel="stylesheet" href="${ctx}/resources/css/diagram-print.css" media="print">
    <!-- Load Mermaid -->
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10.6.1/dist/mermaid.min.js"></script>
</head>
<body>
    <aside class="sidebar" id="sidebar">
        <div class="sidebar-header">V-SPORT Docs</div>
        <div class="menu-group" id="menuGroup">
            <!-- Menus will be generated here -->
        </div>
    </aside>
    
    <main class="main-content">
        <header class="header">
            <div style="display:flex; align-items:center; gap:10px;">
                <button class="btn" id="toggleSidebar">☰</button>
                <h2>Tài liệu sơ đồ hệ thống</h2>
            </div>
            <div class="toolbar">
                <input type="text" id="searchInput" class="search-box" placeholder="Tìm kiếm sơ đồ...">
                <button class="btn" onclick="window.print()">In toàn bộ</button>
            </div>
        </header>
        
        <div class="diagram-container" id="diagramContainer">
            <!-- Diagram Card Template -->
            <div class="diagram-card" id="cardTemplate" style="display: none;">
                <div class="card-header">
                    <div>
                        <div class="card-title"></div>
                        <div class="card-meta"></div>
                    </div>
                    <div>
                        <button class="btn print-btn">In sơ đồ</button>
                    </div>
                </div>
                <div class="canvas-wrapper">
                    <div class="canvas-inner"></div>
                    <div class="controls">
                        <button class="zoom-in">+</button>
                        <button class="zoom-out">-</button>
                        <button class="zoom-reset">R</button>
                    </div>
                </div>
                <div class="info-panel"></div>
            </div>
            
            <div id="diagramList"></div>
        </div>
    </main>
    
    <script src="${ctx}/resources/js/diagram-data.js"></script>
    <script src="${ctx}/resources/js/svg-diagram-renderer.js"></script>
    <script src="${ctx}/resources/js/diagram-viewer.js"></script>
</body>
</html>
