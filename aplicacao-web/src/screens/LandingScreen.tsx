import { useEffect, useRef, useState } from 'react';
import { ValueCard } from '../components/landing/ValueCard';
import { StepItem } from '../components/landing/StepItem';
import { Header } from '../ui/components/layout/Header';
import { Footer } from '../ui/components/layout/Footer';

export function LandingScreen() {
  const [revealed, setRevealed] = useState<Record<string, boolean>>({});
  
  const howRef = useRef<HTMLDivElement>(null);
  const featuresRef = useRef<HTMLDivElement>(null);
  const privacyRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    document.title = "Linka Speedtest - Medição direta, sem distrações";
    document.querySelector('meta[name="description"]')?.setAttribute('content', 'Linka é um SpeedTest minimalista e eficiente exclusivo do ecossistema Apple. Abre, mede e mostra o resultado de forma clara.');

    const keys = ['how', 'features', 'privacy'];
    const refs = { how: howRef, features: featuresRef, privacy: privacyRef };
    
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
        .centered-container { max-width: 860px; margin: 0 auto; width: 100%; box-sizing: border-box; padding: 0 24px 120px; text-align: center; }
        .section-block { padding: clamp(48px, 10vw, 120px) 0; text-align: left; }
        .hero-block { padding: clamp(80px, 15vw, 160px) 0 clamp(60px, 10vw, 100px); text-align: center; display: flex; flex-direction: column; alignItems: center; }
      `}</style>
      
      <Header />

      <main className="centered-container">
        {/* HERO SECTION */}
        <section className="hero-block">
          <div style={{ animation: 'linkaRise .8s cubic-bezier(.22,.61,.36,1) both' }}>
            <p style={{ fontFamily: 'var(--font-mono, monospace)', fontSize: '12px', letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-secondary, #666)', margin: '0 0 18px' }}>Linka Speedtest</p>
            <h1 style={{ fontFamily: 'var(--font-display, sans-serif)', fontSize: 'clamp(38px,6vw,64px)', fontWeight: 700, letterSpacing: '-0.02em', lineHeight: 1.1, margin: '0 auto 22px', textWrap: 'pretty', maxWidth: 700 }}>Sua conexão. Sem distrações.</h1>
            <p style={{ fontSize: '19px', lineHeight: 1.6, color: 'var(--text-secondary, #666)', margin: '0 auto 40px', maxWidth: 540, textWrap: 'pretty' }}>Download, upload e latência para o ecossistema Apple. Sem cadastro e sem configurações complicadas.</p>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '20px', flexWrap: 'wrap' }}>
              <a href="#como-funciona" style={{ fontSize: '16px', fontWeight: 600, color: 'var(--text-primary, #000)', textDecoration: 'none', padding: '12px 24px', borderRadius: '8px', background: 'var(--border-default, #e5e5e5)' }}>Ver como funciona</a>
            </div>
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
            <h2 style={{ fontFamily: 'var(--font-display, sans-serif)', fontSize: 'clamp(26px,3.4vw,34px)', fontWeight: 700, letterSpacing: '-0.015em', margin: '0 0 40px', textWrap: 'pretty' }}>Feito para o ecossistema Apple.</h2>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '16px', textAlign: 'left' }}>
              <ValueCard label="Medição">Um número, direto. O app mede sozinho quando abre.</ValueCard>
              <ValueCard label="Histórico">Seus testes organizados localmente por data.</ValueCard>
              <ValueCard label="Nativo">Construído com os padrões do iOS. Parece parte do sistema.</ValueCard>
            </div>
          </div>
        </section>

        {/* PRIVACY SECTION */}
        <section className="section-block">
          <div ref={privacyRef} style={{ ...revealStyle('privacy') }}>
            <p style={{ fontFamily: 'var(--font-mono, monospace)', fontSize: '12px', letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-secondary, #666)', margin: '0 0 16px' }}>Privacidade</p>
            <h2 style={{ fontFamily: 'var(--font-display, sans-serif)', fontSize: 'clamp(26px,3.4vw,34px)', fontWeight: 700, letterSpacing: '-0.015em', margin: '0 0 18px', textWrap: 'pretty' }}>Só coletamos o que o teste precisa.</h2>
            <p style={{ fontSize: '16px', lineHeight: 1.6, color: 'var(--text-secondary, #666)', margin: 0 }}>O Linka não exige conta de usuário para funcionar e não implementa painéis de rastreamento de terceiros.</p>
          </div>
        </section>
      </main>

      <Footer />
    </div>
  );
}
