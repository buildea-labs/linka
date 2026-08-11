import { useEffect, useState } from 'react';
import type { ConnectionType, DeviceInfo, DeviceType, ServerInfo } from '../types';
import { getDefaultServer, getServer } from '../utils/serverRegistry';

interface NetworkInformation {
  type?: string;
  effectiveType?: string;
  addEventListener(type: string, listener: EventListenerOrEventListenerObject): void;
  removeEventListener(type: string, listener: EventListenerOrEventListenerObject): void;
}

/**
 * Cascata de detecção PWA:
 *
 * 1. **PWA web**: usa `navigator.connection.type` quando
 *    disponível (`wifi` / `cellular` / `ethernet` / `wimax` / `bluetooth`).
 *    Pega também `effectiveType` lento como sinal indireto de celular.
 * 2. **Fallback final** (Safari iOS, Firefox, Chrome com `type='unknown'`):
 *    usa `unknown`, permitindo override manual quando necessário.
 *    Log `console.warn` para diagnóstico.
 *
 * Override manual via `HamburgerMenu` (configurações → conexão) sempre vence
 * — é aplicado em `App.tsx::effectiveConnection` e nunca passa por aqui.
 */

function detectConnectionTypeFromWeb(): ConnectionType | null {
  const conn = (navigator as Navigator & { connection?: NetworkInformation }).connection;
  const t = conn?.type;
  const eff = conn?.effectiveType;

  if (t === 'wifi') return 'wifi';
  if (t === 'cellular') return 'mobile';
  if (t === 'ethernet' || t === 'wimax') return 'cable';
  // `bluetooth` é tethering — geralmente celular compartilhado.
  if (t === 'bluetooth') return 'mobile';
  // effectiveType lento sem `type` = rede celular quase certo.
  if (!t && (eff === '2g' || eff === '3g' || eff === 'slow-2g')) return 'mobile';
  return null;
}

function detectDevice(): DeviceInfo {
  const ua = navigator.userAgent;
  const w = window.innerWidth;
  let deviceType: DeviceType = 'desktop';
  if (/Mobi|Android/i.test(ua) || w <= 768) deviceType = 'mobile';
  else if (w <= 1024) deviceType = 'tablet';

  const fromWeb = detectConnectionTypeFromWeb();
  if (fromWeb) {
    return { deviceType, connectionType: fromWeb };
  }

  // Fallback final (sem sinal confiável da Web API e sem bridge ainda):
  // PWA standalone em iOS Safari / Firefox costuma ser Wi-Fi doméstico.
  // Em desktop sem Network Information API, default é `cable` (Ethernet ou
  // Wi-Fi indistinguíveis sem dados nativos — mas não é mobile).
  // Log para diagnóstico — caso real precise de override manual.
  if (typeof console !== 'undefined' && deviceType === 'mobile') {
    console.warn(
      '[linka] navigator.connection indisponível — assumindo conexão "unknown" como default em mobile. ' +
      'Use o override manual se precisar fixar Wi-Fi, cabo ou móvel.',
    );
  }
  const fallback: ConnectionType = 'unknown';
  return { deviceType, connectionType: fallback };
}

interface State {
  device: DeviceInfo | null;
  server: ServerInfo | null;
  loading: boolean;
  error: string | null;
}

export function useDeviceInfo(serverId = 'cloudflare'): State & { reload: () => void } {
  const [state, setState] = useState<State>({
    device: detectDevice(),
    server: null,
    loading: true,
    error: null,
  });
  const [reloadKey, setReloadKey] = useState(0);

  // Re-detecta tipo de conexão quando o usuário alterna entre WiFi e dados móveis.
  // Bug-fix 2026-05 (ISP cached): além de atualizar `device`, dispara
  // re-fetch de `getInfo()` (via reloadKey) para que o ISP/colo/IP do banner
  // de contexto reflita a rede atual. Antes, o ISP só era resolvido no mount
  // e ficava congelado mesmo após troca de Wi-Fi → móvel (ou troca de
  // operadora). Chrome Android dispara `connection.change` de forma
  // confiável; em iOS Safari (que não expõe `navigator.connection`) o
  // refresh acontece via reload manual em `App.tsx` antes de cada teste.
  useEffect(() => {
    const conn = (navigator as Navigator & { connection?: NetworkInformation }).connection;
    if (!conn) return;
    const handleChange = () => {
      setState((s) => ({ ...s, device: detectDevice() }));
      setReloadKey((k) => k + 1);
    };
    conn.addEventListener('change', handleChange);
    return () => conn.removeEventListener('change', handleChange);
  }, []);

  // Bug-fix 2026-05 (ISP cached + rede móvel): também ouve `online`/`offline`
  // para refrescar quando a rede sair/voltar (caso clássico iOS: avião → 5G,
  // ou Android cabo → mobile via tether USB). Bumpa `reloadKey` para forçar
  // refresh do ISP.
  useEffect(() => {
    const handleOnline = () => {
      setState((s) => ({ ...s, device: detectDevice() }));
      setReloadKey((k) => k + 1);
    };
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOnline);
    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOnline);
    };
  }, []);

  useEffect(() => {
    let cancelled = false;

    (async () => {
      if (!cancelled) setState((s) => (!s.loading ? { ...s, loading: true, error: null } : s));
      const device = detectDevice();
      const provider = serverId ? getServer(serverId) : getDefaultServer();
      try {
        const info = await provider.getInfo();
        const available = info.available && (await provider.checkAvailability());
        if (cancelled) return;
        setState((prev) => ({
          // Preserva override/re-deteccao anterior quando existir.
          device: prev.device ?? device,
          server: { ...info, available },
          loading: false,
          error: available ? null : 'Servidor de teste indisponível.',
        }));
      } catch {
        if (cancelled) return;
        setState((prev) => ({
          device: prev.device ?? device,
          server: {
            id: provider.id,
            name: provider.name,
            ip: '—',
            colo: '—',
            loc: '—',
            isp: '—',
            available: false,
          },
          loading: false,
          error: 'Não foi possível conectar ao servidor de teste.',
        }));
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [serverId, reloadKey]);

  return { ...state, reload: () => setReloadKey((k) => k + 1) };
}
