import React, { useState, useRef } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { useRouter } from 'expo-router';

export const ParentGate = () => {
  const [tapCount, setTapCount] = useState(0);
  const router = useRouter();
  const timerRef = useRef<NodeJS.Timeout | null>(null);

  const handleTap = () => {
    if (timerRef.current) {
      clearTimeout(timerRef.current);
    }

    const nextCount = tapCount + 1;
    if (nextCount >= 4) {
      router.push('/parent');
      setTapCount(0);
    } else {
      setTapCount(nextCount);
      timerRef.current = setTimeout(() => {
        setTapCount(0);
      }, 1000);
    }
  };

  return (
    <Pressable style={styles.gate} onPress={handleTap}>
      <View style={styles.indicator} />
    </Pressable>
  );
};

const styles = StyleSheet.create({
  gate: {
    position: 'absolute',
    top: 40,
    right: 20,
    width: 60,
    height: 60,
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1000,
  },
  indicator: {
    width: 20,
    height: 20,
    borderRadius: 10,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
  },
});
