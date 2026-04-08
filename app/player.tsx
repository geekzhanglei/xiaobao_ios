import React, { useEffect, useRef, useState } from 'react';
import { View, StyleSheet, Image, Pressable, Text } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Video, ResizeMode, AVPlaybackStatus } from 'expo-av';
import { useStore } from '../src/store/useStore';
import { X } from 'lucide-react-native';

const IMAGE_DURATION = 5000; // 5 seconds

export default function PlayerScreen() {
  const { id } = useLocalSearchParams();
  const router = useRouter();
  const { contents, learningState, updateTime, setLocked } = useStore();
  const item = contents.find(c => c.id === id);
  const [lastUpdateTime, setLastUpdateTime] = useState(0);

  const videoRef = useRef<Video>(null);

  useEffect(() => {
    if (!item) {
      router.back();
      return;
    }

    if (item.type === 'image') {
      const timer = setTimeout(() => {
        router.back();
      }, IMAGE_DURATION);
      return () => clearTimeout(timer);
    }
  }, [item]);

  const handlePlaybackStatusUpdate = (status: AVPlaybackStatus) => {
    if (!status.isLoaded) return;

    if (status.isPlaying) {
      const currentTime = Math.floor(status.positionMillis / 1000);
      if (currentTime > lastUpdateTime) {
        const delta = currentTime - lastUpdateTime;
        updateTime(delta);
        setLastUpdateTime(currentTime);
      }
    }

    if (status.didJustFinish) {
      if (learningState.usedTime >= learningState.limit) {
        setLocked(true);
      }
      router.back();
    }
  };

  if (!item) return null;

  return (
    <View style={styles.container}>
      <Pressable style={styles.closeButton} onPress={() => router.back()}>
        <X color="#fff" size={30} />
      </Pressable>

      {item.type === 'video' ? (
        <Video
          ref={videoRef}
          source={{ uri: item.uri }}
          style={styles.media}
          useNativeControls
          resizeMode={ResizeMode.CONTAIN}
          shouldPlay
          onPlaybackStatusUpdate={handlePlaybackStatusUpdate}
        />
      ) : (
        <Image source={{ uri: item.uri }} style={styles.media} resizeMode="contain" />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
    justifyContent: 'center',
    alignItems: 'center',
  },
  media: {
    width: '100%',
    height: '100%',
  },
  closeButton: {
    position: 'absolute',
    top: 50,
    right: 20,
    zIndex: 10,
    padding: 10,
    backgroundColor: 'rgba(0,0,0,0.5)',
    borderRadius: 25,
  },
});
