import { useEffect } from 'react';
import { Header } from '../ui/components/layout/Header';
import { Footer } from '../ui/components/layout/Footer';

export function NotFoundScreen() {
  useEffect(() => {
    document.title = "Página não encontrada - Linka Speedtest";
  }, []);

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', fontFamily: 'var(--font-body, sans-serif)', color: 'var(--text-primary, #000)', background: 'var(--surface-page, #f9f9f9)' }}>
      <style>{`
        @keyframes linkaRise { from { opacity: 0; transform: translateY(18px); } to { opacity: 1; transform: none; } }
        .centered-container { max-width: 860px; margin: 0 auto; width: 100%; box-sizing: border-box; padding: 0 24px 120px; text-align: left; }
        .hero-block { padding: clamp(80px, 15vw, 120px) 0 clamp(40px, 8vw, 60px); text-align: left; }
      `}</style>
      <Header />
      <main className="centered-container" style={{ flex: 1 }}>
        <section className="hero-block">
          <div style={{ animation: 'linkaRise .8s cubic-bezier(.22,.61,.36,1) both' }}>
            <h1 style={{ fontFamily: 'var(--font-display, sans-serif)', fontSize: 'clamp(34px, 5.5vw, 56px)', fontWeight: 700, letterSpacing: '-0.02em', lineHeight: 1.1, margin: '0 0 24px', textWrap: 'pretty' }}>Página não encontrada.</h1>
            <p style={{ fontSize: '19px', lineHeight: 1.6, color: 'var(--text-secondary, #666)', margin: '0 0 48px', maxWidth: 640 }}>A URL acessada não existe ou foi movida.</p>
            <a href="/" style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', minHeight: 44, padding: '0 24px', borderRadius: 8, background: 'var(--border-default, #e5e5e5)', color: 'var(--text-primary, #000)', fontSize: 16, fontWeight: 600, textDecoration: 'none' }}>Voltar ao início</a>
          </div>
        </section>
      </main>
      <Footer />
    </div>
  );
}
