document.addEventListener('DOMContentLoaded', () => {
    // FAQ Accordion interaction
    const faqItems = document.querySelectorAll('.cd-faq-item');
    const faqAnsTitle = document.getElementById('cdFaqAnsTitle');
    const faqAnsText = document.getElementById('cdFaqAnsText');

    if (faqItems.length > 0 && faqAnsTitle && faqAnsText) {
        faqItems.forEach(item => {
            item.addEventListener('click', () => {
                // Remove active class from all
                faqItems.forEach(i => i.classList.remove('active'));
                
                // Add to clicked
                item.classList.add('active');
                
                // Update text based on data attributes or internal content
                const qText = item.querySelector('.cd-faq-q-txt').textContent;
                const aText = item.getAttribute('data-answer');
                
                faqAnsTitle.textContent = qText;
                faqAnsText.textContent = aText;
            });
        });
    }

    // Hero Slider
    const slides = document.querySelectorAll('.vsh-hero-slide');
    if (slides.length > 1) {
        let currentSlide = 0;
        let slideInterval;
        const intervalTime = 4800; // 4.8s per slide

        const nextSlide = () => {
            slides[currentSlide].classList.remove('is-active');
            currentSlide = (currentSlide + 1) % slides.length;
            slides[currentSlide].classList.add('is-active');
        };

        const prevSlide = () => {
            slides[currentSlide].classList.remove('is-active');
            currentSlide = (currentSlide - 1 + slides.length) % slides.length;
            slides[currentSlide].classList.add('is-active');
        };

        const startSlider = () => {
            slideInterval = setInterval(nextSlide, intervalTime);
        };

        const stopSlider = () => {
            clearInterval(slideInterval);
        };

        startSlider();

        // Pause on tab visibility change
        document.addEventListener('visibilitychange', () => {
            if (document.hidden) {
                stopSlider();
            } else {
                startSlider();
            }
        });

        // Swipe support for mobile
        const sliderSection = document.querySelector('.vsh-hero-slider');
        let touchStartX = 0;
        let touchEndX = 0;

        sliderSection.addEventListener('touchstart', e => {
            touchStartX = e.changedTouches[0].screenX;
        }, { passive: true });

        sliderSection.addEventListener('touchend', e => {
            touchEndX = e.changedTouches[0].screenX;
            handleSwipe();
        }, { passive: true });

        const handleSwipe = () => {
            const threshold = 50;
            if (touchEndX < touchStartX - threshold) {
                // Swiped left
                stopSlider();
                nextSlide();
                startSlider();
            }
            if (touchEndX > touchStartX + threshold) {
                // Swiped right
                stopSlider();
                prevSlide();
                startSlider();
            }
        };
    }
});
