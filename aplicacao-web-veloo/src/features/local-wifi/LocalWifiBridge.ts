import type { LocalWifiRawInfo } from './types';

export async function getLocalWifiRawInfoFromBridge(): Promise<LocalWifiRawInfo> {
  return {
    available: false,
    permissionStatus: 'unknown',
    platform: 'web',
  };
}
