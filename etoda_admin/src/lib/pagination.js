// ── Windowed paginator helper: shows at most 5 page buttons with ellipses ──
export const buildPageWindow = (current, total) => {
  if (total <= 5) return Array.from({ length: total }, (_, i) => i + 1);
  const pages = [];
  const start = Math.max(2, current - 1);
  const end   = Math.min(total - 1, current + 1);
  pages.push(1);
  if (start > 2) pages.push('…');
  for (let i = start; i <= end; i++) pages.push(i);
  if (end < total - 1) pages.push('…');
  pages.push(total);
  return pages;
};