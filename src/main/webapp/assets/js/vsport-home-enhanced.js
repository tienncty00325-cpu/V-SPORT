document.addEventListener('DOMContentLoaded', () => {
    // 1. Scroll Reveal Animation
    const revealElements = document.querySelectorAll('.reveal');
    
    const revealOptions = {
        threshold: 0.1,
        rootMargin: "0px 0px -50px 0px"
    };

    const revealOnScroll = new IntersectionObserver(function(entries, observer) {
        entries.forEach(entry => {
            if (!entry.isIntersecting) return;
            entry.target.classList.add('revealed');
            observer.unobserve(entry.target);
        });
    }, revealOptions);

    revealElements.forEach(el => revealOnScroll.observe(el));

    // 2. Hero Mouse Parallax
    const heroSection = document.querySelector('.hero-banner');
    const parallaxElements = document.querySelectorAll('.parallax-el');

    if (heroSection) {
        heroSection.addEventListener('mousemove', (e) => {
            const x = (window.innerWidth - e.pageX * 2) / 90;
            const y = (window.innerHeight - e.pageY * 2) / 90;

            parallaxElements.forEach(el => {
                const speed = el.getAttribute('data-speed') || 1;
                el.style.transform = `translateX(${x * speed}px) translateY(${y * speed}px)`;
            });
        });
        heroSection.addEventListener('mouseleave', () => {
            parallaxElements.forEach(el => {
                el.style.transform = `translateX(0px) translateY(0px)`;
            });
        });
    }

    // 3. Number Counter Animation
    const counters = document.querySelectorAll('.counter');
    const counterObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const counter = entry.target;
                const target = parseFloat(counter.getAttribute('data-target'));
                const duration = 2000; // ms
                const start = 0;
                let startTime = null;

                const step = (timestamp) => {
                    if (!startTime) startTime = timestamp;
                    const progress = Math.min((timestamp - startTime) / duration, 1);
                    // easeOutQuart
                    const easeProgress = 1 - Math.pow(1 - progress, 4);
                    const current = start + easeProgress * (target - start);
                    
                    if (Number.isInteger(target)) {
                        counter.innerText = Math.floor(current).toLocaleString();
                    } else {
                        counter.innerText = current.toFixed(1);
                    }

                    if (progress < 1) {
                        window.requestAnimationFrame(step);
                    }
                };
                window.requestAnimationFrame(step);
                observer.unobserve(counter);
            }
        });
    }, { threshold: 0.5 });

    counters.forEach(counter => counterObserver.observe(counter));

    // 4. Scroll Progress Bar
    const progressBar = document.createElement('div');
    progressBar.className = 'scroll-progress';
    document.body.appendChild(progressBar);

    window.addEventListener('scroll', () => {
        const winScroll = document.body.scrollTop || document.documentElement.scrollTop;
        const height = document.documentElement.scrollHeight - document.documentElement.clientHeight;
        const scrolled = (winScroll / height) * 100;
        progressBar.style.width = scrolled + '%';
        
        // Back to top button
        const backToTop = document.getElementById('back-to-top');
        if (backToTop) {
            if (winScroll > 300) {
                backToTop.classList.add('visible');
            } else {
                backToTop.classList.remove('visible');
            }
        }
    });

    // 5. Toast System
    window.showEnhancedToast = function(message, type = 'success') {
        const container = document.getElementById('toast-container');
        if (!container) return;
        
        const toast = document.createElement('div');
        toast.className = `toast-enhanced toast-${type}`;
        
        let icon = 'fa-check-circle';
        if (type === 'error') icon = 'fa-exclamation-circle';
        if (type === 'info') icon = 'fa-info-circle';
        
        toast.innerHTML = `
            <div class="toast-icon"><i class="fa-solid ${icon}"></i></div>
            <div class="toast-message">${message}</div>
            <button class="toast-close"><i class="fa-solid fa-xmark"></i></button>
        `;
        
        container.appendChild(toast);
        
        // Trigger reflow
        void toast.offsetWidth;
        toast.classList.add('show');
        
        const removeToast = () => {
            toast.classList.remove('show');
            setTimeout(() => toast.remove(), 300);
        };
        
        toast.querySelector('.toast-close').addEventListener('click', removeToast);
        setTimeout(removeToast, 3000);
    };

    // 6. Lightbox Gallery
    const galleryItems = document.querySelectorAll('.gallery-lightbox-item');
    if (galleryItems.length > 0) {
        const lightbox = document.createElement('div');
        lightbox.className = 'lightbox-modal';
        lightbox.innerHTML = `
            <div class="lightbox-content">
                <button class="lightbox-close"><i class="fa-solid fa-xmark"></i></button>
                <img src="" alt="Lightbox Image">
                <div class="lightbox-caption"></div>
            </div>
        `;
        document.body.appendChild(lightbox);

        const lightboxImg = lightbox.querySelector('img');
        const lightboxCaption = lightbox.querySelector('.lightbox-caption');
        
        galleryItems.forEach(item => {
            item.addEventListener('click', (e) => {
                e.preventDefault();
                const imgSrc = item.getAttribute('href') || item.querySelector('img').src;
                const caption = item.getAttribute('data-caption') || '';
                lightboxImg.src = imgSrc;
                lightboxCaption.textContent = caption;
                lightbox.classList.add('active');
            });
        });

        lightbox.addEventListener('click', (e) => {
            if (e.target === lightbox || e.target.closest('.lightbox-close')) {
                lightbox.classList.remove('active');
            }
        });
    }

    // 7. Ripple Effect for Buttons
    const rippleButtons = document.querySelectorAll('.btn-ripple');
    rippleButtons.forEach(btn => {
        btn.addEventListener('click', function(e) {
            const x = e.clientX - e.target.getBoundingClientRect().left;
            const y = e.clientY - e.target.getBoundingClientRect().top;
            
            const ripples = document.createElement('span');
            ripples.className = 'ripple-effect';
            ripples.style.left = x + 'px';
            ripples.style.top = y + 'px';
            
            this.appendChild(ripples);
            setTimeout(() => ripples.remove(), 600);
        });
    });

    // 8. Back to top logic
    const btt = document.createElement('button');
    btt.id = 'back-to-top';
    btt.innerHTML = '<i class="fa-solid fa-arrow-up"></i>';
    document.body.appendChild(btt);
    
    btt.addEventListener('click', () => {
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });

    // 9. Floating Particles Generation for Hero
    const heroBg = document.querySelector('.hero-banner');
    if (heroBg) {
        const particlesContainer = document.createElement('div');
        particlesContainer.className = 'particles-container';
        heroBg.appendChild(particlesContainer);
        
        for (let i = 0; i < 20; i++) {
            const particle = document.createElement('div');
            particle.className = 'particle';
            particle.style.left = Math.random() * 100 + '%';
            particle.style.top = Math.random() * 100 + '%';
            particle.style.animationDuration = (Math.random() * 3 + 2) + 's';
            particle.style.animationDelay = Math.random() * 2 + 's';
            particlesContainer.appendChild(particle);
        }
    }
});
