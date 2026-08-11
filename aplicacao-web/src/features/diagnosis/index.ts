/**
 * Diagnosis feature exports
 */

export { rulesEngine } from './rulesEngine';
export { geminiDiagnosis, combinedDiagnosis } from './geminiApi';
export { useDiagnosis } from './useDiagnosis';
export { useDiagnosisItems } from './useDiagnosisItems';
export { diagnosisRecommendationToItems, speedTestResultToEngineInput } from './diagnosisAdapter';
export type {
  DiagnosisCause,
  Severity,
  RecommendationCategory,
  SpeedTestResult,
  ContractPlanInfo,
  DiagnosisProblem,
  Recommendation,
  DiagnosisRecommendation,
  DiagnosisEngineInput,
} from './types';
export type { UseDiagnosisResult } from './useDiagnosis';
export type { UseDiagnosisItemsResult } from './useDiagnosisItems';
