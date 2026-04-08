import React, { useState } from 'react';
import { View, Text, StyleSheet, FlatList, Pressable, ScrollView, TextInput, Alert, Image } from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import * as DocumentPicker from 'expo-document-picker';
import { useStore } from '../../src/store/useStore';
import { Plus, Trash2, Video, Image as ImageIcon, RotateCcw } from 'lucide-react-native';

export default function ParentPanel() {
  const { contents, categories, addContent, deleteContent, addCategory, deleteCategory, learningState, resetLearningState } = useStore();
  const [newCategoryName, setNewCategoryName] = useState('');
  const [selectedCategory, setSelectedCategory] = useState(categories[0] || '');

  const pickImage = async () => {
    if (!selectedCategory) {
      Alert.alert('错误', '请先选择一个分类');
      return;
    }
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      quality: 1,
    });

    if (!result.canceled) {
      const asset = result.assets[0];
      await addContent({
        id: Date.now().toString(),
        type: 'image',
        uri: asset.uri,
        cover: asset.uri,
        category: selectedCategory,
        title: '新图片'
      });
    }
  };

  const pickVideo = async () => {
    if (!selectedCategory) {
      Alert.alert('错误', '请先选择一个分类');
      return;
    }
    const result = await DocumentPicker.getDocumentAsync({
      type: 'video/*',
    });

    if (!result.canceled) {
      const asset = result.assets[0];
      await addContent({
        id: Date.now().toString(),
        type: 'video',
        uri: asset.uri,
        category: selectedCategory,
        title: asset.name
      });
    }
  };

  const handleAddCategory = async () => {
    if (newCategoryName.trim()) {
      await addCategory(newCategoryName.trim());
      setNewCategoryName('');
      setSelectedCategory(newCategoryName.trim());
    }
  };

  return (
    <ScrollView style={styles.container}>
      {/* Learning State Management */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>学习时长管理</Text>
        <View style={styles.statsRow}>
          <Text style={styles.statsText}>已用时长: {Math.floor(learningState.usedTime / 60)} 分钟</Text>
          <Text style={styles.statsText}>总限时: {Math.floor(learningState.limit / 60)} 分钟</Text>
          <Pressable style={styles.resetButton} onPress={resetLearningState}>
            <RotateCcw color="#fff" size={18} />
            <Text style={styles.resetButtonText}>重置</Text>
          </Pressable>
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
          {categories.map(cat => (
            <Pressable
              key={cat}
              style={[styles.categoryTag, selectedCategory === cat && styles.categoryTagActive]}
              onPress={() => setSelectedCategory(cat)}
              onLongPress={() => {
                Alert.alert('删除分类', `确定删除分类 "${cat}" 吗？`, [
                  { text: '取消', style: 'cancel' },
                  { text: '删除', style: 'destructive', onPress: () => deleteCategory(cat) }
                ]);
              }}
            >
              <Text style={[styles.categoryTagText, selectedCategory === cat && styles.categoryTagTextActive]}>{cat}</Text>
            </Pressable>
          ))}
        </ScrollView>
      </View>

      {/* Content Management */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>内容上传</Text>
        <View style={styles.uploadRow}>
          <Pressable style={styles.uploadButton} onPress={pickVideo}>
            <Video color="#fff" size={30} />
            <Text style={styles.uploadButtonText}>上传视频</Text>
          </Pressable>
          <Pressable style={styles.uploadButton} onPress={pickImage}>
            <ImageIcon color="#fff" size={30} />
            <Text style={styles.uploadButtonText}>上传图片</Text>
          </Pressable>
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>所有内容 ({contents.length})</Text>
        {contents.map(item => (
          <View key={item.id} style={styles.contentItem}>
            <Image source={{ uri: item.cover || item.uri }} style={styles.itemThumb} />
            <View style={styles.itemInfo}>
              <Text style={styles.itemTitle}>{item.title}</Text>
              <Text style={styles.itemSub}>{item.category} | {item.type}</Text>
            </View>
            <Pressable onPress={() => deleteContent(item.id)}>
              <Trash2 color="#ff4444" size={24} />
            </Pressable>
          </View>
        ))}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8f9fa',
  },
  section: {
    padding: 20,
    backgroundColor: '#fff',
    marginBottom: 10,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 15,
    color: '#333',
  },
  statsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  statsText: {
    fontSize: 14,
    color: '#666',
  },
  resetButton: {
    backgroundColor: '#007bff',
    paddingHorizontal: 15,
    paddingVertical: 8,
    borderRadius: 8,
    flexDirection: 'row',
    alignItems: 'center',
  },
  resetButtonText: {
    color: '#fff',
    marginLeft: 5,
    fontWeight: '600',
  },
  inputRow: {
    flexDirection: 'row',
    marginBottom: 15,
  },
  input: {
    flex: 1,
    height: 44,
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    paddingHorizontal: 15,
    marginRight: 10,
  },
  addButton: {
    backgroundColor: '#28a745',
    width: 44,
    height: 44,
    borderRadius: 22,
    justifyContent: 'center',
    alignItems: 'center',
  },
  categoryScroll: {
    flexDirection: 'row',
  },
  categoryTag: {
    paddingHorizontal: 15,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: '#eee',
    marginRight: 10,
  },
  categoryTagActive: {
    backgroundColor: '#007bff',
  },
  categoryTagText: {
    color: '#666',
  },
  categoryTagTextActive: {
    color: '#fff',
  },
  uploadRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  uploadButton: {
    backgroundColor: '#333',
    padding: 20,
    borderRadius: 12,
    alignItems: 'center',
    width: '45%',
  },
  uploadButtonText: {
    color: '#fff',
    marginTop: 10,
    fontWeight: '600',
  },
  contentItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  itemThumb: {
    width: 60,
    height: 40,
    borderRadius: 4,
    backgroundColor: '#eee',
  },
  itemInfo: {
    flex: 1,
    marginLeft: 15,
  },
  itemTitle: {
    fontSize: 14,
    fontWeight: '500',
    color: '#333',
  },
  itemSub: {
    fontSize: 12,
    color: '#888',
    marginTop: 2,
  },
});
