import { useState } from 'react';
import { X, Search, Plus, CheckCircle, AlertCircle } from 'lucide-react';
import { useLang } from '../../contexts/LanguageContext';
import { useHomeAssistant } from '../../hooks/useHomeAssistant';

interface Props {
  onClose: () => void;
  onAdded: (entityId: string, name: string) => void;
}

type SearchState = 'idle' | 'found' | 'not_found';

export function AddDeviceModal({ onClose, onAdded }: Props) {
  const { t } = useLang();
  const { entities } = useHomeAssistant();

  const [entityId, setEntityId]     = useState('');
  const [customName, setCustomName] = useState('');
  const [searchState, setSearchState] = useState<SearchState>('idle');
  const [foundName, setFoundName]   = useState('');
  const [suggestions, setSuggestions] = useState<string[]>([]);

  // Live suggestions as user types
  function handleEntityInput(val: string) {
    setEntityId(val);
    setSearchState('idle');
    setFoundName('');
    if (val.length >= 2) {
      const lower = val.toLowerCase();
      const matches = entities
        .filter(e =>
          e.entity_id.toLowerCase().includes(lower) ||
          ((e.attributes.friendly_name as string) || '').toLowerCase().includes(lower)
        )
        .slice(0, 6)
        .map(e => e.entity_id);
      setSuggestions(matches);
    } else {
      setSuggestions([]);
    }
  }

  function pickSuggestion(id: string) {
    setEntityId(id);
    setSuggestions([]);
    doSearch(id);
  }

  function doSearch(id = entityId) {
    const found = entities.find(e => e.entity_id === id.trim());
    if (found) {
      const name = (found.attributes.friendly_name as string) || found.entity_id;
      setFoundName(name);
      setCustomName(name);
      setSearchState('found');
    } else {
      setSearchState('not_found');
    }
    setSuggestions([]);
  }

  function handleAdd() {
    if (!entityId.trim()) return;
    onAdded(entityId.trim(), customName || foundName || entityId.trim());
    onClose();
  }

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal-box glass-panel" onClick={e => e.stopPropagation()}>

        {/* Header */}
        <div className="modal-header">
          <h2><Plus size={18} /> {t('dev_add_title')}</h2>
          <button className="modal-close" onClick={onClose}><X size={20} /></button>
        </div>

        {/* Entity ID field */}
        <div className="form-group" style={{ position: 'relative' }}>
          <label>{t('dev_add_entity_id')}</label>
          <div className="input-row">
            <input
              className="text-input"
              value={entityId}
              onChange={e => handleEntityInput(e.target.value)}
              placeholder={t('dev_add_entity_hint')}
              onKeyDown={e => e.key === 'Enter' && doSearch()}
              autoFocus
            />
            <button className="btn btn-primary btn-icon" onClick={() => doSearch()}>
              <Search size={16} />
            </button>
          </div>

          {/* Autocomplete suggestions */}
          {suggestions.length > 0 && (
            <ul className="suggestions-list glass-panel">
              {suggestions.map(s => (
                <li key={s} onClick={() => pickSuggestion(s)}>
                  <span className="sug-domain">{s.split('.')[0]}</span>
                  <span className="sug-id">{s.split('.').slice(1).join('.')}</span>
                </li>
              ))}
            </ul>
          )}
        </div>

        {/* Search result */}
        {searchState === 'found' && (
          <div className="search-result found">
            <CheckCircle size={16} color="var(--success)" />
            <span>{t('dev_add_found')}: <strong>{foundName}</strong></span>
          </div>
        )}
        {searchState === 'not_found' && (
          <div className="search-result not-found">
            <AlertCircle size={16} color="var(--danger)" />
            <span>{t('dev_add_not_found')}</span>
          </div>
        )}

        {/* Custom name */}
        {(searchState === 'found' || searchState === 'not_found') && (
          <div className="form-group">
            <label>{t('dev_add_name')}</label>
            <input
              className="text-input"
              value={customName}
              onChange={e => setCustomName(e.target.value)}
              placeholder={entityId}
            />
          </div>
        )}

        {/* Actions */}
        <div className="modal-actions">
          <button className="btn btn-ghost" onClick={onClose}>
            {t('dev_add_cancel')}
          </button>
          <button
            className="btn btn-primary"
            onClick={handleAdd}
            disabled={!entityId.trim()}
          >
            <Plus size={15} /> {t('dev_add_save')}
          </button>
        </div>
      </div>
    </div>
  );
}
