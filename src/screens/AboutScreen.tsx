import { Card } from '../ui/components/core/Card';

export function AboutScreen() {
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '40px 24px 80px' }}>
      <div style={{ maxWidth: 720, width: '100%', textAlign: 'center' }}>
        <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 16px' }}>Sobre Nós</p>
        <h1 style={{ fontFamily: 'var(--font-display)', fontSize: 40, fontWeight: 700, letterSpacing: '-0.02em', lineHeight: 1.15, margin: '0 0 24px' }}>Medir a internet não precisa ser feio.</h1>
        <p style={{ fontSize: 17, lineHeight: 1.6, color: 'var(--text-secondary)', margin: 0 }}>Nós queríamos apenas ver um número na tela sem sermos bombardeados por distrações. Como não achamos, resolvemos criar o nosso.</p>
      </div>

      <div style={{ maxWidth: 720, width: '100%', marginTop: 64 }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 20 }}>
          <Card style={{ minHeight: 180 }}>
            <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 10px' }}>Simples e leve</p>
            <p style={{ fontSize: 15, lineHeight: 1.55, color: 'var(--text-primary)', margin: 0 }}>Sem interfaces poluídas ou gráficos confusos. Apenas uma tela limpa, indo direto ao ponto para entregar o resultado em segundos.</p>
          </Card>
          <Card style={{ minHeight: 180 }}>
            <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 10px' }}>Privacidade real</p>
            <p style={{ fontSize: 15, lineHeight: 1.55, color: 'var(--text-primary)', margin: 0 }}>Seu teste é apenas seu. Não criamos perfis de usuário, não pedimos login e não atrelamos a medição à sua identidade.</p>
          </Card>
          <Card style={{ minHeight: 180 }}>
            <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 10px' }}>E as contas?</p>
            <p style={{ fontSize: 15, lineHeight: 1.55, color: 'var(--text-primary)', margin: 0 }}>Temos um espaço reservado para anúncios no final do teste para ajudar a pagar os servidores, mas sempre de forma discreta e sem atrapalhar a sua experiência.</p>
          </Card>
        </div>
      </div>
    </div>
  );
}
