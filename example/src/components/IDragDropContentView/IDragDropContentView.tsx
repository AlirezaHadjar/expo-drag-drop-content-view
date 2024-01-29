import {
  DragDropContentView,
  DragDropContentViewProps,
  OnDropEvent,
} from "expo-drag-drop-content-view";
import React, { useState } from "react";
import { Image, StyleSheet, Text, TouchableOpacity } from "react-native";
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
  placeholderContainer: {
    paddingHorizontal: 30,
    backgroundColor: "#2f95dc",
    opacity: 0.5,
    height: "100%",
    width: "100%",
    justifyContent: "center",
    alignItems: "center",
    borderRadius: 20,
  },
  placeholderText: {
    color: "white",
    textAlign: "center",
  },
});

const AnimatedTouchable = Animated.createAnimatedComponent(TouchableOpacity);

export const IDragDropContentView: React.FC<DragDropContentViewProps> = (
  props
) => {
  const [imageData, setImageData] = useState<OnDropEvent[] | null>(null);

  const handleClear = () => setImageData(null);
  return (
    <DragDropContentView
      {...props}
      onDropEvent={(event) => {
        setImageData(event.nativeEvent.assets);
        props.onDropEvent?.(event);
      }}
      style={[styles.container, props.style]}
    >
      {imageData ? (
        imageData.map(({ uri }, index) => {
          const rotation = Math.ceil(index / 2) * 5;
          const direction = index % 2 === 0 ? 1 : -1;
          const rotate = `${rotation * direction}deg`;

          return (
            <AnimatedTouchable
              key={uri}
              onPress={handleClear}
              entering={FadeIn.springify().delay(index * 100)}
              style={[styles.imageContainer, { transform: [{ rotate }] }]}
            >
              <Image source={{ uri }} style={styles.image} />
            </AnimatedTouchable>
          );
        })
      ) : (
        <Animated.View style={styles.placeholderContainer}>
          <Text style={styles.placeholderText}>Drop any image here!</Text>
        </Animated.View>
      )}
    </DragDropContentView>
  );
};
