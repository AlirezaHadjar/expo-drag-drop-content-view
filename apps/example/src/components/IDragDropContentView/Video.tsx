import { useVideoPlayer, VideoView, VideoViewProps } from "expo-video";
import { useEffect } from "react";

export const IVideo = ({
  uri,
  ...props
}: { uri: string } & Omit<VideoViewProps, "player">) => {
  const player = useVideoPlayer(uri, (player) => {
    player.muted = true;
    player.loop = true;
  });

  // WORKAROUND:- autoPlay video for web is not working
  useEffect(() => {
    player.play();
  }, [player]);

  return (
    <VideoView
      player={player}
      {...props}
      contentFit="cover"
      nativeControls={false}
    />
  );
};
