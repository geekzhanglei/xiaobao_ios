import { type AVPlaybackStatus, ResizeMode, Video } from "expo-av";
import { useLocalSearchParams, useRouter } from "expo-router";
import { X } from "lucide-react-native";
import React, { useEffect, useMemo, useRef, useState } from "react";
import {
	Dimensions,
	FlatList,
	Image,
	type NativeScrollEvent,
	type NativeSyntheticEvent,
	Pressable,
	StatusBar,
	StyleSheet,
	View,
} from "react-native";
import { useStore } from "../src/store/useStore";

export default function PlayerScreen() {
	const { id } = useLocalSearchParams();
	const router = useRouter();
	const { contents, learningState, updateTime, setLocked } = useStore();

	// 动态获取屏幕尺寸和方向
	const [screenData, setScreenData] = useState(() => {
		const { width, height } = Dimensions.get("window");
		return {
			width,
			height,
			isLandscape: width > height,
		};
	});

	// 监听设备旋转
	useEffect(() => {
		const subscription = Dimensions.addEventListener("change", ({ window }) => {
			setScreenData({
				width: window.width,
				height: window.height,
				isLandscape: window.width > window.height,
			});
		});

		return () => subscription?.remove();
	}, []);

	// 根据屏幕方向控制状态栏
	useEffect(() => {
		if (screenData.isLandscape) {
			StatusBar.setHidden(true);
		} else {
			StatusBar.setHidden(false);
		}
	}, [screenData.isLandscape]);

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
	const timeUpdateInterval = useRef<number | null>(null);

	// Auto-back timer for images (only if user doesn't interact, but here we prefer manual close for browsing)
	// Removing the auto-back timer to allow browsing

	// Track time for images
	useEffect(() => {
		const item = groupItems[currentIndex];
		if (item?.type === "image") {
			timeUpdateInterval.current = setInterval(() => {
				updateTime(1);
			}, 1000) as unknown as number;
		} else {
			if (timeUpdateInterval.current) clearInterval(timeUpdateInterval.current);
		}

		return () => {
			if (timeUpdateInterval.current) clearInterval(timeUpdateInterval.current);
		};
	}, [currentIndex, groupItems, updateTime]);

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
    const index = Math.round(event.nativeEvent.contentOffset.x / screenData.width);
    if (index !== currentIndex && index >= 0 && index < groupItems.length) {
      setCurrentIndex(index);
      setLastUpdateTime(0); // Reset for new item
    }
  };

	if (!currentItem || groupItems.length === 0) return null;

	const renderItem = ({ item }: { item: typeof currentItem }) => {
		return (
			<View style={[styles.itemContainer, { width: screenData.width, height: screenData.height }]}>
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
					length: screenData.width,
					offset: screenData.width * index,
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
		justifyContent: "center",
		alignItems: "center",
	},
	media: {
		width: "100%",
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
