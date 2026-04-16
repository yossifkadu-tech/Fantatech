
import { Wifi, WifiOff, Loader } from 'lucide-react';
import { useLang } from '../../contexts/LanguageContext';
import { UserMenu } from '../Auth/UserMenu';
import type { ConnectionStatus } from '../../hooks/useHomeAssistant';

interface Props {
  title: string;
  status: ConnectionStatus;
}

export function TopBar({ title, status }: Props) {
  const { t } = useLang();

  const statusIcon = {
    connected: <Wifi size={18} style={{ color: 'var(--success)' }} />,
    connecting: <Loader size={18} className="spin" />,
    error: <WifiOff size={18} style={{ color: 'var(--danger)' }} />,
    disconnected: <WifiOff size={18} style={{ color: 'var(--text-secondary)' }} />,
  }[status];

  const statusLabel = {
    connected: t('conn_connected'),
    connecting: t('conn_connecting'),
    error: t('conn_error'),
    disconnected: t('conn_disconnected'),
  }[status];

  return (
    <header className="topbar">
      <h1>{title}</h1>
      <div className="topbar-right">
        <div className="connection-badge">
          {statusIcon}
          <span>{statusLabel}</span>
        </div>
        <UserMenu />
      </div>
    </header>
  );
}
