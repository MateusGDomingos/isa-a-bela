import Svg, { Path } from 'react-native-svg';
import type { TabIconProps } from '@/src/theme/icons/types';
import { colors, withAlpha } from '@/src/theme/tokens';

const FILL_ATIVO = withAlpha(colors.accent, 0.22);

export function SparkleIcon({ size = 22, color = colors.textMuted, filled = false }: TabIconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path
        d="M11 4.5 12.6 9 17 10.6l-4.4 1.6L11 16.7l-1.6-4.5L5 10.6 9.4 9z"
        stroke={color}
        strokeWidth={1.6}
        strokeLinecap="round"
        strokeLinejoin="round"
        fill={filled ? FILL_ATIVO : 'none'}
      />
      <Path
        d="M18 3.5v3M16.5 5h3M17.5 16.5v3M16 18h3"
        stroke={color}
        strokeWidth={1.6}
        strokeLinecap="round"
        fill="none"
      />
    </Svg>
  );
}
