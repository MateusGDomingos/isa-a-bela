import Svg, { Path, Rect } from 'react-native-svg';
import type { TabIconProps } from '@/src/theme/icons/types';
import { colors } from '@/src/theme/tokens';

export function CalendarHeartIcon({
  size = 22,
  color = colors.textMuted,
  filled = false,
}: TabIconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Rect
        x={3.5}
        y={5}
        width={17}
        height={15.5}
        rx={2.5}
        stroke={color}
        strokeWidth={1.6}
        strokeLinejoin="round"
        fill={filled ? 'rgba(194,69,110,0.22)' : 'none'}
      />
      <Path
        d="M8 3v4M16 3v4M3.5 9.5h17"
        stroke={color}
        strokeWidth={1.6}
        strokeLinecap="round"
        fill="none"
      />
      <Path
        d="M12 18.2s-2.7-1.5-2.7-3.4a1.45 1.45 0 0 1 2.7-.7 1.45 1.45 0 0 1 2.7.7c0 1.9-2.7 3.4-2.7 3.4z"
        stroke={color}
        strokeWidth={1.6}
        strokeLinejoin="round"
        fill={filled ? 'rgba(194,69,110,0.22)' : 'none'}
      />
    </Svg>
  );
}
