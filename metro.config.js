// Learn more https://docs.expo.dev/guides/customizing-metro
const { getDefaultConfig } = require('expo/metro-config');

/** @type {import('expo/metro-config').MetroConfig} */
const config = getDefaultConfig(__dirname);

// Add .wasm to asset extensions to support expo-sqlite on web
config.resolver.assetExts.push('wasm');

module.exports = config;
