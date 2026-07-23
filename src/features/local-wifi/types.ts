export type WifiBand = '2.4GHz' | '5GHz' | '6GHz' | 'unknown';

export type WifiQuality =
  | 'excellent'
  | 'good'
  | 'fair'
  | 'weak'
  | 'critical'
  | 'unknown';

export type WifiChannelQuality = 'good' | 'medium' | 'bad';

export interface LocalWifiNetworkInfo {
  ssid: string;
  bssid: string;
  frequencyMhz: number;
  rssiDbm: number;
  capabilities: string;
}

export interface LocalWifiRawInfo {
  available: boolean;
  ssid?: string;
  bssid?: string;
  rssiDbm?: number;
  linkSpeedMbps?: number;
  frequencyMhz?: number;
  channel?: number;
  gateway?: string;
  ipAddress?: string;
  permissionStatus?: 'granted' | 'denied' | 'unknown';
  platform?: 'web' | 'unknown';
  wifiStandard?: string;
  nearbyNetworks?: LocalWifiNetworkInfo[];
}

export interface WifiDiagnosticResult {
  available: boolean;
  ssid?: string;
  bssid?: string;
  rssiDbm?: number;
  linkSpeedMbps?: number;
  frequencyMhz?: number;
  band?: WifiBand;
  channel?: number;
  channelQuality?: WifiChannelQuality;
  suggestedChannel?: number;
  gateway?: string;
  ipAddress?: string;
  quality?: WifiQuality;
  /** Padrão WiFi (e.g., "802.11ac", "802.11ax"), quando disponivel. */
  wifiStandard?: string;
  /**
   * Array de redes Wi-Fi próximas, resultado do scan assíncrono.
   * Pode estar vazio na primeira chamada (scan em background).
   */
  nearbyNetworks?: LocalWifiNetworkInfo[];
  /**
   * Estado da permissao, quando alguma origem web/externa conseguir informar.
   */
  permissionStatus?: 'granted' | 'denied' | 'unknown';
  /** Plataforma de origem do diagnostico. */
  platform?: 'web' | 'unknown';
  title: string;
  explanation: string;
  primaryAction: string;
  limitations: string[];
}
