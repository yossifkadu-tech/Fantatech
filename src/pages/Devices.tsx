import { useState, useEffect } from 'react';
import { Search, Plus, X, Star } from 'lucide-react';
import { useHomeAssistant } from '../hooks/useHomeAssistant';
import { useLang } from '../contexts/LanguageContext';
import { TopBar } from '../components/Layout/TopBar';
import { DeviceCard } from '../components/Devices/DeviceCard';
import { AddDeviceModal } from '../components/Devices/AddDeviceModal';

const FAVORITES_KEY = 'fantatech_favorites';

function loadFavorites(): string[] {
  try { return JSON.parse(localStorage.getItem(FAVORITES_KEY) ?? '[]'); } catch { return []; }
}
function saveFavorites(ids: string[]) {
  try { localStorage.setItem(FAVORITES_KEY, JSON.stringify(ids)); } catch {}
}

export function DevicesPage() {
  const { entities, status, entitiesByDomain } = useHomeAssistant();
  const { t } = useLang();
  const [filter, setFilter]       = useState('all');
  const [search, setSearch]       = useState('');
  const [showModal, setShowModal] = useState(false);
  const [favorites, setFavorites] = useState<string[]>(loadFavorites);
  const [toast, setToast]         = useState('');

  useEffect(() => { saveFavorites(favorites); }, [favorites]);

  // Auto-hide toast
  useEffect(() => {
    if (!toast) return;
    const t = setTimeout(() => setToast(''), 2500);
    return () => clearTimeout(t);
  }, [toast]);

  const DOMAINS = [
    { key: 'all',          label: t('dev_all')     },
    { key: 'favorites',    label: t('dev_favorites') },
    { key: 'light',        label: t('dev_lights')  },
    { key: 'switch',       label: t('dev_switches') },
    { key: 'cover',        label: t('dev_covers')  },
    { key: 'lock',         label: t('dev_locks')   },
    { key: 'climate',      label: t('dev_climate') },
    { key: 'media_player', label: t('dev_media')   },
    { key: 'sensor',       label: t('dev_sensors') },
  ];

  const baseList =
    filter === 'all'       ? entities :
    filter === 'favorites' ? entities.filter(e => favorites.includes(e.entity_id)) :
    entitiesByDomain(filter);

  const filtered = baseList.filter(e => {
    const name = (e.attributes.friendly_name as string) || e.entity_id;
    return name.toLowerCase().includes(search.toLowerCase()) ||
           e.entity_id.toLowerCase().includes(search.toLowerCase());
  });

  function handleAdded(entityId: string, name: string) {
    if (!favorites.includes(entityId)) {
      setFavorites(prev => [...prev, entityId]);
    }
    setToast(`${t('dev_add_success')} — ${name}`);
  }

  return (
    <>
      <TopBar title={t('nav_devices')} status={status} />

      {/* Filter + search bar */}
      <div className="filter-bar glass-panel">
        {/* Search row */}
        <div className="search-row">
          <div className="search-wrap">
            <Search size={15} className="search-icon" />
            <input
              className="search-input"
              placeholder={t('dev_search')}
              value={search}
              onChange={e => setSearch(e.target.value)}
            />
            {search && (
              <button className="search-clear" onClick={() => setSearch('')}>
                <X size={13} />
              </button>
            )}
          </div>
          <button className="btn btn-primary btn-add-device" onClick={() => setShowModal(true)}>
            <Plus size={16} />
            <span>{t('dev_add')}</span>
          </button>
        </div>

        {/* Domain filters */}
        <div className="domain-filters">
          {DOMAINS.map(({ key, label }) => (
            <button
              key={key}
              className={`filter-btn ${filter === key ? 'active' : ''}`}
              onClick={() => setFilter(key)}
            >
              {key === 'favorites' && <Star size={11} style={{ marginInlineEnd: 3 }} />}
              {label}
            </button>
          ))}
        </div>
      </div>

      {/* Device grid */}
      {filtered.length === 0 ? (
        <p className="muted">{t('dev_none')}</p>
      ) : (
        <div className="widgets-grid">
          {filtered.map(e => (
            <DeviceCard
              key={e.entity_id}
              entity={e}
              isFavorite={favorites.includes(e.entity_id)}
              onToggleFavorite={id =>
                setFavorites(prev =>
                  prev.includes(id) ? prev.filter(f => f !== id) : [...prev, id]
                )
              }
            />
          ))}
        </div>
      )}

      {/* Add Device Modal */}
      {showModal && (
        <AddDeviceModal
          onClose={() => setShowModal(false)}
          onAdded={handleAdded}
        />
      )}

      {/* Toast notification */}
      {toast && <div className="toast">{toast}</div>}
    </>
  );
}
