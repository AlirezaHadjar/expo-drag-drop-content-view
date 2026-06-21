const expoModuleConfig = require("expo-module-scripts/eslint.config.base");
const universeWebConfig = require("eslint-config-universe/flat/web");

module.exports = [
  ...expoModuleConfig,
  ...[universeWebConfig].flat(),
  {
    ignores: ["build/**"],
  },
];
