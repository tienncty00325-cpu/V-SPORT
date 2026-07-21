<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="icon" type="image/svg+xml" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🧭</text></svg>">
<title>V-Sport — Nâng Tầm Quản Lý Cơ Sở Thể Thao</title>
<meta name="description" content="Hệ thống quản lý thông minh giúp tối ưu lịch đặt sân, quản lý hội viên và tăng doanh thu hiệu quả với công nghệ AI tiên tiến.">
<meta name="theme-color" content="#17130E">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="">
<link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@300;400;500;600;700&amp;family=Fraunces:ital,opsz,wght@0,9..144,300..900;1,9..144,300..700&amp;display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<style>
/* ============================== TOKENS ============================== */
:root{
--ink:#17130E;          /* warm near-black */
--ink-2:#2a231b;
--paper:#F3ECE0;        /* warm bone */
--paper-2:#EDE4D5;
--night:#13100B;        /* dark interlude ground */
--night-2:#1c1812;
--accent:#C9612F;       /* rationed sunset amber — the ONLY saturated color */
--accent-2:#E08A4F;
--stone:#8b7f6d;        /* muted text */
--stone-d:#a99b85;      /* muted on dark */
--line:rgba(23,19,14,.14);
--line-d:rgba(243,236,224,.16);
--ease:cubic-bezier(.16,1,.3,1);      /* signature: fast start, long settle */
--ease-soft:cubic-bezier(.19,1,.22,1);
--serif:"Fraunces",Georgia,serif;
--sans:"Be Vietnam Pro",-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;
--maxw:1320px;
--pad:clamp(20px,5vw,84px);
}
*{box-sizing:border-box;margin:0;padding:0}
html{-webkit-text-size-adjust:100%}
body{
font-family:var(--sans);
background:var(--paper);
color:var(--ink);
line-height:1.6;
-webkit-font-smoothing:antialiased;
overflow-x:clip;
}
img{display:block;max-width:100%;height:auto}
a{color:inherit;text-decoration:none}
::selection{background:var(--accent);color:#fff}
/* film grain — self-contained SVG turbulence, fixed, very subtle */
body::before{
content:"";position:fixed;inset:0;z-index:9000;pointer-events:none;
opacity:.05;mix-blend-mode:multiply;
background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='160' height='160'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='.9' numOctaves='2' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
}
/* ============================== TYPE ============================== */
.eyebrow{
font-family:var(--sans);font-weight:500;font-size:.72rem;letter-spacing:.28em;
text-transform:uppercase;color:var(--accent);
}
.eyebrow.muted{color:var(--stone)}
h1,h2,h3{font-family:var(--serif);font-weight:540;line-height:1.02;letter-spacing:-.02em}
.thin{font-weight:300;font-style:italic;letter-spacing:-.01em}
.display{font-size:clamp(2.8rem,8.5vw,8.2rem)}
.h2{font-size:clamp(2rem,5vw,4.4rem);line-height:1.04}
.lead{font-size:clamp(1.05rem,1.5vw,1.35rem);color:var(--ink-2);max-width:46ch;font-weight:300}
.small-caps{font-size:.74rem;letter-spacing:.22em;text-transform:uppercase;color:var(--stone);font-weight:500}
.wrap{max-width:var(--maxw);margin-inline:auto;padding-inline:var(--pad)}
/* ============================== CHROME ============================== */
.progress{position:fixed;top:0;left:0;height:2px;width:100%;transform:scaleX(0);transform-origin:0 50%;
background:var(--accent);z-index:8000}
header.nav{
position:fixed;top:0;left:0;width:100%;z-index:7000;
display:flex;align-items:center;justify-content:space-between;
padding:22px var(--pad);
transition:padding .5s var(--ease),background .5s var(--ease),color .5s var(--ease);
color:var(--paper);mix-blend-mode:difference;
}
header.nav.solid{mix-blend-mode:normal;background:rgba(4,12,24,.9);backdrop-filter:blur(12px);
color:var(--paper);padding:14px var(--pad);border-bottom:1px solid rgba(255,255,255,0.1)}
.brand{font-family:var(--serif);font-weight:600;font-size:1.28rem;letter-spacing:.04em}
.brand span{color:var(--accent)}
.nav-links{display:flex;gap:34px;align-items:center}
.nav-links a{font-size:.82rem;letter-spacing:.04em;font-weight:500;opacity:.85;transition:opacity .3s}
.nav-links a:hover{opacity:1}
.nav-cta{border:1px solid currentColor;border-radius:100px;padding:9px 20px;font-size:.78rem;
letter-spacing:.06em;font-weight:500;transition:background .35s var(--ease),color .35s var(--ease),transform .35s}
header.nav.solid .nav-cta{background:var(--accent);color:#fff;border-color:var(--accent)}
header.nav.solid .nav-cta:hover{background:var(--accent-2);transform:translateY(-2px)}
@media(max-width:760px){.nav-links a:not(.nav-cta){display:none}}
/* custom cursor (desktop pointer only) */
.cursor{position:fixed;top:0;left:0;z-index:9500;pointer-events:none;
display:flex;align-items:center;gap:8px;
background:var(--accent);color:#fff;border-radius:100px;
padding:8px 16px;font-size:.7rem;letter-spacing:.1em;text-transform:uppercase;font-weight:600;
transform:translate(-50%,-50%) scale(.4);opacity:0;transition:opacity .3s,transform .3s var(--ease);
white-space:nowrap;font-family:var(--sans)}
.cursor.show{opacity:1;transform:translate(-50%,-50%) scale(1)}
@media(hover:none),(pointer:coarse){.cursor{display:none}}
/* cartographic route rail (fixed waypoint indicator, left gutter, desktop) */
.rail{position:fixed;left:26px;top:50%;transform:translateY(-50%);z-index:6000;pointer-events:none;
display:flex;flex-direction:column;align-items:center;gap:16px;color:var(--rail-fg,#fff);
transition:color .6s var(--ease)}
.rail .rcap{font-size:.58rem;letter-spacing:.28em;text-transform:uppercase;writing-mode:vertical-rl;
min-height:118px;display:flex;align-items:center;justify-content:center;font-weight:600;
transition:opacity .4s var(--ease)}
.rail .rtrack{width:1px;height:150px;background:currentColor;opacity:.4;position:relative}
.rail .rdot{position:absolute;left:50%;top:0;width:7px;height:7px;margin-left:-3px;border-radius:50%;
background:var(--accent);box-shadow:0 0 0 4px rgba(201,97,47,.16)}
.rail .rlabel{font-size:.5rem;letter-spacing:.34em;writing-mode:vertical-rl;opacity:.55;font-weight:500}
@media(max-width:980px){.rail{display:none}}
/* veil entrance */
.veil{position:fixed;inset:0;z-index:9999;background:var(--ink);
display:flex;align-items:center;justify-content:center;flex-direction:column;gap:24px;color:var(--paper)}
.veil .vmark{font-family:var(--serif);font-size:clamp(2rem,6vw,3.6rem);letter-spacing:.1em;
font-weight:600;overflow:hidden}
.veil .vmark span{display:inline-block}
.veil .vbar{width:min(220px,50vw);height:1px;background:var(--line-d);position:relative;overflow:hidden}
.veil .vbar i{position:absolute;inset:0;background:var(--accent);transform:scaleX(0);transform-origin:0 50%}
/* ============================== HERO ============================== */
.hero{position:relative;height:100svh;min-height:820px;overflow:hidden;background:var(--ink);color:var(--paper)}
.hero-media{position:absolute;inset:-8% -4%;will-change:transform}
.hero-media img{width:100%;height:100%;object-fit:cover;object-position:center right;transform:scale(1.05)}
.hero::after{content:"";position:absolute;inset:0;
background:linear-gradient(90deg,rgba(4,12,24,.94) 0%,rgba(4,12,24,.82) 28%,rgba(4,12,24,.35) 58%,rgba(4,12,24,.08) 100%),linear-gradient(0deg,rgba(3,9,18,.6) 0%,rgba(3,9,18,.05) 55%);}
.hero-inner{position:relative;z-index:3;height:100%;display:flex;flex-direction:column;justify-content:flex-end;
padding:0 var(--pad) clamp(40px,8vh,90px);max-width:var(--maxw);margin-inline:auto}
.hero-content-wrap{max-width:65%;}
.hero .eyebrow{margin-bottom:24px;font-size:clamp(11px,1.2vw,13px);}
.hero h1{font-size:clamp(54px,6vw,92px);max-width:14ch;margin-top:2px}
.hero .line-wrap{overflow:hidden;display:block}
.hero-sub{display:flex;flex-wrap:wrap;gap:26px;align-items:flex-end;justify-content:space-between;margin-top:34px}
.hero-sub .lead{color:rgba(243,236,224,.86);font-size:clamp(17px,1.8vw,20px);}
.cta-split{display:flex;align-items:center;gap:14px;flex-shrink:0}
.pill{display:inline-flex;align-items:center;gap:10px;background:var(--accent);color:#fff;
border-radius:100px;padding:16px 28px;font-weight:600;font-size:clamp(14px,1vw,16px);letter-spacing:.02em;
transition:transform .4s var(--ease),background .4s var(--ease);will-change:transform}
.pill:hover{background:var(--accent-2);transform:translateY(-2px)}
.disc{width:54px;height:54px;border-radius:50%;border:1px solid rgba(243,236,224,.5);
display:grid;place-items:center;color:var(--paper);flex-shrink:0;transition:.4s var(--ease)}
.disc:hover{background:var(--paper);color:var(--ink);border-color:var(--paper);transform:translateY(-2px)}
.disc svg{width:18px;height:18px}
.scrollcue{position:absolute;bottom:26px;left:50%;transform:translateX(-50%);z-index:4;
display:flex;flex-direction:column;align-items:center;gap:10px;color:rgba(243,236,224,.7)}
.scrollcue .ln{width:1px;height:48px;background:rgba(243,236,224,.4);position:relative;overflow:hidden}
.scrollcue .ln::after{content:"";position:absolute;left:0;top:0;width:100%;height:40%;background:var(--accent);
animation:cue 2.1s var(--ease) infinite}
@keyframes cue{0%{transform:translateY(-110%)}60%,100%{transform:translateY(260%)}}
.scrollcue span{font-size:.62rem;letter-spacing:.3em;text-transform:uppercase}
@media(max-width:980px){
  .hero-content-wrap{max-width:100%;}
  .hero h1{font-size:clamp(40px,7vw,60px);}
}
@media(max-width:760px){
  .scrollcue{display:none}
  .hero-media img{object-position:70% center;}
  .hero::after{background:linear-gradient(180deg,rgba(4,12,24,.4) 0%,rgba(4,12,24,.95) 100%),linear-gradient(90deg,rgba(4,12,24,.9) 0%,rgba(4,12,24,.4) 100%);}
  .hero-sub{flex-direction:column;align-items:flex-start;gap:20px;}
  .cta-split{width:100%;justify-content:space-between;}
}
/* ============================== MANIFESTO ============================== */
.manifesto{position:relative;padding:clamp(110px,16vh,210px) 0;background:var(--paper)}
.manifesto .ghost{position:absolute;top:8%;left:50%;transform:translateX(-50%);
font-family:var(--serif);font-weight:600;font-size:clamp(8rem,28vw,26rem);color:var(--ink);
opacity:.03;letter-spacing:-.04em;pointer-events:none;white-space:nowrap;z-index:0}
.manifesto .wrap{position:relative;z-index:1}
.statement{font-family:var(--serif);font-weight:540;font-size:clamp(1.9rem,4.6vw,4rem);
line-height:1.12;letter-spacing:-.02em;max-width:20ch}
.statement em{color:var(--accent);font-style:italic;font-weight:400}
.manifesto .body{margin-top:48px;display:grid;grid-template-columns:1fr 1fr;gap:40px;max-width:760px}
.manifesto .body p{color:var(--ink-2);font-weight:300;font-size:1.02rem}
@media(max-width:680px){.manifesto .body{grid-template-columns:1fr}}
/* ============================== JOURNEYS (horizontal) ============================== */
.journeys{background:var(--ink);color:var(--paper)}
.jpin{height:100svh;overflow:hidden;display:flex;align-items:center}
.jtrack{display:flex;gap:clamp(20px,3vw,46px);padding:0 var(--pad);align-items:stretch;will-change:transform}
.jpanel{flex:0 0 auto;width:min(78vw,560px);display:flex;flex-direction:column;justify-content:center}
.jpanel h2{font-size:clamp(2.2rem,5vw,4.2rem)}
.jpanel .lead{color:var(--stone-d);margin-top:22px}
.jpanel .eyebrow{margin-bottom:18px}
.joutro .pill{align-self:flex-start;margin-top:30px}
.jcard{flex:0 0 auto;width:min(70vw,440px);position:relative;display:flex;flex-direction:column;justify-content:flex-end}
.jcard .frame{position:relative;width:100%;aspect-ratio:4/5;overflow:hidden;border-radius:2px;background:var(--ink-2)}
.jcard .frame img{position:absolute;inset:-8% 0;width:100%;height:116%;object-fit:cover;will-change:transform}
.jcard .frame::after{content:"";position:absolute;inset:0;
background:linear-gradient(180deg,transparent 40%,rgba(19,16,11,.78) 100%)}
.jcard .meta{position:absolute;left:24px;right:24px;bottom:24px;z-index:2}
.jcard .coord{font-family:var(--sans);font-size:.7rem;letter-spacing:.18em;color:var(--accent-2);font-weight:600}
.jcard h3{font-size:clamp(1.7rem,2.4vw,2.4rem);margin:8px 0 6px}
.jcard .note{font-size:.92rem;color:var(--stone-d);font-weight:300}
.jcard .idx{position:absolute;top:18px;left:24px;z-index:2;font-size:.72rem;letter-spacing:.12em;
color:rgba(243,236,224,.7);font-weight:600}
.jhint{position:absolute;bottom:30px;right:var(--pad);z-index:5;color:var(--stone-d);
font-size:.66rem;letter-spacing:.26em;text-transform:uppercase;display:flex;align-items:center;gap:10px}
.jhint .bar{width:42px;height:1px;background:var(--line-d);position:relative;overflow:hidden}
.jhint .bar i{position:absolute;inset:0;background:var(--accent);transform-origin:0 50%;transform:scaleX(0)}
/* mobile fallback: native horizontal scroll, no pin */
.journeys.mobile .jpin{height:auto;padding:90px 0;display:block}
.journeys.mobile .jtrack{overflow-x:auto;scroll-snap-type:x mandatory;-webkit-overflow-scrolling:touch;
padding-bottom:20px;transform:none!important}
.journeys.mobile .jcard,.journeys.mobile .jpanel{scroll-snap-align:center}
.journeys.mobile .jhint{display:none}
/* ============================== EXPERIENCE (sticky scrollytelling) ============================== */
.exp{background:var(--paper-2);padding:clamp(90px,12vh,150px) 0}
.exp .head{margin-bottom:clamp(40px,7vh,90px);max-width:680px}
.exp .head h2{margin-top:18px}
.exp-grid{display:grid;grid-template-columns:1.05fr .95fr;gap:clamp(30px,5vw,80px);align-items:start}
.exp-media{position:sticky;top:14vh;height:72vh;border-radius:2px;overflow:hidden;background:var(--ink)}
.exp-media .em-img{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;opacity:0;
transform:scale(1.04);transition:opacity .9s var(--ease),transform 6s linear;will-change:opacity}
.exp-media .em-img.on{opacity:1;transform:scale(1.1)}
.exp-media .cap{position:absolute;left:22px;bottom:20px;z-index:2;color:var(--paper);
font-size:.74rem;letter-spacing:.18em;text-transform:uppercase;font-weight:500;opacity:0;transition:opacity .5s var(--ease)}
.exp-media::after{content:"";position:absolute;inset:0;background:linear-gradient(180deg,transparent 55%,rgba(19,16,11,.6) 100%)}
.exp-steps{display:flex;flex-direction:column}
.estep{min-height:64vh;display:flex;flex-direction:column;justify-content:center;
border-top:1px solid var(--line);padding:30px 0;opacity:.32;transition:opacity .5s var(--ease)}
.estep:first-child{border-top:none}
.estep.active{opacity:1}
.estep .num{font-family:var(--serif);font-size:clamp(2.6rem,5vw,4.4rem);color:var(--accent);
line-height:1;font-weight:300}
.estep h3{font-size:clamp(1.5rem,2.6vw,2.3rem);margin:14px 0 12px}
.estep p{color:var(--ink-2);font-weight:300;max-width:38ch}
@media(max-width:860px){
.exp-grid{grid-template-columns:1fr}
.exp-media{position:relative;top:0;height:52vh;margin-bottom:30px}
.estep{min-height:auto;padding:34px 0;opacity:1}
}
/* ============================== STAY (split, clip-wipe) ============================== */
.stay{background:var(--paper);padding:clamp(90px,13vh,170px) 0}
.stay-grid{display:grid;grid-template-columns:1fr 1fr;gap:clamp(30px,5vw,72px);align-items:center}
.stay-media{position:relative;aspect-ratio:16/11;overflow:hidden;border-radius:2px;background:var(--ink)}
.stay-media img{width:100%;height:108%;object-fit:cover;will-change:transform}
.stay-copy h2{margin:18px 0 26px}
.stay-copy .lead{margin-bottom:26px}
.stay-copy .ledger{border-top:1px solid var(--line)}
.stay-copy .ledger div{display:flex;justify-content:space-between;gap:20px;padding:15px 0;
border-bottom:1px solid var(--line);font-size:.92rem}
.stay-copy .ledger span:first-child{color:var(--stone);letter-spacing:.04em}
.stay-copy .ledger span:last-child{font-weight:500}
@media(max-width:780px){.stay-grid{grid-template-columns:1fr}.stay-media{order:-1}}
/* ============================== DARK INTERLUDE ============================== */
.interlude{position:relative;min-height:100svh;display:flex;align-items:center;
background:var(--night);color:var(--paper);overflow:hidden}
.interlude .bg{position:absolute;inset:-8% 0;will-change:transform}
.interlude .bg img{width:100%;height:116%;object-fit:cover;opacity:.66}
.interlude::after{content:"";position:absolute;inset:0;background:radial-gradient(120% 90% at 50% 40%,transparent 30%,rgba(19,16,11,.86) 100%)}
.interlude .wrap{position:relative;z-index:2;text-align:center}
.interlude .eyebrow{margin-bottom:26px}
.interlude .big{font-family:var(--serif);font-weight:400;font-size:clamp(1.9rem,4.6vw,4rem);
line-height:1.18;max-width:18ch;margin-inline:auto}
.interlude .big em{font-style:italic;color:var(--accent-2)}
.interlude .fieldnote{margin-top:40px;font-size:.8rem;letter-spacing:.18em;text-transform:uppercase;color:var(--stone-d)}
/* ============================== NUMBERS ============================== */
.numbers{position:relative;padding:clamp(100px,15vh,200px) 0;overflow:hidden;background:var(--ink);color:var(--paper)}
.numbers .bg{position:absolute;inset:-12% 0;will-change:transform}
.numbers .bg img{width:100%;height:124%;object-fit:cover;opacity:.28}
.numbers::after{content:"";position:absolute;inset:0;background:rgba(19,16,11,.62)}
.numbers .wrap{position:relative;z-index:2}
.numbers .head{display:flex;justify-content:space-between;align-items:flex-end;gap:30px;flex-wrap:wrap;
margin-bottom:clamp(50px,8vh,100px)}
.numbers .head h2{max-width:14ch}
.nledger{display:grid;grid-template-columns:repeat(4,1fr);gap:1px;background:var(--line-d);border:1px solid var(--line-d)}
.nstat{background:var(--ink);padding:38px 30px;display:flex;flex-direction:column;gap:14px}
.nstat .v{font-family:var(--serif);font-weight:400;font-size:clamp(3rem,6vw,5.6rem);line-height:.9;color:var(--paper)}
.nstat.lead-stat .v{color:var(--accent-2)}
.nstat .k{font-size:.86rem;color:var(--stone-d);font-weight:300;letter-spacing:.02em}
@media(max-width:860px){.nledger{grid-template-columns:repeat(2,1fr)}}
/* ============================== QUOTE BAND ============================== */
.quote{background:var(--accent);color:#fff;padding:clamp(90px,16vh,200px) 0;position:relative;overflow:hidden}
.quote .wrap{position:relative;z-index:2;max-width:980px}
.quote q{font-family:var(--serif);font-weight:400;font-size:clamp(1.8rem,4.4vw,3.6rem);line-height:1.18;
letter-spacing:-.01em;display:block;quotes:none}
.quote q::before{content:"\201C";font-family:var(--serif);position:absolute;top:-.2em;left:-.04em;
font-size:clamp(6rem,16vw,16rem);opacity:.22;line-height:1;z-index:-1}
.quote .who{margin-top:38px;font-size:.86rem;letter-spacing:.16em;text-transform:uppercase;font-weight:500;opacity:.9}
/* ============================== MARQUEE ============================== */
.marquee{background:var(--paper);padding:clamp(50px,8vh,90px) 0;overflow:hidden;border-top:1px solid var(--line);border-bottom:1px solid var(--line)}
.mrow{display:flex;white-space:nowrap;width:max-content;will-change:transform}
.mrow + .mrow{margin-top:16px}
.mrow span{font-family:var(--serif);font-size:clamp(1.6rem,3.4vw,2.8rem);font-weight:500;
padding:0 26px;color:var(--ink);display:inline-flex;align-items:center;gap:26px;letter-spacing:-.01em}
.mrow span::after{content:"\2022";color:var(--accent);font-size:.5em}
.mrow.dim span{color:transparent;-webkit-text-stroke:1px var(--line)}
/* ============================== FINAL CTA ============================== */
.final{position:relative;min-height:100svh;display:flex;align-items:center;
background:var(--ink);color:var(--paper);overflow:hidden;padding: clamp(80px, 12vh, 150px) 0;}
.final .bg{position:absolute;inset:-8% 0;will-change:transform}
.final .bg img{width:100%;height:116%;object-fit:cover;opacity:.35}
.final::after{content:"";position:absolute;inset:0;
background:linear-gradient(180deg,rgba(19,16,11,.7),rgba(19,16,11,.4) 45%,rgba(19,16,11,.92))}
.final .wrap{position:relative;z-index:2;width:100%; display: grid; grid-template-columns: 1fr 1fr; gap: clamp(30px,5vw,80px); align-items: center;}
.final .eyebrow{margin-bottom:26px}
.final h2{font-size:clamp(2.5rem,6vw,5.5rem);max-width:14ch; line-height: 1.05}
.final .lead{color:rgba(243,236,224,.84);margin:28px 0 44px}
@media(max-width:991px){
.final .wrap { grid-template-columns: 1fr; }
}
/* ============================== FOOTER ============================== */
footer.foot{background:var(--night);color:var(--paper);padding:clamp(70px,10vh,120px) 0 50px}
.foot-top{display:grid;grid-template-columns:2fr 1fr 1fr 1fr;gap:40px;
padding-bottom:60px;border-bottom:1px solid var(--line-d)}
.foot .brand{font-size:1.8rem;display:block;margin-bottom:16px}
.foot-top p{color:var(--stone-d);font-weight:300;max-width:34ch;font-size:.95rem}
.foot-col h4{font-family:var(--sans);font-size:.72rem;letter-spacing:.2em;text-transform:uppercase;
color:var(--stone-d);font-weight:600;margin-bottom:18px}
.foot-col a{display:block;padding:7px 0;font-size:.95rem;opacity:.85;transition:.3s}
.foot-col a:hover{opacity:1;color:var(--accent-2);transform:translateX(4px)}
.foot-bottom{display:flex;justify-content:space-between;gap:20px;flex-wrap:wrap;padding-top:30px;
font-size:.8rem;color:var(--stone-d)}
@media(max-width:760px){.foot-top{grid-template-columns:1fr 1fr}}
/* ============================== REVEAL DEFAULTS ============================== */
.reveal{opacity:0;transform:translateY(28px)}
/* line-mask wrappers: pad the bottom so glyph descenders + italics are NOT clipped by overflow:hidden */
.line-wrap{overflow:hidden;padding-bottom:.2em;margin-bottom:-.2em}
.ln{display:block;padding-bottom:.02em}
/* reduced motion: show everything, kill transforms */
@media(prefers-reduced-motion:reduce){
.reveal{opacity:1!important;transform:none!important}
.hero-media,.exp-media img,.jcard .frame img,.stay-media img,.interlude .bg,.numbers .bg,.final .bg{transform:none!important}
.scrollcue .ln::after,.cue{animation:none}
.veil{display:none}
}
#stepIndicators::-webkit-scrollbar { display: none; }
#stepIndicators { -ms-overflow-style: none; scrollbar-width: none; }
</style>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
</head>
<body>
<script>window.__MIMG={"aerial":"https://hoirqrkdgbmvpwutwuwj.supabase.co/storage/v1/object/public/assets/assets/cbc45d24-68dd-4afc-a185-a9cd27ebd80e_original.jpg","coast":"https://hoirqrkdgbmvpwutwuwj.supabase.co/storage/v1/object/public/assets/assets/fd52c5b2-98d6-4b50-ae83-410751803891_original.jpg","dunes":"https://hoirqrkdgbmvpwutwuwj.supabase.co/storage/v1/object/public/assets/assets/182bf631-7989-42d6-af11-db0c28c5e78b_original.jpg","hero":"https://hoirqrkdgbmvpwutwuwj.supabase.co/storage/v1/object/public/assets/assets/e43ce459-2d34-4c70-9cbf-28bee8ce4136_original.jpg","night":"https://hoirqrkdgbmvpwutwuwj.supabase.co/storage/v1/object/public/assets/assets/eedbc5aa-da5b-4a56-a93d-7f1293f986e4_original.jpg","peaks":"https://hoirqrkdgbmvpwutwuwj.supabase.co/storage/v1/object/public/assets/assets/5cd81936-fb20-478f-a409-86725064eaea_original.jpg","stay":"https://hoirqrkdgbmvpwutwuwj.supabase.co/storage/v1/object/public/assets/assets/ffcda4c1-50d3-4145-a7fb-97b2489884ab_original.jpg","traveler":"https://hoirqrkdgbmvpwutwuwj.supabase.co/storage/v1/object/public/assets/assets/7061e592-83e9-4e96-9da7-73d8df82b88d_original.jpg"};
document.addEventListener('DOMContentLoaded',function(){var M=window.__MIMG;document.querySelectorAll('img[data-mimg]').forEach(function(i){var u=M[i.getAttribute('data-mimg')];if(u)i.src=u;});});</script>

<div class="progress" id="progress"></div>
<div class="cursor" id="cursor"><span class="label">Khám phá</span></div>

<div class="rail" id="rail" aria-hidden="true">
  <span class="rcap" id="railCap">Khởi hành</span>
  <span class="rtrack"><span class="rdot" id="railDot"></span></span>
  <span class="rlabel">V-SPORT</span>
</div>

<div class="veil" id="veil">
  <div class="vmark"><span>V-SPORT</span></div>
  <div class="vbar"><i id="vbar"></i></div>
</div>

<header class="nav" id="nav">
  <a href="${pageContext.request.contextPath}/" class="brand">V-SPORT<span>.</span></a>
  <nav class="nav-links">
    <a href="#journeys" data-cursor="Xem tính năng">Tính năng</a>
    <a href="#experience" data-cursor="Xem quy trình">Quy trình</a>
    <a href="#stay" data-cursor="Xem giải pháp">Giải pháp</a>
    <a href="#begin" class="nav-cta" data-cursor="Đăng ký đối tác">Đăng ký ngay</a>
  </nav>
</header>

<main id="smooth">

  <!-- HERO -->
  <section class="hero" id="hero" data-geo="Khởi hành|dark">
    <div class="hero-media" data-speed="0.82"><img src="${pageContext.request.contextPath}/assets/images/owner/owner-hero-vsport.webp" alt="V-SPORT Sports Management Platform"></div>
    <div class="hero-inner">
      <div class="hero-content-wrap">
        <p class="eyebrow">V-SPORT · GIẢI PHÁP VẬN HÀNH THỂ THAO</p>
        <h1>
          <span class="line-wrap"><span class="ln">Nâng tầm vận hành</span></span>
          <span class="line-wrap"><span class="ln thin">cơ sở thể thao của bạn.</span></span>
        </h1>
        <div class="hero-sub">
          <p class="lead reveal">Quản lý lịch sân, nhân sự, thanh toán và doanh thu trên một nền tảng duy nhất — giúp cơ sở vận hành chính xác và phát triển bền vững.</p>
          <div class="cta-split reveal">
            <a href="#begin" class="pill magnetic" data-cursor="Đăng ký cơ sở">Đăng ký cơ sở miễn phí</a>
            <a href="#journeys" class="disc magnetic" aria-label="Khám phá giải pháp" data-cursor="Khám phá">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M5 12h14M13 6l6 6-6 6"></path></svg>
            </a>
          </div>
        </div>
        <div class="hero-benefits reveal" style="margin-top: 40px; display: flex; gap: 24px; flex-wrap: wrap;">
           <div style="display:flex; align-items:center; gap: 8px; font-size: 0.95rem; color: rgba(243,236,224,.85)"><span class="material-symbols-outlined text-[#C9612F]" style="font-size: 20px;">event_available</span> Quản lý lịch sân tập trung</div>
           <div style="display:flex; align-items:center; gap: 8px; font-size: 0.95rem; color: rgba(243,236,224,.85)"><span class="material-symbols-outlined text-[#C9612F]" style="font-size: 20px;">monitoring</span> Theo dõi doanh thu theo thời gian thực</div>
           <div style="display:flex; align-items:center; gap: 8px; font-size: 0.95rem; color: rgba(243,236,224,.85)"><span class="material-symbols-outlined text-[#C9612F]" style="font-size: 20px;">groups</span> Vận hành nhân sự và dịch vụ hiệu quả</div>
        </div>
      </div>
    </div>
    <div class="scrollcue"><span>Cuộn</span><span class="ln"></span></div>
  </section>

  <!-- MANIFESTO -->
  <section class="manifesto" id="about" data-geo="Ý tưởng|light">
    <div class="ghost" data-speed="1.15">v-sport</div>
    <div class="wrap">
      <p class="eyebrow muted reveal">/ Ý tưởng</p>
      <h2 class="statement" style="margin-top:26px">Chúng tôi không chỉ bán phần mềm. Chúng tôi xây dựng sự <em>kết nối</em> giữa bạn và khách hàng.</h2>
      <div class="body">
        <p class="reveal">V-Sport được thiết kế để giải phóng thời gian vận hành của chủ sân. Mọi tính năng từ đặt sân, báo cáo doanh thu đến chăm sóc khách hàng đều tự động hóa hoàn toàn.</p>
        <p class="reveal">Giúp bạn quản lý dễ dàng mọi cơ sở thể thao chỉ trên một ứng dụng duy nhất, hoạt động 24/7 mượt mà trên nền tảng đám mây.</p>
      </div>
    </div>
  </section>

  <!-- JOURNEYS (horizontal pinned) -->
  <section class="journeys" id="journeys" data-geo="Tính năng|dark">
    <div class="jpin">
      <div class="jtrack" id="jtrack">
        <div class="jpanel jintro">
          <p class="eyebrow">/ Tính năng cốt lõi</p>
          <h2>Ba giải pháp<br>vận hành vượt trội.</h2>
          <p class="lead">Hệ thống tích hợp mọi công cụ cần thiết để tối ưu doanh thu và quản lý sân chơi hiệu quả. Cuộn hoặc kéo chuột để khám phá.</p>
        </div>

        <article class="jcard">
          <div class="frame"><img data-mimg="peaks" alt="Đặt lịch thông minh"></div>
          <span class="idx">01 / 03</span>
          <div class="meta">
            <p class="coord">Nhanh chóng · Tiện lợi</p>
            <h3>Đặt lịch thông minh</h3>
            <p class="note">Giao diện đặt lịch trực quan, tránh trùng lịch trong 3 giây.</p>
          </div>
        </article>

        <article class="jcard">
          <div class="frame"><img data-mimg="dunes" alt="Quản lý Hội viên"></div>
          <span class="idx">02 / 03</span>
          <div class="meta">
            <p class="coord">Tự động · Chuyên nghiệp</p>
            <h3>Quản lý Hội viên</h3>
            <p class="note">Theo dõi gói tập, điểm danh tự động thông qua mã QR Code.</p>
          </div>
        </article>

        <article class="jcard">
          <div class="frame"><img data-mimg="coast" alt="Báo cáo Doanh thu"></div>
          <span class="idx">03 / 03</span>
          <div class="meta">
            <p class="coord">Trực quan · Chính xác</p>
            <h3>Báo cáo Doanh thu</h3>
            <p class="note">Báo cáo thời gian thực, minh bạch biểu đồ doanh thu chi tiết.</p>
          </div>
        </article>

        <div class="jpanel joutro">
          <p class="eyebrow">/ Sẵn sàng đồng hành</p>
          <h2>Bắt đầu số hóa<br>ngay hôm nay?</h2>
          <a href="#begin" class="pill magnetic" data-cursor="Đăng ký đối tác">Trở thành đối tác
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M5 12h14M13 6l6 6-6 6"></path></svg>
          </a>
        </div>
      </div>
      <div class="jhint"><span>Kéo để xem tiếp</span><span class="bar"><i id="jbar"></i></span></div>
    </div>
  </section>

  <!-- EXPERIENCE (sticky scrollytelling) -->
  <section class="exp" id="experience" data-geo="Quy trình|light">
    <div class="wrap">
      <div class="head">
        <p class="eyebrow muted reveal">/ Quy trình</p>
        <h2 class="h2 reveal">Bốn bước đơn giản.<br>Hệ thống sẵn sàng vận hành.</h2>
      </div>
      <div class="exp-grid">
        <div class="exp-media" id="expMedia">
          <img class="em-img on" data-mimg="hero" alt="Đăng ký thông tin">
          <img class="em-img" data-mimg="coast" alt="Xác thực Email">
          <img class="em-img" data-mimg="stay" alt="Cấu hình sân">
          <img class="em-img" data-mimg="traveler" alt="Vận hành hệ thống">
          <span class="cap" id="expCap">01 — Đăng ký thông tin</span>
        </div>
        <div class="exp-steps">
          <div class="estep" data-cap="01 — Đăng ký thông tin"><div class="num">01</div><h3>Đăng ký thông tin</h3><p>Điền thông tin cơ bản về cơ sở của bạn chỉ trong 1 phút để khởi tạo tài khoản quản lý.</p></div>
          <div class="estep" data-cap="02 — Xác thực Email"><div class="num">02</div><h3>Xác thực Email</h3><p>Nhập mã bảo mật OTP gửi trực tiếp tới email của bạn để xác minh chủ quyền.</p></div>
          <div class="estep" data-cap="03 — Cấu hình sân"><div class="num">03</div><h3>Cấu hình sân</h3><p>Khai báo thông tin các môn thể thao, số lượng sân hiện tại và cấu hình khung giờ mở cửa hoạt động.</p></div>
          <div class="estep" data-cap="04 — Vận hành hệ thống"><div class="num">04</div><h3>Vận hành hệ thống</h3><p>Sân của bạn lập tức hiển thị trên hệ sinh thái V-Sport để đón nhận những lịch đặt sân đầu tiên.</p></div>
        </div>
      </div>
    </div>
  </section>

  <!-- STAY -->
  <section class="stay" id="stay" data-geo="Giải pháp|light">
    <div class="wrap">
      <div class="stay-grid">
        <div class="stay-media"><img data-mimg="stay" alt="Warm minimalist lodge interior at dusk"></div>
        <div class="stay-copy">
            <p class="eyebrow muted reveal">/ Giải pháp quản lý</p>
            <h2 class="h2 reveal">Giải phóng thời gian<br>Tối ưu doanh thu cơ sở.</h2>
            <p class="lead reveal">Không còn những cuốn sổ tay ghi chép hay file Excel phức tạp dễ sai sót. V-Sport mang lại giao diện tinh tế, dễ dàng làm quen trong vài phút và bảo mật dữ liệu chuẩn quốc tế.</p>
            <div class="ledger reveal">
              <div><span>Thời gian thiết lập</span><span>Dưới 5 phút</span></div>
              <div><span>Nền tảng vận hành</span><span>Cloud &amp; Mobile</span></div>
              <div><span>Hỗ trợ kỹ thuật</span><span>24/7 Miễn phí</span></div>
            </div>
        </div>
      </div>
    </div>
  </section>

  <!-- DARK INTERLUDE -->
  <section class="interlude" id="interlude" data-geo="Trải nghiệm|dark">
    <div class="bg" data-speed="0.8"><img data-mimg="night" alt="The Milky Way over a lit tent on a high plateau"></div>
    <div class="wrap">
      <p class="eyebrow reveal">/ Trải nghiệm khách hàng</p>
      <p class="big reveal">Sự hài lòng của khách hàng và sự <em>an tâm</em> của bạn là thành công lớn nhất của chúng tôi.</p>
      <p class="fieldnote reveal">— Đồng hành cùng hàng trăm cơ sở thể thao trên cả nước</p>
    </div>
  </section>

  <!-- NUMBERS -->
  <section class="numbers" id="numbers" data-geo="Thống kê|dark">
    <div class="bg" data-speed="0.78"><img data-mimg="aerial" alt="Aerial view of a river winding through autumn wilderness"></div>
    <div class="wrap">
      <div class="head">
        <p class="eyebrow reveal">/ Những con số ấn tượng</p>
        <h2 class="h2 reveal">Kiến tạo giá trị thực.</h2>
      </div>
      <div class="nledger">
        <div class="nstat lead-stat"><div class="v" data-count="500" data-suffix="+">500+</div><div class="k">sân vận động &amp; cơ sở thể thao tin dùng</div></div>
        <div class="nstat"><div class="v" data-count="99" data-suffix="%">99%</div><div class="k">chủ sân hài lòng với hệ thống</div></div>
        <div class="nstat"><div class="v" data-count="24" data-suffix="/7">24/7</div><div class="k">hỗ trợ kỹ thuật và vận hành liên tục</div></div>
        <div class="nstat"><div class="v" data-count="1" data-suffix="M+">1M+</div><div class="k">giao dịch đặt sân thành công</div></div>
      </div>
    </div>
  </section>

  <!-- QUOTE -->
  <section class="quote">
    <div class="wrap">
      <q>Từ khi dùng V-Sport, tôi không còn bị đau đầu vì trùng lịch đặt sân của khách nữa. Doanh thu tăng hơn 25% nhờ tối ưu các khung giờ trống.</q>
      <p class="who">— Anh Minh Tuấn · Chủ sân bóng Tân Bình</p>
    </div>
  </section>

  <!-- MARQUEE -->
  <section class="marquee" aria-hidden="true">
    <div class="mrow" id="mrow1">
      <span>Bóng đá</span><span>Bóng rổ</span><span>Cầu lông</span><span>Tennis</span><span>Bóng chuyền</span><span>Billiards</span><span>Pickleball</span>
      <span>Bóng đá</span><span>Bóng rổ</span><span>Cầu lông</span><span>Tennis</span><span>Bóng chuyền</span><span>Billiards</span><span>Pickleball</span>
    </div>
    <div class="mrow dim" id="mrow2">
      <span>V-SPORT</span><span>QUẢN LÝ THÔNG MINH</span><span>TỐI ƯU DOANH THU</span><span>V-SPORT</span><span>QUẢN LÝ THÔNG MINH</span><span>TỐI ƯU DOANH THU</span>
      <span>V-SPORT</span><span>QUẢN LÝ THÔNG MINH</span><span>TỐI ƯU DOANH THU</span><span>V-SPORT</span><span>QUẢN LÝ THÔNG MINH</span><span>TỐI ƯU DOANH THU</span>
    </div>
  </section>

  <!-- FINAL CTA -->
  <section class="final" id="begin" data-geo="Đăng ký|dark">
    <div class="bg" data-speed="0.85"><img data-mimg="traveler" alt="A lone traveller at a clifftop viewpoint at sunrise"></div>
    <div class="wrap">
      <div>
        <p class="eyebrow">/ Đăng ký đối tác</p>
        <h2>
          <span class="line-wrap"><span class="ln">Bắt đầu cùng</span></span>
          <span class="line-wrap"><span class="ln thin">V-Sport.</span></span>
        </h2>
        <p class="lead">Điền thông tin bên dưới để bắt đầu số hóa quy trình vận hành và tối ưu doanh thu ngay hôm nay. Đội ngũ chúng tôi sẽ liên hệ trong vòng 24 giờ để hỗ trợ bạn cấu hình hệ thống.</p>
        <div style="margin-top:20px; display: flex; flex-direction:column; gap:12px;">
          <div style="display:flex; align-items:center; gap:8px; font-size: 0.95rem; color: rgba(243,236,224,.8)">
            <span class="material-symbols-outlined text-[#C9612F]" style="font-size:20px">check_circle</span> Miễn phí dùng thử 30 ngày đầy đủ tính năng
          </div>
          <div style="display:flex; align-items:center; gap:8px; font-size: 0.95rem; color: rgba(243,236,224,.8)">
            <span class="material-symbols-outlined text-[#C9612F]" style="font-size:20px">check_circle</span> Hỗ trợ cài đặt và đào tạo trực tiếp miễn phí
          </div>
          <div style="display:flex; align-items:center; gap:8px; font-size: 0.95rem; color: rgba(243,236,224,.8)">
            <span class="material-symbols-outlined text-[#C9612F]" style="font-size:20px">check_circle</span> Không cam kết ràng buộc hợp đồng dài hạn
          </div>
        </div>
      </div>

      <!-- ====== REGISTRATION FORM ====== -->
      <div class="bg-white/10 backdrop-blur-md rounded-3xl p-6 md:p-10 border border-white/20 text-white relative z-10 w-full max-w-xl justify-self-center lg:justify-self-end">
        <!-- Success Alert -->
        <div id="successAlert" class="hidden mb-6 p-4 bg-green-900/40 border border-green-500/50 text-green-200 rounded-2xl flex items-center gap-3">
          <span class="material-symbols-outlined">check_circle</span>
          <span>Đăng ký thành công! Chúng tôi sẽ sớm liên hệ với bạn.</span>
        </div>
        <!-- Error Alert -->
        <div id="errorAlert" class="hidden mb-6 p-4 bg-red-900/40 border border-red-500/50 text-red-200 rounded-2xl flex items-center gap-3">
          <span class="material-symbols-outlined">error</span>
          <span id="errorMessage"></span>
        </div>

        <!-- Step Indicators -->
        <div class="flex items-center justify-between gap-2 md:gap-3 mb-8 overflow-x-auto pb-2 scrollbar-none" id="stepIndicators">
          <div class="step-dot active flex items-center gap-2 px-4 py-2.5 rounded-2xl bg-[#C9612F] text-white text-sm font-semibold transition-all shrink-0 whitespace-nowrap" data-step="1">
            <span class="flex items-center justify-center w-5 h-5 rounded-lg bg-white/20 text-xs">1</span> <span class="hidden sm:inline">Thông tin</span>
          </div>
          <div class="flex-grow h-px bg-white/20 min-w-[8px] max-w-[32px]"></div>
          <div class="step-dot flex items-center gap-2 px-4 py-2.5 rounded-2xl bg-white/10 text-white/60 text-sm font-semibold transition-all shrink-0 whitespace-nowrap" data-step="2">
            <span class="flex items-center justify-center w-5 h-5 rounded-lg bg-white/10 text-xs">2</span> <span class="hidden sm:inline">Xác thực OTP</span>
          </div>
          <div class="flex-grow h-px bg-white/20 min-w-[8px] max-w-[32px]"></div>
          <div class="step-dot flex items-center gap-2 px-4 py-2.5 rounded-2xl bg-white/10 text-white/60 text-sm font-semibold transition-all shrink-0 whitespace-nowrap" data-step="3">
            <span class="flex items-center justify-center w-5 h-5 rounded-lg bg-white/10 text-xs">3</span> <span class="hidden sm:inline">Cơ sở & Sân</span>
          </div>
        </div>

        <!-- Xóa bản nháp / Bắt đầu lại -->
        <div class="flex justify-end -mt-4 mb-4">
          <button type="button" onclick="confirmResetOwnerDraft()" class="text-white/35 hover:text-white/70 text-xs underline underline-offset-2 bg-transparent border-none cursor-pointer transition-colors">Xóa bản nháp / Bắt đầu lại</button>
        </div>

        <!-- ====== STEP 1: Basic Info ====== -->
        <div id="formStep1" class="form-step">
          <h3 class="font-serif text-xl mb-6 font-medium">Thông tin cơ bản</h3>
          <div class="space-y-5">
            <div>
              <label class="block text-xs font-semibold tracking-wider uppercase text-white/70 mb-2" for="ownerName">Tên cơ sở <span class="text-[#C9612F]">*</span></label>
              <input type="text" id="ownerName" name="ownerName" required placeholder="VD: Sân bóng Tân Bình" class="w-full px-5 py-3.5 border border-white/20 rounded-xl bg-black/20 text-white focus:outline-none focus:ring-2 focus:ring-[#C9612F]/40 focus:border-[#C9612F] transition-all placeholder:text-white/30" />
            </div>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
              <div>
                <label class="block text-xs font-semibold tracking-wider uppercase text-white/70 mb-2" for="regEmail">Email liên hệ <span class="text-[#C9612F]">*</span></label>
                <input type="email" id="regEmail" required placeholder="email@example.com" class="w-full px-5 py-3.5 border border-white/20 rounded-xl bg-black/20 text-white focus:outline-none focus:ring-2 focus:ring-[#C9612F]/40 focus:border-[#C9612F] transition-all placeholder:text-white/30" />
              </div>
              <div>
                <label class="block text-xs font-semibold tracking-wider uppercase text-white/70 mb-2" for="regPhone">Số điện thoại <span class="text-[#C9612F]">*</span></label>
                <input type="tel" id="regPhone" required placeholder="0912 345 678" class="w-full px-5 py-3.5 border border-white/20 rounded-xl bg-black/20 text-white focus:outline-none focus:ring-2 focus:ring-[#C9612F]/40 focus:border-[#C9612F] transition-all placeholder:text-white/30" />
              </div>
            </div>
            <div>
              <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-1.5 sm:gap-4 mb-2">
                <label class="block text-xs font-semibold tracking-wider uppercase text-white/70" for="regAddress" style="font-family: var(--sans);">Địa chỉ cơ sở</label>
                <button type="button" onclick="autoFillAddress()" class="text-xs text-[#E08A4F] hover:underline flex items-center gap-1 bg-transparent border-none cursor-pointer focus:outline-none" style="font-family: var(--sans);">
                  <span class="material-symbols-outlined text-[14px]">my_location</span> Lấy vị trí / Tọa độ GG Map
                </button>
              </div>
              <input type="text" id="regAddress" placeholder="Số nhà, đường, phường/xã, quận/huyện, tỉnh/thành" class="w-full px-5 py-3.5 border border-white/20 rounded-xl bg-black/20 text-white focus:outline-none focus:ring-2 focus:ring-[#C9612F]/40 focus:border-[#C9612F] transition-all placeholder:text-white/30" style="font-family: var(--sans);" />
              <div id="coordPreview" class="hidden mt-1.5 flex flex-col gap-0.5">
                <div class="flex items-start gap-1.5">
                  <span class="material-symbols-outlined mt-px" style="font-size:14px;color:#E08A4F">location_on</span>
                  <span id="coordPreviewText" class="text-xs leading-snug" style="color:#E08A4F;font-family:var(--sans)"></span>
                </div>
                <a id="coordMapsLink" href="#" target="_blank" rel="noopener noreferrer" class="hidden text-xs underline pl-5" style="color:#E08A4F;font-family:var(--sans);">Mở Google Maps để kiểm tra vị trí</a>
              </div>
            </div>
            <button type="button" onclick="goToStep2()" class="pill w-full py-4 text-base mt-2 flex justify-center items-center gap-2 text-white bg-[#C9612F] hover:bg-[#E08A4F] transition-all rounded-full font-semibold border-none cursor-pointer">
              Tiếp tục — Xác thực Email <span class="material-symbols-outlined align-middle text-lg">arrow_forward</span>
            </button>
          </div>
        </div>

        <!-- ====== STEP 2: OTP Verification ====== -->
        <div id="formStep2" class="form-step hidden">
          <h3 class="font-serif text-xl mb-2 font-medium">Xác thực Email</h3>
          <p class="text-white/80 text-sm mb-6">Chúng tôi đã gửi mã OTP đến <strong id="otpEmailDisplay" class="text-[#E08A4F]"></strong>. Vui lòng nhập mã bên dưới.</p>
          <p id="otpValidityHint" class="hidden text-white/50 text-xs -mt-4 mb-4"></p>
          <div class="flex justify-center gap-2 mb-6" id="otpInputs">
            <input type="text" maxlength="1" class="otp-box w-12 h-12 text-center text-xl font-bold border-2 border-white/20 rounded-xl bg-black/25 text-white focus:outline-none focus:ring-2 focus:ring-[#C9612F]/40 focus:border-[#C9612F] transition-all" data-index="0" />
            <input type="text" maxlength="1" class="otp-box w-12 h-12 text-center text-xl font-bold border-2 border-white/20 rounded-xl bg-black/25 text-white focus:outline-none focus:ring-2 focus:ring-[#C9612F]/40 focus:border-[#C9612F] transition-all" data-index="1" />
            <input type="text" maxlength="1" class="otp-box w-12 h-12 text-center text-xl font-bold border-2 border-white/20 rounded-xl bg-black/25 text-white focus:outline-none focus:ring-2 focus:ring-[#C9612F]/40 focus:border-[#C9612F] transition-all" data-index="2" />
            <input type="text" maxlength="1" class="otp-box w-12 h-12 text-center text-xl font-bold border-2 border-white/20 rounded-xl bg-black/25 text-white focus:outline-none focus:ring-2 focus:ring-[#C9612F]/40 focus:border-[#C9612F] transition-all" data-index="3" />
            <input type="text" maxlength="1" class="otp-box w-12 h-12 text-center text-xl font-bold border-2 border-white/20 rounded-xl bg-black/25 text-white focus:outline-none focus:ring-2 focus:ring-[#C9612F]/40 focus:border-[#C9612F] transition-all" data-index="4" />
            <input type="text" maxlength="1" class="otp-box w-12 h-12 text-center text-xl font-bold border-2 border-white/20 rounded-xl bg-black/25 text-white focus:outline-none focus:ring-2 focus:ring-[#C9612F]/40 focus:border-[#C9612F] transition-all" data-index="5" />
          </div>
          <div id="otpError" class="hidden text-center text-red-400 text-sm mb-4"></div>
          <div class="flex flex-col gap-3">
            <button type="button" onclick="verifyOtp()" id="btnVerifyOtp" class="pill w-full py-4 text-base flex justify-center items-center text-white bg-[#C9612F] hover:bg-[#E08A4F] transition-all rounded-full font-semibold border-none cursor-pointer">
              Xác thực OTP
            </button>
            <div class="flex items-center justify-between mt-2">
              <button type="button" onclick="goToStep1()" class="text-white/60 hover:text-white transition-colors text-sm flex items-center gap-1 bg-transparent border-none cursor-pointer">
                <span class="material-symbols-outlined text-sm">arrow_back</span> Quay lại
              </button>
              <button type="button" onclick="resendOtp()" id="btnResendOtp" class="text-[#E08A4F] hover:text-[#E08A4F]/80 text-sm transition-colors disabled:opacity-40 bg-transparent border-none cursor-pointer" disabled>
                Gửi lại mã<span id="resendCountdownWrap"> (<span id="resendCountdown">60</span>s)</span>
              </button>
            </div>
          </div>
          <p class="text-center text-white/50 text-xs mt-4">Số lần nhập sai: <span id="otpAttemptCount" class="font-bold text-red-400">0</span>/5</p>
        </div>

        <!-- ====== STEP 3: Sports, Courts, Operating Hours ====== -->
        <div id="formStep3" class="form-step hidden">
          <h3 class="font-serif text-xl mb-6 font-medium">Cấu hình cơ sở</h3>

          <!-- Sports selector -->
          <div class="mb-6">
            <label class="block text-xs font-semibold tracking-wider uppercase text-white/70 mb-2">Môn thể thao / Dịch vụ <span class="text-[#C9612F]">*</span></label>
            <button type="button" onclick="openSportsPopup()" class="w-full px-5 py-3.5 border border-white/20 rounded-xl bg-black/20 text-left flex items-center justify-between hover:border-[#C9612F]/50 transition-all text-white/80 cursor-pointer">
              <span id="sportsPreviewText" class="text-white/40">Chọn các môn thể thao...</span>
              <span class="material-symbols-outlined text-[#C9612F]">add_circle</span>
            </button>
          </div>

          <!-- Selected sports tags + court quantities -->
          <div id="courtQuantitySection" class="hidden mb-6">
            <label class="block text-xs font-semibold tracking-wider uppercase text-white/70 mb-3">Số lượng sân từng môn</label>
            <div id="courtQuantityList" class="space-y-3"></div>
          </div>

          <!-- Operating hours -->
          <input type="hidden" id="openTime"  value="06:00">
          <input type="hidden" id="closeTime" value="22:00">
          <!-- Coordinates (set by geo modal) -->
          <input type="hidden" id="viDo"   name="viDo">
          <input type="hidden" id="kinhDo" name="kinhDo">
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-5 mb-6">
            <div>
              <label class="block text-xs font-semibold tracking-wider uppercase text-white/70 mb-2">Giờ mở cửa <span class="text-[#C9612F]">*</span></label>
              <div class="flex gap-2">
                <select id="openTimeH" onchange="syncOwnerTime('open')" class="flex-1 px-3 py-3.5 border border-white/20 rounded-xl bg-black/20 text-white focus:outline-none focus:ring-2 focus:ring-[#C9612F]/40 focus:border-[#C9612F] transition-all cursor-pointer"></select>
                <select id="openTimeM" onchange="syncOwnerTime('open')" class="w-[80px] px-3 py-3.5 border border-white/20 rounded-xl bg-black/20 text-white focus:outline-none focus:ring-2 focus:ring-[#C9612F]/40 focus:border-[#C9612F] transition-all cursor-pointer"></select>
              </div>
            </div>
            <div>
              <label class="block text-xs font-semibold tracking-wider uppercase text-white/70 mb-2">Giờ đóng cửa <span class="text-[#C9612F]">*</span></label>
              <div class="flex gap-2">
                <select id="closeTimeH" onchange="syncOwnerTime('close')" class="flex-1 px-3 py-3.5 border border-white/20 rounded-xl bg-black/20 text-white focus:outline-none focus:ring-2 focus:ring-[#C9612F]/40 focus:border-[#C9612F] transition-all cursor-pointer"></select>
                <select id="closeTimeM" onchange="syncOwnerTime('close')" class="w-[80px] px-3 py-3.5 border border-white/20 rounded-xl bg-black/20 text-white focus:outline-none focus:ring-2 focus:ring-[#C9612F]/40 focus:border-[#C9612F] transition-all cursor-pointer"></select>
              </div>
            </div>
          </div>

          <!-- Operating days -->
          <div class="mb-6">
            <label class="block text-xs font-semibold tracking-wider uppercase text-white/70 mb-3">Ngày hoạt động <span class="text-[#C9612F]">*</span></label>
            <div class="flex flex-wrap gap-2" id="operatingDays">
              <label class="day-chip cursor-pointer">
                <input type="checkbox" value="T2" checked class="hidden peer"/>
                <span class="inline-block px-4 py-2 rounded-full border border-white/20 text-sm font-semibold text-white/70 peer-checked:bg-[#C9612F] peer-checked:text-white peer-checked:border-[#C9612F] transition-all">Thứ 2</span>
              </label>
              <label class="day-chip cursor-pointer">
                <input type="checkbox" value="T3" checked class="hidden peer"/>
                <span class="inline-block px-4 py-2 rounded-full border border-white/20 text-sm font-semibold text-white/70 peer-checked:bg-[#C9612F] peer-checked:text-white peer-checked:border-[#C9612F] transition-all">Thứ 3</span>
              </label>
              <label class="day-chip cursor-pointer">
                <input type="checkbox" value="T4" checked class="hidden peer"/>
                <span class="inline-block px-4 py-2 rounded-full border border-white/20 text-sm font-semibold text-white/70 peer-checked:bg-[#C9612F] peer-checked:text-white peer-checked:border-[#C9612F] transition-all">Thứ 4</span>
              </label>
              <label class="day-chip cursor-pointer">
                <input type="checkbox" value="T5" checked class="hidden peer"/>
                <span class="inline-block px-4 py-2 rounded-full border border-white/20 text-sm font-semibold text-white/70 peer-checked:bg-[#C9612F] peer-checked:text-white peer-checked:border-[#C9612F] transition-all">Thứ 5</span>
              </label>
              <label class="day-chip cursor-pointer">
                <input type="checkbox" value="T6" checked class="hidden peer"/>
                <span class="inline-block px-4 py-2 rounded-full border border-white/20 text-sm font-semibold text-white/70 peer-checked:bg-[#C9612F] peer-checked:text-white peer-checked:border-[#C9612F] transition-all">Thứ 6</span>
              </label>
              <label class="day-chip cursor-pointer">
                <input type="checkbox" value="T7" checked class="hidden peer"/>
                <span class="inline-block px-4 py-2 rounded-full border border-white/20 text-sm font-semibold text-white/70 peer-checked:bg-[#C9612F] peer-checked:text-white peer-checked:border-[#C9612F] transition-all">Thứ 7</span>
              </label>
              <label class="day-chip cursor-pointer">
                <input type="checkbox" value="CN" checked class="hidden peer"/>
                <span class="inline-block px-4 py-2 rounded-full border border-white/20 text-sm font-semibold text-white/70 peer-checked:bg-[#C9612F] peer-checked:text-white peer-checked:border-[#C9612F] transition-all">Chủ nhật</span>
              </label>
            </div>
          </div>

          <!-- Description -->
          <div class="mb-6">
            <label class="block text-xs font-semibold tracking-wider uppercase text-white/70 mb-2" for="regDescription">Mô tả thêm về cơ sở</label>
            <textarea id="regDescription" rows="3" placeholder="Dịch vụ đi kèm, tiện ích, lưu ý đặc biệt..." class="w-full px-5 py-3.5 border border-white/20 rounded-xl bg-black/20 text-white focus:outline-none focus:ring-2 focus:ring-[#C9612F]/40 focus:border-[#C9612F] transition-all resize-vertical placeholder:text-white/30"></textarea>
          </div>

          <div class="flex gap-3">
            <button type="button" onclick="goToStep2Back()" class="flex-shrink-0 px-6 py-4 rounded-full border border-white/20 text-white/80 hover:bg-white/10 transition-all flex items-center gap-1 bg-transparent cursor-pointer">
              <span class="material-symbols-outlined text-sm">arrow_back</span> Quay lại
            </button>
            <button type="button" onclick="submitFullForm()" class="pill flex-1 py-4 text-base text-white bg-[#C9612F] hover:bg-[#E08A4F] transition-all rounded-full font-semibold border-none cursor-pointer">
              🚀 Gửi đăng ký
            </button>
          </div>
        </div>
      </div>
    </div>
  </section>

  <!-- FOOTER -->
  <footer class="foot">
    <div class="wrap">
      <div class="foot-top">
        <div>
          <a href="#" class="brand">V-SPORT<span style="color:var(--accent)">.</span></a>
          <p>Hệ thống quản lý thể thao hàng đầu. Đơn giản hóa quy trình vận hành và tối ưu doanh thu của bạn.</p>
        </div>
        <div class="foot-col"><h4>Tính năng</h4><a href="#journeys">Đặt lịch</a><a href="#journeys">Hội viên</a><a href="#journeys">Báo cáo</a><a href="#journeys">Tất cả tính năng</a></div>
        <div class="foot-col"><h4>Thông tin</h4><a href="#about">Ý tưởng</a><a href="#experience">Quy trình</a><a href="#stay">Giải pháp</a></div>
        <div class="foot-col"><h4>Liên kết</h4><a href="#begin">Đăng ký đối tác</a><a href="#">Hỗ trợ 24/7</a><a href="#">Điều khoản</a></div>
      </div>
      <div class="foot-bottom">
        <span>© 2026 V-Sport. Tất cả quyền được bảo lưu.</span>
        <span>Premium Sports Management.</span>
      </div>
    </div>
  </footer>

</main>

<!-- ====== SPORTS POPUP MODAL ====== -->
<div id="sportsPopup" class="fixed inset-0 z-[100] hidden">
  <div class="absolute inset-0 bg-black/70 backdrop-blur-sm" onclick="closeSportsPopup()"></div>
  <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-[#1c1812] border border-white/10 rounded-3xl w-[95vw] max-w-lg max-h-[80vh] overflow-hidden shadow-2xl flex flex-col text-white">
    <div class="p-6 border-b border-white/10 flex items-center justify-between">
      <h3 class="font-serif text-xl font-medium">Chọn môn thể thao</h3>
      <button onclick="closeSportsPopup()" class="w-10 h-10 rounded-full hover:bg-white/10 flex items-center justify-center transition-all bg-transparent border-none text-white cursor-pointer">
        <span class="material-symbols-outlined">close</span>
      </button>
    </div>
    <div class="p-6 overflow-y-auto flex-1">
      <div class="grid grid-cols-2 gap-3" id="sportsGrid">
        <!-- Sports will be generated by JS -->
      </div>
    </div>
    <div class="p-6 border-t border-white/10 flex justify-between items-center">
      <span class="text-sm text-white/60">Đã chọn: <strong id="selectedSportsCount" class="text-[#E08A4F]">0</strong> môn</span>
      <button onclick="confirmSportsSelection()" class="pill text-white px-8 py-3 rounded-full font-semibold border-none cursor-pointer bg-[#C9612F] hover:bg-[#E08A4F]">
        Xác nhận
      </button>
    </div>
  </div>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/gsap.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/ScrollTrigger.min.js"></script>
<script src="https://unpkg.com/lenis@1.1.13/dist/lenis.min.js"></script>
<script src="https://unpkg.com/split-type@0.3.4/umd/index.min.js"></script>
<script>
(function(){
  "use strict";
  var REDUCE = matchMedia("(prefers-reduced-motion: reduce)").matches;
  var FINE = matchMedia("(hover:hover) and (pointer:fine)").matches;
  gsap.registerPlugin(ScrollTrigger);

  /* ---------- Lenis smooth-scroll substrate ---------- */
  var lenis;
  if(!REDUCE){
    lenis = new Lenis({
      duration: 1.15,
      smoothWheel: true,
      wheelMultiplier: 1
    });
    lenis.on("scroll", ScrollTrigger.update);
    
    function raf(time) {
      lenis.raf(time);
      requestAnimationFrame(raf);
    }
    requestAnimationFrame(raf);
    
    gsap.ticker.lagSmoothing(0);
  }

  /* ---------- Veil entrance + hero reveal (single chained timeline) ---------- */
  if(REDUCE){
    var v=document.getElementById("veil"); if(v) v.style.display="none";
    gsap.set(".hero .ln",{yPercent:0});
    gsap.set(".reveal",{opacity:1,y:0});
  } else {
    gsap.set(".hero .ln",{yPercent:125});
    gsap.set(".hero .reveal",{opacity:0,y:28});
    gsap.timeline()
      .to("#vbar",{scaleX:1,duration:.8,ease:"power2.inOut"})
      .to("#veil",{yPercent:-100,duration:.9,ease:"power3.inOut"},"+=.10")
      .set("#veil",{display:"none"})
      .to(".hero .ln",{yPercent:0,duration:1.1,stagger:.12,ease:"expo.out"},"-=.35")
      .to(".hero .reveal",{opacity:1,y:0,duration:.9,stagger:.14,ease:"expo.out"},"-=.55");
  }

  /* ---------- Nav state ---------- */
  var nav=document.getElementById("nav");
  ScrollTrigger.create({start:"top -80",onUpdate:function(self){ nav.classList.toggle("solid", self.scroll()>80); }});

  /* ---------- Progress bar ---------- */
  gsap.to("#progress",{scaleX:1,ease:"none",scrollTrigger:{trigger:document.body,start:"top top",end:"bottom bottom",scrub:.3}});

  /* ---------- Generic reveals ---------- */
  gsap.utils.toArray(".reveal").forEach(function(el){
    if(el.closest(".hero")) return; // hero handled by veil timeline
    gsap.to(el,{opacity:1,y:0,duration:.9,ease:"expo.out",
      scrollTrigger:{trigger:el,start:"top 86%"}});
  });

  /* ---------- Manifesto statement: line reveal ---------- */
  if(!REDUCE && window.SplitType){
    var st=new SplitType(".statement",{types:"lines"});
    document.querySelectorAll(".statement .line").forEach(function(l){
      var w=document.createElement("span"); w.className="line-wrap"; w.style.display="block";
      l.parentNode.insertBefore(w,l); w.appendChild(l);
    });
    gsap.set(".statement .line",{yPercent:125});
    gsap.to(".statement .line",{yPercent:0,duration:1.1,stagger:.09,ease:"expo.out",
      scrollTrigger:{trigger:".statement",start:"top 82%"}});
  }

  /* ---------- Hero ken-burns + parallax ---------- */
  if(!REDUCE){
    gsap.to(".hero-media img",{scale:1.16,ease:"none",
      scrollTrigger:{trigger:".hero",start:"top top",end:"bottom top",scrub:true}});
    gsap.to(".hero-media",{yPercent:14,ease:"none",
      scrollTrigger:{trigger:".hero",start:"top top",end:"bottom top",scrub:true}});
    // generic data-speed parallax for backgrounds
    gsap.utils.toArray("[data-speed]").forEach(function(el){
      if(el.closest(".hero")) return;
      var s=parseFloat(el.getAttribute("data-speed"));
      gsap.fromTo(el,{yPercent:(1-s)*-14},{yPercent:(1-s)*14,ease:"none",
        scrollTrigger:{trigger:el.closest("section"),start:"top bottom",end:"bottom top",scrub:true}});
    });
    // inner-frame parallax for stay + cards
    gsap.to(".stay-media img",{yPercent:-8,ease:"none",
      scrollTrigger:{trigger:".stay-media",start:"top bottom",end:"bottom top",scrub:true}});
  }

  /* ---------- Journeys horizontal (desktop) / native scroll (mobile) ---------- */
  var mm = gsap.matchMedia();
  mm.add("(min-width: 861px)", function(){
    if(REDUCE) return;
    var track=document.getElementById("jtrack");
    var section=document.querySelector(".journeys");
    function dist(){ return Math.max(0, track.scrollWidth - window.innerWidth); }
    var move=gsap.to(track,{x:function(){return -dist();},ease:"none",
      scrollTrigger:{trigger:section,start:"top top",end:function(){return "+="+dist();},
        pin:".jpin",scrub:1,invalidateOnRefresh:true,
        onUpdate:function(self){ gsap.set("#jbar",{scaleX:self.progress}); }}});
    gsap.utils.toArray(".jcard").forEach(function(card){
      gsap.from(card,{autoAlpha:0,y:40,duration:.7,ease:"expo.out",
        scrollTrigger:{trigger:card,containerAnimation:move,start:"left 88%"}});
      var img=card.querySelector(".frame img");
      gsap.fromTo(img,{xPercent:-4},{xPercent:4,ease:"none",
        scrollTrigger:{trigger:card,containerAnimation:move,start:"left right",end:"right left",scrub:true}});
    });
  });
  mm.add("(max-width: 860px)", function(){
    document.querySelector(".journeys").classList.add("mobile");
  });

  /* ---------- Experience sticky scrollytelling (image swaps per step) ---------- */
  (function(){
    var steps=gsap.utils.toArray(".estep");
    var media=document.getElementById("expMedia");
    var cap=document.getElementById("expCap");
    var imgs=media?Array.prototype.slice.call(media.querySelectorAll(".em-img")):[];
    function activate(i){
      steps.forEach(function(s,k){s.classList.toggle("active",k===i);});
      imgs.forEach(function(im,k){im.classList.toggle("on",k===i);});
      if(cap){cap.textContent=steps[i].getAttribute("data-cap");cap.style.opacity=1;}
    }
    steps.forEach(function(step,i){
      ScrollTrigger.create({trigger:step,start:"top center",end:"bottom center",
        onToggle:function(self){ if(self.isActive) activate(i); }});
    });
    activate(0);
  })();

  /* ---------- Number count-up ---------- */
  gsap.utils.toArray(".nstat .v").forEach(function(el){
    var end=parseFloat(el.getAttribute("data-count"));
    var suf=el.getAttribute("data-suffix")||"";
    var obj={n:0};
    ScrollTrigger.create({trigger:el,start:"top 88%",once:true,onEnter:function(){
      if(REDUCE){el.textContent=end+suf;return;}
      gsap.to(obj,{n:end,duration:1.4,ease:"power2.out",onUpdate:function(){
        el.textContent=Math.round(obj.n)+suf;
      }});
    }});
  });

  /* ---------- Marquee ribbons ---------- */
  if(!REDUCE){
    gsap.to("#mrow1",{xPercent:-50,repeat:-1,duration:34,ease:"none"});
    gsap.set("#mrow2",{xPercent:-50});
    gsap.to("#mrow2",{xPercent:0,repeat:-1,duration:40,ease:"none"});
  }

  /* ---------- Magnetic CTAs ---------- */
  if(FINE && !REDUCE){
    document.querySelectorAll(".magnetic").forEach(function(el){
      el.addEventListener("mousemove",function(e){
        var r=el.getBoundingClientRect();
        gsap.to(el,{x:(e.clientX-r.left-r.width/2)*.3,y:(e.clientY-r.top-r.height/2)*.4,duration:.5,ease:"power3.out"});
      });
      el.addEventListener("mouseleave",function(){gsap.to(el,{x:0,y:0,duration:.6,ease:"elastic.out(1,.4)"});});
    });
  }

  /* ---------- Custom cursor ---------- */
  if(FINE && !REDUCE){
    var cur=document.getElementById("cursor"); var lbl=cur.querySelector(".label");
    var cx=0,cy=0,tx=0,ty=0,shown=false;
    addEventListener("mousemove",function(e){tx=e.clientX;ty=e.clientY;
      if(!shown){shown=true;cur.classList.add("show");}});
    gsap.ticker.add(function(){cx+=(tx-cx)*.2;cy+=(ty-cy)*.2;gsap.set(cur,{x:cx,y:cy});});
    document.querySelectorAll("[data-cursor]").forEach(function(el){
      el.addEventListener("mouseenter",function(){lbl.textContent=el.getAttribute("data-cursor");cur.classList.add("show");});
    });
    addEventListener("mouseleave",function(){cur.classList.remove("show");});
  }

  /* ---------- Cartographic route rail ---------- */
  (function(){
    var rail=document.getElementById("rail"); if(!rail) return;
    var dot=document.getElementById("railDot"), rcap=document.getElementById("railCap");
    if(!REDUCE){
      gsap.to(dot,{top:143,ease:"none",
        scrollTrigger:{trigger:document.body,start:"top top",end:"bottom bottom",scrub:.4}});
    } else { gsap.set(dot,{top:70}); }
    function setTheme(t){ rail.style.setProperty("--rail-fg", t==="dark" ? "#F3ECE0" : "#17130E"); }
    setTheme("dark");
    gsap.utils.toArray("section[data-geo]").forEach(function(s){
      var parts=(s.getAttribute("data-geo")||"|dark").split("|");
      ScrollTrigger.create({trigger:s,start:"top 45%",end:"bottom 45%",
        onToggle:function(self){ if(self.isActive){ rcap.textContent=parts[0]; setTheme(parts[1]||"dark"); } }});
    });
  })();

  /* ---------- Anchor links via Lenis ---------- */
  document.querySelectorAll('a[href^="#"]').forEach(function(a){
    a.addEventListener("click",function(e){
      var id=a.getAttribute("href"); if(id==="#"||id.length<2) return;
      var t=document.querySelector(id); if(!t) return;
      e.preventDefault();
      if(lenis){
        lenis.scrollTo(t,{offset:-40});
      } else {
        t.scrollIntoView({behavior:"smooth"});
      }
    });
  });
})();
</script>

<script>
    // ==========================================
    // GLOBAL STATE
    // ==========================================
    let currentStep = 1;
    let serverOtp = ''; // OTP returned from server
    let otpAttempts = 0;
    let resendCount = 0;
    let resendTimer = null;
    let selectedSports = []; // [{name, icon}]
    let emailVerified = false;

    // Cờ do backend đặt khi JSP được forward lại kèm dữ liệu form (vd: lỗi validate).
    // Khi true, bản nháp trong sessionStorage KHÔNG được ghi đè lên dữ liệu backend trả về.
    if (typeof window.ownerServerFormHasData === 'undefined') {
        window.ownerServerFormHasData = false;
    }

    const POPULAR_SPORTS = [
        { name: 'Bóng đá', icon: 'sports_soccer' },
        { name: 'Bóng rổ', icon: 'sports_basketball' },
        { name: 'Cầu lông', icon: 'sports_tennis' },
        { name: 'Tennis', icon: 'sports_tennis' },
        { name: 'Bóng chuyền', icon: 'sports_volleyball' },
        { name: 'Bóng bàn', icon: 'sports_cricket' },
        { name: 'Bơi lội', icon: 'pool' },
        { name: 'Gym / Fitness', icon: 'fitness_center' },
        { name: 'Yoga', icon: 'self_improvement' },
        { name: 'Pickleball', icon: 'sports_tennis' },
        { name: 'Đá cầu', icon: 'sports' },
        { name: 'Billiards', icon: 'sports' },
        { name: 'Võ thuật', icon: 'sports_martial_arts' },
        { name: 'Chạy bộ', icon: 'directions_run' },
        { name: 'Đồ uống / Canteen', icon: 'local_cafe' },
        { name: 'Khác', icon: 'more_horiz' }
    ];

    // ==========================================
    // STEP NAVIGATION
    // ==========================================
    function showStep(step) {
        currentStep = step;
        document.getElementById('formStep1').classList.toggle('hidden', step !== 1);
        document.getElementById('formStep2').classList.toggle('hidden', step !== 2);
        document.getElementById('formStep3').classList.toggle('hidden', step !== 3);
        // Update step indicators
        document.querySelectorAll('#stepIndicators .step-dot').forEach(dot => {
            const s = parseInt(dot.dataset.step);
            const numSpan = dot.querySelector('span:first-child');
            if (s < step) {
                dot.className = 'step-dot flex items-center gap-2 px-4 py-2.5 rounded-2xl bg-green-700/60 text-white text-sm font-semibold transition-all shrink-0 whitespace-nowrap';
                if (numSpan) numSpan.className = 'flex items-center justify-center w-5 h-5 rounded-lg bg-white/20 text-xs';
            } else if (s === step) {
                dot.className = 'step-dot active flex items-center gap-2 px-4 py-2.5 rounded-2xl bg-[#C9612F] text-white text-sm font-semibold transition-all shrink-0 whitespace-nowrap';
                if (numSpan) numSpan.className = 'flex items-center justify-center w-5 h-5 rounded-lg bg-white/20 text-xs';
            } else {
                dot.className = 'step-dot flex items-center gap-2 px-4 py-2.5 rounded-2xl bg-white/10 text-white/60 text-sm font-semibold transition-all shrink-0 whitespace-nowrap';
                if (numSpan) numSpan.className = 'flex items-center justify-center w-5 h-5 rounded-lg bg-white/10 text-xs';
            }
        });
    }

    function showError(msg) {
        const el = document.getElementById('errorAlert');
        document.getElementById('errorMessage').textContent = msg;
        el.classList.remove('hidden');
        el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
    function hideError() { document.getElementById('errorAlert').classList.add('hidden'); }

    // ==========================================
    // STEP 1 -> STEP 2 (Send OTP)
    // ==========================================
    function autoFillAddress() {
        document.getElementById('geoInput').value = "";
        document.getElementById('geoModal').classList.remove('hidden');
        document.getElementById('geoInput').focus();
    }
    window.autoFillAddress = autoFillAddress;

    function closeGeoModal() {
        document.getElementById('geoModal').classList.add('hidden');
    }
    window.closeGeoModal = closeGeoModal;

    // Parse tọa độ từ nhiều dạng input khác nhau
    function parseCoordinates(input) {
        if (!input) return null;
        const s = input.trim();

        // Cảnh báo link rút gọn (maps.app.goo.gl) — không có tọa độ trực tiếp
        if (/maps\.app\.goo\.gl/i.test(s)) {
            return { error: "Link Google Maps rút gọn không chứa tọa độ trực tiếp. Vui lòng mở link, copy tọa độ hoặc link đầy đủ có dạng @vĩ_độ,kinh_độ." };
        }

        // Thử tìm @lat,lng trong URL Google Maps
        const atMatch = s.match(/@(-?\d+\.?\d*),(-?\d+\.?\d*)/);
        if (atMatch) return validate(atMatch[1], atMatch[2]);

        // Thử q=lat,lng hoặc query=lat,lng
        const qMatch = s.match(/[?&](?:q|query)=(-?\d+\.?\d*),(-?\d+\.?\d*)/);
        if (qMatch) return validate(qMatch[1], qMatch[2]);

        // Thử tọa độ thuần: "lat, lng" hoặc "lat lng"
        const plainMatch = s.match(/^(-?\d+\.?\d*)[,\s]+(-?\d+\.?\d*)$/);
        if (plainMatch) return validate(plainMatch[1], plainMatch[2]);

        // Thử tìm bất kỳ cặp số nào trong chuỗi (fallback cho URL dạng khác)
        const anyMatch = s.match(/(-?\d{1,3}\.\d+)[,\s]+(-?\d{1,3}\.\d+)/);
        if (anyMatch) return validate(anyMatch[1], anyMatch[2]);

        return null;
    }

    function validate(latStr, lngStr) {
        const lat = parseFloat(parseFloat(latStr).toFixed(7));
        const lng = parseFloat(parseFloat(lngStr).toFixed(7));
        if (isNaN(lat) || isNaN(lng)) return null;
        if (lat < -90 || lat > 90) return { error: "Vĩ độ phải nằm trong khoảng -90 đến 90." };
        if (lng < -180 || lng > 180) return { error: "Kinh độ phải nằm trong khoảng -180 đến 180." };
        return { lat, lng };
    }

    function setLocationCoords(lat, lng, accuracy) {
        document.getElementById('viDo').value = lat;
        document.getElementById('kinhDo').value = lng;

        let msg = 'Đã nhận vị trí: ' + lat + ', ' + lng;
        if (accuracy !== undefined) {
            const acc = Math.round(accuracy);
            if (acc <= 50) {
                msg = 'Đã lấy vị trí hiện tại. Độ chính xác khoảng ±' + acc + 'm.';
            } else if (acc <= 200) {
                msg = 'Đã lấy vị trí gần đúng. Độ chính xác khoảng ±' + acc + 'm. Hãy kiểm tra lại trên Google Maps.';
            } else {
                msg = 'Vị trí có độ chính xác thấp khoảng ±' + acc + 'm. Bạn nên copy tọa độ từ Google Maps để chính xác hơn.';
            }
        }
        document.getElementById('coordPreviewText').textContent = msg;

        const mapsLink = document.getElementById('coordMapsLink');
        mapsLink.href = 'https://www.google.com/maps?q=' + lat + ',' + lng;
        mapsLink.classList.remove('hidden');

        document.getElementById('coordPreview').classList.remove('hidden');
    }

    function submitGeoInput() {
        const input = document.getElementById('geoInput').value.trim();
        if (!input) {
            alert("Vui lòng dán tọa độ hoặc link Google Map.");
            return;
        }
        const result = parseCoordinates(input);
        if (result && result.error) {
            alert(result.error);
            return;
        }
        if (result) {
            setLocationCoords(result.lat, result.lng);
            closeGeoModal();
            fetchAddressFromCoords(result.lat, result.lng);
            saveOwnerDraft();
        } else {
            alert("Không đọc được tọa độ. Vui lòng nhập dạng 10.7626, 106.6601 hoặc dán link Google Maps có chứa tọa độ.");
        }
    }
    window.submitGeoInput = submitGeoInput;

    function useCurrentGps() {
        if (!navigator.geolocation) {
            alert("Trình duyệt không hỗ trợ lấy vị trí hiện tại.");
            return;
        }
        const btn = document.getElementById('btnUseGps');
        const geoInput = document.getElementById('geoInput');
        const originalText = btn.innerHTML;
        btn.disabled = true;
        btn.innerHTML = '<span class="animate-spin inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full mr-2"></span> Đang định vị...';

        navigator.geolocation.getCurrentPosition(
            function(pos) {
                btn.disabled = false;
                btn.innerHTML = originalText;

                const lat = parseFloat(pos.coords.latitude.toFixed(7));
                const lng = parseFloat(pos.coords.longitude.toFixed(7));
                const accuracy = Math.round(pos.coords.accuracy);

                geoInput.value = lat + ', ' + lng;

                if (accuracy > 200) {
                    const confirmed = window.confirm(
                        'Vị trí lấy được có độ chính xác thấp khoảng ±' + accuracy + 'm.\n\n' +
                        'Điều này thường xảy ra trên laptop/PC khi dùng Wi-Fi hoặc IP.\n\n' +
                        'Bạn vẫn muốn dùng vị trí này?\n' +
                        '(Bấm Hủy để nhập tọa độ từ Google Maps thay thế.)'
                    );
                    if (!confirmed) return;
                }

                setLocationCoords(lat, lng, accuracy);
                closeGeoModal();
                fetchAddressFromCoords(lat, lng);
                saveOwnerDraft();
            },
            function(err) {
                btn.disabled = false;
                btn.innerHTML = originalText;
                let errorMsg;
                if (err.code === err.PERMISSION_DENIED) {
                    errorMsg = "Bạn đã từ chối quyền vị trí. Hãy cho phép quyền vị trí hoặc nhập tọa độ thủ công.";
                } else if (err.code === err.POSITION_UNAVAILABLE) {
                    errorMsg = "Không lấy được vị trí từ thiết bị. Vui lòng nhập tọa độ hoặc dán link Google Maps.";
                } else if (err.code === err.TIMEOUT) {
                    errorMsg = "Quá thời gian lấy vị trí. Vui lòng thử lại hoặc nhập tọa độ thủ công.";
                } else {
                    errorMsg = "Không lấy được vị trí hiện tại. Vui lòng nhập tọa độ thủ công.";
                }
                alert(errorMsg);
            },
            { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 }
        );
    }
    window.useCurrentGps = useCurrentGps;

    function fetchAddressFromCoords(lat, lon, callback) {
        const addrInput = document.getElementById('regAddress');
        const originalPlaceholder = addrInput.placeholder;
        const savedAddress = addrInput.value.trim(); // giữ lại nếu API lỗi
        addrInput.disabled = true;
        addrInput.value = "";
        addrInput.placeholder = "Đang lấy địa chỉ từ tọa độ [" + parseFloat(lat).toFixed(4) + ", " + parseFloat(lon).toFixed(4) + "]...";

        fetch('https://nominatim.openstreetmap.org/reverse?format=json&lat=' + lat + '&lon=' + lon + '&accept-language=vi')
            .then(r => r.json())
            .then(data => {
                addrInput.disabled = false;
                addrInput.placeholder = originalPlaceholder;
                if (data && data.display_name) {
                    addrInput.value = data.display_name;
                } else {
                    addrInput.value = savedAddress; // khôi phục, không alert
                }
                if (callback) callback();
            })
            .catch(() => {
                addrInput.disabled = false;
                addrInput.placeholder = originalPlaceholder;
                addrInput.value = savedAddress; // khôi phục địa chỉ cũ
                const hint = document.getElementById('coordPreviewText');
                if (hint) hint.textContent += ' — Không tự lấy được địa chỉ, hãy nhập thủ công.';
                if (callback) callback();
            });
    }

    function goToStep1() { hideError(); showStep(1); saveOwnerDraft(); }

    function goToStep2() {
        hideError();
        const name = document.getElementById('ownerName').value.trim();
        const email = document.getElementById('regEmail').value.trim();
        const phone = document.getElementById('regPhone').value.trim();

        if (!name) { showError('Vui lòng nhập tên cơ sở.'); return; }
        if (!email) { showError('Vui lòng nhập email.'); return; }
        if (!phone) { showError('Vui lòng nhập số điện thoại.'); return; }

        // Validate email format
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) { showError('Email không hợp lệ.'); return; }

        // Validate phone format
        if (!/^(0|\+84)[35789][0-9]{8}$/.test(phone)) { showError('Số điện thoại không hợp lệ.'); return; }

        // Send OTP via AJAX
        document.getElementById('otpEmailDisplay').textContent = email;
        sendOtpToServer(email);
    }

    function sendOtpToServer(email) {
        const phone = document.getElementById('regPhone').value.trim();
        const btn = document.querySelector('#formStep1 button');
        btn.disabled = true;
        btn.innerHTML = '<span class="animate-spin inline-block w-5 h-5 border-2 border-white border-t-transparent rounded-full mr-2"></span> Đang gửi OTP...';

        fetch('${pageContext.request.contextPath}/owner/send-otp', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: 'email=' + encodeURIComponent(email) + '&phone=' + encodeURIComponent(phone)
        })
        .then(r => r.json())
        .then(data => {
            btn.disabled = false;
            btn.innerHTML = 'Tiếp tục — Xác thực Email <span class="material-symbols-outlined align-middle text-lg">arrow_forward</span>';
            if (data.success) {
                otpAttempts = 0;
                resendCount = 0;
                document.getElementById('otpAttemptCount').textContent = '0';
                document.getElementById('otpValidityHint').classList.add('hidden');
                showStep(2);
                startResendCountdown();
                saveOwnerDraft();
                // Focus first OTP box
                document.querySelector('.otp-box[data-index="0"]').focus();
            } else {
                showError(data.message || 'Không thể gửi OTP. Vui lòng thử lại.');
            }
        })
        .catch(() => {
            btn.disabled = false;
            btn.innerHTML = 'Tiếp tục — Xác thực Email <span class="material-symbols-outlined align-middle text-lg">arrow_forward</span>';
            showError('Lỗi kết nối. Vui lòng thử lại.');
        });
    }

    // ==========================================
    // OTP INPUT HANDLING
    // ==========================================
    document.querySelectorAll('.otp-box').forEach(box => {
        box.addEventListener('input', (e) => {
            const val = e.target.value;
            if (val && parseInt(e.target.dataset.index) < 5) {
                const next = document.querySelector('.otp-box[data-index="' + (parseInt(e.target.dataset.index) + 1) + '"]');
                if (next) next.focus();
            }
        });
        box.addEventListener('keydown', (e) => {
            if (e.key === 'Backspace' && !e.target.value) {
                const prev = document.querySelector('.otp-box[data-index="' + (parseInt(e.target.dataset.index) - 1) + '"]');
                if (prev) { prev.focus(); prev.value = ''; }
            }
        });
        // Allow paste
        box.addEventListener('paste', (e) => {
            e.preventDefault();
            const pasted = (e.clipboardData || window.clipboardData).getData('text').trim();
            const digits = pasted.replace(/\D/g, '').split('');
            document.querySelectorAll('.otp-box').forEach((b, i) => { b.value = digits[i] || ''; });
            const lastIdx = Math.min(digits.length - 1, 5);
            document.querySelector('.otp-box[data-index="' + lastIdx + '"]').focus();
        });
    });

    // ==========================================
    // VERIFY OTP
    // ==========================================
    function verifyOtp() {
        hideError();
        const otpError = document.getElementById('otpError');
        otpError.classList.add('hidden');

        let otp = '';
        document.querySelectorAll('.otp-box').forEach(b => otp += b.value);
        if (otp.length < 6) { otpError.textContent = 'Vui lòng nhập đủ 6 chữ số.'; otpError.classList.remove('hidden'); return; }

        const email = document.getElementById('regEmail').value.trim();
        const btn = document.getElementById('btnVerifyOtp');
        if (btn.disabled) return; // chống double-click / double-submit
        btn.disabled = true;
        fetch('${pageContext.request.contextPath}/owner/verify-otp', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: 'email=' + encodeURIComponent(email) + '&otp=' + encodeURIComponent(otp)
        })
        .then(r => r.json())
        .then(data => {
            btn.disabled = false;
            if (data.success) {
                emailVerified = true;
                showStep(3);
                saveOwnerDraft();
            } else {
                otpAttempts++;
                document.getElementById('otpAttemptCount').textContent = otpAttempts;
                // Clear OTP boxes
                document.querySelectorAll('.otp-box').forEach(b => b.value = '');
                document.querySelector('.otp-box[data-index="0"]').focus();

                if (otpAttempts >= 5) {
                    showError('Bạn đã nhập sai OTP quá 5 lần. Vui lòng quay lại và thử lại.');
                    showStep(1);
                    otpAttempts = 0;
                } else {
                    otpError.textContent = 'Mã OTP không đúng. Còn ' + (5 - otpAttempts) + ' lần thử.';
                    otpError.classList.remove('hidden');
                }
            }
        })
        .catch(() => {
            btn.disabled = false;
            otpError.textContent = 'Lỗi kết nối. Vui lòng thử lại.';
            otpError.classList.remove('hidden');
        });
    }

    // ==========================================
    // RESEND OTP
    // ==========================================
    function startResendCountdown(startSeconds) {
        let seconds = typeof startSeconds === 'number' ? startSeconds : 60;
        const btn = document.getElementById('btnResendOtp');
        const countdown = document.getElementById('resendCountdown');
        const wrap = document.getElementById('resendCountdownWrap');
        clearInterval(resendTimer);
        if (seconds <= 0) {
            btn.disabled = false;
            if (wrap) wrap.classList.add('hidden');
            return;
        }
        countdown.textContent = seconds;
        if (wrap) wrap.classList.remove('hidden');
        btn.disabled = true;
        resendTimer = setInterval(() => {
            seconds--;
            countdown.textContent = seconds;
            if (seconds <= 0) {
                clearInterval(resendTimer);
                btn.disabled = false;
                if (wrap) wrap.classList.add('hidden');
            }
        }, 1000);
    }

    function resendOtp() {
        resendCount++;
        if (resendCount >= 3) {
            showError('Bạn đã gửi lại mã quá 3 lần. Vui lòng quay lại và thử lại.');
            showStep(1);
            return;
        }
        const email = document.getElementById('regEmail').value.trim();
        sendOtpToServer(email);
        // Reset OTP fields
        document.querySelectorAll('.otp-box').forEach(b => b.value = '');
        otpAttempts = 0;
        document.getElementById('otpAttemptCount').textContent = '0';
    }

    function goToStep2Back() {
        hideError();
        showStep(2);
        saveOwnerDraft();
    }

    // ==========================================
    // SPORTS POPUP
    // ==========================================
    function initSportsGrid() {
        const grid = document.getElementById('sportsGrid');
        grid.innerHTML = '';
        POPULAR_SPORTS.forEach(sport => {
            const isSelected = selectedSports.some(s => s.name === sport.name);
            const div = document.createElement('label');
            div.className = 'sport-item cursor-pointer';
            div.innerHTML = '<input type="checkbox" value="' + sport.name + '" data-icon="' + sport.icon + '" class="hidden peer sport-checkbox" ' + (isSelected ? 'checked' : '') + ' />' +
                '<div class="flex items-center gap-3 p-3 rounded-xl border border-white/10 peer-checked:border-[#C9612F] peer-checked:bg-[#C9612F]/10 transition-all hover:bg-white/5">' +
                    '<span class="material-symbols-outlined text-[22px] peer-checked:text-[#C9612F] text-white/60">' + sport.icon + '</span>' +
                    '<span class="text-sm font-medium text-white">' + sport.name + '</span>' +
                '</div>';
            grid.appendChild(div);
        });
        updateSportsCount();
    }

    function updateSportsCount() {
        const checked = document.querySelectorAll('#sportsGrid .sport-checkbox:checked');
        document.getElementById('selectedSportsCount').textContent = checked.length;
    }

    document.addEventListener('change', (e) => {
        if (e.target.classList.contains('sport-checkbox')) updateSportsCount();
    });

    // Make functions globally accessible so inline HTML event handlers can call them
    window.openSportsPopup = function() {
        initSportsGrid();
        document.getElementById('sportsPopup').classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    };

    window.closeSportsPopup = function() {
        document.getElementById('sportsPopup').classList.add('hidden');
        document.body.style.overflow = '';
    };

    window.confirmSportsSelection = function() {
        selectedSports = [];
        document.querySelectorAll('#sportsGrid .sport-checkbox:checked').forEach(cb => {
            selectedSports.push({ name: cb.value, icon: cb.dataset.icon });
        });
        closeSportsPopup();
        renderCourtQuantities();
        saveOwnerDraft();
    };

    // ==========================================
    // COURT QUANTITIES
    // ==========================================
    function renderCourtQuantities() {
        const section = document.getElementById('courtQuantitySection');
        const list = document.getElementById('courtQuantityList');
        const preview = document.getElementById('sportsPreviewText');

        if (selectedSports.length === 0) {
            section.classList.add('hidden');
            preview.textContent = 'Chọn các môn thể thao...';
            preview.className = 'text-white/40';
            return;
        }

        preview.textContent = selectedSports.map(s => s.name).join(', ');
        preview.className = 'text-white font-medium';
        section.classList.remove('hidden');

        list.innerHTML = '';
        selectedSports.forEach(sport => {
            const row = document.createElement('div');
            row.className = 'flex items-center gap-4 bg-white/5 p-4 rounded-xl border border-white/10';
            row.innerHTML = '<span class="material-symbols-outlined text-[#C9612F] text-[22px]">' + sport.icon + '</span>' +
                '<span class="flex-1 font-medium text-white text-sm">' + sport.name + '</span>' +
                '<div class="flex items-center gap-2">' +
                    '<button type="button" onclick="changeQty(this,-1)" class="w-8 h-8 rounded-lg bg-white/10 border border-white/20 flex items-center justify-center hover:bg-white/20 transition-all text-lg font-bold text-white cursor-pointer">−</button>' +
                    '<input type="number" min="1" value="1" class="court-qty w-14 h-8 text-center border border-white/20 rounded-lg bg-black/20 font-bold text-white text-sm" data-sport="' + sport.name + '" />' +
                    '<button type="button" onclick="changeQty(this,1)" class="w-8 h-8 rounded-lg bg-white/10 border border-white/20 flex items-center justify-center hover:bg-white/20 transition-all text-lg font-bold text-white cursor-pointer">+</button>' +
                    '<span class="text-xs text-white/60 ml-1">sân</span>' +
                '</div>';
            list.appendChild(row);
        });
    }

    window.changeQty = function(btn, delta) {
        const input = btn.parentElement.querySelector('.court-qty');
        let val = parseInt(input.value) || 1;
        val = Math.max(1, val + delta);
        input.value = val;
        saveOwnerDraft();
    };

    // ==========================================
    // FINAL SUBMISSION
    // ==========================================
    window.submitFullForm = function() {
        hideError();
        if (!emailVerified) { showError('Vui lòng xác thực email trước.'); return; }
        if (selectedSports.length === 0) { showError('Vui lòng chọn ít nhất 1 môn thể thao.'); return; }

        const openTime = document.getElementById('openTime').value;
        const closeTime = document.getElementById('closeTime').value;
        if (!openTime || !closeTime) { showError('Vui lòng chọn giờ mở cửa và đóng cửa.'); return; }

        // Collect operating days
        const days = [];
        document.querySelectorAll('#operatingDays input[type="checkbox"]:checked').forEach(cb => days.push(cb.value));
        if (days.length === 0) { showError('Vui lòng chọn ít nhất 1 ngày hoạt động.'); return; }

        // Collect court data
        const sportsData = [];
        document.querySelectorAll('.court-qty').forEach(input => {
            sportsData.push({ sport: input.dataset.sport, quantity: parseInt(input.value) || 1 });
        });

        // Build form data
        const formData = new URLSearchParams();
        formData.append('ownerName', document.getElementById('ownerName').value.trim());
        formData.append('email', document.getElementById('regEmail').value.trim());
        formData.append('phone', document.getElementById('regPhone').value.trim());
        formData.append('address', document.getElementById('regAddress').value.trim());
        formData.append('description', document.getElementById('regDescription').value.trim());
        formData.append('openTime', openTime);
        formData.append('closeTime', closeTime);
        formData.append('operatingDays', days.join(','));
        formData.append('sportsData', JSON.stringify(sportsData));
        const viDoVal = document.getElementById('viDo').value;
        const kinhDoVal = document.getElementById('kinhDo').value;
        if (viDoVal) formData.append('viDo', viDoVal);
        if (kinhDoVal) formData.append('kinhDo', kinhDoVal);

        const btn = document.querySelector('#formStep3 button[onclick="submitFullForm()"]');
        btn.disabled = true;
        btn.innerHTML = '<span class="animate-spin inline-block w-5 h-5 border-2 border-white border-t-transparent rounded-full mr-2"></span> Đang gửi...';

        fetch('${pageContext.request.contextPath}/owner/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: formData.toString()
        })
        .then(r => r.json())
        .then(data => {
            btn.disabled = false;
            btn.innerHTML = '🚀 Gửi đăng ký';
            if (data.success) {
                document.getElementById('successAlert').classList.remove('hidden');
                document.getElementById('formStep3').innerHTML = '<div class="text-center py-12"><span class="material-symbols-outlined text-green-500 text-6xl mb-4">check_circle</span><h3 class="font-serif text-2xl text-white mb-2">Đăng ký thành công!</h3><p class="text-white/70">Chúng tôi sẽ sớm liên hệ với bạn qua email hoặc số điện thoại đã cung cấp.</p></div>';
                clearOwnerDraft();
            } else {
                showError(data.message || 'Có lỗi xảy ra. Vui lòng thử lại.');
            }
        })
        .catch(() => {
            btn.disabled = false;
            btn.innerHTML = '🚀 Gửi đăng ký';
            showError('Lỗi kết nối. Vui lòng thử lại.');
        });
    };

    // Attach step transition functions to window so they are globally callable
    window.goToStep1 = goToStep1;
    window.goToStep2 = goToStep2;
    window.goToStep2Back = goToStep2Back;
    window.verifyOtp = verifyOtp;
    window.resendOtp = resendOtp;

    // URL param alerts
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.has('success')) {
        document.getElementById('successAlert').classList.remove('hidden');
        const regSection = document.getElementById('begin');
        if (regSection) regSection.scrollIntoView({behavior:'smooth'});
        clearOwnerDraft();
    }

    function syncOwnerTime(which) {
        const hVal = document.getElementById(which + 'TimeH').value;
        const mVal = document.getElementById(which + 'TimeM').value;
        document.getElementById(which + 'Time').value = hVal + ':' + mVal;
    }
    window.syncOwnerTime = syncOwnerTime;

    // Init 24h time selects for opening/closing hours
    (function() {
        function buildTimeSelects(prefix, defaultH, defaultM) {
            const hSel = document.getElementById(prefix + 'H');
            const mSel = document.getElementById(prefix + 'M');
            if (!hSel || !mSel) return;
            for (let h = 0; h <= 23; h++) {
                const o = document.createElement('option');
                o.value = String(h).padStart(2, '0');
                o.textContent = String(h).padStart(2, '0') + 'h';
                if (h === defaultH) o.selected = true;
                hSel.appendChild(o);
            }
            [0, 15, 30, 45].forEach(function(m) {
                const o = document.createElement('option');
                o.value = String(m).padStart(2, '0');
                o.textContent = String(m).padStart(2, '0');
                if (m === defaultM) o.selected = true;
                mSel.appendChild(o);
            });
        }
        buildTimeSelects('openTime',  6, 0);
        buildTimeSelects('closeTime', 22, 0);
    })();

    // ==========================================
    // BẢN NHÁP ĐĂNG KÝ (sessionStorage) — chống mất dữ liệu khi reload
    // ==========================================
    const OWNER_DRAFT_KEY = 'vsport_owner_registration_draft';
    const OWNER_DRAFT_TTL_MS = 2 * 60 * 60 * 1000; // 2 giờ
    const OWNER_DRAFT_VERSION = 1;

    // Debounce đơn giản: trì hoãn thực thi để không ghi sessionStorage liên tục
    function debounce(fn, wait) {
        let timer = null;
        return function() {
            const args = arguments;
            const ctx = this;
            clearTimeout(timer);
            timer = setTimeout(function() { fn.apply(ctx, args); }, wait);
        };
    }

    function ownerDraftGetVal(id) {
        const el = document.getElementById(id);
        return el ? el.value.trim() : '';
    }

    // Thu thập dữ liệu KHÔNG nhạy cảm từ form hiện tại (không đọc OTP/password)
    function collectOwnerDraft() {
        const courtQuantities = {};
        document.querySelectorAll('.court-qty').forEach(function(input) {
            courtQuantities[input.dataset.sport] = input.value;
        });

        const operatingDays = [];
        document.querySelectorAll('#operatingDays input[type="checkbox"]:checked').forEach(function(cb) {
            operatingDays.push(cb.value);
        });

        return {
            version: OWNER_DRAFT_VERSION,
            savedAt: Date.now(),
            currentStep: currentStep,
            fields: {
                tenCoSo: ownerDraftGetVal('ownerName'),
                email: ownerDraftGetVal('regEmail'),
                soDienThoai: ownerDraftGetVal('regPhone'),
                diaChi: ownerDraftGetVal('regAddress'),
                viDo: ownerDraftGetVal('viDo'),
                kinhDo: ownerDraftGetVal('kinhDo')
            },
            step3: {
                selectedSports: selectedSports,
                courtQuantities: courtQuantities,
                openTimeH: ownerDraftGetVal('openTimeH'),
                openTimeM: ownerDraftGetVal('openTimeM'),
                closeTimeH: ownerDraftGetVal('closeTimeH'),
                closeTimeM: ownerDraftGetVal('closeTimeM'),
                operatingDays: operatingDays,
                description: ownerDraftGetVal('regDescription')
            }
        };
    }

    function saveOwnerDraft() {
        try {
            const draft = collectOwnerDraft();
            sessionStorage.setItem(OWNER_DRAFT_KEY, JSON.stringify(draft));
        } catch (e) {
            // sessionStorage có thể bị trình duyệt chặn (chế độ ẩn danh nghiêm ngặt...) — bỏ qua an toàn
        }
    }
    const debouncedSaveOwnerDraft = debounce(saveOwnerDraft, 400);

    function isDraftExpired(draft) {
        if (!draft || !draft.savedAt) return true;
        return (Date.now() - draft.savedAt) > OWNER_DRAFT_TTL_MS;
    }

    function clearOwnerDraft() {
        try { sessionStorage.removeItem(OWNER_DRAFT_KEY); } catch (e) { /* bỏ qua */ }
    }

    function loadOwnerDraft() {
        let raw;
        try {
            raw = sessionStorage.getItem(OWNER_DRAFT_KEY);
        } catch (e) {
            return null;
        }
        if (!raw) return null;

        let draft;
        try {
            draft = JSON.parse(raw);
        } catch (e) {
            clearOwnerDraft(); // JSON hỏng — xóa key để không lặp lại lỗi ở lần sau
            return null;
        }

        if (!draft || draft.version !== OWNER_DRAFT_VERSION || isDraftExpired(draft)) {
            clearOwnerDraft();
            return null;
        }

        // Nếu chỉ có 1 trong 2 giá trị tọa độ thì bỏ luôn cặp tọa độ lỗi, không restore
        if (draft.fields) {
            const hasVi = !!draft.fields.viDo;
            const hasKinh = !!draft.fields.kinhDo;
            if (hasVi !== hasKinh) {
                draft.fields.viDo = '';
                draft.fields.kinhDo = '';
            }
        }

        return draft;
    }

    // Điều hướng bước dùng khi khôi phục / reset — không kèm side-effect gửi OTP hay submit
    function goToRegistrationStep(step) {
        showStep(step);
    }

    // Đổ dữ liệu draft vào các input thật trên form (không đụng tới bước hiện tại / OTP)
    function restoreOwnerDraftFieldsToDom(draft) {
        const f = draft.fields || {};
        if (f.tenCoSo) document.getElementById('ownerName').value = f.tenCoSo;
        if (f.email) document.getElementById('regEmail').value = f.email;
        if (f.soDienThoai) document.getElementById('regPhone').value = f.soDienThoai;
        if (f.diaChi) document.getElementById('regAddress').value = f.diaChi;

        if (f.viDo && f.kinhDo) {
            document.getElementById('viDo').value = f.viDo;
            document.getElementById('kinhDo').value = f.kinhDo;
            setLocationCoords(f.viDo, f.kinhDo); // chỉ hiển thị lại preview, không gọi GPS/Nominatim
        }

        const s3 = draft.step3 || {};
        if (Array.isArray(s3.selectedSports) && s3.selectedSports.length) {
            selectedSports = s3.selectedSports;
            renderCourtQuantities();
            if (s3.courtQuantities) {
                document.querySelectorAll('.court-qty').forEach(function(input) {
                    const qty = s3.courtQuantities[input.dataset.sport];
                    if (qty) input.value = qty;
                });
            }
        }

        if (Array.isArray(s3.operatingDays) && s3.operatingDays.length) {
            document.querySelectorAll('#operatingDays input[type="checkbox"]').forEach(function(cb) {
                cb.checked = s3.operatingDays.indexOf(cb.value) !== -1;
            });
        }

        if (s3.openTimeH) { document.getElementById('openTimeH').value = s3.openTimeH; syncOwnerTime('open'); }
        if (s3.openTimeM) { document.getElementById('openTimeM').value = s3.openTimeM; syncOwnerTime('open'); }
        if (s3.closeTimeH) { document.getElementById('closeTimeH').value = s3.closeTimeH; syncOwnerTime('close'); }
        if (s3.closeTimeM) { document.getElementById('closeTimeM').value = s3.closeTimeM; syncOwnerTime('close'); }

        if (s3.description) document.getElementById('regDescription').value = s3.description;
    }

    // Gọi server để biết trạng thái OTP/xác thực THẬT (không bao giờ tin sessionStorage cho việc này)
    function fetchOwnerOtpStatus() {
        return fetch('${pageContext.request.contextPath}/owner/otp-status')
            .then(function(r) { return r.json(); })
            .catch(function() { return { emailVerified: false, otpActive: false, secondsRemaining: 0, otpEmail: null }; });
    }

    function showOtpValidityHint(secondsRemaining) {
        const el = document.getElementById('otpValidityHint');
        if (!el) return;
        const mins = Math.max(1, Math.ceil(secondsRemaining / 60));
        el.textContent = 'Mã xác thực còn hiệu lực khoảng ' + mins + ' phút.';
        el.classList.remove('hidden');
    }

    // Suy ra cooldown còn lại của nút "Gửi lại mã" (60s) từ thời gian OTP đã tồn tại (tối đa 5 phút)
    function applyResendCooldownFromOtpValidity(secondsRemainingOtpValidity) {
        const elapsedSinceSent = Math.max(0, 300 - (secondsRemainingOtpValidity || 0));
        const cooldownLeft = Math.max(0, 60 - elapsedSinceSent);
        startResendCountdown(cooldownLeft);
    }

    // Đối chiếu bước muốn khôi phục với trạng thái OTP thật trên server (CASE A/B/C)
    async function reconcileOtpState(candidateStep, emailForDisplay) {
        if (!candidateStep || candidateStep <= 1) {
            goToRegistrationStep(1);
            return;
        }

        const status = await fetchOwnerOtpStatus();

        if (status.emailVerified) {
            // CASE C — server xác nhận email đã verify, không bắt xác minh lại
            emailVerified = true;
            if (emailForDisplay) document.getElementById('otpEmailDisplay').textContent = emailForDisplay;
            goToRegistrationStep(3);
            return;
        }

        if (status.otpActive) {
            // CASE A — OTP server vẫn còn hiệu lực, không tự gửi lại
            document.getElementById('otpEmailDisplay').textContent = status.otpEmail || emailForDisplay || '';
            goToRegistrationStep(2);
            applyResendCooldownFromOtpValidity(status.secondsRemaining);
            showOtpValidityHint(status.secondsRemaining);
            return;
        }

        // CASE B — OTP hết hạn hoặc không còn phiên hợp lệ
        emailVerified = false;
        showError('Phiên xác thực đã hết hạn. Vui lòng gửi lại OTP.');
        goToRegistrationStep(1);
    }

    async function initOwnerRegistrationDraft() {
        if (window.ownerServerFormHasData) return; // ưu tiên dữ liệu backend, không ghi đè bằng draft cũ
        const draft = loadOwnerDraft();
        if (!draft) return;

        restoreOwnerDraftFieldsToDom(draft);
        await reconcileOtpState(draft.currentStep, draft.fields && draft.fields.email);
    }

    // Tự động lưu draft khi người dùng nhập/chọn (không gắn cho OTP box / file input)
    const OWNER_DRAFT_WATCHED_SELECTOR = '#ownerName, #regEmail, #regPhone, #regAddress, #regDescription, ' +
        '#openTimeH, #openTimeM, #closeTimeH, #closeTimeM, #operatingDays input[type="checkbox"], .court-qty';

    ['input', 'change', 'focusout'].forEach(function(evt) {
        document.addEventListener(evt, function(e) {
            if (e.target && e.target.matches && e.target.matches(OWNER_DRAFT_WATCHED_SELECTOR)) {
                debouncedSaveOwnerDraft();
            }
        });
    });

    // Nút "Xóa bản nháp / Bắt đầu lại"
    window.confirmResetOwnerDraft = function() {
        const ok = window.confirm('Bạn có chắc muốn xóa toàn bộ thông tin đã nhập và bắt đầu lại không?');
        if (!ok) return;
        clearOwnerDraft();
        resetOwnerFormToInitialState();
    };

    function resetOwnerFormToInitialState() {
        document.getElementById('ownerName').value = '';
        document.getElementById('regEmail').value = '';
        document.getElementById('regPhone').value = '';
        document.getElementById('regAddress').value = '';
        document.getElementById('viDo').value = '';
        document.getElementById('kinhDo').value = '';
        document.getElementById('coordPreview').classList.add('hidden');
        document.getElementById('coordPreviewText').textContent = '';
        document.getElementById('coordMapsLink').classList.add('hidden');
        document.getElementById('regDescription').value = '';

        selectedSports = [];
        renderCourtQuantities();
        document.querySelectorAll('#operatingDays input[type="checkbox"]').forEach(function(cb) { cb.checked = true; });

        emailVerified = false;
        otpAttempts = 0;
        resendCount = 0;
        clearInterval(resendTimer);
        document.querySelectorAll('.otp-box').forEach(function(b) { b.value = ''; });
        document.getElementById('otpValidityHint').classList.add('hidden');

        hideError();
        goToRegistrationStep(1);
    }

    document.addEventListener('DOMContentLoaded', function() {
        initOwnerRegistrationDraft();
    });

    // Khôi phục từ bfcache (nút back/forward trình duyệt): chỉ đồng bộ lại trạng thái OTP,
    // KHÔNG gửi lại OTP, KHÔNG submit lại — dữ liệu form đã được bfcache giữ nguyên.
    window.addEventListener('pageshow', function(e) {
        if (e.persisted && currentStep > 1) {
            reconcileOtpState(currentStep, ownerDraftGetVal('regEmail'));
        }
    });
</script>

<!-- Custom Geolocation Modal -->
<div id="geoModal" class="hidden fixed inset-0 z-[8000] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 geo-animate-fade" style="font-family: var(--sans);">
  <style>
    @keyframes geoFadeIn { from { opacity: 0; } to { opacity: 1; } }
    @keyframes geoScaleUp { from { transform: scale(0.95); opacity: 0; } to { transform: scale(1); opacity: 1; } }
    .geo-animate-fade { animation: geoFadeIn 180ms ease-out forwards; }
    .geo-animate-scale { animation: geoScaleUp 240ms cubic-bezier(.16, 1, .3, 1) forwards; }
  </style>
  <div class="bg-[#1c1812] border border-white/10 rounded-3xl p-6 md:p-8 w-full max-w-md text-white shadow-2xl relative geo-animate-scale">
    <!-- Close button -->
    <button type="button" onclick="closeGeoModal()" class="absolute top-4 right-4 text-white/50 hover:text-white transition-all bg-transparent border-none cursor-pointer focus:outline-none">
      <span class="material-symbols-outlined text-2xl">close</span>
    </button>
    
    <div class="flex items-center gap-3 mb-4">
      <span class="material-symbols-outlined text-[#C9612F] text-3xl">location_on</span>
      <h3 class="font-serif text-xl font-medium tracking-wide">Nhập vị trí cơ sở</h3>
    </div>
    
    <p class="text-sm text-white/70 mb-6 leading-relaxed" style="font-family: var(--sans);">
      Dán tọa độ Google Map (VD: <code class="text-[#E08A4F]" style="font-family: var(--sans);">10.7626, 106.6601</code>) hoặc link bản đồ có dạng <code class="text-[#E08A4F]" style="font-family: var(--sans);">@vĩ_độ,kinh_độ</code> để tự động lấy địa chỉ.<br/>
      <span class="text-[#E08A4F]/80">Cách chính xác nhất:</span> mở Google Maps tại vị trí cơ sở, bấm giữ/click phải, copy tọa độ rồi dán vào đây.
    </p>
    
    <div class="space-y-4 mb-6">
      <div>
        <label class="block text-[11px] font-semibold tracking-wider uppercase text-white/50 mb-2" for="geoInput" style="font-family: var(--sans);">Tọa độ hoặc Link Google Map</label>
        <input type="text" id="geoInput" placeholder="Dán tọa độ hoặc link tại đây..." class="w-full px-4 py-3.5 border border-white/15 rounded-xl bg-black/30 text-white focus:outline-none focus:ring-2 focus:ring-[#C9612F]/40 focus:border-[#C9612F] transition-all placeholder:text-white/20 text-sm" style="font-family: var(--sans);" />
      </div>
    </div>
    
    <div class="flex flex-col gap-3">
      <button type="button" onclick="submitGeoInput()" class="pill w-full py-3.5 text-sm flex justify-center items-center gap-2 text-white bg-[#C9612F] hover:bg-[#E08A4F] transition-all rounded-full font-semibold border-none cursor-pointer" style="font-family: var(--sans);">
        <span class="material-symbols-outlined text-lg">travel_explore</span> Xác nhận & Tìm địa chỉ
      </button>
      <button type="button" onclick="useCurrentGps()" id="btnUseGps" class="w-full py-3 text-sm flex justify-center items-center gap-2 text-white/80 hover:text-white border border-white/20 hover:border-white/40 bg-white/5 hover:bg-white/10 transition-all rounded-full font-semibold cursor-pointer" style="font-family: var(--sans);">
        <span class="material-symbols-outlined text-lg">my_location</span> Lấy vị trí gần đúng hiện tại
      </button>
      <p class="text-xs text-white/40 text-center leading-relaxed px-1" style="font-family: var(--sans);">Lưu ý: Trên laptop/PC, vị trí có thể bị lệch. Để chính xác nhất, hãy copy tọa độ trực tiếp từ Google Maps.</p>
    </div>
  </div>
</div>

</body>
</html>
