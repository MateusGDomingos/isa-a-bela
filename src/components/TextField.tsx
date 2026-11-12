import { StyleSheet, Text, TextInput, View, type TextInputProps } from 'react-native';
import { colors, fonts, radii, spacing } from '@/src/theme/tokens';

export type TextFieldProps = Omit<TextInputProps, 'value' | 'onChangeText'> & {
  label: string;
  value: string;
  onChangeText: (text: string) => void;
  error?: string;
};

export function TextField({ label, value, onChangeText, error, style, ...rest }: TextFieldProps) {
  return (
    <View style={{ marginBottom: spacing.md }}>
      <Text style={styles.label}>{label}</Text>
      <TextInput
        accessibilityLabel={label}
        accessibilityHint={error}
        value={value}
        onChangeText={onChangeText}
        placeholderTextColor={colors.textMuted}
        {...rest}
        // `style` entra DEPOIS de `...rest` e some sob um array, não sozinho: um
        // `{...rest}` espalhado depois do tema apagaria o campo inteiro, inclusive a
        // borda vermelha de erro, se quem chama passar `style`. RN mescla arrays de
        // estilo em ordem, então o do campo some ganha dos tokens só onde conflitar.
        style={[styles.field, error ? { borderColor: colors.danger } : null, style]}
      />
      {error ? <Text style={styles.error}>{error}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  label: {
    fontFamily: fonts.bodyStrong,
    fontSize: 12,
    color: colors.textMuted,
    marginBottom: spacing.xs,
  },
  field: {
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
  error: {
    fontFamily: fonts.body,
    fontSize: 12,
    color: colors.danger,
    marginTop: spacing.xs,
  },
});
