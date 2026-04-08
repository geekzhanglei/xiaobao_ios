import React, { useState, useRef } from 'react';
import { Pressable, StyleSheet, View, ViewStyle, StyleProp } from 'react-native';
import { useRouter } from 'expo-router';

interface ParentGateProps {
  children?: React.ReactNode;
  style?: StyleProp<ViewStyle>;
}

export const ParentGate = ({ children, style }: ParentGateProps) => {
  const [tapCount, setTapCount] = useState(0);
  const router = useRouter();
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

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
    <Pressable style={style} onPress={handleTap}>
      {children}
    </Pressable>
  );
};
