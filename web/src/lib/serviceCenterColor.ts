/** Returns a consistent pastel HSL color for a given service center name. */
export function getServiceCenterColor(name: string): string {
  let hash = 5381;
  for (let i = 0; i < name.length; i++) {
    hash = ((hash << 5) + hash + name.charCodeAt(i)) >>> 0;
  }
  return `hsl(${(hash * 137.508) % 360}, 70%, 70%)`;
}
