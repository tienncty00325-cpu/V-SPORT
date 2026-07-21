class SVGDiagramRenderer {
    constructor(containerId) {
        this.container = document.getElementById(containerId);
        if (!this.container) throw new Error("Container not found");
        this.svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
        this.svg.setAttribute("width", "100%");
        this.svg.setAttribute("height", "100%");
        this.svg.style.backgroundColor = "#ffffff";
        this.svg.style.fontFamily = "Arial, sans-serif";
        this.svg.style.userSelect = "none";
        this.container.innerHTML = "";
        this.container.appendChild(this.svg);
        this.defs = document.createElementNS("http://www.w3.org/2000/svg", "defs");
        this.svg.appendChild(this.defs);
        this.initDefs();
    }

    initDefs() {
        // Grid pattern
        const pattern = document.createElementNS("http://www.w3.org/2000/svg", "pattern");
        pattern.setAttribute("id", "grid");
        pattern.setAttribute("width", "20");
        pattern.setAttribute("height", "20");
        pattern.setAttribute("patternUnits", "userSpaceOnUse");
        
        const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
        path.setAttribute("d", "M 20 0 L 0 0 0 20");
        path.setAttribute("fill", "none");
        path.setAttribute("stroke", "#f0f0f0");
        path.setAttribute("stroke-width", "1");
        pattern.appendChild(path);
        
        // Arrow markers
        const createMarker = (id, color) => {
            const marker = document.createElementNS("http://www.w3.org/2000/svg", "marker");
            marker.setAttribute("id", id);
            marker.setAttribute("viewBox", "0 0 10 10");
            marker.setAttribute("refX", "9");
            marker.setAttribute("refY", "5");
            marker.setAttribute("markerWidth", "6");
            marker.setAttribute("markerHeight", "6");
            marker.setAttribute("orient", "auto-start-reverse");
            const poly = document.createElementNS("http://www.w3.org/2000/svg", "path");
            poly.setAttribute("d", "M 0 0 L 10 5 L 0 10 z");
            poly.setAttribute("fill", "none");
            poly.setAttribute("stroke", color);
            poly.setAttribute("stroke-width", "1.5");
            marker.appendChild(poly);
            this.defs.appendChild(marker);
        };
        
        createMarker("arrow-include", "#4CAF50");
        createMarker("arrow-extend", "#FF9800");
        createMarker("arrow-black", "#000000");

        this.defs.appendChild(pattern);
    }

    renderUseCase(diagramData) {
        this.svg.innerHTML = "";
        this.svg.appendChild(this.defs);
        
        // Draw grid
        const rect = document.createElementNS("http://www.w3.org/2000/svg", "rect");
        rect.setAttribute("width", "100%");
        rect.setAttribute("height", "100%");
        rect.setAttribute("fill", "url(#grid)");
        this.svg.appendChild(rect);
        
        const g = document.createElementNS("http://www.w3.org/2000/svg", "g");
        this.svg.appendChild(g);
        
        // Very basic layout engine
        const actors = diagramData.actors || [];
        const nodes = diagramData.nodes || [];
        const relations = diagramData.relations || [];
        
        const actorX = 100;
        const mainNodeX = 400;
        const subNodeX = 750;
        
        let actorY = 150;
        let mainNodeY = 150;
        let subNodeY = 100;
        
        const posMap = {};
        
        // Draw System Boundary
        if (nodes.length > 0) {
            const boundary = document.createElementNS("http://www.w3.org/2000/svg", "rect");
            boundary.setAttribute("x", "200");
            boundary.setAttribute("y", "40");
            boundary.setAttribute("width", "750");
            const maxNodes = Math.max(nodes.length, 5);
            boundary.setAttribute("height", `${maxNodes * 120}`);
            boundary.setAttribute("fill", "none");
            boundary.setAttribute("stroke", "#000");
            boundary.setAttribute("stroke-width", "1.5");
            g.appendChild(boundary);
            
            const boundaryText = document.createElementNS("http://www.w3.org/2000/svg", "text");
            boundaryText.setAttribute("x", "575");
            boundaryText.setAttribute("y", "70");
            boundaryText.setAttribute("text-anchor", "middle");
            boundaryText.setAttribute("font-size", "16");
            boundaryText.setAttribute("font-weight", "bold");
            boundaryText.textContent = "V-SPORT – Hệ thống quản lý chuỗi sân thể thao";
            g.appendChild(boundaryText);
        }
        
        // Draw Actors
        actors.forEach(actor => {
            posMap[actor.id] = { x: actorX, y: actorY, type: 'actor' };
            this.drawActor(g, actorX, actorY, actor.name);
            actorY += 150;
        });
        
        // Split nodes into main and sub (very naive heuristic: if target of include/extend, it's sub)
        const subNodeIds = new Set();
        relations.forEach(r => {
            if (r.type === 'include' || r.type === 'extend') {
                subNodeIds.add(r.target);
            }
        });
        
        nodes.forEach(node => {
            if (subNodeIds.has(node.id)) {
                posMap[node.id] = { x: subNodeX, y: subNodeY, type: 'usecase' };
                this.drawOval(g, subNodeX, subNodeY, node.name);
                subNodeY += 120;
            } else {
                posMap[node.id] = { x: mainNodeX, y: mainNodeY, type: 'usecase' };
                this.drawOval(g, mainNodeX, mainNodeY, node.name);
                mainNodeY += 150;
            }
        });
        
        // Draw Relations
        relations.forEach(rel => {
            const src = posMap[rel.source];
            const tgt = posMap[rel.target];
            if (src && tgt) {
                this.drawRelation(g, src, tgt, rel.type);
            }
        });
        
        // Auto-scale viewBox based on drawn content
        try {
            const bbox = g.getBBox();
            const pad = 50;
            this.svg.setAttribute("viewBox", `${Math.min(0, bbox.x - pad)} ${Math.min(0, bbox.y - pad)} ${bbox.width + pad * 2} ${bbox.height + pad * 2}`);
        } catch (e) {
            console.error(e);
        }
    }

    drawActor(g, x, y, name) {
        // Stickman
        const r = 12;
        const head = document.createElementNS("http://www.w3.org/2000/svg", "circle");
        head.setAttribute("cx", x);
        head.setAttribute("cy", y - 30);
        head.setAttribute("r", r);
        head.setAttribute("fill", "none");
        head.setAttribute("stroke", "#000");
        head.setAttribute("stroke-width", "2");
        g.appendChild(head);
        
        const body = document.createElementNS("http://www.w3.org/2000/svg", "path");
        body.setAttribute("d", `M ${x} ${y - 30 + r} L ${x} ${y + 20} M ${x - 20} ${y - 5} L ${x + 20} ${y - 5} M ${x} ${y + 20} L ${x - 15} ${y + 50} M ${x} ${y + 20} L ${x + 15} ${y + 50}`);
        body.setAttribute("fill", "none");
        body.setAttribute("stroke", "#000");
        body.setAttribute("stroke-width", "2");
        g.appendChild(body);
        
        const text = document.createElementNS("http://www.w3.org/2000/svg", "text");
        text.setAttribute("x", x);
        text.setAttribute("y", y + 70);
        text.setAttribute("text-anchor", "middle");
        text.setAttribute("font-size", "14");
        text.setAttribute("fill", "#000");
        text.textContent = name;
        g.appendChild(text);
    }

    drawOval(g, x, y, textContent) {
        const lines = textContent.split('\n');
        const width = Math.max(160, ...lines.map(l => l.length * 8)) + 40;
        const height = lines.length * 20 + 40;
        
        const ellipse = document.createElementNS("http://www.w3.org/2000/svg", "ellipse");
        ellipse.setAttribute("cx", x);
        ellipse.setAttribute("cy", y);
        ellipse.setAttribute("rx", width / 2);
        ellipse.setAttribute("ry", height / 2);
        ellipse.setAttribute("fill", "#fff");
        ellipse.setAttribute("stroke", "#000");
        ellipse.setAttribute("stroke-width", "1.5");
        g.appendChild(ellipse);
        
        const text = document.createElementNS("http://www.w3.org/2000/svg", "text");
        text.setAttribute("x", x);
        text.setAttribute("y", y - ((lines.length - 1) * 10));
        text.setAttribute("text-anchor", "middle");
        text.setAttribute("dominant-baseline", "middle");
        text.setAttribute("font-size", "14");
        text.setAttribute("fill", "#000");
        
        lines.forEach((line, index) => {
            const tspan = document.createElementNS("http://www.w3.org/2000/svg", "tspan");
            tspan.setAttribute("x", x);
            tspan.setAttribute("dy", index === 0 ? "0" : "20");
            tspan.textContent = line;
            text.appendChild(tspan);
        });
        
        g.appendChild(text);
    }

    drawRelation(g, src, tgt, type) {
        // Calculate intersection with oval boundary roughly
        let x1 = src.x;
        let y1 = src.y;
        let x2 = tgt.x;
        let y2 = tgt.y;
        
        if (src.type === 'actor') {
            x1 += 20; // right edge of actor roughly
        } else {
            const dx = tgt.x - src.x;
            const dy = tgt.y - src.y;
            const angle = Math.atan2(dy, dx);
            x1 += Math.cos(angle) * 80;
            y1 += Math.sin(angle) * 30;
        }
        
        if (tgt.type === 'actor') {
            x2 -= 20;
        } else {
            const dx = src.x - tgt.x;
            const dy = src.y - tgt.y;
            const angle = Math.atan2(dy, dx);
            x2 += Math.cos(angle) * 80;
            y2 += Math.sin(angle) * 30;
        }

        const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
        path.setAttribute("d", `M ${x1} ${y1} L ${x2} ${y2}`);
        path.setAttribute("fill", "none");
        path.setAttribute("stroke-width", "1");
        
        if (type === 'association') {
            path.setAttribute("stroke", "#000");
        } else if (type === 'include' || type === 'extend') {
            const isInclude = type === 'include';
            path.setAttribute("stroke", isInclude ? "#4CAF50" : "#FF9800");
            path.setAttribute("stroke-dasharray", "5,5");
            path.setAttribute("marker-end", isInclude ? "url(#arrow-include)" : "url(#arrow-extend)");
            
            // Add Label
            const mx = (x1 + x2) / 2;
            const my = (y1 + y2) / 2;
            
            // Background rect for text readability
            const rect = document.createElementNS("http://www.w3.org/2000/svg", "rect");
            rect.setAttribute("x", mx - 35);
            rect.setAttribute("y", my - 10);
            rect.setAttribute("width", "70");
            rect.setAttribute("height", "16");
            rect.setAttribute("fill", "#fff");
            g.appendChild(rect);

            const text = document.createElementNS("http://www.w3.org/2000/svg", "text");
            text.setAttribute("x", mx);
            text.setAttribute("y", my + 2);
            text.setAttribute("text-anchor", "middle");
            text.setAttribute("font-size", "12");
            text.setAttribute("font-weight", "bold");
            text.setAttribute("fill", isInclude ? "#4CAF50" : "#FF9800");
            text.textContent = isInclude ? "<<include>>" : "<<extend>>";
            g.appendChild(text);
        }
        
        g.appendChild(path);
    }
}
window.SVGDiagramRenderer = SVGDiagramRenderer;
