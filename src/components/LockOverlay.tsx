import React, { useEffect } from "react";
import { View, Text, StyleSheet, Pressable } from "react-native";
import { useStore } from "../store/useStore";
import { Lock } from "lucide-react-native";
import { ParentGate } from "./ParentGate";

export const LockOverlay = () => {
  const { learningState } = useStore();

  if (!learningState.locked) return null;

  return (
    <View style={styles.overlay}>
      <Lock color="#fff" size={80} />
      <Text style={styles.title}>今天的学习结束了</Text>
      <Text style={styles.subtitle}>请休息一下 👀</Text>
      <ParentGate style={styles.gate}>
        <Text style={styles.gateText}>家长管理</Text>
      </ParentGate>
    </View>
  );
};

const styles = StyleSheet.create({
  overlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(0, 0, 0, 0.9)",
    justifyContent: "center",
    alignItems: "center",
    zIndex: 9999,
  },
  gate: {
    position: "absolute",
    bottom: 50,
    padding: 10,
  },
  gateText: {
    color: "rgba(255, 255, 255, 0.3)",
    fontSize: 14,
  },
  title: {
    color: "#fff",
    fontSize: 32,
    fontWeight: "bold",
    marginTop: 20,
    textAlign: "center",
  },
  subtitle: {
    color: "#ddd",
    fontSize: 20,
    marginTop: 10,
    textAlign: "center",
  },
});
