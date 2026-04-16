import { useEffect, useState } from 'react';
import { connectHA, onStateChange, loadConfig, isConnected } from '../api/homeAssistant';
import type { HAEntity } from '../types';

export type ConnectionStatus = 'disconnected' | 'connecting' | 'connected' | 'error';

export function useHomeAssistant() {
  const [entities, setEntities] = useState<HAEntity[]>([]);
  const [status, setStatus] = useState<ConnectionStatus>('disconnected');

  useEffect(() => {
    const unsubscribe = onStateChange((updated) => {
      setEntities(updated);
      setStatus('connected');
    });

    const config = loadConfig();
    if (config && !isConnected()) {
      setStatus('connecting');
      connectHA(config)
        .then(() => setStatus('connected'))
        .catch(() => setStatus('error'));
    }

    return unsubscribe;
  }, []);

  const entitiesByDomain = (domain: string) =>
    entities.filter((e) => e.entity_id.startsWith(domain + '.'));

  return { entities, status, entitiesByDomain };
}
