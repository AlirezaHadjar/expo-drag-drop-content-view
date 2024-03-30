import {
  DragDropContentView,
  DragDropContentViewProps,
  OnDropEvent,
} from "expo-drag-drop-content-view";
import { Image } from "expo-image";
import React, { useState } from "react";
import { Platform, Pressable, StyleSheet, Text } from "react-native";
import Animated, { FadeIn } from "react-native-reanimated";
import { Video, ResizeMode } from "expo-av";
import { usePermission } from "../../hooks/permission";

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
  sourceContainer: {
    position: "absolute",
    width: "100%",
    height: "100%",
    borderRadius,
    overflow: "hidden",
    justifyContent: "center",
    alignItems: "center",
  },
  image: {
    width: "100%",
    height: "100%",
    overflow: "hidden",
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
  text: {
    textAlign: "center",
  },
});

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

export const IDragDropContentView: React.FC<DragDropContentViewProps> = (
  props
) => {
  usePermission();
  const [sources, setSources] = useState<OnDropEvent[] | null>(null);
  const [isActive, setIsActive] = useState(false);

  const handleClear = () => setSources(null);

  return (
    <DragDropContentView
      {...props}
      includeBase64={false}
      draggableSources={sources?.map(
        (source) => (source.uri || source.base64 || source.text) as string
      )}
      onDropStartEvent={() => {
        setIsActive(true);
      }}
      onDropEndEvent={() => {
        setIsActive(false);
      }}
      highlightColor="#2f95dc"
      highlightBorderRadius={borderRadius}
      onDropEvent={(event) => {
        console.log(JSON.stringify(event.assets));
        const newData = [...(sources ?? []), ...event.assets];
        setSources(newData);
        props.onDropEvent?.(event);
      }}
      style={[styles.container, props.style]}
    >
      {sources ? (
        sources.map((source, index) => {
          const uri = (source.uri ? source.uri : source.base64) || "";
          const rotation = Math.ceil(index / 2) * 5;
          const direction = index % 2 === 0 ? 1 : -1;
          const rotate = `${rotation * direction}deg`;
          const isImage = source.type?.startsWith("image");
          const isVideo = source.type?.startsWith("video");
          const isText = source.type?.startsWith("text");

          return (
            <AnimatedPressable
              key={index}
              onPress={handleClear}
              entering={
                Platform.OS === "web"
                  ? undefined
                  : FadeIn.springify().delay(index * 100)
              }
              style={[styles.sourceContainer, { transform: [{ rotate }] }]}
            >
              {isImage ? (
                <Image source={{ uri }} style={styles.image} />
              ) : isVideo ? (
                <Video
                  isMuted
                  style={styles.image}
                  shouldPlay
                  onError={(error) => console.log(JSON.stringify(error))}
                  source={{ uri }}
                  resizeMode={ResizeMode.COVER}
                  isLooping
                  onReadyForDisplay={(videoData) => {
                    if (Platform.OS === "web")
                      //@ts-ignore
                      videoData.srcElement.style.position = "initial";
                  }}
                />
              ) : isText ? (
                <Text style={styles.text}>{source.text}</Text>
              ) : null}
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
          <Text style={styles.placeholderText}>Drop here!</Text>
        </Animated.View>
      )}
    </DragDropContentView>
  );
};
