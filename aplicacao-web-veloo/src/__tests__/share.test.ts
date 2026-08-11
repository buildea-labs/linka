import { describe, it, expect, vi, afterEach } from 'vitest';
import type { SpeedTestResult } from '../types';
import { buildShareText, shareResultText } from '../utils/share';

const baseResult: SpeedTestResult = {
  dl: 87.3,
  ul: 32.1,
  latency: 18.2,
  jitter: 3.4,
  packetLoss: 0,
  timestamp: new Date('2026-04-28T14:32:00-03:00').getTime(),
};

function testNavigator(): Record<string, unknown> {
  const g = globalThis as unknown as { navigator?: Record<string, unknown> };
  if (typeof g.navigator !== 'object' || g.navigator == null) {
    g.navigator = {} as Record<string, unknown>;
  }
  return g.navigator;
}

afterEach(() => {
  vi.restoreAllMocks();
  const nav = testNavigator();
  Reflect.deleteProperty(nav, 'share');
  Reflect.deleteProperty(nav, 'clipboard');
});

describe('share result', () => {
  it('usa navigator.share quando disponível e envia title + text corretos', async () => {
    const mockShare = vi.fn().mockResolvedValue(undefined);
    Object.defineProperty(testNavigator(), 'share', { value: mockShare, configurable: true });

    const text = buildShareText(baseResult, 'good', 'mbps');
    const outcome = await shareResultText(text);

    expect(outcome).toBe('shared');
    expect(mockShare).toHaveBeenCalledTimes(1);
    expect(mockShare).toHaveBeenCalledWith({
      title: 'Veloo',
      text,
    });
    expect(text).toContain('↓ 87.3 Mbps');
    expect(text).toContain('↑ 32.1 Mbps');
    expect(text).toContain('Resposta 18 ms');
    expect(text).toContain('Oscilação 3 ms');
  });

  it('chama clipboard.writeText quando navigator.share não existe', async () => {
    const mockWriteText = vi.fn().mockResolvedValue(undefined);
    Object.defineProperty(testNavigator(), 'clipboard', {
      value: { writeText: mockWriteText },
      configurable: true,
    });

    const text = buildShareText(baseResult, 'good', 'mbps');
    const outcome = await shareResultText(text);

    expect(outcome).toBe('copied');
    expect(mockWriteText).toHaveBeenCalledTimes(1);
    expect(mockWriteText).toHaveBeenCalledWith(text);
  });

  it('não lança quando navigator.share rejeita', async () => {
    const mockShare = vi.fn().mockRejectedValue(new Error('cancelled'));
    Object.defineProperty(testNavigator(), 'share', { value: mockShare, configurable: true });

    const text = buildShareText(baseResult, 'good', 'mbps');

    await expect(shareResultText(text)).resolves.toBe('none');
  });

  it('não lança quando clipboard falha', async () => {
    const mockWriteText = vi.fn().mockRejectedValue(new Error('no permission'));
    Object.defineProperty(testNavigator(), 'clipboard', {
      value: { writeText: mockWriteText },
      configurable: true,
    });

    const text = buildShareText(baseResult, 'good', 'mbps');

    await expect(shareResultText(text)).resolves.toBe('none');
  });
});
