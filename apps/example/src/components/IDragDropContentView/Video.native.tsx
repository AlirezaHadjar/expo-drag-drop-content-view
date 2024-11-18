import { useVideoPlayer, VideoView, VideoViewProps } from "expo-video";

export const IVideo = ({
  uri,
  ...props
}: { uri: string } & Omit<VideoViewProps, "player">) => {
  const player = useVideoPlayer(uri, (player) => {
    player.play();
    player.muted = true;
    player.loop = true;
  });
  return (
    <VideoView
      player={player}
      {...props}
      contentFit="cover"
      nativeControls={false}
    />
  );
};
