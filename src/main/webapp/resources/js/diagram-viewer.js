mermaid.initialize({
    startOnLoad: false,
    theme: 'base',
    themeVariables: {
        primaryColor: '#ffffff',
        primaryBorderColor: '#000000',
        lineColor: '#000000',
        textColor: '#000000',
        fontFamily: 'Arial'
    }
});

document.addEventListener('DOMContentLoaded', () => {
    const list = document.getElementById('diagramList');
    const template = document.getElementById('cardTemplate');
    const menuGroup = document.getElementById('menuGroup');
    const searchInput = document.getElementById('searchInput');
    
    let renderedCount = 0;
    
    // Group diagrams by type
    const groups = {
        'TỔNG QUAN': [],
        'USE CASE': [],
        'KIẾN TRÚC': [],
        'THIẾT KẾ': [],
        'SEQUENCE DIAGRAM': [],
        'ACTIVITY DIAGRAM': [],
        'THỐNG KÊ': []
    };
    
    window.diagramCatalog.forEach(d => {
        if (d.type === 'usecase' || d.type === 'usecase_detail') groups['USE CASE'].push(d);
        else if (d.type === 'architecture' || d.type === 'mvc') groups['KIẾN TRÚC'].push(d);
        else if (d.type === 'erd' || d.type === 'class') groups['THIẾT KẾ'].push(d);
        else if (d.type === 'sequence') groups['SEQUENCE DIAGRAM'].push(d);
        else if (d.type === 'activity') groups['ACTIVITY DIAGRAM'].push(d);
        else if (d.type === 'chart') groups['THỐNG KÊ'].push(d);
        else groups['TỔNG QUAN'].push(d);
    });
    
    // Build Sidebar
    for (const [gName, items] of Object.entries(groups)) {
        if (items.length === 0) continue;
        const title = document.createElement('div');
        title.className = 'menu-title';
        title.textContent = gName;
        menuGroup.appendChild(title);
        
        items.forEach(item => {
            const a = document.createElement('a');
            a.className = 'menu-item';
            a.href = '#' + item.slug;
            a.textContent = item.title;
            menuGroup.appendChild(a);
        });
    }
    
    // Render Diagrams
    window.diagramCatalog.forEach(d => {
        const card = template.cloneNode(true);
        card.id = d.slug;
        card.style.display = 'flex';
        
        card.querySelector('.card-title').textContent = d.title;
        card.querySelector('.card-meta').textContent = `Mã: ${d.id} | Chương: ${d.chapter} | Trạng thái: ${d.status === 'completed' ? 'Hoàn thành' : 'Chưa có dữ liệu'}`;
        
        const info = card.querySelector('.info-panel');
        if (d.purpose) info.innerHTML += `<div class="info-row"><span class="info-label">Mục đích:</span> ${d.purpose}</div>`;
        if (d.precondition) info.innerHTML += `<div class="info-row"><span class="info-label">Điều kiện trước:</span> ${d.precondition}</div>`;
        if (d.main_flow) info.innerHTML += `<div class="info-row"><span class="info-label">Luồng chính:</span> ${d.main_flow}</div>`;
        if (d.alt_flow) info.innerHTML += `<div class="info-row"><span class="info-label">Luồng ngoại lệ:</span> ${d.alt_flow}</div>`;
        if (d.postcondition) info.innerHTML += `<div class="info-row"><span class="info-label">Điều kiện sau:</span> ${d.postcondition}</div>`;
        if (d.sourceFiles && d.sourceFiles.length > 0) info.innerHTML += `<div class="info-row"><span class="info-label">Source liên quan:</span> ${d.sourceFiles.join(', ')}</div>`;
        
        const inner = card.querySelector('.canvas-inner');
        const wrapper = card.querySelector('.canvas-wrapper');
        
        if (d.type === 'usecase' || d.type === 'usecase_detail') {
            inner.id = 'svg-uc-' + d.id;
            // Renderer will attach to it
            setTimeout(() => {
                const renderer = new SVGDiagramRenderer(inner.id);
                renderer.renderUseCase(d);
            }, 50);
        } else if (d.status === 'pending') {
            inner.innerHTML = `<div style="padding:40px;text-align:center;color:#666;">Chưa cập nhật kết quả thực tế.</div>`;
        } else {
            // Render basic mermaid block as placeholder for architecture, mvc, erd, sequence, activity
            // Since we don't have full mermaid strings in our basic data, we generate a mock or specific graph
            let mermaidStr = '';
            if (d.type === 'sequence') mermaidStr = `sequenceDiagram\nautonumber\nParticipant A\nParticipant B\nA->>B: Request\nB-->>A: Response`;
            else if (d.type === 'activity') mermaidStr = `stateDiagram-v2\n[*] --> State1\nState1 --> [*]`;
            else if (d.type === 'erd') mermaidStr = `erDiagram\nRoles ||--o{ Accounts : has`;
            else if (d.type === 'class') mermaidStr = `classDiagram\nclass Servlet\nclass DAO`;
            else mermaidStr = `graph TD\nA-->B`;
            
            const mId = 'mermaid-' + d.id;
            inner.innerHTML = `<pre class="mermaid" id="${mId}">${mermaidStr}</pre>`;
        }
        
        // Print Button
        card.querySelector('.print-btn').addEventListener('click', () => {
            const originalContents = document.body.innerHTML;
            const printContents = card.innerHTML;
            document.body.innerHTML = `<div class="diagram-card" style="box-shadow:none;border:none;margin:0;max-width:none;">${printContents}</div>`;
            window.print();
            document.body.innerHTML = originalContents;
            location.reload();
        });
        
        // Pan & Zoom
        let scale = 1;
        let isDragging = false;
        let startX, startY;
        let translateX = 0, translateY = 0;
        
        const updateTransform = () => {
            inner.style.transform = `translate(${translateX}px, ${translateY}px) scale(${scale})`;
        };
        
        card.querySelector('.zoom-in').addEventListener('click', () => { scale *= 1.2; updateTransform(); });
        card.querySelector('.zoom-out').addEventListener('click', () => { scale /= 1.2; updateTransform(); });
        card.querySelector('.zoom-reset').addEventListener('click', () => { scale = 1; translateX = 0; translateY = 0; updateTransform(); });
        
        wrapper.addEventListener('mousedown', (e) => {
            isDragging = true;
            startX = e.clientX - translateX;
            startY = e.clientY - translateY;
        });
        wrapper.addEventListener('mousemove', (e) => {
            if (!isDragging) return;
            translateX = e.clientX - startX;
            translateY = e.clientY - startY;
            updateTransform();
        });
        wrapper.addEventListener('mouseup', () => { isDragging = false; });
        wrapper.addEventListener('mouseleave', () => { isDragging = false; });
        
        wrapper.addEventListener('wheel', (e) => {
            if (e.ctrlKey) {
                e.preventDefault();
                scale += e.deltaY * -0.001;
                scale = Math.min(Math.max(0.125, scale), 4);
                updateTransform();
            }
        });
        
        list.appendChild(card);
    });
    
    setTimeout(() => { mermaid.init(undefined, document.querySelectorAll('.mermaid')); }, 100);
    
    // Sidebar toggle
    document.getElementById('toggleSidebar').addEventListener('click', () => {
        document.getElementById('sidebar').classList.toggle('open');
    });
    
    // Search filter
    searchInput.addEventListener('input', (e) => {
        const val = e.target.value.toLowerCase();
        document.querySelectorAll('.diagram-card').forEach(card => {
            if (card.id === 'cardTemplate') return;
            const text = card.textContent.toLowerCase();
            card.style.display = text.includes(val) ? 'flex' : 'none';
        });
    });
});
