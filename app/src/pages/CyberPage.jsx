/**
 * CyberPage — network & device security dashboard.
 * Runs a security audit via the hub backend and shows:
 *   • Security score (0–100)
 *   • Threat list with severity levels
 *   • Device audit (per-device issues)
 *   • Recommendations
 */
import { useState } from 'react'
import { api } from '../hooks/useHub'
import { useLang } from '../context/LangContext'

export default function CyberPage() {
  const { t, rtl } = useLang()
  const [status, setStatus]   = useState('idle')   // idle | scanning | done | error
  const [result, setResult]   = useState(null)
  const [devAudit, setDevAudit] = useState(null)
  const [errMsg, setErrMsg]   = useState('')
  const [devTab, setDevTab]   = useState(false)

  const runScan = async () => {
    setStatus('scanning'); setResult(null); setDevAudit(null); setErrMsg('')
    try {
      const [scanRes, auditRes] = await Promise.allSettled([
        api.get('/cyber/scan'),
        api.get('/cyber/devices-audit'),
      ])
      if (scanRes.status === 'fulfilled') setResult(scanRes.value.data)
      else throw new Error(scanRes.reason?.response?.data?.detail || t.error)
      if (auditRes.status === 'fulfilled') setDevAudit(auditRes.value.data)
      setStatus('done')
    } catch (e) {
      setErrMsg(e?.message || t.error)
      setStatus('error')
    }
  }

  const scoreColor = s =>
    s >= 80 ? '#22c55e' : s >= 60 ? '#f59e0b' : '#ef4444'
  const scoreLabel = s =>
    s >= 80 ? (t.cyber_score_good ?? 'Good') : s >= 60 ? (t.cyber_score_medium ?? 'Fair') : (t.cyber_score_low ?? 'At Risk')

  const levelColor = l =>
    l === 'high' ? '#ef4444' : l === 'medium' ? '#f59e0b' : l === 'low' ? '#38bdf8' : '#64748b'
  const levelBg = l =>
    l === 'high' ? '#450a0a' : l === 'medium' ? '#431407' : l === 'low' ? '#0c2340' : '#1e293b'
  const levelBorder = l =>
    l === 'high' ? '#ef444444' : l === 'medium' ? '#f59e0b44' : l === 'low' ? '#38bdf844' : '#334155'

  return (
    <div style={{ direction: rtl ? 'rtl' : 'ltr' }}>

      {/* ── Header ── */}
      <div style={{ marginBottom: 16 }}>
        <h2 style={{ margin: '0 0 4px', color: '#e2e8f0', fontSize: 18 }}>
          🛡️ {t.cyber_title ?? 'Cyber Security'}
        </h2>
        <div style={{ fontSize: 12, color: '#475569' }}>
          {t.cyber_subtitle ?? 'Network & device vulnerability scanner'}
        </div>
      </div>

      {/* ── Scan button ── */}
      {status !== 'scanning' && (
        <button onClick={runScan} style={{
          width: '100%', padding: '13px 0', borderRadius: 12,
          background: status === 'done' ? '#1e3a5f' : '#1d4ed8',
          border: `1px solid ${status === 'done' ? '#3b82f6' : '#2563eb'}`,
          color: '#fff', fontWeight: 700, fontSize: 14, cursor: 'pointer', marginBottom: 18,
        }}>
          🔍 {status === 'done' ? (t.cyber_rescan ?? 'Re-scan') : (t.cyber_start_scan ?? 'Start Security Scan')}
        </button>
      )}

      {/* ── Scanning indicator ── */}
      {status === 'scanning' && (
        <div style={{
          background: '#0f172a', border: '1px solid #1d4ed8', borderRadius: 14,
          padding: 24, textAlign: 'center', marginBottom: 18,
        }}>
          <div style={{ fontSize: 42, marginBottom: 10 }}>🔍</div>
          <div style={{ color: '#38bdf8', fontWeight: 700, fontSize: 14, marginBottom: 6 }}>
            {t.cyber_scanning ?? 'Scanning network & devices...'}
          </div>
          <div style={{ display: 'flex', gap: 6, justifyContent: 'center', flexWrap: 'wrap', marginTop: 10 }}>
            {['Ports', 'Devices', 'Firmware', 'Auth'].map(step => (
              <span key={step} style={{
                background: '#1e293b', border: '1px solid #334155',
                borderRadius: 6, padding: '3px 10px', fontSize: 11, color: '#64748b',
              }}>⏳ {step}</span>
            ))}
          </div>
          {/* Animated bar */}
          <div style={{ width: '100%', height: 3, background: '#1e293b', borderRadius: 2, overflow: 'hidden', marginTop: 16 }}>
            <div style={{
              height: '100%', width: '35%', background: '#1d4ed8',
              borderRadius: 2, animation: 'slide 1.4s ease-in-out infinite',
            }} />
            <style>{`@keyframes slide { 0%{margin-right:100%} 100%{margin-right:-35%} }`}</style>
          </div>
        </div>
      )}

      {/* ── Error ── */}
      {status === 'error' && (
        <div style={{
          background: '#7f1d1d', border: '1px solid #ef4444', borderRadius: 10,
          padding: '12px 16px', fontSize: 13, color: '#fca5a5', marginBottom: 16,
        }}>⚠️ {errMsg}</div>
      )}

      {/* ── Results ── */}
      {status === 'done' && result && (
        <div>

          {/* Score card */}
          <div style={{
            background: '#1e293b', border: `2px solid ${scoreColor(result.score)}22`,
            borderRadius: 16, padding: '20px 16px', marginBottom: 16,
            display: 'flex', alignItems: 'center', gap: 20,
          }}>
            {/* Big score */}
            <div style={{ textAlign: 'center', flexShrink: 0 }}>
              <div style={{
                width: 80, height: 80, borderRadius: '50%',
                border: `4px solid ${scoreColor(result.score)}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                background: `${scoreColor(result.score)}11`,
              }}>
                <span style={{ fontSize: 26, fontWeight: 900, color: scoreColor(result.score) }}>
                  {result.score}
                </span>
              </div>
              <div style={{ fontSize: 11, color: scoreColor(result.score), fontWeight: 700, marginTop: 4 }}>
                {scoreLabel(result.score)}
              </div>
            </div>

            <div>
              <div style={{ fontSize: 16, fontWeight: 800, color: '#e2e8f0', marginBottom: 6 }}>
                {t.cyber_security_score ?? 'Security Score'}
              </div>
              <div style={{ fontSize: 12, color: '#64748b', lineHeight: 1.7 }}>
                {result.devices_checked > 0 && (
                  <div>🔌 {result.devices_checked} {t.cyber_devices_checked ?? 'devices checked'}</div>
                )}
                {result.gateway && (
                  <div>🌐 {t.cyber_gateway ?? 'Gateway'}: {result.gateway}</div>
                )}
                <div>⚠️ {result.threats?.length ?? 0} {t.cyber_threats_found ?? 'findings'}</div>
              </div>
            </div>
          </div>

          {/* Threats */}
          {result.threats?.length > 0 && (
            <div style={{ marginBottom: 16 }}>
              <div style={{ fontSize: 13, fontWeight: 700, color: '#94a3b8', marginBottom: 10 }}>
                🔎 {t.cyber_findings ?? 'Findings'}
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {result.threats.map((th, i) => (
                  <div key={i} style={{
                    background: levelBg(th.level),
                    border: `1px solid ${levelBorder(th.level)}`,
                    borderRadius: 10, padding: '10px 14px',
                  }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 3 }}>
                      <span style={{ fontSize: 16 }}>{th.icon}</span>
                      <span style={{ fontSize: 13, fontWeight: 700, color: levelColor(th.level) }}>
                        {th.title}
                      </span>
                      <span style={{
                        marginRight: 'auto', fontSize: 9, fontWeight: 700,
                        color: levelColor(th.level),
                        background: `${levelColor(th.level)}22`, borderRadius: 4, padding: '1px 6px',
                        textTransform: 'uppercase',
                      }}>{th.level}</span>
                    </div>
                    <div style={{ fontSize: 11, color: '#94a3b8', lineHeight: 1.6, paddingRight: 24 }}>
                      {th.detail}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Recommendations */}
          {result.recommendations?.length > 0 && (
            <div style={{ marginBottom: 16 }}>
              <div style={{ fontSize: 13, fontWeight: 700, color: '#94a3b8', marginBottom: 10 }}>
                💡 {t.cyber_recommendations ?? 'Recommendations'}
              </div>
              <div style={{
                background: '#0f2d4a', border: '1px solid #1d4ed8',
                borderRadius: 12, padding: '12px 16px',
                display: 'flex', flexDirection: 'column', gap: 8,
              }}>
                {result.recommendations.map((rec, i) => (
                  <div key={i} style={{ fontSize: 12, color: '#93c5fd', lineHeight: 1.6 }}>
                    {rec}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Device audit toggle */}
          {devAudit?.devices?.length > 0 && (
            <div style={{ marginBottom: 16 }}>
              <button
                onClick={() => setDevTab(v => !v)}
                style={{
                  width: '100%', padding: '10px 16px', borderRadius: 10,
                  background: '#1e293b', border: '1px solid #334155',
                  color: '#94a3b8', cursor: 'pointer', fontSize: 13, fontWeight: 600,
                  display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                }}
              >
                <span>🔌 {t.cyber_device_audit ?? 'Device Audit'} ({devAudit.devices.length})</span>
                <span>{devTab ? '▲' : '▼'}</span>
              </button>

              {devTab && (
                <div style={{ marginTop: 8, display: 'flex', flexDirection: 'column', gap: 6 }}>
                  {devAudit.devices.map((dev, i) => (
                    <div key={i} style={{
                      background: dev.issues?.length > 0 ? '#451a03' : '#0f2d1a',
                      border: `1px solid ${dev.issues?.length > 0 ? '#f59e0b44' : '#22c55e44'}`,
                      borderRadius: 10, padding: '8px 12px',
                      display: 'flex', alignItems: 'center', gap: 10,
                    }}>
                      <span style={{ fontSize: 18 }}>
                        {dev.issues?.length > 0 ? '⚠️' : '✅'}
                      </span>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ fontSize: 13, fontWeight: 700, color: '#e2e8f0', marginBottom: 2 }}>
                          {dev.name}
                        </div>
                        {dev.ip && (
                          <div style={{ fontSize: 10, color: '#475569', direction: 'ltr' }}>{dev.ip}</div>
                        )}
                        {dev.issues?.map((iss, j) => (
                          <div key={j} style={{ fontSize: 11, color: '#fbbf24', marginTop: 2 }}>
                            {iss}
                          </div>
                        ))}
                        {!dev.issues?.length && (
                          <div style={{ fontSize: 11, color: '#22c55e' }}>
                            {t.cyber_no_issues ?? 'No issues found'}
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

        </div>
      )}

      {/* ── Idle state info ── */}
      {status === 'idle' && (
        <div style={{
          background: '#1e293b', border: '1px solid #334155',
          borderRadius: 14, padding: 24, textAlign: 'center',
        }}>
          <div style={{ fontSize: 48, marginBottom: 12 }}>🛡️</div>
          <div style={{ fontSize: 14, fontWeight: 700, color: '#e2e8f0', marginBottom: 8 }}>
            {t.cyber_idle_title ?? 'Security Scanner Ready'}
          </div>
          <div style={{ fontSize: 12, color: '#475569', lineHeight: 1.8 }}>
            {t.cyber_idle_hint ?? 'Scans for open ports, unprotected devices, and network vulnerabilities'}
          </div>
          <div style={{ display: 'flex', gap: 8, justifyContent: 'center', marginTop: 14, flexWrap: 'wrap' }}>
            {['🔓 Default passwords', '📡 Open ports', '🔒 Auth check', '📶 Router audit'].map(item => (
              <span key={item} style={{
                background: '#0f172a', border: '1px solid #334155',
                borderRadius: 6, padding: '4px 10px', fontSize: 11, color: '#64748b',
              }}>{item}</span>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
