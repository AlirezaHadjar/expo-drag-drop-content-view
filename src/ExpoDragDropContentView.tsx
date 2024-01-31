import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";
import {
  NativeSyntheticEvent,
  StyleSheet,
  ViewProps,
  processColor,
} from "react-native";

export type OnDropEvent = {
  uri: string;
  type: string;
  base64?: string;
  path: string;
  height: number;
  width: number;
  fileName: string;
};
type Assets = { assets: OnDropEvent[] };

export type Props = ViewProps & {
  onDropEvent?: (event: Assets) => void;
  onDropStartEvent?: () => void;
  onDropEndEvent?: () => void;
  includeBase64?: boolean;
  highlightColor?: string | null;
  highlightBorderRadius?: number;
};

function withDeprecatedNativeEvent<NativeEvent>(
  event: NativeSyntheticEvent<NativeEvent>
): NativeEvent {
  Object.defineProperty(event.nativeEvent, "nativeEvent", {
    get() {
      console.warn(
        '[expo-drag-drop-content-view]: Accessing event payload through "nativeEvent" is deprecated, it is now part of the event object itself'
      );
      return event.nativeEvent;
    },
  });
  return event.nativeEvent;
}

const NativeExpoDragDropContentView: React.ComponentType<Props> =
  requireNativeViewManager("ExpoDragDropContentView");

export default class ExpoDragDropContentView extends React.PureComponent<Props> {
  nativeViewRef;

  constructor(props) {
    super(props);
    this.nativeViewRef = React.createRef();
  }

  onDropEvent = (event: NativeSyntheticEvent<Assets>) => {
    this.props.onDropEvent?.(withDeprecatedNativeEvent(event));
  };

  onDropStartEvent = (event: NativeSyntheticEvent<Assets>) => {
    this.props.onDropStartEvent?.();
  };

  onDropEndEvent = () => {
    this.props.onDropEndEvent?.();
  };

  render() {
    const {
      style,
      highlightColor: _highlightColor,
      highlightBorderRadius: _highlightBorderRadius,
      ...props
    } = this.props;
    const resolvedStyle = StyleSheet.flatten(style);

    const highlightColor = processColor(_highlightColor || undefined);
    const highlightBorderRadius = _highlightBorderRadius
      ? _highlightBorderRadius * 3
      : undefined;

    return (
      <NativeExpoDragDropContentView
        {...props}
        style={resolvedStyle}
        //@ts-ignore
        onDropEvent={this.onDropEvent}
        //@ts-ignore
        onDropStartEvent={this.onDropStartEvent}
        //@ts-ignore
        onDropEndEvent={this.onDropEndEvent}
        //@ts-ignore
        highlightColor={highlightColor}
        highlightBorderRadius={highlightBorderRadius}
        ref={this.nativeViewRef}
      />
    );
  }
}
