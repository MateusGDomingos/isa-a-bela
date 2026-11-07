import { StyleSheet, Text, View } from 'react-native';
import { Botao } from '@/src/components/Botao';
import { colors, fonts, spacing } from '@/src/theme/tokens';

export type EstadoVazioProps = {
  titulo: string;
  descricao: string;
  acao?: { titulo: string; onPress: () => void };
};

export function EstadoVazio({ titulo, descricao, acao }: EstadoVazioProps) {
  return (
    <View style={estilos.area}>
      <Text style={estilos.titulo}>{titulo}</Text>
      <Text style={estilos.descricao}>{descricao}</Text>
      {acao ? (
        <View style={{ marginTop: spacing.lg }}>
          <Botao titulo={acao.titulo} onPress={acao.onPress} variante="secundario" />
        </View>
      ) : null}
    </View>
  );
}

const estilos = StyleSheet.create({
  area: { alignItems: 'center', padding: spacing.xl },
  titulo: {
    fontFamily: fonts.bodyStrong,
    fontSize: 16,
    color: colors.text,
    textAlign: 'center',
  },
  descricao: {
    fontFamily: fonts.body,
    fontSize: 14,
    color: colors.textMuted,
    textAlign: 'center',
    marginTop: spacing.xs,
  },
});
