import { ActivityIndicator, Pressable, StyleSheet, Text } from 'react-native';
import { colors, fonts, radii, spacing } from '@/src/theme/tokens';

export type BotaoProps = {
  titulo: string;
  onPress: () => void;
  variante?: 'primario' | 'secundario' | 'perigo';
  carregando?: boolean;
  desabilitado?: boolean;
};

export function Botao({
  titulo,
  onPress,
  variante = 'primario',
  carregando = false,
  desabilitado = false,
}: BotaoProps) {
  const bloqueado = desabilitado || carregando;
  const fundo =
    variante === 'primario' ? colors.accent : variante === 'perigo' ? colors.danger : 'transparent';
  const cor = variante === 'secundario' ? colors.accent : colors.surface;

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={carregando ? 'Salvando' : titulo}
      accessibilityState={{ disabled: bloqueado, busy: carregando }}
      disabled={bloqueado}
      onPress={onPress}
      style={[
        estilos.botao,
        { backgroundColor: fundo, opacity: bloqueado ? 0.6 : 1 },
        variante === 'secundario' && { borderWidth: 1, borderColor: colors.accent },
      ]}
    >
      {carregando ? (
        <ActivityIndicator color={cor} />
      ) : (
        <Text style={[estilos.texto, { color: cor }]}>{titulo}</Text>
      )}
    </Pressable>
  );
}

const estilos = StyleSheet.create({
  botao: {
    borderRadius: radii.pill,
    paddingVertical: spacing.md,
    paddingHorizontal: spacing.xl,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 48,
  },
  texto: { fontFamily: fonts.bodyStrong, fontSize: 16 },
});
