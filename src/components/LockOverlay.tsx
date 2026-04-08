import React, { useEffect } from "react";
import { View, Text, StyleSheet, Pressable } from "react-native";
import { useStore } from "../store/useStore";
import { Lock } from "lucide-react-native";
import { ParentGate } from "./ParentGate";

export const LockOverlay = () => {
  const { learningState, setLocked } = useStore();

  if (!learningState.locked) return null;

  return (
    <View style={styles.overlay}>
      <ParentGate
        triggerCount={5}
        style={styles.lockContainer}
        onTrigger={() => setLocked(false)}
      >
        <Lock color="#fff" size={80} />
      </ParentGate>
      <Text style={styles.title}>今天就学习到这里了</Text>
      <Text style={styles.subtitle}>不能再看了，请休息一下 👀</Text>
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
  lockContainer: {
    padding: 20,
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
