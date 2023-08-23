import { ViewProps } from "react-native";
import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";

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
  includeBase64?: boolean;
};

const NativeView: React.ComponentType<Props> = requireNativeViewManager(
  "ExpoDragDropContentView"
);

export default function ExpoDragDropContentView(props: Props) {
  return <NativeView {...props} />;
}
