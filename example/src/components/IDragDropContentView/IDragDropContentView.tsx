import {
  DragDropContentView,
  DragDropContentViewProps,
  OnDropEvent,
} from "expo-drag-drop-content-view";
import { Image } from "expo-image";
import React, { useEffect, useState } from "react";
import { Platform, Pressable, StyleSheet, Text } from "react-native";
import Animated, { FadeIn } from "react-native-reanimated";

const borderRadius = 20;

const styles = StyleSheet.create({
  container: {
    width: "100%",
    height: "100%",
    backgroundColor: "#fefefe",
    borderRadius,
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
    borderRadius,
    overflow: "hidden",
  },
  image: {
    width: "100%",
    height: "100%",
  },
  placeholderContainer: {
    paddingHorizontal: 30,
    backgroundColor: "#2f95dc",
    opacity: 0.5,
    height: "100%",
    width: "100%",
    justifyContent: "center",
    alignItems: "center",
    borderRadius,
  },
  activePlaceholderContainer: {
    backgroundColor: "#2f95dc",
    opacity: 1,
  },
  placeholderText: {
    color: "white",
    textAlign: "center",
  },
});

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

const usePermission = () => {
  useEffect(() => {
    const fn = async () => {
      try {
        // @ts-ignore
        const PermissionsAndroid = await import("react-native").then(
          (module) => module.PermissionsAndroid
        );
        await PermissionsAndroid.request(
          "android.permission.READ_MEDIA_IMAGES"
        );
      } catch (_) {}
    };
    if (Platform.OS === "android") fn();
  }, []);
};

export const IDragDropContentView: React.FC<DragDropContentViewProps> = (
  props
) => {
  usePermission();
  const [imageData, setImageData] = useState<OnDropEvent[] | null>(null);
  const [isActive, setIsActive] = useState(false);

  const handleClear = () => setImageData(null);

  return (
    <DragDropContentView
      {...props}
      // includeBase64
      draggableImageUris={imageData?.map((image) => image.uri!)}
      onDropStartEvent={() => {
        setIsActive(true);
      }}
      onDropEndEvent={() => {
        setIsActive(false);
      }}
      highlightColor="#2f95dc"
      highlightBorderRadius={borderRadius}
      onDropEvent={(event) => {
        const newData = [...(imageData ?? []), ...event.assets];
        console.log(newData);
        setImageData(newData);
        props.onDropEvent?.(event);
      }}
      style={[styles.container, props.style]}
    >
      {imageData ? (
        imageData.map((image, index) => {
          const uri = image.uri ? image.uri : image.base64;
          const rotation = Math.ceil(index / 2) * 5;
          const direction = index % 2 === 0 ? 1 : -1;
          const rotate = `${rotation * direction}deg`;

          return (
            <AnimatedPressable
              pointerEvents="none"
              key={index}
              onPress={handleClear}
              entering={
                Platform.OS === "web"
                  ? undefined
                  : FadeIn.springify().delay(index * 100)
              }
              style={[styles.imageContainer, { transform: [{ rotate }] }]}
            >
              <Image source={{ uri }} style={[styles.image]} />
            </AnimatedPressable>
          );
        })
      ) : (
        <Animated.View
          style={[
            styles.placeholderContainer,
            isActive && styles.activePlaceholderContainer,
          ]}
        >
          <Text style={styles.placeholderText}>Drop any image here!</Text>
        </Animated.View>
      )}
    </DragDropContentView>
  ) as React.ReactNode;
};
