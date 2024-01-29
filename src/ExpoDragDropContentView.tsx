import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";
import { ViewProps } from "react-native";

export type OnDropEvent = {
  uri: string;
  type: string;
  base64?: string;
  path: string;
  height: number;
  width: number;
  fileName: string;
};

export type Props = ViewProps & {
  onDropEvent?: (event: { nativeEvent: { assets: OnDropEvent[] } }) => void;
  onDropStartEvent?: () => void;
  onDropEndEvent?: () => void;
  includeBase64?: boolean;
};

const NativeView: React.ComponentType<Props> = requireNativeViewManager(
  "ExpoDragDropContentView"
);

export default function ExpoDragDropContentView(props: Props) {
  return <NativeView {...props} />;
}
