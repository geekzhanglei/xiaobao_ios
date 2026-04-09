import {
  DarkTheme,
  DefaultTheme,
  ThemeProvider,
} from "@react-navigation/native";
import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import "react-native-reanimated";
import React, { useEffect } from "react";
import { Audio, InterruptionModeIOS, InterruptionModeAndroid } from "expo-av";
import { useColorScheme } from "@/hooks/use-color-scheme";
import { useStore } from "../src/store/useStore";
import { LockOverlay } from "../src/components/LockOverlay";

export const unstable_settings = {
  anchor: "返回",
};

export default function RootLayout() {
  const colorScheme = useColorScheme();
  const init = useStore((state) => state.init);

  useEffect(() => {
    init();
    // Configure audio to play even when silent mode is on
    Audio.setAudioModeAsync({
      playsInSilentModeIOS: true,
      allowsRecordingIOS: false,
      interruptionModeIOS: InterruptionModeIOS.DoNotMix,
      shouldDuckAndroid: true,
      interruptionModeAndroid: InterruptionModeAndroid.DoNotMix,
      playThroughEarpieceAndroid: false,
    });
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
          options={{
            title: "家长管理",
            headerShown: true,
            headerBackTitle: "返回",
          }}
        />
      </Stack>
      <StatusBar style="auto" />
      <LockOverlay />
    </ThemeProvider>
  );
}
