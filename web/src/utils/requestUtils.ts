export const formatDate = (dateString: string): string => {
  if (!dateString.includes('-')) return dateString;
  return new Date(dateString).toLocaleDateString('th-TH', { year: 'numeric', month: 'short', day: 'numeric' });
};

export const formatDateTime = (isoString?: string): string => {
  if (!isoString) return '-';
  const date = new Date(isoString);
  const datePart = date.toLocaleDateString('th-TH', { year: 'numeric', month: 'short', day: 'numeric' });
  const hours = date.getHours().toString().padStart(2, '0');
  const minutes = date.getMinutes().toString().padStart(2, '0');
  return `${datePart} เวลา ${hours}:${minutes} น.`;
};

export const getOverdueDays = (dateStr: string, status: string): number => {
  if (status !== 'pending' && status !== 'preparing' && status !== 'ready') return 0;
  const selected = new Date(dateStr);
  selected.setHours(0, 0, 0, 0);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const diff = today.getTime() - selected.getTime();
  return diff > 0 ? Math.floor(diff / (1000 * 60 * 60 * 24)) : 0;
};
