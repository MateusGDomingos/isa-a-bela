import { StyleSheet, View, type ViewProps } from 'react-native';
import { colors, radii, spacing } from '@/src/theme/tokens';

export function Cartao({ children, style, ...resto }: ViewProps) {
  return (
    <View style={[estilos.cartao, style]} {...resto}>
      {children}
    </View>
  );
}

const estilos = StyleSheet.create({
  cartao: {
    backgroundColor: colors.surface,
    borderRadius: radii.card,
    borderWidth: 1,
    borderColor: colors.line,
    padding: spacing.lg,
  },
});
