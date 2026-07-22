<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>XtraMarket - Supermarket</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        /* Reset */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        /* Variables */
        :root {
            --primary: #01e281;
            --primary-hover: #01c771;
            --navy: #122d40;
            --navy-light: #1a3c54;
            --navy-dark: #0d2130;
            --background: #f8f9fa;
            --surface: #ffffff;
            --heading: #111111;
            --body-text: #555555;
            --muted-text: #888888;
            --border: #eeeeee;
            --danger: #ff4757;
            --warning: #ffa502;
            
            --container-width: 1320px;
            --section-spacing: 80px;
            
            --radius-small: 8px;
            --radius-medium: 16px;
            --radius-large: 24px;
            --radius-xl: 32px;
            
            --shadow-small: 0 4px 10px rgba(0, 0, 0, 0.05);
            --shadow-medium: 0 10px 30px rgba(18, 45, 64, 0.08);
            --shadow-large: 0 20px 40px rgba(18, 45, 64, 0.12);
            --transition: all 0.3s ease;
        }

        /* Base */
        body {
            font-family: 'Inter', sans-serif;
            color: var(--body-text);
            background-color: var(--background);
            line-height: 1.6;
            overflow-x: hidden;
        }

        h1, h2, h3, h4, h5, h6 {
            font-family: 'Outfit', sans-serif;
            color: var(--heading);
            font-weight: 700;
            line-height: 1.2;
        }

        a {
            text-decoration: none;
            color: inherit;
            transition: var(--transition);
        }

        ul {
            list-style: none;
        }

        img {
            max-width: 100%;
            height: auto;
            display: block;
        }

        .container {
            width: 100%;
            max-width: var(--container-width);
            margin: 0 auto;
            padding: 0 20px;
        }
        
        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 12px 28px;
            border-radius: 50px;
            font-family: 'Outfit', sans-serif;
            font-weight: 600;
            font-size: 15px;
            cursor: pointer;
            transition: var(--transition);
            border: none;
        }
        
        .btn-primary {
            background-color: var(--primary);
            color: var(--surface);
        }
        
        .btn-primary:hover {
            background-color: var(--navy);
            color: var(--surface);
        }
        
        .btn-outline {
            background-color: transparent;
            color: var(--surface);
            border: 1px solid rgba(255,255,255,0.2);
        }
        
        .btn-outline:hover {
            background-color: var(--surface);
            color: var(--navy);
        }

        .highlight {
            color: var(--primary);
            position: relative;
            z-index: 1;
        }
        
        .highlight::after {
            content: '';
            position: absolute;
            left: 0;
            bottom: 4px;
            width: 100%;
            height: 8px;
            background-color: rgba(1, 226, 129, 0.2);
            z-index: -1;
            border-radius: 4px;
        }

        .section-title {
            text-align: center;
            font-size: 36px;
            margin-bottom: 40px;
        }

        /* Header */
        .top-header {
            background-color: var(--navy);
            color: var(--surface);
            padding: 20px 0;
            position: relative;
            z-index: 100;
        }

        .header-main {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 30px;
        }

        .logo {
            display: flex;
            align-items: center;
            gap: 10px;
            font-family: 'Outfit', sans-serif;
            font-size: 28px;
            font-weight: 700;
            color: var(--surface);
        }
        
        .logo i {
            color: var(--primary);
            font-size: 32px;
        }
        
        .logo span {
            color: var(--primary);
        }

        .search-bar {
            flex: 1;
            max-width: 500px;
            position: relative;
        }

        .search-bar input {
            width: 100%;
            padding: 15px 25px;
            padding-right: 50px;
            border-radius: 50px;
            border: none;
            background-color: rgba(255, 255, 255, 0.1);
            color: var(--surface);
            font-family: 'Inter', sans-serif;
            font-size: 14px;
            outline: none;
        }
        
        .search-bar input::placeholder {
            color: rgba(255, 255, 255, 0.6);
        }

        .search-bar button {
            position: absolute;
            right: 20px;
            top: 50%;
            transform: translateY(-50%);
            background: none;
            border: none;
            color: rgba(255, 255, 255, 0.6);
            cursor: pointer;
            font-size: 16px;
        }

        .header-actions {
            display: flex;
            align-items: center;
            gap: 25px;
        }

        .call-center {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        
        .call-icon {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background-color: rgba(255, 255, 255, 0.1);
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--surface);
        }

        .call-text {
            display: flex;
            flex-direction: column;
        }
        
        .call-text span {
            font-size: 12px;
            color: rgba(255, 255, 255, 0.6);
        }
        
        .call-text strong {
            font-size: 15px;
            font-weight: 700;
            font-family: 'Outfit', sans-serif;
        }

        .action-icons {
            display: flex;
            align-items: center;
            gap: 15px;
            border-left: 1px solid rgba(255, 255, 255, 0.1);
            padding-left: 25px;
        }

        .icon-btn {
            position: relative;
            color: var(--surface);
            font-size: 20px;
            width: 44px;
            height: 44px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            background: rgba(255, 255, 255, 0.05);
        }
        
        .icon-btn:hover {
            background: rgba(255, 255, 255, 0.15);
        }

        .badge {
            position: absolute;
            top: -5px;
            right: -5px;
            background-color: var(--primary);
            color: var(--navy);
            font-size: 11px;
            font-weight: 700;
            width: 18px;
            height: 18px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        /* Navigation */
        .bottom-header {
            background-color: var(--navy);
            border-top: 1px solid rgba(255, 255, 255, 0.05);
        }
        
        .nav-inner {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 15px 0;
        }

        .main-nav ul {
            display: flex;
            align-items: center;
            gap: 20px;
        }

        .main-nav a {
            color: var(--surface);
            font-family: 'Outfit', sans-serif;
            font-weight: 500;
            font-size: 15px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .main-nav a:hover {
            color: var(--primary);
        }
        
        .nav-category {
            background: rgba(255,255,255,0.1);
            padding: 10px 20px;
            border-radius: 50px;
        }

        .nav-category i {
            margin-left: 5px;
            font-size: 12px;
        }

        .main-nav a.nav-active {
            background: var(--primary);
            color: var(--navy);
            padding: 10px 20px;
            border-radius: 50px;
            font-weight: 700;
        }

        .main-nav a.nav-active:hover {
            color: var(--navy);
        }

        .hot-badge {
            background-color: var(--danger);
            color: var(--surface);
            font-size: 10px;
            padding: 2px 6px;
            border-radius: 4px;
            font-weight: 700;
            margin-left: 5px;
        }

        /* Hero */
        .hero {
            background-color: #e5f6f1;
            position: relative;
            padding: 50px 0 80px;
            overflow: hidden;
            z-index: 1;
        }
        
        .hero-pattern {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-image: radial-gradient(#01e281 1px, transparent 1px);
            background-size: 30px 30px;
            opacity: 0.1;
            z-index: -1;
        }

        .hero-inner {
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .hero-content {
            flex: 1;
            max-width: 550px;
            padding-right: 40px;
        }

        .hero-content h1 {
            font-size: 52px;
            margin-bottom: 20px;
        }

        .hero-content p {
            font-size: 18px;
            color: var(--body-text);
            margin-bottom: 40px;
            font-weight: 400;
        }

        .hero-actions {
            display: flex;
            gap: 20px;
        }

        .hero-actions .btn:hover {
            transform: translateY(-2px);
        }

        .hero-actions .btn-outline {
            border-color: var(--navy);
            color: var(--navy);
        }
        
        .hero-actions .btn-outline:hover {
            background-color: var(--navy);
            color: var(--surface);
        }

        .hero-image {
            flex: 1;
            position: relative;
        }
        
        .hero-image img {
            border-radius: var(--radius-large);
            box-shadow: var(--shadow-large);
            width: 100%;
            height: 400px;
            object-fit: cover;
            transition: transform 0.3s ease;
        }
        
        .hero-image:hover img {
            transform: scale(1.02);
        }

        @media (prefers-reduced-motion: no-preference) {
            .hero-content {
                animation: fadeInUp 0.8s ease forwards;
            }
            .hero-image {
                animation: fadeInUp 0.8s ease 0.15s forwards;
                opacity: 0;
            }
        }

        @keyframes fadeInUp {
            from {
                opacity: 0;
                transform: translateY(20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        /* Benefits */
        .benefits-wrapper {
            margin-top: -60px;
            position: relative;
            z-index: 10;
        }
        
        .benefits {
            background-color: var(--surface);
            border-radius: var(--radius-xl);
            box-shadow: var(--shadow-large);
            padding: 40px;
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 20px;
        }

        .benefit-item {
            display: flex;
            align-items: center;
            gap: 20px;
        }

        .benefit-icon {
            width: 72px;
            height: 72px;
            border-radius: 50%;
            background-color: rgba(1, 226, 129, 0.1);
            color: var(--primary);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 28px;
            flex-shrink: 0;
            transition: var(--transition);
        }
        
        .benefit-item:hover .benefit-icon {
            background-color: var(--primary);
            color: var(--surface);
        }

        .benefit-text h4 {
            font-size: 18px;
            margin-bottom: 5px;
        }

        .benefit-text p {
            font-size: 14px;
            color: var(--muted-text);
        }

        /* Banners */
        .promo-banners {
            padding: var(--section-spacing) 0;
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 30px;
        }

        .promo-banner {
            border-radius: var(--radius-large);
            padding: 35px 30px;
            position: relative;
            overflow: hidden;
            min-height: 250px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            transition: var(--transition);
            z-index: 1;
        }
        
        .promo-banner:hover {
            transform: translateY(-5px);
            box-shadow: var(--shadow-medium);
        }
        
        .banner-red { background-color: #ff4d6d; color: white; }
        .banner-light { background-color: #f8f9fa; color: var(--heading); }
        .banner-green { background-color: var(--primary); color: white; }
        .banner-navy { background-color: var(--navy); color: white; }
        
        .promo-banner.banner-red, .promo-banner.banner-green, .promo-banner.banner-navy {
            color: white;
        }
        
        .promo-banner.banner-red h3, .promo-banner.banner-green h3, .promo-banner.banner-navy h3 {
            color: white;
        }

        .banner-content {
            position: relative;
            z-index: 2;
            max-width: 60%;
        }

        .banner-discount {
            font-family: 'Outfit', sans-serif;
            font-size: 18px;
            font-weight: 500;
            margin-bottom: 10px;
        }

        .promo-banner h3 {
            font-size: 28px;
            margin-bottom: 20px;
            line-height: 1.1;
        }

        .banner-image {
            position: absolute;
            right: -20px;
            bottom: -20px;
            width: 60%;
            z-index: 1;
            transition: var(--transition);
        }
        
        .promo-banner:hover .banner-image {
            transform: scale(1.05);
        }
        
        .btn-banner {
            background: var(--navy);
            color: white;
            padding: 10px 20px;
            border-radius: 50px;
            font-size: 13px;
            font-weight: 600;
            display: inline-block;
        }
        
        .banner-navy .btn-banner {
            background: var(--primary);
        }

        /* Categories */
        .categories {
            padding: 0 0 var(--section-spacing);
        }

        .category-grid {
            display: grid;
            grid-template-columns: repeat(6, 1fr);
            gap: 20px;
        }

        .category-card {
            background-color: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius-medium);
            padding: 30px 15px;
            text-align: center;
            transition: var(--transition);
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100%;
        }

        .category-card:hover {
            border-color: var(--primary);
            box-shadow: var(--shadow-medium);
            transform: translateY(-5px);
        }

        .category-icon {
            font-size: 40px;
            color: var(--primary);
            margin-bottom: 20px;
            transition: var(--transition);
        }
        
        .category-card:hover .category-icon {
            transform: scale(1.1);
        }

        .category-card h4 {
            font-size: 16px;
            margin: 0;
        }

        /* Products */
        .products {
            padding: 0 0 var(--section-spacing);
        }
        
        .products-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 40px;
        }
        
        .products-header .section-title {
            margin-bottom: 0;
            text-align: left;
        }

        .product-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 30px;
        }

        .product-card {
            background-color: var(--surface);
            border-radius: var(--radius-medium);
            padding: 25px;
            position: relative;
            transition: var(--transition);
            border: 1px solid transparent;
        }

        .product-card:hover {
            box-shadow: var(--shadow-medium);
            border-color: var(--border);
        }

        .product-badges {
            position: absolute;
            top: 20px;
            left: 20px;
            display: flex;
            flex-direction: column;
            gap: 5px;
            z-index: 2;
        }

        .badge-sale {
            background-color: var(--navy);
            color: white;
            font-size: 12px;
            font-weight: 600;
            padding: 4px 10px;
            border-radius: 20px;
        }

        .badge-discount {
            background-color: var(--danger);
            color: white;
            font-size: 12px;
            font-weight: 600;
            padding: 4px 10px;
            border-radius: 20px;
        }

        .product-actions {
            position: absolute;
            top: 20px;
            right: 20px;
            display: flex;
            flex-direction: column;
            gap: 10px;
            opacity: 0;
            transform: translateX(10px);
            transition: var(--transition);
            z-index: 2;
        }

        .product-card:hover .product-actions {
            opacity: 1;
            transform: translateX(0);
        }

        .action-icon {
            width: 36px;
            height: 36px;
            background-color: var(--surface);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--navy);
            box-shadow: var(--shadow-small);
            cursor: pointer;
            transition: var(--transition);
            border: 1px solid var(--border);
        }

        .action-icon:hover {
            background-color: var(--primary);
            color: white;
            border-color: var(--primary);
        }

        .product-image {
            height: 220px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 20px;
            position: relative;
        }

        .product-image img {
            max-height: 100%;
            transition: var(--transition);
        }
        
        .product-card:hover .product-image img {
            transform: scale(1.05);
        }

        .product-category {
            font-size: 13px;
            color: var(--muted-text);
            margin-bottom: 5px;
        }

        .product-title {
            font-size: 18px;
            margin-bottom: 10px;
        }
        
        .product-title a:hover {
            color: var(--primary);
        }

        .product-rating {
            color: var(--warning);
            font-size: 14px;
            margin-bottom: 15px;
        }

        .product-price {
            display: flex;
            align-items: center;
            gap: 10px;
            font-family: 'Outfit', sans-serif;
            font-weight: 700;
            font-size: 20px;
            color: var(--navy);
        }

        .price-old {
            color: var(--muted-text);
            text-decoration: line-through;
            font-size: 16px;
            font-weight: 500;
        }

        .add-to-cart {
            margin-top: 15px;
            width: 100%;
            background-color: transparent;
            color: var(--primary);
            border: 1px solid var(--primary);
            padding: 10px;
            border-radius: 50px;
            font-family: 'Outfit', sans-serif;
            font-weight: 600;
            cursor: pointer;
            transition: var(--transition);
            opacity: 0;
            visibility: hidden;
            transform: translateY(10px);
            position: absolute;
            bottom: 20px;
            left: 0;
            width: calc(100% - 50px);
            margin: 0 25px;
        }
        
        .product-card:hover .add-to-cart {
            opacity: 1;
            visibility: visible;
            transform: translateY(0);
        }

        .add-to-cart:hover {
            background-color: var(--primary);
            color: white;
        }
        
        .product-card:hover .product-price-wrapper {
            opacity: 0;
        }
        
        .product-price-wrapper {
            transition: var(--transition);
        }

        /* Mobile App */
        .mobile-app {
            background-color: var(--primary);
            border-radius: var(--radius-xl);
            padding: 60px 80px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            position: relative;
            overflow: hidden;
            margin-bottom: var(--section-spacing);
            color: white;
        }
        
        .mobile-app::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-image: radial-gradient(rgba(255,255,255,0.2) 1px, transparent 1px);
            background-size: 30px 30px;
            z-index: 1;
        }

        .app-content {
            position: relative;
            z-index: 2;
            max-width: 500px;
        }
        
        .app-content h2 {
            color: white;
            font-size: 48px;
            margin-bottom: 20px;
        }
        
        .app-content p {
            font-size: 18px;
            margin-bottom: 30px;
            opacity: 0.9;
        }

        .app-buttons {
            display: flex;
            gap: 20px;
        }

        .app-btn {
            background-color: var(--navy);
            color: white;
            padding: 12px 25px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            gap: 15px;
            transition: var(--transition);
        }
        
        .app-btn:hover {
            background-color: var(--navy-dark);
            transform: translateY(-3px);
        }
        
        .app-btn i {
            font-size: 30px;
        }
        
        .app-btn-text span {
            display: block;
            font-size: 11px;
            font-weight: 500;
        }
        
        .app-btn-text strong {
            display: block;
            font-family: 'Outfit', sans-serif;
            font-size: 18px;
            font-weight: 700;
        }

        .app-image {
            position: absolute;
            right: 50px;
            bottom: -50px;
            z-index: 2;
            width: 500px;
        }

        /* Blog */
        .blog {
            padding: 0 0 var(--section-spacing);
        }
        
        .blog-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 40px;
        }
        
        .blog-header h2 {
            margin: 0;
        }
        
        .blog-nav {
            display: flex;
            gap: 10px;
        }
        
        .blog-nav button {
            width: 44px;
            height: 44px;
            border-radius: 50%;
            border: 1px solid var(--border);
            background: var(--surface);
            color: var(--navy);
            cursor: pointer;
            transition: var(--transition);
        }
        
        .blog-nav button:hover {
            background: var(--primary);
            color: white;
            border-color: var(--primary);
        }

        .blog-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 30px;
        }

        .blog-card {
            border-radius: var(--radius-medium);
            overflow: hidden;
            background-color: var(--surface);
            transition: var(--transition);
            position: relative;
        }

        .blog-card:hover {
            box-shadow: var(--shadow-medium);
        }

        .blog-image {
            position: relative;
            height: 250px;
            overflow: hidden;
        }

        .blog-image img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            transition: transform 0.5s ease;
        }

        .blog-card:hover .blog-image img {
            transform: scale(1.1);
        }
        
        .blog-badge {
            position: absolute;
            top: 15px;
            left: 15px;
            background-color: var(--navy);
            color: white;
            font-family: 'Outfit', sans-serif;
            font-size: 12px;
            font-weight: 600;
            padding: 4px 12px;
            border-radius: 20px;
            z-index: 2;
        }

        .blog-content {
            padding: 20px;
        }

        .blog-date {
            font-size: 13px;
            color: var(--primary);
            font-weight: 500;
            margin-bottom: 10px;
            display: block;
        }

        .blog-title {
            font-size: 18px;
            margin-bottom: 15px;
            line-height: 1.4;
        }
        
        .blog-title a:hover {
            color: var(--primary);
        }

        /* Customer Reviews */
        .reviews {
            padding: 0 0 var(--section-spacing);
        }

        .reviews-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-end;
            margin-bottom: 40px;
            gap: 20px;
        }

        .reviews-header h2 {
            margin: 0 0 8px;
        }

        .reviews-subtitle {
            color: var(--body-text);
            font-size: 15px;
            margin: 0;
        }

        .reviews-nav {
            display: flex;
            gap: 10px;
            flex-shrink: 0;
        }

        .reviews-nav button {
            width: 44px;
            height: 44px;
            border-radius: 50%;
            border: 1px solid var(--border);
            background: var(--surface);
            color: var(--navy);
            cursor: pointer;
            transition: var(--transition);
        }

        .reviews-nav button:hover {
            background: var(--primary);
            color: white;
            border-color: var(--primary);
        }

        .reviews-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 30px;
        }

        .review-card {
            background-color: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius-medium);
            padding: 25px;
            transition: var(--transition);
        }

        .review-card:hover {
            box-shadow: var(--shadow-medium);
        }

        .review-top {
            display: flex;
            align-items: center;
            gap: 14px;
            margin-bottom: 16px;
        }

        .review-avatar {
            width: 52px;
            height: 52px;
            border-radius: 50%;
            object-fit: cover;
            flex-shrink: 0;
        }

        .review-identity h4 {
            margin: 0 0 2px;
            font-size: 16px;
        }

        .review-sport {
            font-size: 13px;
            color: var(--primary);
            font-weight: 500;
        }

        .review-rating {
            color: var(--warning);
            font-size: 13px;
            margin-bottom: 12px;
        }

        .review-rating span {
            color: var(--muted-text);
            font-size: 12px;
            margin-left: 4px;
        }

        .review-text {
            color: var(--body-text);
            font-size: 14.5px;
            line-height: 1.6;
            margin-bottom: 16px;
        }

        .review-meta {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 8px;
            padding-top: 14px;
            border-top: 1px solid var(--border);
        }

        .review-venue {
            font-size: 13px;
            font-weight: 600;
            color: var(--navy);
        }

        .review-date {
            font-size: 12px;
            color: var(--muted-text);
        }

        .review-badge {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            background-color: rgba(1, 226, 129, 0.1);
            color: var(--primary-hover);
            font-size: 11px;
            font-weight: 600;
            padding: 4px 10px;
            border-radius: 20px;
        }

        @media (max-width: 991px) {
            .reviews-grid { grid-template-columns: repeat(2, 1fr); }
        }

        @media (max-width: 767px) {
            .reviews-grid { grid-template-columns: 1fr; }
        }

        /* Newsletter */
        .newsletter-wrapper {
            position: relative;
            z-index: 10;
            margin-bottom: -80px;
        }
        
        .newsletter {
            background-color: var(--navy);
            border-radius: var(--radius-xl);
            padding: 60px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            position: relative;
            overflow: hidden;
        }
        
        .newsletter::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-image: radial-gradient(rgba(255,255,255,0.05) 1px, transparent 1px);
            background-size: 20px 20px;
            z-index: 1;
        }

        .newsletter-content {
            position: relative;
            z-index: 2;
            color: white;
            max-width: 500px;
        }
        
        .newsletter-content h2 {
            color: white;
            font-size: 32px;
            margin-bottom: 10px;
        }
        
        .newsletter-content p {
            color: rgba(255,255,255,0.7);
        }

        .newsletter-form {
            position: relative;
            z-index: 2;
            width: 100%;
            max-width: 500px;
            display: flex;
        }

        .newsletter-form input {
            flex: 1;
            padding: 18px 25px;
            border-radius: 50px 0 0 50px;
            border: none;
            outline: none;
            font-family: 'Inter', sans-serif;
            font-size: 15px;
        }

        .newsletter-form button {
            background-color: var(--primary);
            color: white;
            border: none;
            padding: 0 35px;
            border-radius: 0 50px 50px 0;
            font-family: 'Outfit', sans-serif;
            font-weight: 700;
            font-size: 15px;
            cursor: pointer;
            transition: var(--transition);
        }
        
        .newsletter-form button:hover {
            background-color: var(--primary-hover);
        }

        /* Footer */
        .footer {
            background-color: var(--navy-dark);
            color: rgba(255, 255, 255, 0.7);
            padding: 150px 0 30px;
        }

        .footer-grid {
            display: grid;
            grid-template-columns: 2fr 1fr 1fr 1fr;
            gap: 40px;
            margin-bottom: 50px;
            padding-bottom: 50px;
            border-bottom: 1px solid rgba(255,255,255,0.05);
        }
        
        .footer-col .logo {
            margin-bottom: 25px;
        }
        
        .footer-col p {
            margin-bottom: 25px;
            line-height: 1.8;
            max-width: 300px;
        }
        
        .social-icons {
            display: flex;
            gap: 10px;
        }
        
        .social-icons a {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: rgba(255,255,255,0.05);
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: var(--transition);
        }
        
        .social-icons a:hover {
            background: var(--primary);
        }

        .footer-col h4 {
            color: white;
            font-size: 20px;
            margin-bottom: 25px;
        }

        .footer-links li {
            margin-bottom: 15px;
        }

        .footer-links a {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .footer-links a::before {
            content: '\f105';
            font-family: 'Font Awesome 6 Free';
            font-weight: 900;
            font-size: 12px;
            color: var(--primary);
            transition: var(--transition);
        }

        .footer-links a:hover {
            color: var(--primary);
            transform: translateX(5px);
        }
        
        .contact-info li {
            display: flex;
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .contact-info i {
            color: var(--primary);
            font-size: 18px;
            margin-top: 5px;
        }
        
        .contact-info a {
            color: white;
            font-family: 'Outfit', sans-serif;
            font-weight: 600;
            font-size: 18px;
        }
        
        .contact-info a:hover {
            color: var(--primary);
        }

        .footer-bottom {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .payments {
            display: flex;
            gap: 10px;
        }
        
        .payment-card {
            width: 50px;
            height: 30px;
            background: white;
            border-radius: 4px;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 5px;
        }

        /* Floating Button */
        .scroll-top {
            position: fixed;
            bottom: 30px;
            right: 30px;
            width: 50px;
            height: 50px;
            background-color: var(--primary);
            color: white;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            cursor: pointer;
            box-shadow: var(--shadow-medium);
            z-index: 99;
            opacity: 0;
            visibility: hidden;
            transition: var(--transition);
        }
        
        .scroll-top.active {
            opacity: 1;
            visibility: visible;
        }
        
        .scroll-top:hover {
            background-color: var(--navy);
            transform: translateY(-5px);
        }

        /* Responsive */
        @media (max-width: 1400px) {
            .container { max-width: 1140px; }
            .hero-content h1 { font-size: 54px; }
        }

        @media (max-width: 1200px) {
            .container { max-width: 960px; }
            .benefits { grid-template-columns: repeat(2, 1fr); }
            .promo-banners { grid-template-columns: repeat(2, 1fr); }
            .category-grid { grid-template-columns: repeat(3, 1fr); }
            .product-grid { grid-template-columns: repeat(3, 1fr); }
            .app-image { width: 400px; right: 0; }
            .blog-grid { grid-template-columns: repeat(2, 1fr); }
            .footer-grid { grid-template-columns: repeat(2, 1fr); }
        }

        @media (max-width: 992px) {
            .container { max-width: 720px; }
            .header-main { flex-wrap: wrap; justify-content: space-between; }
            .search-bar { order: 3; max-width: 100%; flex: 1 1 100%; margin-top: 15px; }
            .bottom-header { display: none; /* Add hamburger menu logic here */ }
            .hero-inner { flex-direction: column; text-align: center; }
            .hero-content { padding-right: 0; margin-bottom: 40px; }
            .hero-actions { justify-content: center; }
            .benefits-wrapper { margin-top: 40px; }
            .product-grid { grid-template-columns: repeat(2, 1fr); }
            .mobile-app { flex-direction: column; text-align: center; padding: 40px; }
            .app-content { margin-bottom: 40px; }
            .app-buttons { justify-content: center; }
            .app-image { position: relative; right: auto; bottom: auto; width: 80%; }
            .newsletter { flex-direction: column; text-align: center; gap: 30px; padding: 40px; }
        }

        @media (max-width: 768px) {
            .container { max-width: 540px; }
            .benefits { grid-template-columns: 1fr; }
            .promo-banners { grid-template-columns: 1fr; }
            .category-grid { grid-template-columns: repeat(2, 1fr); }
            .blog-grid { grid-template-columns: 1fr; }
            .footer-grid { grid-template-columns: 1fr; }
            .hero-content h1 { font-size: 40px; }
            .newsletter-form { flex-direction: column; gap: 15px; border-radius: 0; }
            .newsletter-form input { border-radius: 50px; }
            .newsletter-form button { border-radius: 50px; padding: 15px; }
            .footer-bottom { flex-direction: column; gap: 20px; text-align: center; }
        }

        @media (max-width: 576px) {
            .container { max-width: 100%; padding: 0 15px; }
            .header-actions .call-center { display: none; }
            .category-grid { grid-template-columns: 1fr; }
            .product-grid { grid-template-columns: 1fr; }
            .app-buttons { flex-direction: column; }
        }

        /* Auth View Shared */
        .page-view {
            display: none;
            animation: fadeIn 0.3s ease-in;
        }
        
        .page-view.active {
            display: block;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        /* Auth Page Header */
        .auth-header {
            background-color: var(--surface);
            padding: 30px 0;
            border-bottom: 1px solid var(--border);
            margin-bottom: 60px;
        }
        
        .auth-header-inner {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .auth-title {
            font-size: 28px;
            margin: 0;
        }
        
        .breadcrumb {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 14px;
            color: var(--muted-text);
        }
        
        .breadcrumb a {
            color: var(--navy);
            font-weight: 500;
        }
        
        .breadcrumb a:hover {
            color: var(--primary);
        }
        
        /* Auth Layout */
        .auth-container {
            max-width: 1100px;
            margin: 0 auto;
            padding: 50px;
            background-color: #f1f4f7;
            border-radius: var(--radius-large);
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 50px;
            margin-bottom: 80px;
        }

        /* Auth Form */
        .auth-col h3 {
            font-size: 24px;
            margin-bottom: 30px;
        }
        
        .form-group {
            margin-bottom: 20px;
            position: relative;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-size: 14px;
            font-weight: 500;
            color: var(--heading);
        }
        
        .form-group label span {
            color: var(--danger);
        }
        
        /* Auth Input */
        .form-control {
            width: 100%;
            padding: 15px 20px;
            border: 1px solid var(--border);
            border-radius: var(--radius-small);
            font-family: 'Inter', sans-serif;
            font-size: 15px;
            color: var(--heading);
            background-color: var(--surface);
            transition: var(--transition);
        }
        
        .form-control:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(1, 226, 129, 0.1);
        }
        
        .form-control[aria-invalid="true"] {
            border-color: var(--danger);
        }
        
        .error-message {
            color: var(--danger);
            font-size: 12px;
            margin-top: 5px;
            display: none;
        }
        
        /* Auth Password Toggle */
        .password-input-wrap {
            position: relative;
        }
        
        .password-toggle {
            position: absolute;
            right: 15px;
            top: 50%;
            transform: translateY(-50%);
            background: none;
            border: none;
            color: var(--muted-text);
            cursor: pointer;
            padding: 5px;
        }
        
        .password-toggle:hover {
            color: var(--primary);
        }
        
        .password-helper {
            font-size: 12px;
            color: var(--muted-text);
            margin-top: 5px;
        }
        
        /* Auth Checkbox */
        .form-check {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 20px;
            cursor: pointer;
        }
        
        .form-check input[type="checkbox"] {
            width: 18px;
            height: 18px;
            accent-color: var(--primary);
            cursor: pointer;
        }
        
        .form-check label {
            margin: 0;
            font-size: 14px;
            font-weight: 400;
            cursor: pointer;
        }
        
        /* Auth Buttons */
        .auth-actions {
            display: flex;
            align-items: center;
            gap: 20px;
            margin-top: 30px;
        }
        
        .btn-auth {
            padding: 12px 35px;
            font-size: 16px;
        }
        
        .btn-auth:disabled {
            opacity: 0.7;
            cursor: not-allowed;
        }
        
        .btn-auth .fa-spinner {
            display: none;
            animation: spin 1s linear infinite;
        }
        
        .btn-auth.loading .fa-spinner {
            display: inline-block;
            margin-right: 8px;
        }
        
        @keyframes spin {
            100% { transform: rotate(360deg); }
        }
        
        .forgot-link {
            color: var(--navy);
            font-size: 14px;
            font-weight: 500;
            margin-top: 20px;
            display: inline-block;
        }
        
        .forgot-link:hover {
            color: var(--primary);
            text-decoration: underline;
        }
        
        /* Auth Modal */
        .modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(18, 45, 64, 0.7);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 1000;
            opacity: 0;
            visibility: hidden;
            transition: var(--transition);
        }
        
        .modal-overlay.active {
            opacity: 1;
            visibility: visible;
        }
        
        .modal-content {
            background: var(--surface);
            border-radius: var(--radius-large);
            padding: 40px;
            width: 90%;
            max-width: 500px;
            position: relative;
            transform: translateY(20px);
            transition: var(--transition);
        }
        
        .modal-overlay.active .modal-content {
            transform: translateY(0);
        }
        
        .modal-close {
            position: absolute;
            top: 20px;
            right: 20px;
            background: none;
            border: none;
            font-size: 20px;
            color: var(--muted-text);
            cursor: pointer;
        }
        
        .modal-close:hover {
            color: var(--danger);
        }
        
        .modal-content h3 {
            margin-bottom: 10px;
            font-size: 24px;
        }
        
        .modal-content p {
            color: var(--body-text);
            margin-bottom: 25px;
            font-size: 14px;
        }
        
        .success-toast {
            position: fixed;
            bottom: 30px;
            left: 50%;
            transform: translateX(-50%) translateY(20px);
            background: var(--primary);
            color: white;
            padding: 12px 25px;
            border-radius: 50px;
            font-weight: 600;
            font-family: 'Outfit', sans-serif;
            box-shadow: var(--shadow-medium);
            z-index: 1001;
            opacity: 0;
            visibility: hidden;
            transition: var(--transition);
        }
        
        .success-toast.active {
            opacity: 1;
            visibility: visible;
            transform: translateX(-50%) translateY(0);
        }
        
        /* Auth Tabs (Mobile) */
        .auth-tabs {
            display: none;
            border-bottom: 1px solid var(--border);
            margin-bottom: 30px;
        }
        
        .auth-tab-btn {
            flex: 1;
            background: none;
            border: none;
            padding: 15px;
            font-family: 'Outfit', sans-serif;
            font-size: 18px;
            font-weight: 600;
            color: var(--muted-text);
            cursor: pointer;
            position: relative;
        }
        
        .auth-tab-btn.active {
            color: var(--primary);
        }
        
        .auth-tab-btn.active::after {
            content: '';
            position: absolute;
            bottom: -1px;
            left: 0;
            width: 100%;
            height: 3px;
            background: var(--primary);
        }
        
        /* Auth Responsive */
        @media (max-width: 992px) {
            .auth-container {
                gap: 30px;
                padding: 40px 30px;
            }
        }
        
        @media (max-width: 768px) {
            .auth-container {
                display: block;
                padding: 30px 20px;
                margin-bottom: 40px;
            }
            .auth-tabs {
                display: flex;
            }
            .auth-col {
                display: none;
            }
            .auth-col.active {
                display: block;
            }
            .auth-col h3 {
                display: none;
            }
            .auth-actions {
                flex-direction: column;
                align-items: stretch;
            }
            .btn-auth {
                width: 100%;
            }
            .forgot-link {
                text-align: center;
                display: block;
                margin-top: 10px;
            }
            .auth-header-inner {
                flex-direction: column;
                gap: 15px;
                text-align: center;
            }
        }
    </style>
</head>