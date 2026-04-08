import React, { useEffect, useRef, useState, useMemo } from "react";
import {
  View,
  StyleSheet,
  Image,
  Pressable,
  Dimensions,
  FlatList,
  NativeSyntheticEvent,
  NativeScrollEvent,
} from "react-native";
import { useLocalSearchParams, useRouter } from "expo-router";
import { Video, ResizeMode, AVPlaybackStatus } from "expo-av";
import { useStore } from "../src/store/useStore";
import { X } from "lucide-react-native";

const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get("window");

export default function PlayerScreen() {
  const { id } = useLocalSearchParams();
  const router = useRouter();
  const { contents, learningState, updateTime, setLocked } = useStore();

  // Find the current item and its group
  const currentItem = contents.find((c) => c.id === id);
  const groupItems = useMemo(() => {
    if (!currentItem) return [];
    return contents.filter((c) => c.category === currentItem.category);
  }, [contents, currentItem]);

  const initialIndex = useMemo(() => {
    return groupItems.findIndex((item) => item.id === id);
  }, [groupItems, id]);

  const [currentIndex, setCurrentIndex] = useState(initialIndex);
  const [lastUpdateTime, setLastUpdateTime] = useState(0);

  const videoRef = useRef<Video>(null);
  const timeUpdateInterval = useRef<any>(null);

  // Auto-back timer for images (only if user doesn't interact, but here we prefer manual close for browsing)
  // Removing the auto-back timer to allow browsing

  // Track time for images
  useEffect(() => {
    const item = groupItems[currentIndex];
    if (item?.type === "image") {
      timeUpdateInterval.current = setInterval(() => {
        updateTime(1);
      }, 1000);
    } else {
      if (timeUpdateInterval.current) clearInterval(timeUpdateInterval.current);
    }

    return () => {
      if (timeUpdateInterval.current) clearInterval(timeUpdateInterval.current);
    };
  }, [currentIndex, groupItems]);

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
        router.back();
      }
      // For videos, we don't auto-next to maintain "group isolation" in terms of intent
      // But if user wants to browse, they can swipe.
    }
  };

  const handleScroll = (event: NativeSyntheticEvent<NativeScrollEvent>) => {
    const index = Math.round(event.nativeEvent.contentOffset.x / SCREEN_WIDTH);
    if (index !== currentIndex && index >= 0 && index < groupItems.length) {
      setCurrentIndex(index);
      setLastUpdateTime(0); // Reset for new item
    }
  };

  if (!currentItem || groupItems.length === 0) return null;

  const renderItem = ({ item }: { item: typeof currentItem }) => {
    return (
      <View style={styles.itemContainer}>
        {item.type === "video" ? (
          <Video
            ref={videoRef}
            source={{ uri: item.uri }}
            style={styles.media}
            useNativeControls
            resizeMode={ResizeMode.CONTAIN}
            shouldPlay={groupItems[currentIndex].id === item.id}
            onPlaybackStatusUpdate={handlePlaybackStatusUpdate}
          />
        ) : (
          <Image
            source={{ uri: item.uri }}
            style={styles.media}
            resizeMode="contain"
          />
        )}
      </View>
    );
  };

  const handleClose = () => {
    if (learningState.usedTime >= learningState.limit) {
      setLocked(true);
    }
    router.back();
  };

  return (
    <View style={styles.container}>
      <FlatList
        data={groupItems}
        renderItem={renderItem}
        keyExtractor={(item) => item.id}
        horizontal
        pagingEnabled
        showsHorizontalScrollIndicator={false}
        initialScrollIndex={initialIndex}
        getItemLayout={(_, index) => ({
          length: SCREEN_WIDTH,
          offset: SCREEN_WIDTH * index,
          index,
        })}
        onScroll={handleScroll}
        scrollEventThrottle={16}
      />

      <Pressable style={styles.closeButton} onPress={handleClose}>
        <X color="#fff" size={30} />
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#000",
  },
  itemContainer: {
    width: SCREEN_WIDTH,
    height: SCREEN_HEIGHT,
    justifyContent: "center",
    alignItems: "center",
  },
  media: {
    width: SCREEN_WIDTH,
    height: "100%",
  },
  closeButton: {
    position: "absolute",
    top: 50,
    right: 20,
    zIndex: 10,
    padding: 10,
    backgroundColor: "rgba(0,0,0,0.5)",
    borderRadius: 25,
  },
});
