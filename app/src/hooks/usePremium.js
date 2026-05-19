/**
 * usePremium — plan management hook.
 *
 * Plans: free | smart | pro | business
 * Stored in localStorage 'fantatech_plan' (replace with backend in production).
 */

export const PLANS = {
  free: {
    id: 'free', nameHe: 'חינמי', nameEn: 'Free',
    price: 0, priceLabel: 'חינמי',
    color: '#64748b',
    features: ['עד 10 מכשירים', 'עד 5 אוטומציות', 'Dashboard בסיסי', 'חנות FantaTech'],
    limits: { devices: 10, automations: 5, scheduler: false, ai: false, cameras: 2 },
  },
  smart: {
    id: 'smart', nameHe: 'Smart', nameEn: 'Smart',
    price: 29, priceLabel: '₪29/חודש',
    color: '#3b82f6',
    popular: false,
    features: ['מכשירים ללא הגבלה', 'אוטומציות ללא הגבלה', 'Scheduler + תזמונים', 'פקודות קוליות', 'התראות Push', 'ייצוא נתונים'],
    limits: { devices: Infinity, automations: Infinity, scheduler: true, ai: false, cameras: 5 },
  },
  pro: {
    id: 'pro', nameHe: 'Pro', nameEn: 'Pro',
    price: 59, priceLabel: '₪59/חודש',
    color: '#8b5cf6',
    popular: true,
    features: ['הכל ב-Smart', 'Gemini AI Assistant', 'מצלמות ללא הגבלה', 'אבטחה מתקדמת', 'GPS + גיאו-גידור', 'דוחות ואנליטיקה'],
    limits: { devices: Infinity, automations: Infinity, scheduler: true, ai: true, cameras: Infinity },
  },
  business: {
    id: 'business', nameHe: 'עסקי', nameEn: 'Business',
    price: 99, priceLabel: '₪99/חודש',
    color: '#f59e0b',
    features: ['הכל ב-Pro', 'עד 5 משתמשים', 'API גישה מלאה', 'לוגו מותאם אישית', 'תמיכה ישירה 24/7', 'SLA מובטח'],
    limits: { devices: Infinity, automations: Infinity, scheduler: true, ai: true, cameras: Infinity },
  },
}

const PLAN_ORDER = ['free', 'smart', 'pro', 'business']

export function getPlan() {
  const saved = localStorage.getItem('fantatech_plan')
  return PLANS[saved] ?? PLANS.free
}

export function setPlan(planId) {
  localStorage.setItem('fantatech_plan', planId)
  window.dispatchEvent(new Event('fantatech_plan_change'))
}

export function usePremium() {
  const plan = getPlan()

  const isPremium  = plan.id !== 'free'
  const isPro      = plan.id === 'pro' || plan.id === 'business'
  const isBusiness = plan.id === 'business'

  const can = (feature) => {
    switch (feature) {
      case 'scheduler':  return plan.limits.scheduler
      case 'ai':         return plan.limits.ai
      case 'cameras':    return (plan.limits.cameras || 0) > 2
      case 'users':      return isBusiness
      default:           return true
    }
  }

  const planLevel = PLAN_ORDER.indexOf(plan.id)
  const isAtLeast = (planId) => planLevel >= PLAN_ORDER.indexOf(planId)

  return { plan, isPremium, isPro, isBusiness, can, isAtLeast }
}
