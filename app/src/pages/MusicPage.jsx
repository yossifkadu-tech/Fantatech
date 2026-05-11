/**
 * MusicPage — YouTube Music player
 * Uses YouTube IFrame Player API (free, no key needed for playback).
 * Search requires a YouTube Data API v3 key (configurable in Settings or inline).
 */
import { useState, useEffect, useRef, useCallback } from 'react'
import { useLang } from '../context/LangContext'

const YT_SEARCH_URL = 'https://www.googleapis.com/youtube/v3/search'
const STORAGE_QUEUE = 'fantatech_music_queue'
const STORAGE_YTKEY = 'fantatech_yt_api_key'

/* ── Helpers ── */
const loadQueue = () => { try { return JSON.parse(localStorage.getItem(STORAGE_QUEUE) || '[]') } catch { return [] } }
const saveQueue = q  => { try { localStorage.setItem(STORAGE_QUEUE, JSON.stringify(q)) } catch {} }

/* ── Thumbnail helper ── */
const thumb = id => `https://i.ytimg.com/vi/${id}/mqdefault.jpg`

/* ── Load YouTube IFrame API once ── */
let ytApiLoaded = false
function loadYtApi(cb) {
  if (ytApiLoaded) { cb(); return }
  if (window.YT && window.YT.Player) { ytApiLoaded = true; cb(); return }
  const script = document.createElement('script')
  script.src = 'https://www.youtube.com/iframe_api'
  document.head.appendChild(script)
  const prev = window.onYouTubeIframeAPIReady
  window.onYouTubeIframeAPIReady = () => {
    ytApiLoaded = true
    if (prev) prev()
    cb()
  }
}

/* ── Result card ── */
function VideoCard({ item, onPlay, playing }) {
  const id    = item.id?.videoId
  const title = item.snippet?.title || ''
  const ch    = item.snippet?.channelTitle || ''
  return (
    <div onClick={() => onPlay(item)} style={{
      display: 'flex', gap: 10, alignItems: 'center',
      padding: '10px 12px', borderRadius: 12, cursor: 'pointer',
      background: playing ? 'rgba(29,78,216,0.2)' : '#1e293b',
      border: `1px solid ${playing ? '#1d4ed8' : '#334155'}`,
      transition: 'background 0.15s',
    }}>
      <div style={{ position: 'relative', flexShrink: 0 }}>
        <img src={thumb(id)} alt="" style={{ width: 64, height: 48, borderRadius: 8, objectFit: 'cover', display: 'block' }} />
        {playing && (
          <div style={{
            position: 'absolute', inset: 0, background: 'rgba(29,78,216,0.7)',
            borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 18,
          }}>▶</div>
        )}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontSize: 13, fontWeight: 600, color: playing ? '#60a5fa' : '#e2e8f0',
          overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
        }}>{title}</div>
        <div style={{ fontSize: 11, color: '#64748b', marginTop: 2 }}>{ch}</div>
      </div>
      <span style={{ fontSize: 18, flexShrink: 0 }}>{playing ? '🎵' : '▶'}</span>
    </div>
  )
}

/* ── Main component ── */
export default function MusicPage() {
  const { t, rtl } = useLang()

  /* API key */
  const [apiKey, setApiKey]     = useState(() => localStorage.getItem(STORAGE_YTKEY) || '')
  const [showKey, setShowKey]   = useState(false)
  const [keyInput, setKeyInput] = useState('')

  /* Search */
  const [query, setQuery]       = useState('')
  const [results, setResults]   = useState([])
  const [searching, setSearching] = useState(false)
  const [searchErr, setSearchErr] = useState('')

  /* Queue */
  const [queue, setQueue]       = useState(loadQueue)
  const [queueIdx, setQueueIdx] = useState(0)

  /* Player state */
  const [playerReady, setPlayerReady] = useState(false)
  const [playing, setPlaying]         = useState(false)
  const [currentItem, setCurrentItem] = useState(null)
  const [volume, setVolume]           = useState(70)

  const playerDivRef = useRef(null)
  const playerRef    = useRef(null)

  /* ── Init YouTube player ── */
  useEffect(() => {
    loadYtApi(() => {
      if (!playerDivRef.current) return
      playerRef.current = new window.YT.Player(playerDivRef.current, {
        height: '100%', width: '100%',
        playerVars: { autoplay: 1, controls: 0, rel: 0, modestbranding: 1, iv_load_policy: 3 },
        events: {
          onReady:       () => { setPlayerReady(true); playerRef.current?.setVolume(70) },
          onStateChange: (e) => {
            setPlaying(e.data === window.YT.PlayerState.PLAYING)
            // Auto-advance queue
            if (e.data === window.YT.PlayerState.ENDED) nextTrack()
          },
        },
      })
    })
    return () => { try { playerRef.current?.destroy() } catch {} }
  }, [])

  /* ── Play a video item ── */
  const playItem = useCallback((item) => {
    const id = item?.id?.videoId
    if (!id || !playerRef.current) return
    setCurrentItem(item)
    playerRef.current.loadVideoById(id)
    playerRef.current.setVolume(volume)
    setPlaying(true)
  }, [volume])

  /* ── Queue management ── */
  const addToQueue = (item) => {
    const updated = [...queue, item]
    setQueue(updated)
    saveQueue(updated)
  }

  const playFromQueue = (idx) => {
    if (!queue[idx]) return
    setQueueIdx(idx)
    playItem(queue[idx])
  }

  const nextTrack = useCallback(() => {
    const next = queueIdx + 1
    if (queue[next]) { setQueueIdx(next); playItem(queue[next]) }
  }, [queueIdx, queue, playItem])

  const prevTrack = () => {
    const prev = queueIdx - 1
    if (queue[prev]) { setQueueIdx(prev); playItem(queue[prev]) }
  }

  /* ── Search ── */
  const search = async () => {
    if (!query.trim()) return
    if (!apiKey.trim()) { setSearchErr(t.music_api_key_needed ?? 'Enter a YouTube API key below to search'); return }
    setSearching(true); setSearchErr(''); setResults([])
    try {
      const url = `${YT_SEARCH_URL}?part=snippet&q=${encodeURIComponent(query)}&type=video&videoCategoryId=10&maxResults=15&key=${apiKey}`
      const r = await fetch(url)
      const d = await r.json()
      if (d.error) { setSearchErr(d.error.message || 'Search error'); return }
      setResults(d.items || [])
    } catch (e) {
      setSearchErr(String(e))
    } finally {
      setSearching(false)
    }
  }

  /* ── Volume sync ── */
  const changeVolume = (v) => {
    setVolume(v)
    try { playerRef.current?.setVolume(v) } catch {}
  }

  const togglePlay = () => {
    try {
      if (playing) playerRef.current?.pauseVideo()
      else         playerRef.current?.playVideo()
    } catch {}
  }

  const saveApiKey = () => {
    localStorage.setItem(STORAGE_YTKEY, keyInput.trim())
    setApiKey(keyInput.trim())
    setShowKey(false)
    setKeyInput('')
  }

  const currentTitle = currentItem?.snippet?.title || (t.music_nothing_playing ?? 'Nothing playing')
  const currentCh    = currentItem?.snippet?.channelTitle || ''

  return (
    <div style={{ direction: rtl ? 'rtl' : 'ltr', paddingBottom: 20 }}>
      <h2 style={{ margin: '0 0 16px', color: '#e2e8f0', fontSize: 18 }}>
        🎵 {t.music_title ?? 'YouTube Music'}
      </h2>

      {/* ── Hidden player div ── */}
      <div style={{ position: 'absolute', width: 1, height: 1, overflow: 'hidden', opacity: 0, pointerEvents: 'none' }}>
        <div ref={playerDivRef} id="yt-player" />
      </div>

      {/* ── Now Playing card ── */}
      <div style={{
        background: playing ? 'linear-gradient(135deg, #1e3a5f, #1e1b4b)' : '#1e293b',
        border: `1px solid ${playing ? '#3b82f6' : '#334155'}`,
        borderRadius: 16, padding: '16px', marginBottom: 16,
        boxShadow: playing ? '0 0 20px rgba(59,130,246,0.2)' : 'none',
        transition: 'all 0.3s',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
          {currentItem ? (
            <img src={thumb(currentItem.id?.videoId)} alt=""
              style={{ width: 56, height: 42, borderRadius: 8, objectFit: 'cover' }} />
          ) : (
            <div style={{ width: 56, height: 42, borderRadius: 8, background: '#334155', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 22 }}>🎵</div>
          )}
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 13, fontWeight: 700, color: '#f1f5f9', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              {currentTitle}
            </div>
            {currentCh && <div style={{ fontSize: 11, color: '#64748b', marginTop: 2 }}>{currentCh}</div>}
          </div>
          {!playerReady && <div style={{ fontSize: 11, color: '#475569' }}>⏳</div>}
        </div>

        {/* Controls */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 16, marginBottom: 12 }}>
          <button onClick={prevTrack} disabled={queueIdx === 0} style={{
            background: 'none', border: 'none', color: queueIdx === 0 ? '#334155' : '#94a3b8',
            fontSize: 22, cursor: queueIdx === 0 ? 'default' : 'pointer',
          }}>⏮</button>
          <button onClick={togglePlay} disabled={!playerReady} style={{
            width: 52, height: 52, borderRadius: '50%', border: 'none',
            background: playerReady ? '#1d4ed8' : '#334155', color: '#fff',
            fontSize: 22, cursor: playerReady ? 'pointer' : 'default',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: playerReady && playing ? '0 0 14px #1d4ed8' : 'none',
          }}>
            {playing ? '⏸' : '▶'}
          </button>
          <button onClick={nextTrack} disabled={queueIdx >= queue.length - 1} style={{
            background: 'none', border: 'none', color: queueIdx >= queue.length - 1 ? '#334155' : '#94a3b8',
            fontSize: 22, cursor: queueIdx >= queue.length - 1 ? 'default' : 'pointer',
          }}>⏭</button>
        </div>

        {/* Volume */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <span style={{ fontSize: 14 }}>🔈</span>
          <input type="range" min="0" max="100" value={volume}
            onChange={e => changeVolume(parseInt(e.target.value))}
            style={{ flex: 1, accentColor: '#3b82f6' }} />
          <span style={{ fontSize: 14 }}>🔊</span>
          <span style={{ fontSize: 11, color: '#64748b', width: 28, textAlign: 'center' }}>{volume}%</span>
        </div>
      </div>

      {/* ── Search ── */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 12 }}>
        <input
          value={query}
          onChange={e => setQuery(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && search()}
          placeholder={t.music_search_placeholder ?? '🔍 Search for music…'}
          style={{
            flex: 1, padding: '11px 14px', borderRadius: 12,
            border: '1px solid #334155', background: '#1e293b',
            color: '#f1f5f9', fontSize: 14, outline: 'none',
            direction: rtl ? 'rtl' : 'ltr',
          }}
        />
        <button onClick={search} disabled={searching} style={{
          padding: '11px 18px', borderRadius: 12, border: 'none',
          background: searching ? '#334155' : '#1d4ed8',
          color: '#fff', cursor: 'pointer', fontWeight: 700, fontSize: 14,
        }}>
          {searching ? '⏳' : '🔍'}
        </button>
      </div>

      {searchErr && (
        <div style={{ background: '#450a0a', border: '1px solid #ef4444', borderRadius: 10, padding: '10px 14px', fontSize: 12, color: '#fca5a5', marginBottom: 10 }}>
          ⚠️ {searchErr}
        </div>
      )}

      {/* ── Search results ── */}
      {results.length > 0 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginBottom: 16 }}>
          <div style={{ fontSize: 12, color: '#64748b', marginBottom: 4 }}>
            {t.music_results ?? 'Results'} ({results.length})
          </div>
          {results.map(item => (
            <VideoCard
              key={item.id?.videoId}
              item={item}
              playing={currentItem?.id?.videoId === item.id?.videoId}
              onPlay={(it) => { playItem(it); addToQueue(it) }}
            />
          ))}
        </div>
      )}

      {/* ── Queue ── */}
      {queue.length > 0 && (
        <div style={{ background: '#1e293b', borderRadius: 14, border: '1px solid #334155', padding: '12px 14px', marginBottom: 16 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 10 }}>
            <div style={{ fontSize: 13, fontWeight: 700, color: '#e2e8f0' }}>
              🎶 {t.music_queue ?? 'Queue'} ({queue.length})
            </div>
            <button onClick={() => { setQueue([]); saveQueue([]); setQueueIdx(0) }} style={{
              background: 'none', border: 'none', color: '#475569', fontSize: 11, cursor: 'pointer',
            }}>{t.music_clear_queue ?? 'Clear'}</button>
          </div>
          {queue.map((item, i) => (
            <div key={i} onClick={() => playFromQueue(i)} style={{
              display: 'flex', alignItems: 'center', gap: 8, padding: '6px 0',
              borderBottom: i < queue.length - 1 ? '1px solid #1e293b' : 'none',
              cursor: 'pointer',
            }}>
              <span style={{ fontSize: 11, color: i === queueIdx ? '#3b82f6' : '#475569', width: 16, textAlign: 'center' }}>
                {i === queueIdx ? '▶' : i + 1}
              </span>
              <img src={thumb(item.id?.videoId)} alt="" style={{ width: 40, height: 30, borderRadius: 6, objectFit: 'cover' }} />
              <div style={{ flex: 1, fontSize: 12, color: i === queueIdx ? '#60a5fa' : '#94a3b8', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                {item.snippet?.title}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* ── API Key setup ── */}
      <div style={{ background: '#1e293b', borderRadius: 14, border: `1px solid ${apiKey ? '#22c55e33' : '#f59e0b33'}`, padding: '12px 14px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
          <div style={{ fontSize: 13, fontWeight: 700, color: '#e2e8f0' }}>
            🔑 YouTube Data API Key
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <div style={{ width: 7, height: 7, borderRadius: '50%', background: apiKey ? '#22c55e' : '#f59e0b' }} />
            <span style={{ fontSize: 11, color: apiKey ? '#22c55e' : '#f59e0b' }}>
              {apiKey ? (t.music_key_set ?? 'Key saved ✓') : (t.music_key_missing ?? 'Required for search')}
            </span>
          </div>
        </div>
        <div style={{ fontSize: 11, color: '#475569', marginBottom: 8 }}>
          {t.music_api_hint ?? 'Get a free key at console.cloud.google.com → YouTube Data API v3'}
        </div>
        {showKey ? (
          <div style={{ display: 'flex', gap: 8 }}>
            <input value={keyInput} onChange={e => setKeyInput(e.target.value)}
              placeholder="AIzaSy..." style={{
                flex: 1, padding: '9px 12px', borderRadius: 10, border: '1px solid #334155',
                background: '#0f172a', color: '#f1f5f9', fontSize: 13, outline: 'none',
              }} />
            <button onClick={saveApiKey} style={{
              padding: '9px 16px', borderRadius: 10, border: 'none',
              background: '#22c55e', color: '#fff', fontWeight: 700, cursor: 'pointer',
            }}>✓</button>
          </div>
        ) : (
          <button onClick={() => { setShowKey(true); setKeyInput(apiKey) }} style={{
            background: 'none', border: '1px solid #334155', borderRadius: 8,
            color: '#64748b', fontSize: 12, cursor: 'pointer', padding: '6px 14px',
          }}>
            {apiKey ? (t.music_change_key ?? 'Change Key') : (t.music_enter_key ?? 'Enter API Key')}
          </button>
        )}
      </div>
    </div>
  )
}
