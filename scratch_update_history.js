const fs = require('fs');
const file = 'aplicacao-web/src/screens/HistoryScreen.tsx';
let content = fs.readFileSync(file, 'utf8');

const lines = content.split('\n');
const startIndex = lines.findIndex(l => l.includes('<div className="lk-history__content">'));
const endIndex = lines.findIndex((l, i) => i > startIndex && l.includes('</main>'));

const replacement = `
          <div className="lk-history__content" style={{ padding: '0 16px 24px' }}>
            <div style={{ padding: 16, background: 'var(--brand-accent-warm)', color: '#fff', borderRadius: 16, marginBottom: 24 }}>
              <span style={{ color: 'rgba(255,255,255,0.7)', fontSize: 13, display: 'flex', alignItems: 'center', gap: 6 }}>✦ Insight da Semana</span>
              <p style={{ margin: '8px 0 16px', fontSize: 17, lineHeight: 1.4, fontWeight: 500 }}>Sua conexão Wi-Fi está 15% mais rápida nos últimos 3 dias.</p>
              <span style={{ fontSize: 13, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 4, cursor: 'pointer' }}>
                Perguntar ao Assist
              </span>
            </div>
            <p style={{ fontFamily: 'var(--font-mono)', fontSize: 13, textTransform: 'uppercase', letterSpacing: '0.1em', color: 'var(--text-secondary)', marginBottom: 12 }}>Mês atual</p>
            {items.map((r) => (
              <div key={r.id} onClick={() => setSelectedId(r.id)} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 0', borderBottom: '0.5px solid var(--border-color)', cursor: 'pointer' }}>
                <div>
                  <p style={{ fontSize: 15, margin: '0 0 4px' }}>{formatDate(r.timestamp)}</p>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, color: 'var(--text-secondary)' }}>
                    <ConnectionIcon kind={r.connectionType} size={12} />
                    <span>{tipoLabel(r.connectionType).toUpperCase()}</span>
                  </div>
                </div>
                <div style={{ display: 'flex', gap: 16, textAlign: 'right' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                    <span style={{ color: 'var(--brand-accent-warm)', fontSize: 12 }}>↓</span>
                    <span style={{ fontSize: 15, fontWeight: 500 }}>{formatMbps(r.dl, unit)}</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                    <span style={{ color: 'var(--text-secondary)', fontSize: 12 }}>↑</span>
                    <span style={{ fontSize: 15, fontWeight: 500, color: 'var(--text-secondary)' }}>{formatMbps(r.ul, unit)}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
`;

lines.splice(startIndex, endIndex - startIndex, replacement);

fs.writeFileSync(file, lines.join('\n'));
console.log('HistoryScreen updated');
