import { StyleSheet, Text, TextInput, View, type TextInputProps } from 'react-native';
import { colors, fonts, radii, spacing } from '@/src/theme/tokens';

export type TextFieldProps = Omit<TextInputProps, 'value' | 'onChangeText'> & {
  label: string;
  value: string;
  onChangeText: (text: string) => void;
  error?: string;
};

export function TextField({ label, value, onChangeText, error, ...rest }: TextFieldProps) {
  return (
    <View style={{ marginBottom: spacing.md }}>
      <Text style={styles.label}>{label}</Text>
      <TextInput
        accessibilityLabel={label}
        accessibilityHint={error}
        value={value}
        onChangeText={onChangeText}
        placeholderTextColor={colors.textMuted}
        style={[styles.field, error ? { borderColor: colors.danger } : null]}
        {...rest}
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
