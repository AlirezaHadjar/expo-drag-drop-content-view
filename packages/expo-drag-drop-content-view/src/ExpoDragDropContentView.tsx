/* eslint-disable prettier/prettier */
import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";
import { NativeSyntheticEvent, StyleSheet, processColor } from "react-native";

import { Assets, DragDropContentViewProps } from "./types";

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

const NativeExpoDragDropContentView: React.ComponentType<DragDropContentViewProps> =
  requireNativeViewManager("ExpoDragDropContentView");

export default class ExpoDragDropContentView extends React.PureComponent<DragDropContentViewProps> {
  nativeViewRef;

  constructor(props: DragDropContentViewProps) {
    super(props);
    this.nativeViewRef = React.createRef();
  }

  onDropEvent = (event: NativeSyntheticEvent<Assets>) => {
    this.props.onDrop?.(withDeprecatedNativeEvent(event));
  };

  onDropStartEvent = (event: NativeSyntheticEvent<Assets>) => {
    this.props.onDropStart?.();
  };

  onDropEndEvent = () => {
    this.props.onDropEnd?.();
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
        onDrop={this.onDropEvent}
        //@ts-ignore
        onDropStart={this.onDropStartEvent}
        //@ts-ignore
        onDropEnd={this.onDropEndEvent}
        //@ts-ignore
        highlightColor={highlightColor}
        highlightBorderRadius={highlightBorderRadius}
        ref={this.nativeViewRef}
      />
    );
  }
}
