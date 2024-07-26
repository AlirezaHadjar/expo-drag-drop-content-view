import {
  DragDropContentView,
  DragDropContentViewProps,
  DropAsset,
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
  readyPlaceholderContainer: {
    backgroundColor: "#2f95dc",
    opacity: 0.7,
  },
  placeholderText: {
    color: "white",
    textAlign: "center",
  },
  text: {
    textAlign: "center",
    fontSize: 25,
    padding: 10,
    color: "white",
    backgroundColor: "#2f95dc",
    borderRadius: 10,
    overflow: "hidden",
    borderWidth: 3,
    borderColor: "blue",
  },
});

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

const getSourceType = (source: DropAsset) => {
  if (source.type.startsWith("image")) return "image";
  if (source.type.startsWith("video")) return "video";
  if (source.type.startsWith("text")) return "text";
};

export const IDragDropContentView: React.FC<DragDropContentViewProps> = (
  props
) => {
  usePermission();
  const [sources, setSources] = useState<DropAsset[] | null>(null);
  const [readyToReceive, setReadyToReceive] = useState(false);
  const [isActive, setIsActive] = useState(false);

  console.log(JSON.stringify(sources));

  const handleClear = () => setSources(null);

  return (
    <DragDropContentView
      {...props}
      includeBase64={false}
      draggableSources={sources
        ?.filter((source) => getSourceType(source) !== undefined)
        ?.map((source) => ({
          type: getSourceType(source)!,
          value: source.uri || source.base64 || source.text || "",
        }))}
      onDropListeningStart={() => {
        setReadyToReceive(true);
      }}
      onEnter={() => {
        setIsActive(true);
      }}
      onExit={() => {
        setIsActive(false);
      }}
      onDragEnd={() => {
        setIsActive(false);
        setReadyToReceive(false);
      }}
      onDrop={(event) => {
        // console.log(JSON.stringify(event.assets));
        const newData = [...(sources ?? []), ...event.assets];
        setSources(newData);
        props.onDrop?.(event);
      }}
      style={[styles.container, props.style]}
    >
      {sources ? (
        sources.map((source, index) => {
          const uri = (source.uri ? source.uri : source.base64) || "";
          const rotation = Math.ceil(index / 2) * 5;
          const direction = index % 2 === 0 ? 1 : -1;
          const rotate = `${rotation * direction}deg`;
          const type = getSourceType(source);

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
              {type === "image" ? (
                <Image source={{ uri }} style={styles.image} />
              ) : type === "video" ? (
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
              ) : type === "text" ? (
                <Text
                  //@ts-ignore
                  draggable
                  style={styles.text}
                >
                  {source.text}
                </Text>
              ) : null}
            </AnimatedPressable>
          );
        })
      ) : (
        <Animated.View
          style={[
            styles.placeholderContainer,
            readyToReceive && styles.readyPlaceholderContainer,
            isActive && styles.activePlaceholderContainer,
          ]}
        >
          <Text style={styles.placeholderText}>Drop here!</Text>
        </Animated.View>
      )}
    </DragDropContentView>
  );
};
