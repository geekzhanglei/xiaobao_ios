import {
  DarkTheme,
  DefaultTheme,
  ThemeProvider,
} from "@react-navigation/native";
import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import "react-native-reanimated";
import React, { useEffect } from "react";
import { useColorScheme } from "@/hooks/use-color-scheme";
import { useStore } from "../src/store/useStore";
import { LockOverlay } from "../src/components/LockOverlay";

export const unstable_settings = {
  anchor: "(tabs)",
};

export default function RootLayout() {
  const colorScheme = useColorScheme();
  const init = useStore((state) => state.init);

  useEffect(() => {
    init();
  }, [init]);

  return (
    <ThemeProvider value={colorScheme === "dark" ? DarkTheme : DefaultTheme}>
      <Stack>
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen
          name="player"
          options={{ headerShown: false, presentation: "fullScreenModal" }}
        />
        <Stack.Screen
          name="parent"
          options={{ title: "家长面板", headerShown: true }}
        />
      </Stack>
      <StatusBar style="auto" />
      <LockOverlay />
    </ThemeProvider>
  );
}
