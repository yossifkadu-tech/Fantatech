export interface HAEntity {
  entity_id: string;
  state: string;
  attributes: Record<string, unknown>;
  last_changed: string;
  last_updated: string;
}

export interface HAConfig {
  url: string;
  token: string;
}

export type DeviceDomain =
  | 'light'
  | 'switch'
  | 'cover'
  | 'lock'
  | 'climate'
  | 'camera'
  | 'binary_sensor'
  | 'sensor'
  | 'alarm_control_panel'
  | 'media_player';

export interface DeviceGroup {
  domain: DeviceDomain;
  label: string;
  icon: string;
  entities: HAEntity[];
}
