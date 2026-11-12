import { StyleSheet, Text, View } from 'react-native';
import { Button } from '@/src/components/Button';
import { colors, fonts, spacing } from '@/src/theme/tokens';

export type EmptyStateProps = {
  title: string;
  description: string;
  action?: { title: string; onPress: () => void };
};

export function EmptyState({ title, description, action }: EmptyStateProps) {
  return (
    <View style={styles.area}>
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.description}>{description}</Text>
      {action ? (
        <View style={{ marginTop: spacing.lg }}>
          <Button title={action.title} onPress={action.onPress} variant="secondary" />
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  area: { alignItems: 'center', padding: spacing.xl },
  title: {
    fontFamily: fonts.bodyStrong,
    fontSize: 16,
    color: colors.text,
    textAlign: 'center',
  },
  description: {
    fontFamily: fonts.body,
    fontSize: 14,
    color: colors.textMuted,
    textAlign: 'center',
    marginTop: spacing.xs,
  },
});
