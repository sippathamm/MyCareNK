export function toLocalDateString(d: Date): string {
  const y   = d.getFullYear();
  const m   = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export function formatLeadTime(minutes: number | null | undefined): string {
  if (minutes === null || minutes === undefined || minutes < 0) return '—';
  const mins = Number(minutes);
  if (mins < 1) return `${Math.round(mins * 60)} วินาที`;
  const total = Math.round(mins);
  const h = Math.floor(total / 60);
  const m = total % 60;
  if (h === 0) return `${m} นาที`;
  return `${h} ชม. ${m} นาที`;
}
