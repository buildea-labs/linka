import React, { useEffect, useRef, useState } from 'react';
import { IOSDevice } from '../components/landing/IOSDevice';
import { ValueCard } from '../components/landing/ValueCard';
import { StepItem } from '../components/landing/StepItem';
import { PriceCard } from '../components/landing/PriceCard';
import { Wordmark } from '../ui/components/brand/Wordmark';
import { MockSpeedTest } from '../components/landing/MockSpeedTest';

const PhoneMockup = () => (
  <div style={{ width: 310, height: 633, position: 'relative' }}>
    <div style={{ transform: 'scale(0.68)', transformOrigin: 'top center', width: 402, height: 874, position: 'absolute', top: 0, left: '50%', marginLeft: -201 }}>
      <IOSDevice dark={true}>
        <MockSpeedTest />
      </IOSDevice>
    </div>
  </div>
);

export function LandingScreen() {
  const [revealed, setRevealed] = useState<Record<string, boolean>>({});
  
  const howRef = useRef<HTMLDivElement>(null);
  const featuresRef = useRef<HTMLDivElement>(null);
  const privacyRef = useRef<HTMLDivElement>(null);
  const priceRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const keys = ['how', 'features', 'privacy', 'price'];
    const refs = { how: howRef, features: featuresRef, privacy: privacyRef, price: priceRef };
    
    const obs = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          const key = keys.find((k) => refs[k as keyof typeof refs].current === entry.target);
          if (key) {
            setRevealed((s) => ({ ...s, [key]: true }));
            obs.unobserve(entry.target);
          }
        }
      });
    }, { threshold: 0.15 });

    keys.forEach((k) => { 
      const currentRef = refs[k as keyof typeof refs].current;
      if (currentRef) obs.observe(currentRef); 
    });

    return () => obs.disconnect();
  }, []);

  const revealStyle = (key: string): React.CSSProperties => {
    const on = !!revealed[key];
    return {
      opacity: on ? 1 : 0,
      transform: on ? 'none' : 'translateY(28px)',
      transition: 'opacity .7s cubic-bezier(.22,.61,.36,1), transform .7s cubic-bezier(.22,.61,.36,1)',
    };
  };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', fontFamily: 'var(--font-body, sans-serif)', color: 'var(--text-primary, #000)', background: 'var(--surface-page, #f9f9f9)' }}>
      <style>{`
        @keyframes linkaRise { from { opacity: 0; transform: translateY(18px); } to { opacity: 1; transform: none; } }
        .desktop-split { display: flex; max-width: 1120px; margin: 0 auto; width: 100%; box-sizing: border-box; position: relative; }
        .content-col { flex: 1; padding: 0 24px 120px; max-width: 680px; }
        .phone-col { display: none; }
        .mobile-phone { display: flex; justify-content: center; margin: 48px 0; animation: linkaRise .9s cubic-bezier(.22,.61,.36,1) both; animation-delay: 120ms; }
        .section-block { padding: clamp(48px, 10vw, 120px) 0; }
        
        @media (min-width: 960px) {
          .phone-col { 
            display: flex; flex: 0 0 320px; position: sticky; top: 0; 
            height: 100vh; align-items: center; justify-content: center; 
            margin-right: 24px;
          }
          .mobile-phone { display: none; }
          .content-col { padding-right: 60px; }
        }
      `}</style>
      
      <header style={{ padding: '22px 24px', maxWidth: 1120, margin: '0 auto', width: '100%', boxSizing: 'border-box' }}>
        <Wordmark size="md" color={undefined} dotColor={undefined} />
      </header>

      <main className="desktop-split">
        <div className="content-col">
          {/* HERO SECTION */}
          <section className="section-block" style={{ paddingTop: 'clamp(40px, 8vw, 80px)' }}>
            <div style={{ animation: 'linkaRise .8s cubic-bezier(.22,.61,.36,1) both' }}>
              <p style={{ fontFamily: 'var(--font-mono, monospace)', fontSize: '12px', letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-secondary, #666)', margin: '0 0 18px' }}>Linka Speedtest</p>
              <h1 style={{ fontFamily: 'var(--font-display, sans-serif)', fontSize: 'clamp(34px,5vw,52px)', fontWeight: 700, letterSpacing: '-0.02em', lineHeight: 1.1, margin: '0 0 22px', textWrap: 'pretty' }}>Sua internet, medida com precisão.</h1>
              <p style={{ fontSize: '17px', lineHeight: 1.6, color: 'var(--text-secondary, #666)', margin: '0 0 32px', maxWidth: 460, textWrap: 'pretty' }}>Um app para iPhone. Mostra download, upload e ping. Abre e mede.</p>
              <div style={{ display: 'flex', alignItems: 'center', gap: '20px', flexWrap: 'wrap' }}>
                <a href="#apps" onClick={(e) => e.preventDefault()} style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', minHeight: '44px', padding: '0 22px', borderRadius: 'var(--radius, 8px)', background: 'var(--brand-accent, #007aff)', color: 'var(--text-on-accent, #fff)', fontFamily: 'var(--font-body, sans-serif)', fontSize: '15px', fontWeight: 600, textDecoration: 'none', boxSizing: 'border-box' }}>Baixar o app</a>
                <a href="#como-funciona" style={{ fontSize: '15px', fontWeight: 600, color: 'var(--text-primary, #000)', textDecoration: 'none' }}>Ver como funciona</a>
              </div>
            </div>
            
            {/* MOBILE ONLY MOCKUP */}
            <div className="mobile-phone">
              <PhoneMockup />
            </div>
          </section>

          {/* HOW IT WORKS SECTION */}
          <section id="como-funciona" className="section-block">
            <div ref={howRef} style={{ ...revealStyle('how') }}>
              <p style={{ fontFamily: 'var(--font-mono, monospace)', fontSize: '12px', letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-secondary, #666)', margin: '0 0 16px' }}>Como funciona</p>
              <h2 style={{ fontFamily: 'var(--font-display, sans-serif)', fontSize: 'clamp(26px,3.4vw,34px)', fontWeight: 700, letterSpacing: '-0.015em', margin: '0 0 18px', textWrap: 'pretty' }}>Três fases, um servidor próximo.</h2>
              <p style={{ fontSize: '16px', lineHeight: 1.6, color: 'var(--text-secondary, #666)', margin: '0 0 40px' }}>O teste mede sua conexão de verdade, contra o servidor mais próximo disponível.</p>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                <StepItem number="01" label="Conexão">Mede o tempo até o servidor mais próximo. O ping.</StepItem>
                <StepItem number="02" label="Download">Baixa dados reais por alguns segundos e mostra a velocidade.</StepItem>
                <StepItem number="03" label="Upload">Envia dados até a velocidade se estabilizar.</StepItem>
              </div>
            </div>
          </section>

          {/* FEATURES SECTION */}
          <section className="section-block">
            <div ref={featuresRef} style={{ ...revealStyle('features') }}>
              <p style={{ fontFamily: 'var(--font-mono, monospace)', fontSize: '12px', letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-secondary, #666)', margin: '0 0 16px' }}>Funcionalidades</p>
              <h2 style={{ fontFamily: 'var(--font-display, sans-serif)', fontSize: 'clamp(26px,3.4vw,34px)', fontWeight: 700, letterSpacing: '-0.015em', margin: '0 0 40px', textWrap: 'pretty' }}>Feito para parecer parte do iPhone.</h2>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '16px' }}>
                <ValueCard label="Medição">Um número, direto. O app mede sozinho quando abre.</ValueCard>
                <ValueCard label="Histórico">Seus testes organizados por data. Sem gráfico, sem dashboard.</ValueCard>
                <ValueCard label="Assist">Pergunte sobre qualquer resultado. As respostas usam os seus dados.</ValueCard>
                <ValueCard label="Widget">Sua última medição na tela de início do iPhone.</ValueCard>
                <ValueCard label="Siri">Diga "testar minha internet". O Linka responde.</ValueCard>
                <ValueCard label="Nativo">Construído com os padrões do iOS. Parece parte do sistema.</ValueCard>
              </div>
            </div>
          </section>

          {/* PRIVACY SECTION */}
          <section className="section-block">
            <div ref={privacyRef} style={{ ...revealStyle('privacy') }}>
              <p style={{ fontFamily: 'var(--font-mono, monospace)', fontSize: '12px', letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-secondary, #666)', margin: '0 0 16px' }}>Privacidade</p>
              <h2 style={{ fontFamily: 'var(--font-display, sans-serif)', fontSize: 'clamp(26px,3.4vw,34px)', fontWeight: 700, letterSpacing: '-0.015em', margin: '0 0 18px', textWrap: 'pretty' }}>Só coletamos o que o teste precisa.</h2>
              <p style={{ fontSize: '16px', lineHeight: 1.6, color: 'var(--text-secondary, #666)', margin: 0 }}>Sem venda de dados. Sem rastreamento além do necessário para medir sua conexão. O rastreamento para anúncios é opcional e pode ser recusado.</p>
            </div>
          </section>

          {/* PRICING SECTION */}
          <section id="preco" className="section-block">
            <div ref={priceRef} style={{ ...revealStyle('price') }}>
              <p style={{ fontFamily: 'var(--font-mono, monospace)', fontSize: '12px', letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-secondary, #666)', margin: '0 0 16px' }}>Preço</p>
              <h2 style={{ fontFamily: 'var(--font-display, sans-serif)', fontSize: 'clamp(26px,3.4vw,34px)', fontWeight: 700, letterSpacing: '-0.015em', margin: '0 0 32px' }}>Um preço. Um ano.</h2>
              <PriceCard />
            </div>
          </section>
        </div>

        {/* STICKY MOCKUP COL FOR DESKTOP */}
        <div className="phone-col">
          <PhoneMockup />
        </div>
      </main>

      {/* FOOTER */}
      <footer style={{ padding: '20px 24px', borderTop: '1px solid var(--border-default, #e5e5e5)', display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontSize: '12px', color: 'var(--text-secondary, #666)', gap: '16px', flexWrap: 'wrap', maxWidth: 1120, margin: '0 auto', width: '100%', boxSizing: 'border-box' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <Wordmark size="sm" color={undefined} dotColor={undefined} />
          <span>© 2026 Linka Speedtest</span>
        </div>
        <span>Meça sua internet em segundos.</span>
      </footer>
    </div>
  );
}
