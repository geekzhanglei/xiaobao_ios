import React, { useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  ScrollView,
  SafeAreaView,
  Pressable,
} from "react-native";
import { useRouter } from "expo-router";
import { useStore } from "../../src/store/useStore";
import { ContentCard } from "../../src/components/ContentCard";
import { ParentGate } from "../../src/components/ParentGate";
import { Palette } from "lucide-react-native";

export default function HomeScreen() {
  const { contents, categories, learningState, updateThemeColor } = useStore();
  const [showColorPicker, setShowColorPicker] = useState(false);
  const router = useRouter();

  const themeColors = [
    "#121212",
    "#2c3e50",
    "#8e44ad",
    "#27ae60",
    "#d35400",
    "#c0392b",
  ];

  const handlePressItem = (item: any) => {
    if (learningState.locked) return;
    router.push({
      pathname: "/player",
      params: { id: item.id },
    });
  };

  const renderCategory = ({ item: category }: { item: string }) => {
    const categoryContents = contents.filter((c) => c.category === category);

    if (categoryContents.length === 0) return null;

    return (
      <View style={styles.categoryContainer}>
        <Text style={styles.categoryTitle}>{category}</Text>
        <FlatList
          horizontal
          data={categoryContents}
          keyExtractor={(item) => item.id}
          renderItem={({ item }) => (
            <ContentCard item={item} onPress={() => handlePressItem(item)} />
          )}
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.horizontalList}
        />
      </View>
    );
  };

  return (
    <View style={{ flex: 1, backgroundColor: learningState.themeColor }}>
      <SafeAreaView style={styles.container}>
        <View style={styles.header}>
          <ParentGate>
            <Text style={styles.headerTitle}>我的书架</Text>
          </ParentGate>
          <View style={styles.themeContainer}>
            <Pressable
              style={styles.paletteButton}
              onPress={() => setShowColorPicker(!showColorPicker)}
            >
              <Palette color="#fff" size={24} />
            </Pressable>

            {showColorPicker && (
              <View style={styles.colorPickerPanel}>
                {themeColors.map((color) => (
                  <Pressable
                    key={color}
                    style={[
                      styles.colorDot,
                      { backgroundColor: color },
                      learningState.themeColor === color &&
                        styles.colorDotActive,
                    ]}
                    onPress={() => {
                      updateThemeColor(color);
                      setShowColorPicker(false);
                    }}
                  />
                ))}
              </View>
            )}
          </View>
        </View>

        {contents.length === 0 ? (
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyText}>
              还没有内容哦，请家长帮忙添加吧！
            </Text>
          </View>
        ) : (
          <FlatList
            data={categories}
            keyExtractor={(item) => item}
            renderItem={renderCategory}
            contentContainerStyle={styles.verticalList}
          />
        )}
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    padding: 20,
    paddingTop: 10,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: "bold",
    color: "#fff",
  },
  themeContainer: {
    flexDirection: "row",
    alignItems: "center",
    position: "relative",
  },
  paletteButton: {
    padding: 8,
    backgroundColor: "rgba(255,255,255,0.1)",
    borderRadius: 20,
  },
  colorPickerPanel: {
    position: "absolute",
    right: 45,
    flexDirection: "row",
    backgroundColor: "rgba(0,0,0,0.8)",
    padding: 8,
    borderRadius: 25,
    alignItems: "center",
    zIndex: 2000,
  },
  colorDot: {
    width: 24,
    height: 24,
    borderRadius: 12,
    marginHorizontal: 4,
    borderWidth: 2,
    borderColor: "transparent",
  },
  colorDotActive: {
    borderColor: "#fff",
  },
  categoryContainer: {
    marginBottom: 24,
  },
  categoryTitle: {
    fontSize: 18,
    fontWeight: "600",
    color: "#fff",
    marginLeft: 20,
    marginBottom: 12,
  },
  horizontalList: {
    paddingLeft: 20,
  },
  verticalList: {
    paddingBottom: 40,
  },
  emptyContainer: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    padding: 40,
  },
  emptyText: {
    color: "#888",
    fontSize: 16,
    textAlign: "center",
  },
});
