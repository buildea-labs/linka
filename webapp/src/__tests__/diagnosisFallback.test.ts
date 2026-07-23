import { describe, expect, it } from 'vitest';
import { LOCAL_DIAGNOSIS_FOOTER, withLocalDiagnosisFooter } from '../features/diagnosis/fallback';

describe('diagnosis fallback footer', () => {
  it('adds footer when absent', () => {
    const out = withLocalDiagnosisFooter('Diagnóstico local gerado.');
    expect(out).toContain('Diagnóstico local gerado.');
    expect(out).toContain(LOCAL_DIAGNOSIS_FOOTER);
  });

  it('does not duplicate footer when already present', () => {
    const initial = `Resumo\n\n${LOCAL_DIAGNOSIS_FOOTER}`;
    const out = withLocalDiagnosisFooter(initial);
    const occurrences = out.split(LOCAL_DIAGNOSIS_FOOTER).length - 1;
    expect(occurrences).toBe(1);
  });

  it('returns footer for empty text', () => {
    expect(withLocalDiagnosisFooter('   ')).toBe(LOCAL_DIAGNOSIS_FOOTER);
  });
});
