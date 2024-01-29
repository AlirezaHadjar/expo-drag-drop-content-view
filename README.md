# Expo Drag Drop Content View

![Untitled Project-2](https://github.com/AlirezaHadjar/expo-drag-drop-content-view/assets/57192409/86663ea3-d749-4518-80eb-68e3c4ebcf43)

## What

A superset of View component that supports ios drag and drop feature.

https://github.com/AlirezaHadjar/expo-drag-drop-content-view/assets/57192409/34a2ee62-88e0-480c-b6ca-5e297954d8ad

https://github.com/AlirezaHadjar/expo-drag-drop-content-view/assets/57192409/ced26cf2-b967-4055-82d9-bc11efeb8ce8

## Features

- Ability to drag and drop images from other apps
- Support multi-selection

## Installation

### 🔔 You should have expo installed in your project

#### ⚠️ Since it has native code you cannot run it using Expo Go

You can install the package using the following command:

```sh
npx expo install expo-drag-drop-content-view
```

## Examples

- [Basic Example](./example/App.tsx)

## Usage

#### 🗒️ Since this is an ios (and iPad-os) specific feature, `DragDropContentView` works as a simple `View` on Android and Web

```tsx
import {
  DragDropContentView,
  DragDropContentViewProps,
  OnDropEvent,
} from "expo-drag-drop-content-view";
import React, { useState } from "react";
import { Image, StyleSheet, View } from "react-native";

const styles = StyleSheet.create({
  container: {
    width: "100%",
    height: "100%",
    backgroundColor: "#fefefe",
    borderRadius: 20,
    overflow: "visible",
    justifyContent: "center",
    alignItems: "center",
    borderWidth: 3,
    borderStyle: "dashed",
    borderColor: "#2f95dc",
  },
  imageContainer: {
    position: "absolute",
    width: "100%",
    height: "100%",
    borderRadius: 20,
    overflow: "hidden",
  },
  image: {
    width: "100%",
    height: "100%",
  },
});

export const IDragDropContentView: React.FC<DragDropContentViewProps> = (
  props
) => {
  const [imageData, setImageData] = useState<OnDropEvent[] | null>(null);
  return (
    <DragDropContentView
      {...props}
      onDropEvent={(event) => {
        setImageData(event.nativeEvent.assets);
      }}
      style={[styles.container, props.style]}
    >
      {imageData &&
        imageData.map((asset, index) => {
          const rotation = Math.ceil(index / 2) * 5;
          const direction = index % 2 === 0 ? 1 : -1;
          return (
            <View
              key={asset.uri}
              style={[
                styles.imageContainer,
                {
                  transform: [{ rotate: `${rotation * direction}deg` }],
                },
              ]}
            >
              <Image source={{ uri: asset.uri }} style={styles.image} />
            </View>
          );
        })}
    </DragDropContentView>
  );
};
```

## Options

`DragDropContentView` supports all `View` Props. Other Props:
| Option | iOS | Android | Web | Description |
| ----------------------- | --- | ------- | --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| onDropEvent | OK | NO | NO | A callback that returns an array of assets. [refer to Asset Object](#Asset-Object)
| includeBase64 | OK | NO | NO | If `true`, creates base64 string of the image (Avoid using on large image files due to performance).

## Asset Object

| key      | iOS | Android | Web | Description                                 |
| -------- | --- | ------- | --- | ------------------------------------------- |
| base64   | OK  | NO      | NO  | The base64 string of the image (Optional)   |
| uri      | OK  | NO      | NO  | The file uri in app-specific cache storage. |
| width    | OK  | NO      | NO  | Asset dimensions                            |
| height   | OK  | NO      | NO  | Asset dimensions                            |
| type     | OK  | NO      | NO  | The file mime type                          |
| fileName | OK  | NO      | NO  | The file name                               |

## License

MIT
