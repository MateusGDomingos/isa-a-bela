import { StyleSheet, Text, TextInput, View, type TextInputProps } from 'react-native';
import { colors, fonts, radii, spacing } from '@/src/theme/tokens';

export type CampoProps = Omit<TextInputProps, 'value' | 'onChangeText'> & {
  rotulo: string;
  valor: string;
  onChangeText: (texto: string) => void;
  erro?: string;
};

export function Campo({ rotulo, valor, onChangeText, erro, ...resto }: CampoProps) {
  return (
    <View style={{ marginBottom: spacing.md }}>
      <Text style={estilos.rotulo}>{rotulo}</Text>
      <TextInput
        accessibilityLabel={rotulo}
        accessibilityHint={erro}
        value={valor}
        onChangeText={onChangeText}
        placeholderTextColor={colors.textMuted}
        style={[estilos.campo, erro ? { borderColor: colors.danger } : null]}
        {...resto}
      />
      {erro ? <Text style={estilos.erro}>{erro}</Text> : null}
    </View>
  );
}

const estilos = StyleSheet.create({
  rotulo: {
    fontFamily: fonts.bodyStrong,
    fontSize: 12,
    color: colors.textMuted,
    marginBottom: spacing.xs,
  },
  campo: {
    fontFamily: fonts.body,
    fontSize: 16,
    color: colors.text,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.line,
    borderRadius: radii.item,
    paddingHorizontal: spacing.md,
    minHeight: 48,
  },
  erro: {
    fontFamily: fonts.body,
    fontSize: 12,
    color: colors.danger,
    marginTop: spacing.xs,
  },
});
