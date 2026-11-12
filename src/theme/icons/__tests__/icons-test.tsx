import { render } from '@testing-library/react-native';
import { CalendarHeartIcon, PurseIcon, SparkleIcon, TulipIcon, tabIcons } from '@/src/theme/icons';

// react-native-svg converte fill/stroke em um inteiro ARGB empacotado (0xAARRGGBB, o mesmo
// formato do processColor do React Native) antes do nó chegar à árvore serializada por
// toJSON() — a string de cor original não sobrevive nessa árvore. Para comparar com as cores
// literais do design, aplicamos aqui a mesma conversão, em vez de embutir números mágicos.
function packedColor(r: number, g: number, b: number, a = 1) {
  const packed = ((Math.round(a * 255) << 24) | (r << 16) | (g << 8) | b) >>> 0;
  return `"payload":${packed}`;
}

const PREENCHIMENTO_ROSA = packedColor(194, 69, 110, 0.22); // rgba(194,69,110,0.22)
const PRETO = packedColor(0, 0, 0); // #000000

describe('ícones das abas', () => {
  it('exporta um ícone para cada uma das quatro abas', () => {
    expect(Object.keys(tabIcons)).toEqual(['inicio', 'financas', 'tarefas', 'agenda']);
  });

  it.each([
    ['tulipa', TulipIcon],
    ['bolsinha', PurseIcon],
    ['brilhos', SparkleIcon],
    ['calendário com coração', CalendarHeartIcon],
  ])('renderiza o ícone %s sem erro', async (_nome, Icon) => {
    // @testing-library/react-native 14.x tornou render() assíncrono por padrão
    // (ver migration guide da v14: "async APIs by default"); confirmado também
    // com <View>/<Text> puros, então não é algo específico do react-native-svg.
    const { toJSON } = await render(<Icon />);
    expect(toJSON()).toBeTruthy();
  });

  it('preenche o contorno apenas quando a aba está ativa', async () => {
    // As linhas abertas (caule, argolas) mantêm fill="none" nos dois estados,
    // então a asserção é sobre a presença do preenchimento rosa, não da ausência de "none".
    const inativo = JSON.stringify((await render(<TulipIcon filled={false} />)).toJSON());
    const ativo = JSON.stringify((await render(<TulipIcon filled />)).toJSON());
    expect(inativo).not.toContain(PREENCHIMENTO_ROSA);
    expect(ativo).toContain(PREENCHIMENTO_ROSA);
  });

  it('respeita tamanho e cor recebidos', async () => {
    const arvore = JSON.stringify((await render(<PurseIcon size={30} color="#000000" />)).toJSON());
    expect(arvore).toContain('30');
    expect(arvore).toContain(PRETO);
  });
});
