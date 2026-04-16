import { useState, useRef, useEffect } from 'react';
import { X, Sparkles, Send, Lightbulb, Loader } from 'lucide-react';
import { useHomeAssistant } from '../../hooks/useHomeAssistant';
import { useLang } from '../../contexts/LanguageContext';

interface Props { onClose: () => void; }

interface Message {
  role: 'user' | 'ai';
  text: string;
}

function analyzeDevices(entities: ReturnType<typeof useHomeAssistant>['entities']): string {
  const on    = entities.filter(e => e.state === 'on');
  const lights = on.filter(e => e.entity_id.startsWith('light.'));
  const switches = on.filter(e => e.entity_id.startsWith('switch.'));
  const locks  = entities.filter(e => e.entity_id.startsWith('lock.') && e.state === 'unlocked');

  const parts: string[] = [];
  if (lights.length)   parts.push(`${lights.length} תאורות דולקות`);
  if (switches.length) parts.push(`${switches.length} מתגים פועלים`);
  if (locks.length)    parts.push(`${locks.length} מנעולים פתוחים`);
  if (!parts.length)   return 'כל המכשירים כבויים כרגע.';
  return `כרגע: ${parts.join(', ')}.`;
}

function getAIResponse(input: string, entities: ReturnType<typeof useHomeAssistant>['entities']): string {
  const q = input.toLowerCase();
  const on = entities.filter(e => e.state === 'on');
  const lights = entities.filter(e => e.entity_id.startsWith('light.'));
  const lightsOn = lights.filter(e => e.state === 'on');

  if (q.includes('מה') && (q.includes('דלוק') || q.includes('פועל') || q.includes('מצב')))
    return analyzeDevices(entities);

  if (q.includes('אור') || q.includes('תאורה'))
    return lightsOn.length > 0
      ? `יש ${lightsOn.length} תאורות פועלות: ${lightsOn.map(e => e.attributes.friendly_name || e.entity_id).join(', ')}.`
      : 'כל התאורות כבויות.';

  if (q.includes('חסוך') || q.includes('חשמל') || q.includes('אנרגיה'))
    return on.length > 0
      ? `יש ${on.length} מכשירים פועלים. כדי לחסוך חשמל, שקול לכבות: ${on.slice(0,3).map(e => e.attributes.friendly_name || e.entity_id).join(', ')}.`
      : 'כל המכשירים כבויים — צריכת החשמל נמוכה.';

  if (q.includes('אבטחה') || q.includes('מנעול'))
    return entities.filter(e => e.entity_id.startsWith('lock.') && e.state === 'unlocked').length > 0
      ? 'שים לב — יש מנעולים פתוחים! בדוק בדף האבטחה.'
      : 'כל המנעולים נעולים. הבית מאובטח.';

  if (q.includes('סיכום') || q.includes('דוח') || q.includes('מה קורה'))
    return `סיכום הבית: ${analyzeDevices(entities)} סה"כ ${entities.length} מכשירים מחוברים.`;

  if (q.includes('הצע') || q.includes('המלצה') || q.includes('טיפ'))
    return 'טיפ: הגדר אוטומציה לכיבוי כל האורות בחצות. לחץ על "אוטומציות" בתפריט.';

  return `מצאתי ${entities.length} מכשירים. תוכל לשאול על מצב האורות, חיסכון בחשמל, אבטחה, או לבקש סיכום כללי.`;
}

const SUGGESTIONS = [
  'מה דולק עכשיו?',
  'איך לחסוך חשמל?',
  'מצב האבטחה',
  'תן סיכום כללי',
];

export function AIAssistant({ onClose }: Props) {
  const { entities } = useHomeAssistant();
  const { t } = useLang();
  const [messages, setMessages] = useState<Message[]>([
    { role: 'ai', text: `שלום! אני העוזר החכם של FantaTech. ${analyzeDevices(entities)} איך אוכל לעזור?` },
  ]);
  const [input, setInput]   = useState('');
  const [loading, setLoading] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: 'smooth' }); }, [messages]);

  function send(text = input.trim()) {
    if (!text) return;
    setMessages(m => [...m, { role: 'user', text }]);
    setInput('');
    setLoading(true);
    setTimeout(() => {
      setMessages(m => [...m, { role: 'ai', text: getAIResponse(text, entities) }]);
      setLoading(false);
    }, 600);
  }

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="ai-panel glass-panel" onClick={e => e.stopPropagation()}>

        {/* Header */}
        <div className="ai-header">
          <div className="ai-header-title">
            <div className="ai-avatar"><Sparkles size={18} /></div>
            <div>
              <div className="ai-title">FantaTech AI</div>
              <div className="ai-subtitle">{t('ai_subtitle')}</div>
            </div>
          </div>
          <button className="modal-close" onClick={onClose}><X size={20} /></button>
        </div>

        {/* Messages */}
        <div className="ai-messages">
          {messages.map((m, i) => (
            <div key={i} className={`ai-bubble ai-bubble-${m.role}`}>
              {m.role === 'ai' && <Lightbulb size={14} className="ai-bubble-icon" />}
              <span>{m.text}</span>
            </div>
          ))}
          {loading && (
            <div className="ai-bubble ai-bubble-ai">
              <Loader size={14} className="ai-bubble-icon spin" />
              <span>חושב...</span>
            </div>
          )}
          <div ref={bottomRef} />
        </div>

        {/* Suggestions */}
        <div className="ai-suggestions">
          {SUGGESTIONS.map(s => (
            <button key={s} className="ai-suggestion-btn" onClick={() => send(s)}>{s}</button>
          ))}
        </div>

        {/* Input */}
        <div className="ai-input-row">
          <input
            className="text-input ai-input"
            placeholder={t('ai_placeholder')}
            value={input}
            onChange={e => setInput(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && send()}
            autoFocus
          />
          <button className="btn btn-primary btn-ai-send" onClick={() => send()} disabled={!input.trim()}>
            <Send size={16} />
          </button>
        </div>
      </div>
    </div>
  );
}
