# Expo Drag Drop Content View

## What

A superset of View component that supports ios drag and drop feature.

## Features

- Ability to drag and drop images from other apps
- Support multi-selection

## Installation

You can install the package using the following command:

```sh
yarn add expo-drag-drop-content-view
```

## Examples

- [Basic Example](./example/App.tsx)

## Usage

```tsx
type IDragDropContentViewProps = ComponentProps<typeof DragDropContentView>;

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

export const IDragDropContentView: React.FC<IDragDropContentViewProps> = (
  props
) => {
  const [imageData, setImageData] = useState<OnDropEvent[] | null>(null);
  return (
    <DragDropContentView
      onDropEvent={(event) => {
        setImageData(event.nativeEvent.assets);
      }}
      style={[styles.container]}
    >
      {imageData &&
        imageData.map((asset, index) => {
          const rotation = Math.ceil(index / 2) * 5;
          const direction = index % 2 === 0 ? 1 : -1;
          return (
            <Animated.View
              key={asset.uri}
              entering={FadeIn.springify().delay(index * 100)}
              style={[
                styles.imageContainer,
                {
                  transform: [{ rotate: `${rotation * direction}deg` }],
                },
              ]}
            >
              <Image source={{ uri: asset.uri }} style={styles.image} />
            </Animated.View>
          );
        })}
    </DragDropContentView>
  );
};
```

## License

MIT
