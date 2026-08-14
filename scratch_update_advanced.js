const fs = require('fs');
const file = 'aplicacao-web/src/features/result-detail/AdvancedSheet.tsx';

const content = `import type { ServerInfo, SpeedTestResult, TestRecord } from '../../types';
import { formatMs } from '../../utils/format';
import './AdvancedSheet.css';

interface Props {
  open: boolean;
  onClose: () => void;
  result: SpeedTestResult;
  server: ServerInfo | null;
  unit: 'mbps' | 'gbps';
  history: TestRecord[];
}

export function AdvancedSheet({ open, onClose, result, server }: Props) {
  if (!open) return null;

  const elapsedSec = result.elapsedMs != null ? Math.round(result.elapsedMs / 1000) : '—';

  return (
    <div className="lk-medicao-overlay" onClick={onClose} style={{ zIndex: 100 }}>
      <div className="lk-medicao-sheet" onClick={(e) => e.stopPropagation()} style={{ height: 'auto', paddingBottom: 40 }}>
        <div className="lk-medicao-sheet__handle-row">
          <div className="lk-medicao-sheet__handle" />
        </div>
        <p style={{ textAlign: 'center', fontWeight: 600, margin: '16px 0 24px', fontSize: 17 }}>Detalhes do teste</p>
        <div style={{ padding: '0 24px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 0', borderBottom: '0.5px solid var(--border-color)' }}>
            <span style={{ color: 'var(--text-secondary)' }}>Operadora</span>
            <span style={{ fontWeight: 500 }}>{server?.isp || '—'}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 0', borderBottom: '0.5px solid var(--border-color)' }}>
            <span style={{ color: 'var(--text-secondary)' }}>Duração</span>
            <span style={{ fontWeight: 500 }}>{elapsedSec}s</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 0' }}>
            <span style={{ color: 'var(--text-secondary)' }}>Ping</span>
            <span style={{ fontWeight: 500 }}>{formatMs(result.latency)} ms</span>
          </div>
        </div>
      </div>
    </div>
  );
}
`;

fs.writeFileSync(file, content);
console.log('AdvancedSheet updated');
