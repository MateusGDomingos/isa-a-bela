import { useState } from 'react';
import { render, screen, userEvent } from '@testing-library/react-native';
import { Button, TextField, EmptyState } from '@/src/components';

// `userEvent.type()` acumula o texto digitado sobre a prop `value` atual do TextInput
// (ver docs/api/user-event.md do @testing-library/react-native: "This function will add
// text to the text already present in the text input, as specified by `value` ... props").
// Um `value` fixo (sem recontrolar o componente a cada toque de tecla) faz cada chamada de
// `onChangeText` carregar só o caractere mais novo — confirmado via instrumentação, que
// mostrou chamadas como ["A"], ["ç"], ... terminando num surrogate solto do emoji. Este
// invólucro controlado devolve o texto para `value` a cada mudança, como uma tela real
// faria, permitindo que o teste calculo o texto acumulado corretamente — sem alterar a
// asserção, que é a especificação.
function ControlledTextField({ onChangeText }: { onChangeText: (text: string) => void }) {
  const [value, setValue] = useState('');
  return (
    <TextField
      label="Descrição"
      value={value}
      onChangeText={(text) => {
        setValue(text);
        onChangeText(text);
      }}
    />
  );
}

describe('Button', () => {
  it('chama onPress quando tocado', async () => {
    const onPress = jest.fn();
    await render(<Button title="Salvar" onPress={onPress} />);
    await userEvent.press(screen.getByText('Salvar'));
    expect(onPress).toHaveBeenCalledTimes(1);
  });

  it('não chama onPress quando desabilitado', async () => {
    const onPress = jest.fn();
    await render(<Button title="Salvar" onPress={onPress} disabled />);
    await userEvent.press(screen.getByText('Salvar'));
    expect(onPress).not.toHaveBeenCalled();
  });

  it('não chama onPress enquanto carrega e anuncia o estado', async () => {
    const onPress = jest.fn();
    await render(<Button title="Salvar" onPress={onPress} loading />);
    expect(screen.getByLabelText('Salvando')).toBeTruthy();
    await userEvent.press(screen.getByLabelText('Salvando'));
    expect(onPress).not.toHaveBeenCalled();
  });
});

describe('TextField', () => {
  it('mostra o rótulo e o valor', async () => {
    await render(<TextField label="Descrição" value="Mercado" onChangeText={jest.fn()} />);
    expect(screen.getByText('Descrição')).toBeTruthy();
    expect(screen.getByDisplayValue('Mercado')).toBeTruthy();
  });

  it('mostra a mensagem de erro embaixo do campo e a anuncia no leitor de tela', async () => {
    await render(
      <TextField
        label="Valor"
        value="abc"
        onChangeText={jest.fn()}
        error="Digite um valor maior que zero"
      />,
    );
    expect(screen.getByText('Digite um valor maior que zero')).toBeTruthy();
    expect(screen.getByLabelText('Valor').props.accessibilityHint).toBe(
      'Digite um valor maior que zero',
    );
  });

  it('não deixa dica de acessibilidade pendurada quando não há erro', async () => {
    await render(<TextField label="Valor" value="10" onChangeText={jest.fn()} />);
    expect(screen.getByLabelText('Valor').props.accessibilityHint).toBeUndefined();
  });

  it('preserva acentos e emoji digitados', async () => {
    const onChangeText = jest.fn();
    await render(<ControlledTextField onChangeText={onChangeText} />);
    await userEvent.type(screen.getByLabelText('Descrição'), 'Açaí 🍧');
    expect(onChangeText).toHaveBeenLastCalledWith('Açaí 🍧');
  });
});

describe('EmptyState', () => {
  it('mostra título, descrição e a ação opcional', async () => {
    const onPress = jest.fn();
    await render(
      <EmptyState
        title="Nenhum gasto ainda"
        description="Toque no + para registrar o primeiro."
        action={{ title: 'Registrar gasto', onPress }}
      />,
    );
    expect(screen.getByText('Nenhum gasto ainda')).toBeTruthy();
    expect(screen.getByText('Toque no + para registrar o primeiro.')).toBeTruthy();
    await userEvent.press(screen.getByText('Registrar gasto'));
    expect(onPress).toHaveBeenCalled();
  });

  it('funciona sem ação', async () => {
    await render(<EmptyState title="Nada aqui" description="Por enquanto." />);
    expect(screen.getByText('Nada aqui')).toBeTruthy();
  });
});
