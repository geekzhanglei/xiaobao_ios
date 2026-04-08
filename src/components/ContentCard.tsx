import React from 'react';
import { View, Text, StyleSheet, Image, Pressable } from 'react-native';
import { ContentItem } from '../types';
import { Play, Image as ImageIcon } from 'lucide-react-native';

interface ContentCardProps {
  item: ContentItem;
  onPress: () => void;
}

export const ContentCard = ({ item, onPress }: ContentCardProps) => {
  return (
    <Pressable style={styles.container} onPress={onPress}>
      <View style={styles.card}>
        <Image source={{ uri: item.cover || item.uri }} style={styles.image} />
        {item.type === 'video' ? (
          <View style={styles.overlay}>
            <Play color="#fff" fill="#fff" size={24} />
          </View>
        ) : (
          <View style={styles.imageBadge}>
            <ImageIcon color="#fff" size={16} />
            <Text style={styles.imageBadgeText}>图片</Text>
          </View>
        )}
      </View>
      <Text style={styles.title} numberOfLines={1}>{item.title || '无标题'}</Text>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  container: {
    width: 160,
    marginRight: 16,
  },
  card: {
    width: 160,
    height: 100,
    borderRadius: 12,
    backgroundColor: '#333',
    overflow: 'hidden',
    position: 'relative',
  },
  image: {
    width: '100%',
    height: '100%',
    resizeMode: 'cover',
  },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0, 0, 0, 0.3)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  imageBadge: {
    position: 'absolute',
    bottom: 8,
    right: 8,
    backgroundColor: 'rgba(0, 0, 0, 0.6)',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
    flexDirection: 'row',
    alignItems: 'center',
  },
  imageBadgeText: {
    color: '#fff',
    fontSize: 10,
    marginLeft: 4,
  },
  title: {
    marginTop: 8,
    fontSize: 14,
    color: '#fff',
    fontWeight: '500',
  },
});
