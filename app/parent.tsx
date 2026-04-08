import React, { useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  Pressable,
  ScrollView,
  TextInput,
  Alert,
  Image,
} from "react-native";
import { Stack, useRouter } from "expo-router";
import * as ImagePicker from "expo-image-picker";
import * as DocumentPicker from "expo-document-picker";
import * as VideoThumbnails from "expo-video-thumbnails";
import { useStore } from "../src/store/useStore";
import {
  Plus,
  Trash2,
  Video,
  Image as ImageIcon,
  RotateCcw,
  MinusCircle,
  PlusCircle,
  FileVideo,
} from "lucide-react-native";

export default function ParentPanel() {
  const {
    contents,
    categories,
    addContent,
    deleteContent,
    addCategory,
    deleteCategory,
    learningState,
    resetLearningState,
    updateLimit,
    renameCategory,
  } = useStore();
  const [newCategoryName, setNewCategoryName] = useState("");
  const [selectedCategory, setSelectedCategory] = useState(categories[0] || "");

  const formatTime = (seconds: number) => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m}:${s.toString().padStart(2, "0")}`;
  };

  const adjustLimit = (delta: number) => {
    const newLimit = Math.max(0, learningState.limit + delta);
    updateLimit(newLimit);
  };

  const pickImage = async () => {
    if (!selectedCategory) {
      Alert.alert("错误", "请先选择一个分类");
      return;
    }
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ["images"],
      quality: 1,
    });

    if (!result.canceled) {
      const asset = result.assets[0];
      await addContent({
        id: Date.now().toString(),
        type: "image",
        uri: asset.uri,
        cover: asset.uri,
        category: selectedCategory,
        title: "新图片",
      });
    }
  };

  const generateThumbnail = async (videoUri: string) => {
    try {
      const { uri } = await VideoThumbnails.getThumbnailAsync(videoUri, {
        time: 1000,
      });
      return uri;
    } catch (e) {
      console.warn("Thumbnail generation failed", e);
      return null;
    }
  };

  const pickVideoFromLibrary = async () => {
    if (!selectedCategory) {
      Alert.alert("错误", "请先选择一个分类");
      return;
    }
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ["videos"],
      quality: 1,
    });

    if (!result.canceled) {
      const asset = result.assets[0];
      const thumbnail = await generateThumbnail(asset.uri);
      await addContent({
        id: Date.now().toString(),
        type: "video",
        uri: asset.uri,
        cover: thumbnail || undefined,
        category: selectedCategory,
        title: "相册视频",
      });
    }
  };

  const pickVideoFromFile = async () => {
    if (!selectedCategory) {
      Alert.alert("错误", "请先选择一个分类");
      return;
    }
    const result = await DocumentPicker.getDocumentAsync({
      type: "video/*",
    });

    if (!result.canceled) {
      const asset = result.assets[0];
      const thumbnail = await generateThumbnail(asset.uri);
      await addContent({
        id: Date.now().toString(),
        type: "video",
        uri: asset.uri,
        cover: thumbnail || undefined,
        category: selectedCategory,
        title: asset.name,
      });
    }
  };

  const handleAddCategory = async () => {
    if (newCategoryName.trim()) {
      await addCategory(newCategoryName.trim());
      setNewCategoryName("");
      setSelectedCategory(newCategoryName.trim());
    }
  };

  return (
    <ScrollView style={styles.container}>
      <Stack.Screen options={{ title: "家长管理" }} />
      {/* Learning State Management */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>学习时长管理</Text>
        <View style={styles.statsContainer}>
          <View style={styles.statsRow}>
            <Text style={styles.statsLabel}>已用时长:</Text>
            <Text style={styles.statsValue}>
              {formatTime(learningState.usedTime)}
            </Text>
            <Pressable style={styles.resetButton} onPress={resetLearningState}>
              <RotateCcw color="#fff" size={16} />
              <Text style={styles.resetButtonText}>重置</Text>
            </Pressable>
          </View>

          <View style={[styles.statsRow, { marginTop: 15 }]}>
            <Text style={styles.statsLabel}>总限时:</Text>
            <View style={styles.limitControl}>
              <Pressable onPress={() => adjustLimit(-60)}>
                <MinusCircle color="#007bff" size={24} />
              </Pressable>
              <Pressable
                onPress={() => adjustLimit(-10)}
                style={{ marginLeft: 5 }}
              >
                <Text style={styles.adjustSmall}>-10s</Text>
              </Pressable>

              <Text style={styles.statsValue}>
                {formatTime(learningState.limit)}
              </Text>

              <Pressable
                onPress={() => adjustLimit(10)}
                style={{ marginRight: 5 }}
              >
                <Text style={styles.adjustSmall}>+10s</Text>
              </Pressable>
              <Pressable onPress={() => adjustLimit(60)}>
                <PlusCircle color="#007bff" size={24} />
              </Pressable>
            </View>
          </View>
        </View>
      </View>

      {/* Category Management */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>分类管理</Text>
        <View style={styles.inputRow}>
          <TextInput
            style={styles.input}
            value={newCategoryName}
            onChangeText={setNewCategoryName}
            placeholder="输入新分类名称"
            placeholderTextColor="#888"
          />
          <Pressable style={styles.addButton} onPress={handleAddCategory}>
            <Plus color="#fff" size={24} />
          </Pressable>
        </View>
        <ScrollView horizontal style={styles.categoryScroll}>
          {categories.map((cat) => (
            <Pressable
              key={cat}
              style={[
                styles.categoryTag,
                selectedCategory === cat && styles.categoryTagActive,
              ]}
              onPress={() => setSelectedCategory(cat)}
              onLongPress={() => {
                Alert.alert("分类管理", `你要如何处理分类 "${cat}"？`, [
                  { text: "取消", style: "cancel" },
                  {
                    text: "重命名",
                    onPress: () => {
                      // Note: On iOS we could use Alert.prompt, but for cross-platform
                      // let's use a simple state-based rename if needed, or keep it simple
                      // for now with a prompt if possible.
                      // Given the user specifically asked for rename, I'll use a prompt
                      // which works on iOS (this project is named xiaobao_ios).
                      Alert.prompt(
                        "重命名分类",
                        "请输入新的分类名称",
                        [
                          { text: "取消", style: "cancel" },
                          {
                            text: "确定",
                            onPress: (newName?: string) => {
                              if (newName && newName.trim()) {
                                renameCategory(cat, newName.trim());
                              }
                            },
                          },
                        ],
                        "plain-text",
                        cat,
                      );
                    },
                  },
                  {
                    text: "删除",
                    style: "destructive",
                    onPress: () => deleteCategory(cat),
                  },
                ]);
              }}
            >
              <Text
                style={[
                  styles.categoryTagText,
                  selectedCategory === cat && styles.categoryTagTextActive,
                ]}
              >
                {cat}
              </Text>
            </Pressable>
          ))}
        </ScrollView>
      </View>

      {/* Content Management */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>内容上传</Text>
        <View style={styles.uploadRow}>
          <Pressable style={styles.uploadButton} onPress={pickImage}>
            <ImageIcon color="#fff" size={28} />
            <Text style={styles.uploadButtonText}>相册图片</Text>
          </Pressable>
          <Pressable style={styles.uploadButton} onPress={pickVideoFromLibrary}>
            <Video color="#fff" size={28} />
            <Text style={styles.uploadButtonText}>相册视频</Text>
          </Pressable>
          <Pressable style={styles.uploadButton} onPress={pickVideoFromFile}>
            <FileVideo color="#fff" size={28} />
            <Text style={styles.uploadButtonText}>文件视频</Text>
          </Pressable>
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>所有内容 ({contents.length})</Text>
        {categories.map((cat) => {
          const catContents = contents.filter((c) => c.category === cat);
          if (catContents.length === 0) return null;

          return (
            <View key={cat} style={styles.contentGroup}>
              <Text style={styles.contentGroupTitle}>{cat}</Text>
              {catContents.map((item) => (
                <View key={item.id} style={styles.contentItem}>
                  <Image
                    source={{ uri: item.cover || item.uri }}
                    style={styles.itemThumb}
                  />
                  <View style={styles.itemInfo}>
                    <Text style={styles.itemTitle}>{item.title}</Text>
                    <Text style={styles.itemSub}>{item.type}</Text>
                  </View>
                  <Pressable onPress={() => deleteContent(item.id)}>
                    <Trash2 color="#ff4444" size={20} />
                  </Pressable>
                </View>
              ))}
            </View>
          );
        })}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#f8f9fa",
  },
  section: {
    padding: 20,
    backgroundColor: "#fff",
    marginBottom: 10,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: "bold",
    marginBottom: 15,
    color: "#333",
  },
  statsRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  statsContainer: {
    backgroundColor: "#f8f9fa",
    padding: 15,
    borderRadius: 12,
  },
  statsLabel: {
    fontSize: 16,
    color: "#666",
    fontWeight: "500",
  },
  statsValue: {
    fontSize: 20,
    fontWeight: "bold",
    color: "#007bff",
    minWidth: 60,
    textAlign: "center",
  },
  limitControl: {
    flexDirection: "row",
    alignItems: "center",
  },
  adjustSmall: {
    fontSize: 12,
    color: "#007bff",
    padding: 5,
    fontWeight: "600",
  },
  statsText: {
    fontSize: 14,
    color: "#666",
  },
  resetButton: {
    backgroundColor: "#007bff",
    paddingHorizontal: 15,
    paddingVertical: 8,
    borderRadius: 8,
    flexDirection: "row",
    alignItems: "center",
  },
  resetButtonText: {
    color: "#fff",
    marginLeft: 5,
    fontWeight: "600",
  },
  inputRow: {
    flexDirection: "row",
    marginBottom: 15,
  },
  input: {
    flex: 1,
    height: 44,
    borderWidth: 1,
    borderColor: "#ddd",
    borderRadius: 8,
    paddingHorizontal: 15,
    marginRight: 10,
  },
  addButton: {
    backgroundColor: "#28a745",
    width: 44,
    height: 44,
    borderRadius: 22,
    justifyContent: "center",
    alignItems: "center",
  },
  categoryScroll: {
    flexDirection: "row",
  },
  categoryTag: {
    paddingHorizontal: 15,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: "#eee",
    marginRight: 10,
  },
  categoryTagActive: {
    backgroundColor: "#007bff",
  },
  categoryTagText: {
    color: "#666",
  },
  categoryTagTextActive: {
    color: "#fff",
  },
  uploadRow: {
    flexDirection: "row",
    justifyContent: "space-around",
  },
  uploadButton: {
    backgroundColor: "#333",
    padding: 15,
    borderRadius: 12,
    alignItems: "center",
    width: "30%",
  },
  uploadButtonText: {
    color: "#fff",
    marginTop: 10,
    fontWeight: "600",
  },
  contentGroup: {
    marginBottom: 20,
  },
  contentGroupTitle: {
    fontSize: 16,
    fontWeight: "bold",
    color: "#007bff",
    backgroundColor: "#f0f7ff",
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 4,
    marginBottom: 10,
  },
  contentItem: {
    flexDirection: "row",
    alignItems: "center",
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: "#eee",
  },
  itemThumb: {
    width: 60,
    height: 40,
    borderRadius: 4,
    backgroundColor: "#eee",
  },
  itemInfo: {
    flex: 1,
    marginLeft: 15,
  },
  itemTitle: {
    fontSize: 14,
    fontWeight: "500",
    color: "#333",
  },
  itemSub: {
    fontSize: 12,
    color: "#888",
    marginTop: 2,
  },
});
