/**
 * useNotifications — unified push notification service.
 *
 * Priority:
 *   1. @capacitor/local-notifications  (native Android / iOS)
 *   2. Web Notifications API           (browser / WebView fallback)
 *
 * Usage:
 *   const { permission, requestPermission, notify } = useNotifications()
 */
import { useState, useEffect, useCallback } from 'react'

const PERM_KEY = 'fantatech_notif_perm'

async function tryCapacitorNotify(title, body, id) {
  try {
    const { LocalNotifications } = await import('@capacitor/local-notifications')
    await LocalNotifications.schedule({
      notifications: [{
        id: id ?? Math.floor(Math.random() * 100000),
        title,
        body,
        sound: null,
        smallIcon: 'ic_stat_icon_config_sample',
        iconColor: '#38bdf8',
      }],
    })
    return true
  } catch {
    return false
  }
}

function webNotify(title, body, icon = '/icons/icon-192x192.png') {
  try {
    if (Notification.permission === 'granted') {
      new Notification(title, { body, icon })
      return true
    }
  } catch {}
  return false
}

export function useNotifications() {
  const [permission, setPermission] = useState(() => {
    if (typeof Notification === 'undefined') return 'unsupported'
    return Notification.permission
  })

  // Sync permission state with actual browser state
  useEffect(() => {
    if (typeof Notification === 'undefined') return
    setPermission(Notification.permission)
  }, [])

  const requestPermission = useCallback(async () => {
    // Try Capacitor native first
    try {
      const { LocalNotifications } = await import('@capacitor/local-notifications')
      const result = await LocalNotifications.requestPermissions()
      if (result.display === 'granted') {
        setPermission('granted')
        localStorage.setItem(PERM_KEY, 'granted')
        return 'granted'
      }
    } catch {}

    // Web Notifications API fallback
    if (typeof Notification === 'undefined') return 'unsupported'
    try {
      const result = await Notification.requestPermission()
      setPermission(result)
      localStorage.setItem(PERM_KEY, result)
      return result
    } catch {
      return 'denied'
    }
  }, [])

  const notify = useCallback(async (title, body, opts = {}) => {
    const { id, type = 'info' } = opts
    const prefix = type === 'critical' ? '🔴 '
                 : type === 'warning'  ? '⚠️ '
                 : type === 'success'  ? '✅ '
                 : '🏠 '

    const fullTitle = prefix + title

    // Try native first, fallback to web
    const native = await tryCapacitorNotify(fullTitle, body, id)
    if (!native) webNotify(fullTitle, body)
  }, [])

  return { permission, requestPermission, notify }
}
