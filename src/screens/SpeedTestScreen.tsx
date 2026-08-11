// @ts-nocheck
import React, { useState, useEffect, useRef } from 'react';
import { MetricRing } from '../ui/components/speedtest/MetricRing';
import { PhaseDots } from '../ui/components/speedtest/PhaseDots';
import { StatDisplay } from '../ui/components/speedtest/StatDisplay';
import { DetailsDisclosure } from '../ui/components/speedtest/DetailsDisclosure';
import { Button } from '../ui/components/core/Button';
import { Card } from '../ui/components/core/Card';
import { useSpeedTest } from '../hooks/useSpeedTest';
import { generateResultSentence } from '../features/LkResultIA';

const EASE = 'var(--ease-spring, cubic-bezier(0.32,0.72,0,1))';

export function SpeedTestScreen() {
  const { phase: enginePhase, instantMbps, overallProgress, result: engineResult, error, start, reset } = useSpeedTest();
  
  const [screen, setScreen] = useState('measuring');
  const [leaving, setLeaving] = useState(false);
  const [doneMessage, setDoneMessage] = useState('Consolidando...');
  const [aiSentence, setAiSentence] = useState('Sua conexão está pronta.');

  // Iniciar automaticamente
  useEffect(() => {
    start();
  }, [start]);

  // Transição de tela quando finaliza
  useEffect(() => {
    let isMounted = true;
    if (enginePhase === 'done' && screen === 'measuring') {
      const phrases = [
        'Consolidando dados...',
        'Analisando latência...',
        'Quase pronto...',
        'Avaliando rede...',
        'Calculando...',
      ];
      setDoneMessage(phrases[Math.floor(Math.random() * phrases.length)]);
      
      if (engineResult) {
        generateResultSentence(engineResult).then(sentence => {
          if (isMounted) setAiSentence(sentence);
        });
      }
      
      const tidLeave = setTimeout(() => setLeaving(true), 1500);
      const tidScreen = setTimeout(() => {
        setScreen('result');
        setLeaving(false);
      }, 1500 + 420);
      return () => {
        isMounted = false;
        clearTimeout(tidLeave); clearTimeout(tidScreen);
      };
    }
    return () => { isMounted = false; };
  }, [enginePhase, screen, engineResult]);

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
      : (connecting ? 'Preparando' : '0,0');

  const phaseLabel = connecting
    ? 'Conectando ao servidor mais próximo…'
    : enginePhase === 'download'
    ? 'Medindo velocidade de download…'
    : enginePhase === 'upload'
    ? 'Medindo velocidade de upload…'
    : 'Finalizando…';

  const phasesList = [
    { key: 'download', label: 'Download' },
    { key: 'upload', label: 'Upload' }
  ];

  const enter = (delay: number) => ({
    animation: `linkaRise .85s ${EASE} both`,
    animationDelay: `${delay}ms`
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
      
      {/* Global animations */}
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
          display: 'flex', flexDirection: 'column', alignItems: 'center',
          opacity: leaving ? 0 : 1, transform: leaving ? 'translateY(-12px)' : 'none',
          transition: `opacity .42s ${EASE}, transform .42s ${EASE}`,
          animation: `linkaFadeIn .7s ${EASE} both`
        }}>
          {isDone ? (
            <div style={{ width: 220, height: 220, display: 'grid', placeItems: 'center', margin: '0 auto', animation: 'linkaFadeIn 0.4s ease' }}>
              <p style={{ fontFamily: 'var(--font-display)', fontSize: 26, fontWeight: 700, letterSpacing: '-0.015em', margin: 0, color: 'var(--text-primary)' }}>
                {doneMessage}
              </p>
            </div>
          ) : (
            <MetricRing 
              connecting={connecting} 
              value={displayValue} 
              unit={connecting ? undefined : 'Mbps'} 
              progress={overallProgress} 
              style={{ position: 'static' }} 
            />
          )}
          <p style={{ fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--text-secondary)', margin: '20px 0 12px' }}>LkSpeedTestEngine</p>
          <p style={{ fontSize: 15, color: 'var(--text-secondary)', minHeight: 20 }}>{phaseLabel}</p>
          <PhaseDots phases={phasesList} activeKey={connecting ? '' : enginePhase} style={{ position: 'static' }} />
        </div>
      )}

      {isResult && engineResult && (
        <>
          <div style={{ display: 'flex', gap: 'clamp(28px,4vw,64px)', justifyContent: 'center', alignItems: 'center', flexWrap: 'wrap', ...enter(0) }}>
            <StatDisplay label="Download" value={engineResult.dl.toLocaleString('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 1 })} unit="Mbps" accent={true} style={{ position: 'static' }} />
            
            {/* Linha Fina Separadora */}
            <div style={{ width: 1, backgroundColor: 'var(--color-separator)', alignSelf: 'stretch', margin: '8px 0' }} />
            
            <StatDisplay label="Upload" value={engineResult.ul.toLocaleString('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 1 })} unit="Mbps" style={{ position: 'static' }} />
          </div>
          <p style={{ fontFamily: 'var(--font-display)', fontSize: 26, fontWeight: 700, letterSpacing: '-0.015em', marginTop: 20, ...enter(150) }}>
            {aiSentence}
          </p>
          
          <div style={{ ...enter(280) }}>
            <DetailsDisclosure defaultOpen={false} style={{ position: 'static' }}>
              Ping <b>{Math.round(engineResult.latency)} ms</b> · Jitter <b>{Math.round(engineResult.jitter)} ms</b> · Pkt Loss <b>{engineResult.packetLoss?.available && engineResult.packetLoss.lossPercent != null ? `${engineResult.packetLoss.lossPercent.toFixed(1)}%` : 'N/A'}</b>
            </DetailsDisclosure>
          </div>

          <div style={enter(410)}>
            <Button onClick={handleRetest} style={{ marginTop: 24, display: 'inline-flex', alignItems: 'center' }}>
              Testar novamente{Retry}
            </Button>
          </div>

          <div id="ad-container" style={{ marginTop: 40, width: '100%', maxWidth: 728, display: 'flex', justifyContent: 'center', ...enter(540) }}>
            {/* O AdSense injetará o anúncio aqui. Se não houver, o contêiner colapsa e não mostra nada. */}
          </div>
        </>
      )}
    </div>
  );
}
