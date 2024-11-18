import { Video } from "expo-av";
import { useVideoPlayer, VideoView, VideoViewProps } from "expo-video";

export const IVideo = ({
  uri,
  ...props
}: { uri: string } & Omit<VideoViewProps, "player">) => {
  return <Video isMuted isLooping shouldPlay source={{ uri }} {...props} />;
};
