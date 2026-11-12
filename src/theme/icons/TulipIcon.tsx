import Svg, { Path } from 'react-native-svg';
import type { TabIconProps } from '@/src/theme/icons/types';
import { colors, withAlpha } from '@/src/theme/tokens';

const FILL_ATIVO = withAlpha(colors.accent, 0.22);

export function TulipIcon({ size = 22, color = colors.textMuted, filled = false }: TabIconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      <Path
        d="M12 13.6c-3.3 0-5.4-2.4-5.4-5.8V4.3l2.8 2L12 3.2l2.6 3.1 2.8-2v3.5c0 3.4-2.1 5.8-5.4 5.8z"
        stroke={color}
        strokeWidth={1.6}
        strokeLinecap="round"
        strokeLinejoin="round"
        fill={filled ? FILL_ATIVO : 'none'}
      />
      <Path d="M12 13.6V21" stroke={color} strokeWidth={1.6} strokeLinecap="round" fill="none" />
      <Path
        d="M12 19.2c-.8-2-2.8-3.1-5-3.1.5 2.4 2.5 3.5 5 3.1zM12 18.6c.9-1.8 2.7-2.8 4.6-2.8-.5 2.2-2.3 3.2-4.6 2.8z"
        stroke={color}
        strokeWidth={1.6}
        strokeLinejoin="round"
        fill={filled ? FILL_ATIVO : 'none'}
      />
    </Svg>
  );
}
