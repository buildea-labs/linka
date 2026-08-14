

export function PriceCard() {
  return (
    <div style={{
      display: 'flex',
      flexDirection: 'column',
      padding: '40px 32px',
      borderRadius: 'var(--radius-xl, 24px)',
      background: 'var(--surface-card, #fff)',
      border: '1px solid var(--border-default, #e5e5e5)',
      boxSizing: 'border-box',
      width: '100%',
    }}>
      <p style={{ fontFamily: 'var(--font-mono, monospace)', fontSize: '13px', letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary, #666)', margin: '0 0 4px' }}>Linka Plus</p>
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'center', gap: '6px', margin: '12px 0 4px' }}>
        <span style={{ fontFamily: 'var(--font-mono, monospace)', fontSize: '40px', fontWeight: 700, letterSpacing: '-0.02em', color: 'var(--text-primary, #000)' }}>R$ 6,90</span>
        <span style={{ fontFamily: 'var(--font-mono, monospace)', fontSize: '14px', color: 'var(--text-secondary, #666)' }}>/ ano</span>
      </div>
      <p style={{ fontSize: '13px', color: 'var(--text-secondary, #666)', margin: '0 0 28px' }}>Compra única. Sem renovação automática.</p>
      
      <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', textAlign: 'left', marginBottom: '28px' }}>
        {[
          'Nenhum anúncio',
          'Histórico completo e comparação',
          'Assist para interpretar resultados',
          'Widget na tela de início'
        ].map((item, idx) => (
          <div key={idx} style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: 'var(--text-primary, #000)' }}>
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="var(--color-ink, #000)" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}>
              <path d="M4 12.5l5 5L20 6.5"></path>
            </svg>
            {item}
          </div>
        ))}
      </div>

      <a href="#baixar" onClick={(e) => { e.preventDefault(); /* App download logic here */ }} style={{
        display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '44px',
        padding: '0 22px', borderRadius: 'var(--radius, 8px)', background: 'var(--brand-accent, #007aff)',
        color: 'var(--text-on-accent, #fff)', fontFamily: 'var(--font-body, sans-serif)',
        fontSize: '15px', fontWeight: 600, textDecoration: 'none', boxSizing: 'border-box', width: '100%',
      }}>Baixar o app</a>
      <p style={{ fontSize: '12px', color: 'var(--text-secondary, #666)', margin: '14px 0 0' }}>O Free mede, mostra o resultado e permite repetir. Sem custo.</p>
    </div>
  );
}
