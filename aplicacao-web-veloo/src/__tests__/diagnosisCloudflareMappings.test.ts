import { describe, expect, it } from 'vitest';
import { mapPriority, mapProblemToCause, mapStatusToSeverity } from '../features/diagnosis/claudeApi';

describe('diagnosis cloudflare mappings', () => {
  it('maps status to severity', () => {
    expect(mapStatusToSeverity('excelente')).toBe('healthy');
    expect(mapStatusToSeverity('BOM')).toBe('healthy');
    expect(mapStatusToSeverity('crítico')).toBe('fail');
    expect(mapStatusToSeverity('desconhecido')).toBe('warn');
    expect(mapStatusToSeverity(undefined)).toBe('warn');
  });

  it('maps problem type to cause', () => {
    expect(mapProblemToCause('sem_problema')).toBe('healthy');
    expect(mapProblemToCause('dns_lento')).toBe('dns');
    expect(mapProblemToCause('wifi_congestionado')).toBe('wifi');
    expect(mapProblemToCause('problema_isp')).toBe('isp_limit');
    expect(mapProblemToCause('wan_instavel')).toBe('wan_issue');
    expect(mapProblemToCause('congestionamento_local')).toBe('congestion');
    expect(mapProblemToCause('device_cpu')).toBe('device');
    expect(mapProblemToCause('qualquer_coisa')).toBe('unknown');
  });

  it('maps priority labels', () => {
    expect(mapPriority('alta')).toBe('high');
    expect(mapPriority('high')).toBe('high');
    expect(mapPriority('baixa')).toBe('low');
    expect(mapPriority('low')).toBe('low');
    expect(mapPriority('media')).toBe('medium');
    expect(mapPriority(undefined)).toBe('medium');
  });
});
