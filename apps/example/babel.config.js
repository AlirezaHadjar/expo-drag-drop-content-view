const path = require("path");
module.exports = function (api) {
  api.cache(true);
  return {
    presets: ["babel-preset-expo"],
    plugins: [
      [
        "module-resolver",
        {
          extensions: [".tsx", ".ts", ".js", ".json"],
          alias: {
            // For development, we want to alias the library to the source
            "expo-drag-drop-content-view": path.join(
              __dirname,
              "..",
              "..",
              "packages",
              "expo-drag-drop-content-view",
              "src",
              "index.ts"
            ),
          },
        },
      ],
    ],
  };
};
