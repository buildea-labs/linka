// Wrapper sobre `navigator.vibrate(...)`. iOS Safari/PWA ignora
// silenciosamente, o que é aceitável.
//
// Usado por RunningScreen (transições de fase, conclusão, erro) e por
// qualquer fluxo que queira sinalização tátil no futuro. Bloco 3
// (Polimento, 2026-05).

export type HapticPattern =
  | 'phaseChange'   // 30ms — entre fases ativas (ex.: download → upload)
  | 'success'       // 50ms — conclusão do teste
  | 'error';        // [100, 50, 100] — erro

const PATTERNS: Record<HapticPattern, number | number[]> = {
  phaseChange: 30,
  success:     50,
  error:       [100, 50, 100],
};

/**
 * Dispara vibração no dispositivo se o usuário tiver haptics habilitados
 * e a API estiver disponível. Falha silenciosamente — nunca lança.
 */
export function triggerHaptic(pattern: HapticPattern, enabled: boolean): void {
  if (!enabled) return;
  
  // Toca um beep curto sintético (Tick) na mudança de fase usando Web Audio API
  if (pattern === 'phaseChange' && typeof window !== 'undefined') {
    try {
      const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
      if (AudioContextClass) {
        const ctx = new AudioContextClass();
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        
        osc.type = 'sine';
        osc.frequency.setValueAtTime(800, ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(300, ctx.currentTime + 0.05);
        
        gain.gain.setValueAtTime(1, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.05);
        
        osc.connect(gain);
        gain.connect(ctx.destination);
        
        osc.start();
        osc.stop(ctx.currentTime + 0.05);
      }
    } catch {
      // Ignora erro se AudioContext não for suportado ou for bloqueado por policy
    }
  }

  try {
    if (typeof navigator !== 'undefined' && typeof navigator.vibrate === 'function') {
      navigator.vibrate(PATTERNS[pattern]);
    }
  } catch {
    // sandbox / política de permissão — ignora.
  }
}
