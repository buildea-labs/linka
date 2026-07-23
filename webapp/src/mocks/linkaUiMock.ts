export interface WifiNetworkMock {
  name: string;
  details: string;
  signalDbm: string;
  channel: string;
  connected?: boolean;
}

export interface DeviceMock {
  name: string;
  ip: string;
  status: 'Online' | 'Limitado';
  icon: 'mobile' | 'laptop' | 'stream' | 'person' | 'assistant' | 'game' | 'camera' | 'printer';
}

export const wifiNetworks: WifiNetworkMock[] = [
  { name: 'Casa_5G', details: '5 GHz · WPA2', signalDbm: '-40 dBm', channel: 'Ch 36', connected: true },
  { name: 'Casa_2G', details: '2.4 GHz · WPA2', signalDbm: '-67 dBm', channel: 'Ch 6' },
  { name: 'Vizinho_WiFi', details: '2.4 GHz · WPA2', signalDbm: '-72 dBm', channel: 'Ch 11' },
  { name: 'Convidados', details: '2.4 GHz · Aberta', signalDbm: '-80 dBm', channel: 'Ch 1' },
  { name: 'IoT_Devices', details: '2.4 GHz · WPA2', signalDbm: '-85 dBm', channel: 'Ch 13' },
];

export const connectedDevices: DeviceMock[] = [
  { name: 'Lucas – Pixel 8', ip: '192.168.1.10', status: 'Online', icon: 'mobile' },
  { name: 'Notebook Dell', ip: '192.168.1.12', status: 'Online', icon: 'laptop' },
  { name: 'Smart TV Samsung', ip: '192.168.1.15', status: 'Online', icon: 'stream' },
  { name: 'iPhone de Ana', ip: '192.168.1.16', status: 'Online', icon: 'person' },
  { name: 'Echo Dot', ip: '192.168.1.20', status: 'Online', icon: 'assistant' },
  { name: 'PlayStation 5', ip: '192.168.1.25', status: 'Limitado', icon: 'game' },
  { name: 'Câmera Externa', ip: '192.168.1.30', status: 'Online', icon: 'camera' },
  { name: 'Impressora HP', ip: '192.168.1.35', status: 'Online', icon: 'printer' },
];

export const uptimeData = [99, 99, 99.2, 99.1, 99.2, 52, 99.2];
export const uptimeLabels = ['14/05', '15/05', '16/05', '17/05', '18/05', '19/05', '20/05'];
