import { Inter_400Regular, Inter_600SemiBold } from '@expo-google-fonts/inter';
import { PlayfairDisplay_600SemiBold_Italic } from '@expo-google-fonts/playfair-display';
import { useFonts } from 'expo-font';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { useEffect } from 'react';

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [loaded] = useFonts({
    PlayfairDisplay_600SemiBold_Italic,
    Inter_400Regular,
    Inter_600SemiBold,
  });

  useEffect(() => {
    if (loaded) SplashScreen.hideAsync();
  }, [loaded]);

  if (!loaded) return null;
  return <Stack screenOptions={{ headerShown: false }} />;
}
