import type { DeviceDiscoveryResult } from './types';

export async function discoverLocalNetworkFromBridge(): Promise<DeviceDiscoveryResult> {
  return {
    available: false,
    permissionStatus: 'unknown',
    platform: 'web',
    observations: [],
  };
}
