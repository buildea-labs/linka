import { Card } from '../ui/components/core/Card';

export function AppsScreen() {
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '40px 24px 80px' }}>
      <div style={{ maxWidth: 720, textAlign: 'center' }}>
        <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 16px' }}>Aplicativos</p>
        <h1 style={{ fontFamily: 'var(--font-display)', fontSize: 40, fontWeight: 700, letterSpacing: '-0.02em', lineHeight: 1.15, margin: '0 0 24px' }}>Uma medição, disponível onde você estiver.</h1>
        <p style={{ fontSize: 17, lineHeight: 1.6, color: 'var(--text-secondary)', margin: 0 }}>O Linka Speedtest roda direto no navegador, sem instalação, em qualquer desktop. O mesmo fluxo minimalista está chegando também ao iPhone.</p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: 20, maxWidth: 720, width: '100%', marginTop: 56 }}>
        <Card style={{ minHeight: 220 }}>
          <svg viewBox="0 0 220 120" style={{ width: '100%', height: 'auto', display: 'block', color: 'var(--color-ink)', marginBottom: 16 }} fill="none">
            <rect x="30" y="10" width="160" height="90" rx="6" stroke="currentColor" strokeWidth="2"></rect>
            <line x1="30" y1="28" x2="190" y2="28" stroke="currentColor" strokeWidth="2"></line>
            <circle cx="40" cy="19" r="2" fill="currentColor"></circle>
            <circle cx="48" cy="19" r="2" fill="currentColor"></circle>
            <circle cx="56" cy="19" r="2" fill="currentColor"></circle>
            <text x="110" y="70" textAnchor="middle" fontFamily="var(--font-mono)" fontSize="16" fill="currentColor" fontWeight="600">184,3</text>
          </svg>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <span style={{ width: 6, height: 6, borderRadius: '50%', background: 'var(--color-accent-warm)', display: 'inline-block' }}></span>
            <p style={{ fontFamily: 'var(--font-mono)', fontSize: 11, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: 0 }}>Disponível agora</p>
          </div>
          <p style={{ fontFamily: 'var(--font-display)', fontSize: 17, fontWeight: 600, margin: '0 0 6px' }}>Web (desktop)</p>
          <p style={{ fontSize: 14, lineHeight: 1.55, color: 'var(--text-secondary)', margin: '0 0 14px' }}>Abre no navegador, sem instalação, sem cadastro. É o Linka Speedtest completo.</p>
          <a href="/" style={{ fontSize: 13, fontFamily: 'var(--font-mono)', textDecoration: 'none', color: 'var(--color-ink)', display: 'inline-flex', alignItems: 'center', gap: 4 }}>Abrir app →</a>
        </Card>

        <Card style={{ minHeight: 220 }} dashed={true}>
          <svg viewBox="0 0 220 120" style={{ width: '100%', height: 'auto', display: 'block', color: 'var(--color-ink)', marginBottom: 16, opacity: 0.7 }} fill="none">
            <rect x="82" y="8" width="56" height="104" rx="8" stroke="currentColor" strokeWidth="2"></rect>
            <line x1="100" y1="16" x2="120" y2="16" stroke="currentColor" strokeWidth="2"></line>
            <text x="110" y="66" textAnchor="middle" fontFamily="var(--font-mono)" fontSize="13" fill="currentColor" fontWeight="600">41,2</text>
          </svg>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <span style={{ width: 6, height: 6, borderRadius: '50%', background: 'var(--color-accent-warm)', display: 'inline-block' }}></span>
            <p style={{ fontFamily: 'var(--font-mono)', fontSize: 11, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: 0 }}>Em desenvolvimento</p>
          </div>
          <p style={{ fontFamily: 'var(--font-display)', fontSize: 17, fontWeight: 600, margin: '0 0 6px' }}>iOS</p>
          <p style={{ fontSize: 14, lineHeight: 1.55, color: 'var(--text-secondary)', margin: '0 0 14px' }}>Um app universal para iPhone e iPad, com o mesmo número único e o mesmo fluxo em três fases. Ainda sem data de lançamento.</p>
          <span style={{ fontSize: 13, fontFamily: 'var(--font-mono)', color: 'var(--color-ink)', display: 'inline-flex', alignItems: 'center', gap: 4, opacity: 0.5 }}>Ver protótipo →</span>
        </Card>
      </div>

      <div style={{ maxWidth: 760, width: '100%', marginTop: 64, textAlign: 'center' }}>
        <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 16px' }}>Comparado ao mercado</p>
        <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 26, fontWeight: 700, letterSpacing: '-0.015em', margin: '0 0 32px' }}>Menos tela, mais medição.</h2>
        <div style={{ border: '1px solid var(--border-default)', borderRadius: 'var(--radius-lg)', overflow: 'hidden', textAlign: 'left' }}>
          
          <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr 1fr', background: 'var(--color-fg-soft)' }}>
            <div style={{ padding: '14px 16px', fontFamily: 'var(--font-mono)', fontSize: 11, letterSpacing: '0.06em', textTransform: 'uppercase', color: 'var(--text-secondary)' }}></div>
            <div style={{ padding: '14px 16px', fontFamily: 'var(--font-mono)', fontSize: 11, letterSpacing: '0.06em', textTransform: 'uppercase', color: 'var(--color-ink)', fontWeight: 600 }}>Linka Speedtest</div>
            <div style={{ padding: '14px 16px', fontFamily: 'var(--font-mono)', fontSize: 11, letterSpacing: '0.06em', textTransform: 'uppercase', color: 'var(--text-secondary)' }}>Outros serviços</div>
          </div>
          
          <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr 1fr', borderTop: '1px solid var(--border-default)', fontSize: 14 }}>
            <div style={{ padding: '14px 16px', color: 'var(--text-secondary)' }}>Início da medição</div>
            <div style={{ padding: '14px 16px' }}>Automático, sem clique</div>
            <div style={{ padding: '14px 16px', color: 'var(--text-secondary)' }}>Requer clique em "Iniciar"</div>
          </div>
          
          <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr 1fr', borderTop: '1px solid var(--border-default)', fontSize: 14 }}>
            <div style={{ padding: '14px 16px', color: 'var(--text-secondary)' }}>Anúncios</div>
            <div style={{ padding: '14px 16px' }}>Um espaço reservado, discreto</div>
            <div style={{ padding: '14px 16px', color: 'var(--text-secondary)' }}>Banners e pop-ups em tela cheia</div>
          </div>
          
          <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr 1fr', borderTop: '1px solid var(--border-default)', fontSize: 14 }}>
            <div style={{ padding: '14px 16px', color: 'var(--text-secondary)' }}>Dados coletados</div>
            <div style={{ padding: '14px 16px' }}>Só o necessário para o resultado</div>
            <div style={{ padding: '14px 16px', color: 'var(--text-secondary)' }}>Frequentemente vinculados a conta e perfil</div>
          </div>
          
          <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr 1fr', borderTop: '1px solid var(--border-default)', fontSize: 14 }}>
            <div style={{ padding: '14px 16px', color: 'var(--text-secondary)' }}>Interface</div>
            <div style={{ padding: '14px 16px' }}>Um número, sem distrações</div>
            <div style={{ padding: '14px 16px', color: 'var(--text-secondary)' }}>Gráficos, rankings e comparações</div>
          </div>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 20, maxWidth: 900, width: '100%', marginTop: 64 }}>
        <Card style={{ minHeight: 150 }}>
          <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 10px' }}>Privacidade</p>
          <p style={{ fontSize: 15, lineHeight: 1.55, color: 'var(--text-primary)', margin: 0 }}>Nenhum resultado é vinculado a conta ou identidade em nenhuma das plataformas.</p>
        </Card>
        <Card style={{ minHeight: 150 }}>
          <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 10px' }}>Qualidade</p>
          <p style={{ fontSize: 15, lineHeight: 1.55, color: 'var(--text-primary)', margin: 0 }}>Mesmo método de medição em toda plataforma, contra a mesma rede de servidores.</p>
        </Card>
        <Card style={{ minHeight: 150 }}>
          <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 10px' }}>Velocidade</p>
          <p style={{ fontSize: 15, lineHeight: 1.55, color: 'var(--text-primary)', margin: 0 }}>Resultado em segundos, sem etapas de carregamento entre as fases.</p>
        </Card>
      </div>

      <div style={{ maxWidth: 640, width: '100%', marginTop: 64, textAlign: 'center' }}>
        <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 16px' }}>Modelo minimalista</p>
        <p style={{ fontSize: 17, lineHeight: 1.6, color: 'var(--text-secondary)', margin: 0 }}>Cada plataforma segue a mesma regra: um número, três fases, um resultado. Sem contas, sem histórico salvo, sem elementos que não ajudem a responder a única pergunta que importa, qual é a velocidade agora.</p>
      </div>
    </div>
  );
}
