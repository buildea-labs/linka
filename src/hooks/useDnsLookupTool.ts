import { useState, useCallback } from 'react';

export interface DnsRecord {
  ip: string;
  ttl: number;
}

export interface DnsLookupResult {
  domain: string;
  records: DnsRecord[];
  latencyMs: number;
}

export type DnsLookupToolState =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'result'; data: DnsLookupResult }
  | { status: 'error'; message: string };

const DOH_URL = 'https://cloudflare-dns.com/dns-query';
const TIMEOUT_MS = 5000;

/**
 * Resolve um domínio via DNS-over-HTTPS (Cloudflare DoH).
 * CORS aberto em cloudflare-dns.com — funciona em browser/PWA sem proxy.
 * Retorna registros tipo A (IPv4). Nunca lança — erros são capturados.
 *
 * Nota: o resultado vem do resolver Cloudflare, não do resolver do usuário.
 * Para GeoDNS, os IPs podem diferir dos que o usuário resolveria localmente.
 */
export function useDnsLookupTool() {
  const [state, setState] = useState<DnsLookupToolState>({ status: 'idle' });

  const lookup = useCallback(async (domain: string) => {
    const cleaned = domain.trim().replace(/^https?:\/\//, '').split('/')[0];
    if (!cleaned) {
      setState({ status: 'error', message: 'Digite um domínio válido.' });
      return;
    }

    setState({ status: 'loading' });

    const ctrl = new AbortController();
    const tid = setTimeout(() => ctrl.abort(), TIMEOUT_MS);

    const t0 = performance.now();
    try {
      const url = `${DOH_URL}?name=${encodeURIComponent(cleaned)}&type=A`;
      const response = await fetch(url, {
        headers: { Accept: 'application/dns-json' },
        cache: 'no-store',
        signal: ctrl.signal,
      });
      const latencyMs = Math.round(performance.now() - t0);

      if (!response.ok) {
        setState({ status: 'error', message: `Erro na consulta DNS: ${response.status}` });
        return;
      }

      const data = await response.json() as {
        Status?: number;
        Answer?: Array<{ type: number; data: string; TTL: number }>;
      };

      // Status 3 = NXDOMAIN (domínio não existe)
      if (data.Status === 3) {
        setState({ status: 'error', message: `Domínio "${cleaned}" não encontrado.` });
        return;
      }

      const records: DnsRecord[] = (data.Answer ?? [])
        .filter((a) => a.type === 1) // type 1 = A record (IPv4)
        .map((a) => ({ ip: a.data, ttl: a.TTL }));

      if (records.length === 0) {
        setState({ status: 'error', message: `Nenhum registro A encontrado para "${cleaned}".` });
        return;
      }

      setState({ status: 'result', data: { domain: cleaned, records, latencyMs } });
    } catch (err) {
      if (err instanceof DOMException && err.name === 'AbortError') {
        setState({ status: 'error', message: 'Timeout: consulta DNS demorou mais de 5 segundos.' });
        return;
      }
      console.warn('[useDnsLookupTool] falha no DoH:', err);
      setState({ status: 'error', message: 'Falha na consulta DNS. Verifique sua conexão.' });
    } finally {
      clearTimeout(tid);
    }
  }, []);

  const reset = useCallback(() => {
    setState({ status: 'idle' });
  }, []);

  return { state, lookup, reset };
}
