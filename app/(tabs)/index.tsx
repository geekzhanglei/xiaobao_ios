import React from "react";
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

export default function HomeScreen() {
  const { contents, categories, learningState, updateThemeColor } = useStore();
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
    <SafeAreaView
      style={[styles.container, { backgroundColor: learningState.themeColor }]}
    >
      <View style={styles.header}>
        <ParentGate>
          <Text style={styles.headerTitle}>我的书架</Text>
        </ParentGate>
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          style={styles.themeSelector}
        >
          {themeColors.map((color) => (
            <Pressable
              key={color}
              style={[
                styles.colorDot,
                { backgroundColor: color },
                learningState.themeColor === color && styles.colorDotActive,
              ]}
              onPress={() => updateThemeColor(color)}
            />
          ))}
        </ScrollView>
      </View>

      {contents.length === 0 ? (
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyText}>还没有内容哦，请家长帮忙添加吧！</Text>
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
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#121212",
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
  themeSelector: {
    marginLeft: 20,
    flexGrow: 0,
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
