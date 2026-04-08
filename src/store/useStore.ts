import { create } from "zustand";
import * as SQLite from "expo-sqlite";
import { ContentItem, LearningState } from "../types";
import * as dbActions from "../database/db";

interface AppStore {
  db: SQLite.SQLiteDatabase | null;
  contents: ContentItem[];
  categories: string[];
  learningState: LearningState;

  init: () => Promise<void>;

  // Content Actions
  addContent: (item: ContentItem) => Promise<void>;
  deleteContent: (id: string) => Promise<void>;

  // Category Actions
  addCategory: (name: string) => Promise<void>;
  renameCategory: (oldName: string, newName: string) => Promise<void>;
  deleteCategory: (name: string) => Promise<void>;

  // Learning State Actions
  updateTime: (delta: number) => Promise<void>;
  updateLimit: (limit: number) => Promise<void>;
  updateThemeColor: (color: string) => Promise<void>;
  setLocked: (locked: boolean) => Promise<void>;
  resetLearningState: () => Promise<void>;
}

export const useStore = create<AppStore>((set, get) => ({
  db: null,
  contents: [],
  categories: [],
  learningState: {
    usedTime: 0,
    limit: 600,
    locked: false,
    themeColor: "#121212",
  },

  init: async () => {
    const db = await dbActions.initDatabase();
    const contents = await dbActions.getContent(db);
    const categories = await dbActions.getCategories(db);
    const learningState = await dbActions.getLearningState(db);

    set({ db, contents, categories, learningState });
  },

  addContent: async (item) => {
    const { db } = get();
    if (!db) return;
    await dbActions.addContentItem(db, item);
    const contents = await dbActions.getContent(db);
    set({ contents });
  },

  deleteContent: async (id) => {
    const { db } = get();
    if (!db) return;
    await dbActions.deleteContentItem(db, id);
    const contents = await dbActions.getContent(db);
    set({ contents });
  },

  addCategory: async (name) => {
    const { db } = get();
    if (!db) return;
    await dbActions.addCategory(db, name);
    const categories = await dbActions.getCategories(db);
    set({ categories });
  },

  renameCategory: async (oldName, newName) => {
    const { db } = get();
    if (!db) return;
    await dbActions.updateCategory(db, oldName, newName);
    const categories = await dbActions.getCategories(db);
    const contents = await dbActions.getContent(db);
    set({ categories, contents });
  },

  deleteCategory: async (name) => {
    const { db } = get();
    if (!db) return;
    await dbActions.deleteCategory(db, name);
    const categories = await dbActions.getCategories(db);
    set({ categories });
  },

  updateTime: async (delta) => {
    const { db, learningState } = get();
    if (!db) return;
    const newUsedTime = learningState.usedTime + delta;
    await dbActions.updateLearningState(db, { usedTime: newUsedTime });
    set({ learningState: { ...learningState, usedTime: newUsedTime } });
  },

  updateLimit: async (limit) => {
    const { db, learningState } = get();
    if (!db) return;
    await dbActions.updateLearningState(db, { limit });
    set({ learningState: { ...learningState, limit } });
  },

  updateThemeColor: async (themeColor) => {
    const { db, learningState } = get();
    if (!db) return;
    await dbActions.updateLearningState(db, { themeColor });
    set({ learningState: { ...learningState, themeColor } });
  },

  setLocked: async (locked) => {
    const { db, learningState } = get();
    if (!db) return;
    await dbActions.updateLearningState(db, { locked });
    set({ learningState: { ...learningState, locked } });
  },

  resetLearningState: async () => {
    const { db, learningState } = get();
    if (!db) return;
    const newState = { usedTime: 0, locked: false };
    await dbActions.updateLearningState(db, newState);
    set({ learningState: { ...learningState, ...newState } });
  },
}));
