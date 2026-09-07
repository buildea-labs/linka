import { Wordmark } from '../brand/Wordmark';

export function Footer() {
  return (
    <footer style={{ padding: '48px 24px 32px', borderTop: '1px solid var(--border-default, #e5e5e5)', display: 'flex', flexDirection: 'column', gap: '32px', fontSize: '13px', color: 'var(--text-secondary, #666)', maxWidth: 860, margin: '0 auto', width: '100%', boxSizing: 'border-box' }}>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '32px', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          <a href="/" aria-label="Linka Home" style={{ color: 'inherit', textDecoration: 'none', display: 'inline-block' }}>
            <Wordmark size="sm" color={undefined} dotColor={undefined} />
          </a>
          <span>Sua conexão. Sem distrações.</span>
        </div>
        <nav style={{ display: 'flex', gap: '24px', flexWrap: 'wrap' }} aria-label="Navegação de Rodapé">
          <a href="/sobre" style={{ color: 'inherit', textDecoration: 'none' }}>Sobre</a>
          <a href="/como-medimos" style={{ color: 'inherit', textDecoration: 'none' }}>Como Medimos</a>
          <a href="/privacidade" style={{ color: 'inherit', textDecoration: 'none' }}>Privacidade</a>
          <a href="/termos" style={{ color: 'inherit', textDecoration: 'none' }}>Termos</a>
          <a href="/suporte" style={{ color: 'inherit', textDecoration: 'none' }}>Suporte</a>
        </nav>
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid var(--border-default, #e5e5e5)', paddingTop: '24px' }}>
        <span>© {new Date().getFullYear()} Linka Speedtest.</span>
      </div>
    </footer>
  );
}
