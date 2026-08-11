export function PrivacyScreen() {
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '40px 24px 80px' }}>
      <div style={{ maxWidth: 720, width: '100%', textAlign: 'center' }}>
        <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 16px' }}>Privacidade & Termos</p>
        <h1 style={{ fontFamily: 'var(--font-display)', fontSize: 40, fontWeight: 700, letterSpacing: '-0.02em', lineHeight: 1.15, margin: '0 0 24px' }}>Privacidade, sem complicação.</h1>
        <p style={{ fontSize: 17, lineHeight: 1.6, color: 'var(--text-secondary)', margin: '0 0 8px' }}>O Linka funciona sem conta. Coletamos apenas os dados necessários para realizar a medição e operar o serviço.</p>
        <p style={{ fontSize: 13, color: 'var(--text-secondary)', margin: 0 }}>Atualizado em 11 de agosto de 2026.</p>
      </div>

      <div style={{ maxWidth: 720, width: '100%', marginTop: 56, textAlign: 'left' }}>
        <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--color-accent-warm)', margin: '0 0 20px' }}>Privacidade</p>

        <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, fontWeight: 600, margin: '0 0 10px' }}>Dados da medição</h2>
        <p style={{ fontSize: 15, lineHeight: 1.65, color: 'var(--text-secondary)', margin: '0 0 28px' }}>Durante o teste, o Linka processa métricas como download, upload e latência. Informações técnicas necessárias à conexão com a infraestrutura de teste também podem ser processadas durante a execução.</p>

        <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, fontWeight: 600, margin: '0 0 10px' }}>Sem conta</h2>
        <p style={{ fontSize: 15, lineHeight: 1.65, color: 'var(--text-secondary)', margin: '0 0 28px' }}>Você não precisa criar perfil ou fazer login para medir sua conexão.</p>

        <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, fontWeight: 600, margin: '0 0 10px' }}>Terceiros</h2>
        <p style={{ fontSize: 15, lineHeight: 1.65, color: 'var(--text-secondary)', margin: '0 0 44px' }}>A medição pode usar infraestrutura de terceiros, como a rede da Cloudflare. Publicidade, quando ativada, pode ser fornecida por um parceiro com política própria de privacidade.</p>

        <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--color-accent-warm)', margin: '0 0 20px' }}>Termos de uso</p>

        <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, fontWeight: 600, margin: '0 0 10px' }}>Uso do serviço</h2>
        <p style={{ fontSize: 15, lineHeight: 1.65, color: 'var(--text-secondary)', margin: '0 0 28px' }}>O Linka SpeedTest é oferecido gratuitamente e sem cadastro. Uso que sobrecarregue deliberadamente o serviço pode ser limitado ou bloqueado.</p>

        <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, fontWeight: 600, margin: '0 0 10px' }}>Sobre os resultados</h2>
        <p style={{ fontSize: 15, lineHeight: 1.65, color: 'var(--text-secondary)', margin: '0 0 28px' }}>A medição representa a conexão entre o dispositivo e a infraestrutura de teste naquele momento. Rede local, distância, congestionamento e outras condições podem alterar o resultado.</p>

        <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, fontWeight: 600, margin: '0 0 10px' }}>Propriedade intelectual</h2>
        <p style={{ fontSize: 15, lineHeight: 1.65, color: 'var(--text-secondary)', margin: '0 0 28px' }}>A marca, o design e a interface do Linka pertencem à Buildea Labs, observadas as licenças aplicáveis aos componentes de terceiros.</p>

        <h2 style={{ fontFamily: 'var(--font-display)', fontSize: 20, fontWeight: 600, margin: '0 0 10px' }}>Alterações</h2>
        <p style={{ fontSize: 15, lineHeight: 1.65, color: 'var(--text-secondary)', margin: 0 }}>Esta página pode ser atualizada quando o serviço mudar. A data acima identifica a versão publicada.</p>
      </div>
    </div>
  );
}