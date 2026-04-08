import * as SQLite from "expo-sqlite";
import { ContentItem, LearningState } from "../types";

const DB_NAME = "kids_learning.db";

export const initDatabase = async () => {
  const db = await SQLite.openDatabaseAsync(DB_NAME);

  await db.execAsync(`
    CREATE TABLE IF NOT EXISTS content (
      id TEXT PRIMARY KEY NOT NULL,
      type TEXT NOT NULL,
      title TEXT,
      cover TEXT,
      uri TEXT NOT NULL,
      category TEXT NOT NULL,
      duration INTEGER
    );
    CREATE TABLE IF NOT EXISTS categories (
      name TEXT PRIMARY KEY NOT NULL
    );
    CREATE TABLE IF NOT EXISTS learning_state (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      usedTime INTEGER DEFAULT 0,
      limit_time INTEGER DEFAULT 600,
      locked INTEGER DEFAULT 0,
      lastPlayTime INTEGER,
      theme_color TEXT DEFAULT '#121212'
    );
  `);

  // Migration: Add theme_color if it doesn't exist (for existing users)
  try {
    const tableInfo = await db.getAllAsync<any>("PRAGMA table_info(learning_state)");
    const hasThemeColor = tableInfo.some(col => col.name === 'theme_color');
    if (!hasThemeColor) {
      await db.execAsync("ALTER TABLE learning_state ADD COLUMN theme_color TEXT DEFAULT '#121212'");
    }
  } catch (e) {
    console.error('Database migration failed', e);
  }

  // Initialize learning state if it doesn't exist
  const existingState = await db.getFirstAsync(
    "SELECT * FROM learning_state WHERE id = 1",
  );
  if (!existingState) {
    await db.runAsync(
      "INSERT INTO learning_state (id, usedTime, limit_time, locked) VALUES (1, 0, 600, 0)",
    );
  }

  return db;
};

export const getContent = async (
  db: SQLite.SQLiteDatabase,
): Promise<ContentItem[]> => {
  const rows = await db.getAllAsync<ContentItem>("SELECT * FROM content");
  return rows;
};

export const addContentItem = async (
  db: SQLite.SQLiteDatabase,
  item: ContentItem,
) => {
  await db.runAsync(
    "INSERT OR REPLACE INTO content (id, type, title, cover, uri, category, duration) VALUES (?, ?, ?, ?, ?, ?, ?)",
    [
      item.id,
      item.type,
      item.title || null,
      item.cover || null,
      item.uri,
      item.category,
      item.duration || null,
    ],
  );
};

export const deleteContentItem = async (
  db: SQLite.SQLiteDatabase,
  id: string,
) => {
  await db.runAsync("DELETE FROM content WHERE id = ?", [id]);
};

export const getCategories = async (
  db: SQLite.SQLiteDatabase,
): Promise<string[]> => {
  const rows = await db.getAllAsync<{ name: string }>(
    "SELECT name FROM categories",
  );
  return rows.map((r) => r.name);
};

export const addCategory = async (db: SQLite.SQLiteDatabase, name: string) => {
  await db.runAsync("INSERT OR IGNORE INTO categories (name) VALUES (?)", [
    name,
  ]);
};

export const updateCategory = async (
  db: SQLite.SQLiteDatabase,
  oldName: string,
  newName: string,
) => {
  await db.withTransactionAsync(async () => {
    // 1. Update the category itself
    await db.runAsync("UPDATE categories SET name = ? WHERE name = ?", [
      newName,
      oldName,
    ]);
    // 2. Update all content associated with this category
    await db.runAsync("UPDATE content SET category = ? WHERE category = ?", [
      newName,
      oldName,
    ]);
  });
};

export const deleteCategory = async (
  db: SQLite.SQLiteDatabase,
  name: string,
) => {
  await db.runAsync("DELETE FROM categories WHERE name = ?", [name]);
};

export const getLearningState = async (
  db: SQLite.SQLiteDatabase,
): Promise<LearningState> => {
  const row = await db.getFirstAsync<any>(
    "SELECT * FROM learning_state WHERE id = 1",
  );
  return {
    usedTime: row.usedTime,
    limit: row.limit_time,
    locked: row.locked === 1,
    lastPlayTime: row.lastPlayTime,
    themeColor: row.theme_color || "#121212",
  };
};

export const updateLearningState = async (
  db: SQLite.SQLiteDatabase,
  state: Partial<LearningState>,
) => {
  const updates: string[] = [];
  const params: any[] = [];

  if (state.usedTime !== undefined) {
    updates.push("usedTime = ?");
    params.push(state.usedTime);
  }
  if (state.limit !== undefined) {
    updates.push("limit_time = ?");
    params.push(state.limit);
  }
  if (state.locked !== undefined) {
    updates.push("locked = ?");
    params.push(state.locked ? 1 : 0);
  }
  if (state.lastPlayTime !== undefined) {
    updates.push("lastPlayTime = ?");
    params.push(state.lastPlayTime);
  }
  if (state.themeColor !== undefined) {
    updates.push("theme_color = ?");
    params.push(state.themeColor);
  }

  if (updates.length > 0) {
    params.push(1); // For the id = 1
    await db.runAsync(
      `UPDATE learning_state SET ${updates.join(", ")} WHERE id = ?`,
      params,
    );
  }
};
