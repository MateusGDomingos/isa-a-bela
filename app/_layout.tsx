import { Inter_400Regular, Inter_600SemiBold } from '@expo-google-fonts/inter';
import { PlayfairDisplay_600SemiBold_Italic } from '@expo-google-fonts/playfair-display';
import { useFonts } from 'expo-font';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { useEffect } from 'react';

// Ambas as chamadas devolvem Promise; sem o catch, uma rejeição (splash já escondida
// por outro caminho, módulo nativo ausente etc.) vira unhandled rejection em vez de
// simplesmente não fazer nada.
SplashScreen.preventAutoHideAsync().catch(() => {});

export default function RootLayout() {
  const [loaded, error] = useFonts({
    PlayfairDisplay_600SemiBold_Italic,
    Inter_400Regular,
    Inter_600SemiBold,
  });

  useEffect(() => {
    // `error` também precisa esconder a splash: sem isto, uma fonte que falha ao
    // carregar deixa `loaded` false para sempre e o app nunca sai da tela de splash —
    // contra a promessa da spec §10.2 de que o app nunca simplesmente para.
    if (loaded || error) SplashScreen.hideAsync().catch(() => {});
  }, [loaded, error]);

  // Nem carregou nem falhou: ainda está carregando, e a própria splash já cobre isso.
  if (!loaded && !error) return null;
  return <Stack screenOptions={{ headerShown: false }} />;
}
