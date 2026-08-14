const fs = require('fs');
const file = 'aplicacao-web/src/screens/ResultScreen.tsx';
let content = fs.readFileSync(file, 'utf8');
const lines = content.split('\n');

const startIndex = lines.findIndex(l => l.includes('<section') && l.includes('className="lk-result__test-card"'));
let endIndex = lines.findIndex((l, i) => i > startIndex && l.includes('activeSheet === \'advanced\''));
endIndex = endIndex - 1; // get to the line before activeSheet

const replacement = `
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', animation: 'linkaFadeIn .7s cubic-bezier(.22,.61,.36,1) both' }}>
          <Gauge
            value={1}
            phase=""
            num={formatMbps(animDl, unit)}
            unit={unit === 'gbps' ? 'Gbps' : 'Mbps'}
            color="var(--phase-dl)"
          />
          <p style={{ fontFamily: 'var(--font-mono)', fontSize: 13, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--brand-accent)', margin: '18px 0 10px' }}>Download</p>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, fontSize: 16, margin: '6px 0 32px' }}>
            <span>{formatMbps(animUl, unit)} {unit === 'gbps' ? 'Gbps' : 'Mbps'} <span style={{ color: 'var(--text-secondary)' }}>upload</span></span>
            <span style={{ color: 'var(--text-3)', fontSize: 20 }}>·</span>
            <span>{formatMs(Math.max(0.1, animLat))} ms <span style={{ color: 'var(--text-secondary)' }}>ping</span></span>
          </div>
          <button onClick={() => setActiveSheet('advanced')} style={{ height: 30, padding: '0 12px', fontSize: 13, background: 'rgba(120,120,128,0.12)', color: 'var(--text-primary)', borderRadius: 15, border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 4 }}>
            Ver detalhes
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} style={{ width: 12, height: 12 }}><path d="M6 9l6 6 6-6" /></svg>
          </button>
        </div>

        <div style={{ width: '100%', maxWidth: 400, marginTop: 40, marginInline: 'auto', paddingInline: 20, boxSizing: 'border-box' }}>
          <IOSList
            items={[
              {
                icon: <Icon name="history" size={14} color="var(--text-2)" />,
                title: 'Último teste',
                subtitle: history[1] ? \`\${formatMbps(history[1].dl, unit)} Mbps · \${formatRelativeTime(history[1].timestamp)}\` : 'Nenhum',
                onClick: onExplore,
                showChevron: true
              }
            ]}
          />
        </div>

        <div style={{ position: 'fixed', bottom: 0, left: 0, right: 0, padding: '16px 20px', background: 'var(--surface-blur)', backdropFilter: 'blur(20px)', borderTop: '0.5px solid var(--border-color)', zIndex: 10 }}>
          <button onClick={onRetry} style={{ width: '100%', height: 50, borderRadius: 14, background: 'var(--brand-accent)', color: '#fff', fontSize: 17, fontWeight: 600, border: 'none', cursor: 'pointer' }}>
            Testar novamente
          </button>
        </div>
      </div>
`;

lines.splice(startIndex, endIndex - startIndex, replacement);

// Add import for Gauge
const importIndex = lines.findIndex(l => l.includes('import { IOSList }'));
lines.splice(importIndex, 0, "import { Gauge } from '../components/Gauge';");

fs.writeFileSync(file, lines.join('\n'));
console.log('ResultScreen updated');
