import { Card } from '../ui/components/core/Card';

export function AboutScreen() {
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '40px 24px 80px' }}>
      <div style={{ maxWidth: 720, width: '100%', textAlign: 'center' }}>
        <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 16px' }}>Sobre</p>
        <h1 style={{ fontFamily: 'var(--font-display)', fontSize: 40, fontWeight: 700, letterSpacing: '-0.02em', lineHeight: 1.15, margin: '0 0 24px' }}>Sua conexão. Sem distrações.</h1>
        <p style={{ fontSize: 17, lineHeight: 1.6, color: 'var(--text-secondary)', margin: 0 }}>Download, upload e latência. Sem cadastro.</p>
      </div>

      <div style={{ maxWidth: 720, width: '100%', marginTop: 64 }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 20 }}>
          <Card style={{ minHeight: 150 }}>
            <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 10px' }}>Direto</p>
            <p style={{ fontSize: 15, lineHeight: 1.55, color: 'var(--text-primary)', margin: 0 }}>Abra o Linka. A medição começa.</p>
          </Card>
          <Card style={{ minHeight: 150 }}>
            <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 10px' }}>Sem conta</p>
            <p style={{ fontSize: 15, lineHeight: 1.55, color: 'var(--text-primary)', margin: 0 }}>Você não precisa criar perfil para medir sua conexão.</p>
          </Card>
          <Card style={{ minHeight: 150 }}>
            <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 10px' }}>Gratuito</p>
            <p style={{ fontSize: 15, lineHeight: 1.55, color: 'var(--text-primary)', margin: 0 }}>Publicidade, quando exibida, aparece depois da medição.</p>
          </Card>
        </div>
      </div>
    </div>
  );
}