import { Wordmark } from '../ui/components/brand/Wordmark';

type InfoPage = {
  eyebrow: string;
  title: string;
  intro: string;
  sections: Array<{
    title: string;
    body: string;
    action?: {
      href: string;
      label: string;
    };
  }>;
};

const pages: Record<string, InfoPage> = {
  '/sobre': {
    eyebrow: 'Sobre',
    title: 'Linka SpeedTest',
    intro: 'Um app Apple para medir a qualidade da conexao de forma direta.',
    sections: [
      {
        title: 'O que o Linka faz',
        body: 'Mede download, upload, latencia, jitter e perda quando esses dados estao disponiveis.'
      },
      {
        title: 'O que o Linka nao faz',
        body: 'Nao exige conta para medir e nao transforma a medicao em um painel tecnico.'
      }
    ]
  },
  '/como-medimos': {
    eyebrow: 'Como medimos',
    title: 'Medicao real, resultado simples.',
    intro: 'O teste executa fases de conexao, download e upload e mostra o resultado principal sem pedir configuracao previa.',
    sections: [
      {
        title: 'Fases',
        body: 'Primeiro o app prepara a conexao. Depois mede download e upload. Quando possivel, tambem exibe latencia, jitter, perdas e contexto da rede.'
      },
      {
        title: 'Rede atual',
        body: 'No iPhone, algumas informacoes de Wi-Fi dependem das permissoes que a Apple exige para expor o nome da rede.'
      }
    ]
  },
  '/privacidade': {
    eyebrow: 'Privacidade',
    title: 'Privacidade do Linka',
    intro: 'O Linka coleta apenas o necessario para medir e explicar a conexao dentro do app.',
    sections: [
      {
        title: 'Medicoes',
        body: 'As medicoes podem incluir velocidade, latencia, horario, tipo de conexao e, quando autorizado, nome da rede Wi-Fi.'
      },
      {
        title: 'Wi-Fi',
        body: 'A permissao de localizacao e usada porque o iPhone exige essa autorizacao para informar o nome da rede Wi-Fi. O Linka nao usa isso para rastrear localizacao.'
      },
      {
        title: 'Compras',
        body: 'Assinaturas e restauracao de compra sao processadas pela Apple.'
      }
    ]
  },
  '/termos': {
    eyebrow: 'Termos',
    title: 'Termos de Uso',
    intro: 'Ao usar o Linka, voce entende que resultados de rede variam conforme horario, local, aparelho, roteador, operadora e servidor disponivel.',
    sections: [
      {
        title: 'Uso do app',
        body: 'O Linka oferece medicao e orientacao informativa. Ele nao substitui suporte tecnico da operadora nem garante desempenho minimo contratado.'
      },
      {
        title: 'Assinatura',
        body: 'O Linka Plus e renovado e cancelado pelos controles oficiais da Apple.'
      }
    ]
  },
  '/suporte': {
    eyebrow: 'Suporte',
    title: 'Suporte Linka',
    intro: 'Use este canal para duvidas sobre assinatura, privacidade, medicoes ou funcionamento do app.',
    sections: [
      {
        title: 'Antes de chamar suporte',
        body: 'Inclua modelo do aparelho, versao do iOS ou macOS, versao do Linka e uma descricao curta do que aconteceu.'
      },
      {
        title: 'Canal oficial',
        body: 'O atendimento oficial do Linka usa o endereco do proprio dominio do produto.',
        action: {
          href: 'mailto:suporte@linka.app?subject=Suporte%20Linka',
          label: 'Enviar e-mail para suporte@linka.app'
        }
      }
    ]
  }
};

export function infoPageForPath(pathname: string): InfoPage {
  return pages[pathname] ?? pages['/sobre'];
}

export function InfoScreen({ pathname }: { pathname: string }) {
  const page = infoPageForPath(pathname);

  return (
    <div style={{ minHeight: '100vh', fontFamily: 'var(--font-body, sans-serif)', color: 'var(--text-primary, #000)', background: 'var(--surface-page, #f9f9f9)' }}>
      <header style={{ padding: '22px 24px', maxWidth: 760, margin: '0 auto', width: '100%', boxSizing: 'border-box' }}>
        <a href="/" aria-label="Linka" style={{ color: 'inherit', textDecoration: 'none' }}>
          <Wordmark size="md" color={undefined} dotColor={undefined} />
        </a>
      </header>

      <main style={{ maxWidth: 760, margin: '0 auto', padding: '48px 24px 96px', boxSizing: 'border-box' }}>
        <p style={{ fontFamily: 'var(--font-mono, monospace)', fontSize: 12, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-secondary, #666)', margin: '0 0 16px' }}>{page.eyebrow}</p>
        <h1 style={{ fontFamily: 'var(--font-display, sans-serif)', fontSize: 'clamp(34px, 6vw, 56px)', lineHeight: 1.05, margin: '0 0 20px' }}>{page.title}</h1>
        <p style={{ fontSize: 18, lineHeight: 1.6, color: 'var(--text-secondary, #666)', margin: '0 0 48px', maxWidth: 620 }}>{page.intro}</p>

        <div style={{ display: 'grid', gap: 32 }}>
          {page.sections.map((section) => (
            <section key={section.title}>
              <h2 style={{ fontSize: 22, lineHeight: 1.2, margin: '0 0 10px' }}>{section.title}</h2>
              <p style={{ fontSize: 16, lineHeight: 1.7, color: 'var(--text-secondary, #666)', margin: 0 }}>{section.body}</p>
              {section.action ? (
                <a
                  href={section.action.href}
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    minHeight: 44,
                    marginTop: 16,
                    color: 'var(--brand-accent, #007aff)',
                    fontSize: 16,
                    fontWeight: 600,
                    textDecoration: 'none'
                  }}
                >
                  {section.action.label}
                </a>
              ) : null}
            </section>
          ))}
        </div>
      </main>
    </div>
  );
}
