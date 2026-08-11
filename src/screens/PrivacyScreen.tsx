
export function PrivacyScreen() {
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '40px 24px 80px' }}>
      <div style={{ maxWidth: 720, width: '100%', textAlign: 'center' }}>
        <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 16px' }}>Privacidade & Termos de Uso</p>
        <h1 style={{ fontFamily: 'var(--font-display)', fontSize: 40, fontWeight: 700, letterSpacing: '-0.02em', lineHeight: 1.15, margin: '0 0 24px' }}>O que coletamos e o que você pode esperar do serviço.</h1>
        <p style={{ fontSize: 15, color: 'var(--text-secondary)', margin: '0 0 8px' }}>Última atualização: <b style={{ color: 'var(--text-primary)' }}>11 de agosto de 2026</b></p>
      </div>

      <div style={{ maxWidth: 720, width: '100%', marginTop: 56, textAlign: 'left' }}>
        <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--color-accent-warm)', margin: '0 0 20px' }}>Privacidade</p>

        <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, fontWeight: 600, margin: '0 0 10px' }}>Dados coletados</h2>
        <p style={{ fontSize: 15, lineHeight: 1.65, color: 'var(--text-secondary)', margin: '0 0 28px' }}>Cada teste registra apenas o necessário para calcular e exibir o resultado: velocidade de download e upload, ping, endereço IP (usado só para estimar a operadora e localização aproximada) e o servidor utilizado. Nenhum dado de navegação fora do teste é coletado.</p>

        <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, fontWeight: 600, margin: '0 0 10px' }}>Como usamos</h2>
        <p style={{ fontSize: 15, lineHeight: 1.65, color: 'var(--text-secondary)', margin: '0 0 28px' }}>Os resultados individuais não são vinculados a uma conta ou identidade. Usamos dados agregados e anônimos para relatórios de qualidade de rede e para melhorar a escolha de servidores.</p>

        <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, fontWeight: 600, margin: '0 0 10px' }}>Cookies</h2>
        <p style={{ fontSize: 15, lineHeight: 1.65, color: 'var(--text-secondary)', margin: '0 0 28px' }}>Usamos apenas um cookie técnico para lembrar a preferência de exibir ou não os detalhes da medição. Não usamos cookies de rastreamento publicitário próprios.</p>

        <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, fontWeight: 600, margin: '0 0 10px' }}>Compartilhamento com terceiros</h2>
        <p style={{ fontSize: 15, lineHeight: 1.65, color: 'var(--text-secondary)', margin: '0 0 44px' }}>O teste transfere dados diretamente com a rede da Cloudflare para medir a conexão. O espaço de publicidade reservado na tela de resultado é servido por um parceiro de anúncios, que pode aplicar sua própria política de cookies.</p>

        <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--color-accent-warm)', margin: '0 0 20px' }}>Termos de uso</p>

        <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, fontWeight: 600, margin: '0 0 10px' }}>Uso do serviço</h2>
        <p style={{ fontSize: 15, lineHeight: 1.65, color: 'var(--text-secondary)', margin: '0 0 28px' }}>O Linka Speedtest é oferecido gratuitamente, sem necessidade de cadastro. É permitido o uso pessoal e a automação razoável (scripts, monitoramento); uso que sobrecarregue deliberadamente o serviço pode ser bloqueado.</p>

        <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, fontWeight: 600, margin: '0 0 10px' }}>Precisão e isenção de responsabilidade</h2>
        <p style={{ fontSize: 15, lineHeight: 1.65, color: 'var(--text-secondary)', margin: '0 0 28px' }}>Os resultados refletem a conexão entre o dispositivo e o servidor de teste no momento da medição, e podem variar por rede local, distância do servidor e congestionamento. Não garantimos que o resultado corresponda ao plano contratado com a operadora.</p>

        <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, fontWeight: 600, margin: '0 0 10px' }}>Propriedade intelectual</h2>
        <p style={{ fontSize: 15, lineHeight: 1.65, color: 'var(--text-secondary)', margin: '0 0 28px' }}>A marca, o design e o código da interface pertencem à Linka Network Labs. Os resultados de cada medição pertencem a quem executou o teste.</p>

        <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, fontWeight: 600, margin: '0 0 10px' }}>Alterações</h2>
        <p style={{ fontSize: 15, lineHeight: 1.65, color: 'var(--text-secondary)', margin: 0 }}>Estes termos podem ser atualizados; a data no topo desta página sempre reflete a versão vigente.</p>
      </div>
    </div>
  );
}
