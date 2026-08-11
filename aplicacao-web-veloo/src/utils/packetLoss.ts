export type PacketLossPlatform = 'web';

export interface PacketLossResult {
  available: boolean;
  sent?: number;
  received?: number;
  lossPercent?: number;
  avgRttMs?: number;
  platform?: PacketLossPlatform;
}

export async function measurePacketLossNative(): Promise<PacketLossResult> {
  return { available: false, platform: 'web' };
}

export function isPacketLossNativeAvailable(): boolean {
  return false;
}
