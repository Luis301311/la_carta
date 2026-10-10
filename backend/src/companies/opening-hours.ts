import { BusinessHour } from './business-hour.entity';

const toMinutes = (hhmm: string) => {
  const [h, m] = hhmm.split(':').map(Number);
  return h * 60 + m;
};

/** Día ISO (1 = lunes) y minutos del día en una zona horaria dada */
function nowIn(timezone: string, now: Date) {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: timezone,
    weekday: 'short',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(now);
  const get = (t: string) => parts.find((p) => p.type === t)?.value ?? '';
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return {
    day: days.indexOf(get('weekday')) + 1,
    minutes: parseInt(get('hour'), 10) * 60 + parseInt(get('minute'), 10),
  };
}

/**
 * ¿Está abierto ahora? Soporta horarios que pasan la medianoche
 * (p. ej. viernes 18:00–02:00). Sin horarios configurados = abierto.
 */
export function isOpenNow(hours: BusinessHour[], timezone: string, now = new Date()): boolean {
  if (!hours || hours.length === 0) return true;
  let tz = timezone;
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: tz });
  } catch {
    tz = 'America/Bogota';
  }
  const { day, minutes } = nowIn(tz, now);
  const byDay = new Map(hours.map((h) => [h.dayOfWeek, h]));

  // 1) Turno de hoy
  const today = byDay.get(day);
  if (today && !today.closed) {
    const open = toMinutes(today.openTime);
    const close = toMinutes(today.closeTime);
    if (close > open ? minutes >= open && minutes < close : minutes >= open) return true;
  }

  // 2) Turno de ayer que sigue abierto después de medianoche
  const yesterday = byDay.get(day === 1 ? 7 : day - 1);
  if (yesterday && !yesterday.closed) {
    const open = toMinutes(yesterday.openTime);
    const close = toMinutes(yesterday.closeTime);
    if (close <= open && minutes < close) return true;
  }
  return false;
}
