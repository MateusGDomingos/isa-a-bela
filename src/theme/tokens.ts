export const colors = {
  background: '#FFF6F8',
  surface: '#FFFFFF',
  line: '#F4DFE6',
  accent: '#C2456E',
  accentSoft: '#FBE1E9',
  text: '#3B1F2B',
  textMuted: '#9A7482',
  balanceGradient: ['#EB7A9C', '#C2456E'] as const,
  income: '#2F9E7E',
  expense: '#C2456E',
  noCategory: '#C7C2CB',
  danger: '#B3261E',
} as const;

export const fonts = {
  brand: 'PlayfairDisplay_600SemiBold_Italic',
  body: 'Inter_400Regular',
  bodyStrong: 'Inter_600SemiBold',
} as const;

export const spacing = { xs: 4, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32 } as const;

export const radii = { card: 16, item: 12, tabBar: 24, pill: 999 } as const;
