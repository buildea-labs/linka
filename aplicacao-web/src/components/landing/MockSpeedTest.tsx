import { useState, useEffect } from 'react';
import { MetricRing } from '../../ui/components/speedtest/MetricRing';
import { PhaseDots } from '../../ui/components/speedtest/PhaseDots';

export function MockSpeedTest() {
  const [phase, setPhase] = useState<'connecting' | 'download' | 'upload' | 'done'>('connecting');
  const [progress, setProgress] = useState(0);
  const [value, setValue] = useState(0);

  useEffect(() => {
    let start = performance.now();
    let currentPhase: 'connecting' | 'download' | 'upload' | 'done' = 'connecting';
    let targetVal = 0;
    let currentVal = 0;
    
    const interval = setInterval(() => {
      const time = performance.now();
      const elapsed = time - start;
      
      if (currentPhase === 'connecting') {
        if (elapsed > 2000) { 
          currentPhase = 'download'; 
          start = time; 
          targetVal = 245; 
        }
      } else if (currentPhase === 'download') {
        if (elapsed > 4000) { 
          currentPhase = 'upload'; 
          start = time; 
          setProgress(0); 
          targetVal = 112; 
          currentVal = 0;
        } else {
          setProgress(elapsed / 4000);
          currentVal += (targetVal - currentVal) * 0.15;
          setValue(currentVal);
        }
      } else if (currentPhase === 'upload') {
        if (elapsed > 4000) { 
          currentPhase = 'done'; 
          start = time; 
        } else {
          setProgress(elapsed / 4000);
          currentVal += (targetVal - currentVal) * 0.15;
          setValue(currentVal);
        }
      } else if (currentPhase === 'done') {
        if (elapsed > 3000) { 
          currentPhase = 'connecting'; 
          start = time; 
          setProgress(0); 
          setValue(0); 
        }
      }
      
      setPhase(currentPhase);
    }, 100);
    
    return () => clearInterval(interval);
  }, []);

  const phasesList = [
    { key: 'download', label: 'Download' },
    { key: 'upload', label: 'Upload' },
  ];

  return (
    <div style={{ 
      height: '100%', 
      display: 'flex', 
      flexDirection: 'column', 
      alignItems: 'center', 
      justifyContent: 'center', 
      paddingTop: 60,
      // Forçamos as variáveis para o modo escuro, já que o IOSDevice está dark={true}
      '--brand-accent': '#fff',
      '--text-primary': '#fff',
      '--text-secondary': '#9ba3b4',
      '--border-default': '#333'
    } as React.CSSProperties}>
      <MetricRing 
        connecting={phase === 'connecting'} 
        value={phase === 'connecting' || phase === 'done' ? '--' : value.toFixed(1).replace('.', ',')} 
        unit="Mbps" 
        progress={progress} 
      />
      <div style={{ marginTop: '24px' }}>
        <PhaseDots 
          phases={phasesList} 
          activeKey={phase === 'done' ? '' : phase === 'connecting' ? 'download' : phase} 
        />
      </div>
    </div>
  );
}
