import { Tabs } from "expo-router";
import React from "react";

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarStyle: { display: "none" }, // Hide tab bar
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: '返回书架',
        }}
      />
    </Tabs>
  );
}
