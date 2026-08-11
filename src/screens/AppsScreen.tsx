import { Card } from '../ui/components/core/Card';

export function AppsScreen() {
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '40px 24px 80px' }}>
      <div style={{ maxWidth: 720, textAlign: 'center' }}>
        <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 16px' }}>Aplicativos</p>
        <h1 style={{ fontFamily: 'var(--font-display)', fontSize: 40, fontWeight: 700, letterSpacing: '-0.02em', lineHeight: 1.15, margin: '0 0 24px' }}>Linka em todos os seus dispositivos.</h1>
        <p style={{ fontSize: 17, lineHeight: 1.6, color: 'var(--text-secondary)', margin: 0 }}>Na Web agora. No ecossistema Apple em seguida.</p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: 20, maxWidth: 720, width: '100%', marginTop: 56 }}>
        <Card style={{ minHeight: 220 }}>
          <svg viewBox="0 0 220 120" style={{ width: '100%', height: 'auto', display: 'block', color: 'var(--color-ink)', marginBottom: 16 }} fill="none">
            <rect x="30" y="10" width="160" height="90" rx="6" stroke="currentColor" strokeWidth="2" />
            <line x1="30" y1="28" x2="190" y2="28" stroke="currentColor" strokeWidth="2" />
            <circle cx="40" cy="19" r="2" fill="currentColor" />
            <circle cx="48" cy="19" r="2" fill="currentColor" />
            <circle cx="56" cy="19" r="2" fill="currentColor" />
            <text x="110" y="70" textAnchor="middle" fontFamily="var(--font-mono)" fontSize="16" fill="currentColor" fontWeight="600">184,3</text>
          </svg>
          <p style={{ fontFamily: 'var(--font-mono)', fontSize: 11, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 8px' }}>Disponível agora</p>
          <p style={{ fontFamily: 'var(--font-display)', fontSize: 17, fontWeight: 600, margin: '0 0 6px' }}>Web</p>
          <p style={{ fontSize: 14, lineHeight: 1.55, color: 'var(--text-secondary)', margin: '0 0 14px' }}>Abra e meça direto no navegador. Sem instalação.</p>
          <a href="/" style={{ fontSize: 13, fontFamily: 'var(--font-mono)', textDecoration: 'none', color: 'var(--color-ink)', display: 'inline-flex', alignItems: 'center', gap: 4 }}>Abrir Linka →</a>
        </Card>

        <Card style={{ minHeight: 220 }} dashed={true}>
          <svg viewBox="0 0 220 120" style={{ width: '100%', height: 'auto', display: 'block', color: 'var(--color-ink)', marginBottom: 16, opacity: 0.7 }} fill="none">
            <rect x="82" y="8" width="56" height="104" rx="8" stroke="currentColor" strokeWidth="2" />
            <line x1="100" y1="16" x2="120" y2="16" stroke="currentColor" strokeWidth="2" />
            <text x="110" y="66" textAnchor="middle" fontFamily="var(--font-mono)" fontSize="13" fill="currentColor" fontWeight="600">41,2</text>
          </svg>
          <p style={{ fontFamily: 'var(--font-mono)', fontSize: 11, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 8px' }}>Em desenvolvimento</p>
          <p style={{ fontFamily: 'var(--font-display)', fontSize: 17, fontWeight: 600, margin: '0 0 6px' }}>iPhone e iPad</p>
          <p style={{ fontSize: 14, lineHeight: 1.55, color: 'var(--text-secondary)', margin: 0 }}>Uma experiência nativa criada para o ecossistema Apple.</p>
        </Card>
      </div>
    </div>
  );
}