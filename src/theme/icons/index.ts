import { CalendarHeartIcon } from '@/src/theme/icons/CalendarHeartIcon';
import { PurseIcon } from '@/src/theme/icons/PurseIcon';
import { SparkleIcon } from '@/src/theme/icons/SparkleIcon';
import { TulipIcon } from '@/src/theme/icons/TulipIcon';

export type { TabIconProps } from '@/src/theme/icons/types';
export { TulipIcon } from '@/src/theme/icons/TulipIcon';
export { PurseIcon } from '@/src/theme/icons/PurseIcon';
export { SparkleIcon } from '@/src/theme/icons/SparkleIcon';
export { CalendarHeartIcon } from '@/src/theme/icons/CalendarHeartIcon';

/** A ordem deste objeto é a ordem das abas no rodapé. */
export const tabIcons = {
  inicio: TulipIcon,
  financas: PurseIcon,
  tarefas: SparkleIcon,
  agenda: CalendarHeartIcon,
} as const;
