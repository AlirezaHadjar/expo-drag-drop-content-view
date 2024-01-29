import {
  DragDropContentView,
  DragDropContentViewProps,
  OnDropEvent,
} from "expo-drag-drop-content-view";
import { Image } from "expo-image";
import React, { useEffect, useState } from "react";
import { PermissionsAndroid, StyleSheet } from "react-native";
import Animated, { FadeIn } from "react-native-reanimated";

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
  const [imageData, setImageData] = useState<string[] | null>(null);

  useEffect(() => {
    const fn = async () => {
      try {
        await PermissionsAndroid.request(
          "android.permission.READ_MEDIA_IMAGES"
        );
      } catch (error) {
        console.log("sdfsa", error);
      }
    };
    fn();
  }, []);

  return (
    <DragDropContentView
      {...props}
      onDropEvent={(event) => {
        console.log(event.nativeEvent.assets);
        setImageData([
          "file://" + (event.nativeEvent.assets as unknown as string),
        ]);
        props.onDropEvent?.(event);
      }}
      style={[styles.container, props.style]}
    >
      {imageData &&
        imageData.map((asset, index) => {
          const rotation = Math.ceil(index / 2) * 5;
          const direction = index % 2 === 0 ? 1 : -1;
          console.log("asdfasdf", asset);
          return (
            <Animated.View
              key={asset}
              entering={FadeIn.springify().delay(index * 100)}
              style={[
                styles.imageContainer,
                {
                  transform: [{ rotate: `${rotation * direction}deg` }],
                },
              ]}
            >
              <Image
                onError={(e) => {
                  console.log("xczvxzv", e);
                }}
                source={{
                  uri: asset,
                }}
                // source={require("./example.png")}
                style={styles.image}
              />
            </Animated.View>
          );
        })}
    </DragDropContentView>
  );
};
