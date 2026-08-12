import { useEffect, useState } from 'react';
import { MetricRing } from '../ui/components/speedtest/MetricRing';
import { PhaseDots } from '../ui/components/speedtest/PhaseDots';
import { StatDisplay } from '../ui/components/speedtest/StatDisplay';
import { DetailsDisclosure } from '../ui/components/speedtest/DetailsDisclosure';
import { Button } from '../ui/components/core/Button';
import { useSpeedTest } from '../hooks/useSpeedTest';

const EASE = 'var(--ease-spring, cubic-bezier(0.32,0.72,0,1))';

export function SpeedTestScreen() {
  const { phase: enginePhase, instantMbps, overallProgress, result: engineResult, error, start, reset } = useSpeedTest();

  const [screen, setScreen] = useState('measuring');
  const [leaving, setLeaving] = useState(false);

  useEffect(() => {
    start();
  }, [start]);

  useEffect(() => {
    if (enginePhase === 'done' && screen === 'measuring') {
      const tidLeave = setTimeout(() => setLeaving(true), 500);
      const tidScreen = setTimeout(() => {
        setScreen('result');
        setLeaving(false);
      }, 920);

      return () => {
        clearTimeout(tidLeave);
        clearTimeout(tidScreen);
      };
    }
  }, [enginePhase, screen]);

  const handleRetest = () => {
    reset();
    setScreen('measuring');
    setLeaving(false);
    start();
  };

  const connecting = enginePhase === 'idle' || enginePhase === 'latency';
  const isDone = enginePhase === 'done';
  const isMeasuring = screen === 'measuring';
  const isResult = screen === 'result';

  const displayValue = instantMbps !== null
    ? instantMbps.toLocaleString('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 1 })
    : connecting ? 'Preparando' : '0,0';


  const phasesList = [
    { key: 'download', label: 'Download' },
    { key: 'upload', label: 'Upload' },
  ];

  const enter = (delay: number) => ({
    animation: `linkaRise .85s ${EASE} both`,
    animationDelay: `${delay}ms`,
  });

  const Retry = (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}
      style={{ width: 14, height: 14, marginLeft: 6 }}>
      <path d="M3 12a9 9 0 1 1 3 6.7" />
      <path d="M3 21v-6h6" />
    </svg>
  );

  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '56px 24px', textAlign: 'center' }}>
      <style>{`
        @keyframes linkaRise { from { opacity: 0; transform: translateY(16px); } to { opacity: 1; transform: none; } }
        @keyframes linkaFadeIn { from { opacity: 0; } to { opacity: 1; } }
      `}</style>

      {error && (
        <div style={{ color: 'var(--brand-accent-warm)', marginBottom: 20 }}>
          {error}
        </div>
      )}

      {isMeasuring && (
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          opacity: leaving ? 0 : 1,
          transform: leaving ? 'translateY(-12px)' : 'none',
          transition: `opacity .42s ${EASE}, transform .42s ${EASE}`,
          animation: `linkaFadeIn .7s ${EASE} both`,
        }}>
          {isDone ? (
            <div style={{ width: 220, height: 220, display: 'grid', placeItems: 'center', margin: '0 auto', animation: 'linkaFadeIn 0.4s ease' }}>
              <p style={{ fontFamily: 'var(--font-display)', fontSize: 26, fontWeight: 700, letterSpacing: '-0.015em', margin: 0, color: 'var(--text-primary)' }}>
                Finalizando
              </p>
            </div>
          ) : (
            <MetricRing
              connecting={connecting}
              value={displayValue}
              unit={connecting ? undefined : 'Mbps'}
              progress={overallProgress}
            />
          )}
          <PhaseDots phases={phasesList} activeKey={connecting ? '' : enginePhase} />
        </div>
      )}

      {isResult && engineResult && (
        <>
          <div style={{ display: 'flex', gap: 'clamp(16px,4vw,64px)', justifyContent: 'center', alignItems: 'center', flexWrap: 'nowrap', width: '100%', ...enter(0) }}>
            <StatDisplay label="Download" value={engineResult.dl.toLocaleString('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 1 })} unit="Mbps" accent={true} />
            <div style={{ width: 1, backgroundColor: 'var(--color-separator)', alignSelf: 'stretch', margin: '8px 0' }} />
            <StatDisplay label="Upload" value={engineResult.ul.toLocaleString('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 1 })} unit="Mbps" />
          </div>

          <div style={{ marginTop: 24, ...enter(180) }}>
            <DetailsDisclosure defaultOpen={false}>
              Ping <b>{Math.round(engineResult.latency)} ms</b> · Jitter <b>{Math.round(engineResult.jitter)} ms</b>
            </DetailsDisclosure>
          </div>

          <div style={enter(320)}>
            <Button onClick={handleRetest} style={{ marginTop: 24, display: 'inline-flex', alignItems: 'center' }} icon={Retry}>
              Testar novamente
            </Button>
          </div>

          <div id="ad-container" style={{ marginTop: 40, width: '100%', maxWidth: 728, display: 'flex', justifyContent: 'center', ...enter(440) }}>
            {/* Publicidade, quando existir, entra somente após o resultado. */}
          </div>
        </>
      )}
    </div>
  );
}