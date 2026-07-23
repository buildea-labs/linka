export interface AppCapabilities {
  localWifiDiagnostics: boolean;
  localNetworkDiscovery: boolean;
}

export function isNativeApp(): boolean {
  return false;
}

export function getCapabilities(): AppCapabilities {
  const native = isNativeApp();
  return {
    localWifiDiagnostics: native,
    localNetworkDiscovery: native,
  };
}
