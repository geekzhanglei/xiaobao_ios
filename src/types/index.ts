export type ContentType = "video" | "image";

export interface ContentItem {
  id: string;
  type: ContentType;
  title?: string;
  cover?: string; // 封面（视频封面 or 图片本身）
  uri: string; // 本地路径（视频 or 图片）
  category: string;
  duration?: number; // 视频才有（秒）
}

export type Category = string;

export interface LearningState {
  usedTime: number; // 已使用时长（秒）
  limit: number; // 600秒（10分钟）
  locked: boolean; // 是否锁定
  lastPlayTime?: number; // 上次播放时间戳
}
