import { Card } from '../ui/components/core/Card';
import { DetailsDisclosure } from '../ui/components/speedtest/DetailsDisclosure';

export function MethodologyScreen() {
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '40px 24px 80px' }}>
      <div style={{ maxWidth: 720, textAlign: 'center' }}>
        <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 16px' }}>Como medimos</p>
        <h1 style={{ fontFamily: 'var(--font-display)', fontSize: 40, fontWeight: 700, letterSpacing: '-0.02em', lineHeight: 1.15, margin: '0 0 24px' }}>Três fases, um servidor próximo, sem estimativas.</h1>
        <p style={{ fontSize: 17, lineHeight: 1.6, color: 'var(--text-secondary)', margin: 0 }}>O teste roda inteiramente no navegador. Nenhuma etapa é simulada: cada fase transfere dados reais contra o servidor mais próximo disponível no momento.</p>
      </div>

      <div style={{ maxWidth: 900, width: '100%', marginTop: 56 }}>
        <Card style={{ minHeight: 260 }}>
          <svg viewBox="0 0 900 220" style={{ width: '100%', height: 'auto', display: 'block', color: 'var(--color-ink)' }} fill="none">
            {/* house */}
            <path d="M40 140 V90 L95 55 L150 90 V140 Z" stroke="currentColor" strokeWidth="2" strokeLinejoin="round"></path>
            {/* desktop inside house */}
            <rect x="60" y="100" width="26" height="18" rx="2" stroke="currentColor" strokeWidth="2"></rect>
            <line x1="73" y1="118" x2="73" y2="126" stroke="currentColor" strokeWidth="2"></line>
            <line x1="64" y1="126" x2="82" y2="126" stroke="currentColor" strokeWidth="2"></line>
            {/* phone inside house */}
            <rect x="108" y="98" width="16" height="26" rx="3" stroke="currentColor" strokeWidth="2"></rect>
            <line x1="112" y1="118" x2="120" y2="118" stroke="currentColor" strokeWidth="2"></line>
            {/* wifi arcs phone -> router (wireless) */}
            <path d="M118 132 q8 14 0 28" stroke="currentColor" strokeWidth="1.6" opacity="0.55"></path>
            <path d="M124 128 q16 20 0 40" stroke="currentColor" strokeWidth="1.6" opacity="0.55"></path>
            {/* wired line desktop -> router (physical) */}
            <path d="M73 126 V148 H270 V150" stroke="currentColor" strokeWidth="2" fill="none"></path>
            {/* router */}
            <rect x="256" y="150" width="44" height="20" rx="3" stroke="currentColor" strokeWidth="2"></rect>
            <line x1="264" y1="150" x2="258" y2="132" stroke="currentColor" strokeWidth="2"></line>
            <line x1="292" y1="150" x2="298" y2="132" stroke="currentColor" strokeWidth="2"></line>
            <circle cx="264" cy="160" r="2" fill="currentColor"></circle>
            <circle cx="278" cy="160" r="2" fill="currentColor"></circle>
            {/* street cable, router -> server */}
            <path id="cablePath" d="M278 170 V195 H820 V150" stroke="currentColor" strokeWidth="2" strokeDasharray="6 6" opacity="0.6"></path>
            {/* server rack */}
            <rect x="796" y="70" width="48" height="80" rx="4" stroke="currentColor" strokeWidth="2"></rect>
            <line x1="804" y1="86" x2="836" y2="86" stroke="currentColor" strokeWidth="2"></line>
            <line x1="804" y1="104" x2="836" y2="104" stroke="currentColor" strokeWidth="2"></line>
            <line x1="804" y1="122" x2="836" y2="122" stroke="currentColor" strokeWidth="2"></line>
            <circle cx="830" cy="140" r="3" fill="var(--color-accent-warm)"></circle>
            {/* moving data pulse */}
            <circle r="4" fill="var(--color-accent-warm)">
              <animateMotion dur="4s" repeatCount="indefinite" keyPoints="0;1" keyTimes="0;1" calcMode="linear">
                <mpath href="#cablePath"></mpath>
              </animateMotion>
            </circle>
            <circle cx="73" cy="126" r="3" fill="var(--color-accent-warm)">
              <animate attributeName="opacity" values="1;0.2;1" dur="1.6s" repeatCount="indefinite"></animate>
            </circle>
            <text x="95" y="185" textAnchor="middle" fontFamily="var(--font-mono)" fontSize="11" fill="var(--text-secondary)">Casa</text>
            <text x="278" y="188" textAnchor="middle" fontFamily="var(--font-mono)" fontSize="11" fill="var(--text-secondary)">Roteador</text>
            <text x="550" y="210" textAnchor="middle" fontFamily="var(--font-mono)" fontSize="11" fill="var(--text-secondary)" letterSpacing="1">Rede – cabo até o servidor</text>
            <text x="820" y="165" textAnchor="middle" fontFamily="var(--font-mono)" fontSize="11" fill="var(--text-secondary)">Cloudflare</text>
          </svg>
        </Card>
        <p style={{ fontSize: 13, color: 'var(--text-secondary)', textAlign: 'center', margin: '14px 0 0' }}>Fluxo simplificado: dispositivo (Wi-Fi ou cabo) → roteador → rede física → rede de servidores da Cloudflare, que escolhe automaticamente o ponto mais próximo.</p>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 16, maxWidth: 720, width: '100%', marginTop: 56 }}>
        <Card style={{ minHeight: 110 }}>
          <div style={{ display: 'flex', gap: 20, alignItems: 'flex-start', textAlign: 'left' }}>
            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--text-secondary)', minWidth: 20 }}>01</span>
            <div>
              <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 8px' }}>Conexão (ping)</p>
              <p style={{ fontSize: 15, lineHeight: 1.55, color: 'var(--text-primary)', margin: 0 }}>Conecta a um servidor da rede da Cloudflare, escolhido automaticamente pelo ponto mais próximo disponível, e mede o tempo de ida e volta de pequenos pacotes. Essa fase não aparece na tela, só o resultado final mostra o ping.</p>
            </div>
          </div>
        </Card>
        <Card style={{ minHeight: 110 }}>
          <div style={{ display: 'flex', gap: 20, alignItems: 'flex-start', textAlign: 'left' }}>
            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--text-secondary)', minWidth: 20 }}>02</span>
            <div>
              <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 8px' }}>Download</p>
              <p style={{ fontSize: 15, lineHeight: 1.55, color: 'var(--text-primary)', margin: 0 }}>Abre múltiplas conexões simultâneas e baixa dados por alguns segundos. A velocidade mostrada é a média das conexões, atualizada em tempo real.</p>
            </div>
          </div>
        </Card>
        <Card style={{ minHeight: 110 }}>
          <div style={{ display: 'flex', gap: 20, alignItems: 'flex-start', textAlign: 'left' }}>
            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--text-secondary)', minWidth: 20 }}>03</span>
            <div>
              <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '0 0 8px' }}>Upload</p>
              <p style={{ fontSize: 15, lineHeight: 1.55, color: 'var(--text-primary)', margin: 0 }}>Repete o processo em sentido inverso, enviando dados ao servidor até estabilizar a taxa de transferência.</p>
            </div>
          </div>
        </Card>
      </div>

      <div style={{ marginTop: 56, maxWidth: 720 }}>
        <DetailsDisclosure label="Detalhes técnicos" defaultOpen={true}>
          Servidores em <b>38 pontos</b> · Protocolo <b>HTTPS</b> · Conexões simultâneas <b>4–8</b> · Duração média <b>7–10s</b>
        </DetailsDisclosure>
      </div>
    </div>
  );
}
