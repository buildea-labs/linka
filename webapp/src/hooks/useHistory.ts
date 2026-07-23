import { useState, useCallback } from 'react';
import type { TestRecord } from '../types';
import { loadHistory } from '../utils/history';

export type HistoryPeriod = '7d' | '30d' | '90d' | 'all';

export interface HistoryState {
  records: TestRecord[];
  filtered: TestRecord[];
  period: HistoryPeriod;
  isEmpty: boolean;
}

const PERIOD_MS: Record<HistoryPeriod, number | null> = {
  '7d':  7  * 24 * 3600 * 1000,
  '30d': 30 * 24 * 3600 * 1000,
  '90d': 90 * 24 * 3600 * 1000,
  'all': null,
};

export const PERIOD_LABELS: Record<HistoryPeriod, string> = {
  '7d':  '7 dias',
  '30d': '30 dias',
  '90d': '90 dias',
  'all': 'Todos',
};

function filterByPeriod(records: TestRecord[], period: HistoryPeriod): TestRecord[] {
  const windowMs = PERIOD_MS[period];
  if (windowMs === null) return records;
  const cutoff = Date.now() - windowMs;
  return records.filter((r) => r.timestamp >= cutoff);
}

/**
 * Hook reativo de histórico de testes.
 *
 * - Lê do localStorage via `loadHistory()` ao montar e ao chamar `refresh()`
 * - Filtra registros pelo período selecionado
 * - Expõe `setPeriod` para mudar o filtro sem recarregar
 */
export function useHistory() {
  const [records, setRecords] = useState<TestRecord[]>(() => loadHistory());
  const [period, setPeriod] = useState<HistoryPeriod>('7d');

  const refresh = useCallback(() => {
    setRecords(loadHistory());
  }, []);

  const filtered = filterByPeriod(records, period);

  const state: HistoryState = {
    records,
    filtered,
    period,
    isEmpty: records.length === 0,
  };

  return { state, setPeriod, refresh };
}
