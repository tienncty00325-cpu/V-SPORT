/**
 * V-SPORT Customer Landing Page interactions
 */

// 1. Toast Notification
function showToast(message) {
    const container = document.getElementById('toast-container');
    if (!container) return;
    
    const toast = document.createElement('div');
    toast.className = 'toast';
    toast.innerHTML = `<i class="fa-solid fa-circle-check text-red" style="margin-right: 8px;"></i> ${message}`;
    
    container.appendChild(toast);
    
    // Remove after 3 seconds
    setTimeout(() => {
        toast.style.animation = 'fadeOut 0.3s ease forwards';
        setTimeout(() => {
            if (container.contains(toast)) {
                container.removeChild(toast);
            }
        }, 300);
    }, 3000);
}

// 2. Smooth Scroll
function scrollToSection(e, sectionId) {
    e.preventDefault();
    const target = document.getElementById(sectionId);
    if (target) {
        // Account for sticky header height
        const headerOffset = 80;
        const elementPosition = target.getBoundingClientRect().top;
        const offsetPosition = elementPosition + window.scrollY - headerOffset;
  
        window.scrollTo({
             top: offsetPosition,
             behavior: "smooth"
        });
    }
}

// 3. Scroll Reveal Animation
function reveal() {
    var reveals = document.querySelectorAll(".reveal");
    for (var i = 0; i < reveals.length; i++) {
        var windowHeight = window.innerHeight;
        var elementTop = reveals[i].getBoundingClientRect().top;
        var elementVisible = 100; // Trigger threshold
        
        if (elementTop < windowHeight - elementVisible) {
            reveals[i].classList.add("active");
        }
    }
}
window.addEventListener("scroll", reveal);
reveal(); // Trigger on load

// 4. Counter Animation for Stats
function animateCounters() {
    const counters = document.querySelectorAll('.counter');
    const speed = 200; // The lower the slower

    counters.forEach(counter => {
        const updateCount = () => {
            const target = +counter.getAttribute('data-target');
            const count = +counter.innerText;
            const inc = target / speed;

            if (count < target) {
                // If it's a decimal (like 4.8), format accordingly
                if (target % 1 !== 0) {
                    counter.innerText = (count + inc).toFixed(1);
                } else {
                    counter.innerText = Math.ceil(count + inc);
                }
                setTimeout(updateCount, 10);
            } else {
                counter.innerText = target + (target > 100 ? '+' : '');
            }
        };

        // Check if counter is in viewport before animating
        const rect = counter.getBoundingClientRect();
        if (rect.top < window.innerHeight && counter.innerText == '0') {
            updateCount();
        }
    });
}
window.addEventListener('scroll', animateCounters);

// 5. Tabs for Live Slots (Mock)
document.addEventListener('DOMContentLoaded', () => {
    const tabs = document.querySelectorAll('.tab-btn');
    tabs.forEach(tab => {
        tab.addEventListener('click', (e) => {
            // Remove active from all
            tabs.forEach(t => t.classList.remove('active'));
            // Add active to clicked
            e.target.classList.add('active');
            
            // Re-animate the grid to simulate loading new data
            const grid = document.querySelector('.slots-grid');
            if (grid) {
                grid.style.opacity = '0';
                setTimeout(() => {
                    grid.style.opacity = '1';
                }, 300);
            }
        });
    });
});
