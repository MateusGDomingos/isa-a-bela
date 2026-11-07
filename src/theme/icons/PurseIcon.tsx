import Svg, { Path } from 'react-native-svg';
import type { TabIconProps } from '@/src/theme/icons/types';
import { colors } from '@/src/theme/tokens';

export function PurseIcon({ size = 22, color = colors.textMuted, filled = false }: TabIconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path
        d="M5 9h14l-1.2 10.2a1.6 1.6 0 0 1-1.6 1.3H7.8a1.6 1.6 0 0 1-1.6-1.3z"
        stroke={color}
        strokeWidth={1.6}
        strokeLinecap="round"
        strokeLinejoin="round"
        fill={filled ? 'rgba(194,69,110,0.22)' : 'none'}
      />
      <Path
        d="M8.6 9V7.6a3.4 3.4 0 0 1 6.8 0V9"
        stroke={color}
        strokeWidth={1.6}
        strokeLinecap="round"
        fill="none"
      />
      <Path
        d="M12 16.6s-2-1.1-2-2.5a1.05 1.05 0 0 1 2-.5 1.05 1.05 0 0 1 2 .5c0 1.4-2 2.5-2 2.5z"
        stroke={color}
        strokeWidth={1.6}
        strokeLinejoin="round"
        fill={filled ? 'rgba(194,69,110,0.22)' : 'none'}
      />
    </Svg>
  );
}
