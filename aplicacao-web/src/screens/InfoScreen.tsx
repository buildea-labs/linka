import { useEffect } from 'react';
import { Header } from '../ui/components/layout/Header';
import { Footer } from '../ui/components/layout/Footer';

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
    title: 'Medição direta. Sem distrações.',
    intro: 'O Linka é um app para iPhone, iPad e Mac focado exclusivamente em entregar o resultado da sua conexão de forma rápida.',
    sections: [
      {
        title: 'Foco absoluto',
        body: 'Mede a velocidade de download, upload e latência (ping). Sem telas extras, sem enrolação.'
      },
      {
        title: 'Sem painéis',
        body: 'Não exige conta, cadastro ou configuração prévia, e não transforma a medição em um painel cheio de informações inúteis.'
      }
    ]
  },
  '/como-medimos': {
    eyebrow: 'Como medimos',
    title: 'Três fases. Um resultado.',
    intro: 'O teste executa a medição de verdade e mostra o número que importa imediatamente.',
    sections: [
      {
        title: 'A Metodologia',
        body: 'O app determina o servidor ideal, e então mede latência, download e upload em sequência.'
      },
      {
        title: 'Integração Apple',
        body: 'No iPhone, iPad e Mac, a exibição de informações da rede usa as permissões nativas do ecossistema Apple de forma transparente.'
      }
    ]
  },
  '/privacidade': {
    eyebrow: 'Privacidade',
    title: 'Privacidade levada a sério.',
    intro: 'Luiz F. Giammattey atua como responsável pelo Linka. O app coleta apenas o essencial para medir sua conexão, seguindo os rigorosos padrões do ecossistema Apple.',
    sections: [
      {
        title: 'Dados de Medição',
        body: 'Transferimos apenas dados de teste entre seu aparelho e nossos servidores para calcular a velocidade da sua rede. Não fazemos rastreamento paralelo.'
      },
      {
        title: 'Fale conosco',
        body: 'Questões sobre privacidade? Nosso canal oficial está sempre aberto.',
        action: {
          href: 'mailto:suporte@linka.app?subject=Privacidade%20Linka',
          label: 'Falar com suporte@linka.app'
        }
      }
    ]
  },
  '/termos': {
    eyebrow: 'Termos',
    title: 'Regras claras. Uso simples.',
    intro: 'Ao usar o Linka, você entende que resultados de rede variam naturalmente conforme o aparelho, o local, o roteador e a operadora.',
    sections: [
      {
        title: 'Natureza do app',
        body: 'O Linka oferece medição e orientação puramente informativa. Ele não atua como certificação legal de velocidade contratada perante a sua operadora.'
      }
    ]
  },
  '/suporte': {
    eyebrow: 'Suporte',
    title: 'Suporte. Direto ao ponto.',
    intro: 'Precisa de ajuda com o app, resultados das medições ou quer relatar um problema técnico?',
    sections: [
      {
        title: 'O que enviar',
        body: 'Sempre inclua na sua mensagem: modelo do aparelho (iPhone, iPad ou Mac), versão do sistema (iOS, iPadOS ou macOS), versão do Linka e o que aconteceu.'
      },
      {
        title: 'Como falar',
        body: 'Use o endereço oficial do nosso domínio.',
        action: {
          href: 'mailto:suporte@linka.app?subject=Suporte%20Linka',
          label: 'Enviar e-mail para suporte@linka.app'
        }
      }
    ]
  }
};

function infoPageForPath(pathname: string): InfoPage {
  return pages[pathname] ?? pages['/sobre'];
}

export function InfoScreen({ pathname }: { pathname: string }) {
  const page = infoPageForPath(pathname);

  useEffect(() => {
    document.title = `${page.title} - Linka Speedtest`;
    document.querySelector('meta[name="description"]')?.setAttribute('content', page.intro);
  }, [page]);

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', fontFamily: 'var(--font-body, sans-serif)', color: 'var(--text-primary, #000)', background: 'var(--surface-page, #f9f9f9)' }}>
      <style>{`
        @keyframes linkaRise { from { opacity: 0; transform: translateY(18px); } to { opacity: 1; transform: none; } }
        .centered-container { max-width: 860px; margin: 0 auto; width: 100%; box-sizing: border-box; padding: 0 24px 120px; text-align: left; }
        .hero-block { padding: clamp(80px, 15vw, 120px) 0 clamp(40px, 8vw, 60px); text-align: left; }
        .section-block { padding: clamp(40px, 8vw, 60px) 0 0; text-align: left; }
      `}</style>

      <Header />

      <main className="centered-container">
        <section className="hero-block">
          <div style={{ animation: 'linkaRise .8s cubic-bezier(.22,.61,.36,1) both' }}>
            <p style={{ fontFamily: 'var(--font-mono, monospace)', fontSize: '12px', letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-secondary, #666)', margin: '0 0 16px' }}>{page.eyebrow}</p>
            <h1 style={{ fontFamily: 'var(--font-display, sans-serif)', fontSize: 'clamp(34px, 5.5vw, 56px)', fontWeight: 700, letterSpacing: '-0.02em', lineHeight: 1.1, margin: '0 0 24px', textWrap: 'pretty' }}>{page.title}</h1>
            <p style={{ fontSize: '19px', lineHeight: 1.6, color: 'var(--text-secondary, #666)', margin: '0 0 20px', maxWidth: 640, textWrap: 'pretty' }}>{page.intro}</p>
          </div>
        </section>

        <div style={{ display: 'grid', gap: '16px', animation: 'linkaRise .8s cubic-bezier(.22,.61,.36,1) both', animationDelay: '100ms' }}>
          {page.sections.map((section) => (
            <section key={section.title} className="section-block">
              <h2 style={{ fontFamily: 'var(--font-display, sans-serif)', fontSize: 'clamp(24px, 3.4vw, 32px)', fontWeight: 700, letterSpacing: '-0.015em', margin: '0 0 16px', textWrap: 'pretty' }}>{section.title}</h2>
              <p style={{ fontSize: '16px', lineHeight: 1.6, color: 'var(--text-secondary, #666)', margin: 0, maxWidth: 640 }}>{section.body}</p>
              {section.action ? (
                <a
                  href={section.action.href}
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    minHeight: 44,
                    marginTop: 20,
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

      <Footer />
    </div>
  );
}
