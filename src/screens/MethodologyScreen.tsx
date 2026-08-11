import { Card } from '../ui/components/core/Card';

export function MethodologyScreen() {
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '40px 24px 80px' }}>
      <div style={{ maxWidth: 720, textAlign: 'center' }}>
        <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 16px' }}>Como medimos</p>
        <h1 style={{ fontFamily: 'var(--font-display)', fontSize: 40, fontWeight: 700, letterSpacing: '-0.02em', lineHeight: 1.15, margin: '0 0 24px' }}>Uma medição simples por fora. Cuidadosa por dentro.</h1>
        <p style={{ fontSize: 17, lineHeight: 1.6, color: 'var(--text-secondary)', margin: 0 }}>O Linka mede latência, download e upload transferindo dados reais entre seu dispositivo e a infraestrutura de teste.</p>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 16, maxWidth: 720, width: '100%', marginTop: 56 }}>
        <Card style={{ minHeight: 110 }}>
          <div style={{ display: 'flex', gap: 20, alignItems: 'flex-start', textAlign: 'left' }}>
            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--text-secondary)', minWidth: 20 }}>01</span>
            <div>
              <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 8px' }}>Ping</p>
              <p style={{ fontSize: 15, lineHeight: 1.55, color: 'var(--text-primary)', margin: 0 }}>Mede quanto tempo os dados levam para ir até o servidor e voltar.</p>
            </div>
          </div>
        </Card>

        <Card style={{ minHeight: 110 }}>
          <div style={{ display: 'flex', gap: 20, alignItems: 'flex-start', textAlign: 'left' }}>
            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--text-secondary)', minWidth: 20 }}>02</span>
            <div>
              <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 8px' }}>Download</p>
              <p style={{ fontSize: 15, lineHeight: 1.55, color: 'var(--text-primary)', margin: 0 }}>Mede a velocidade com que seu dispositivo recebe dados da internet.</p>
            </div>
          </div>
        </Card>

        <Card style={{ minHeight: 110 }}>
          <div style={{ display: 'flex', gap: 20, alignItems: 'flex-start', textAlign: 'left' }}>
            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--text-secondary)', minWidth: 20 }}>03</span>
            <div>
              <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 8px' }}>Upload</p>
              <p style={{ fontSize: 15, lineHeight: 1.55, color: 'var(--text-primary)', margin: 0 }}>Mede a velocidade com que seu dispositivo envia dados para a internet.</p>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}