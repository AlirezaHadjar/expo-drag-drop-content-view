/* eslint-disable prettier/prettier */
import { requireNativeViewManager } from "expo-modules-core";
import * as React from "react";
import { NativeSyntheticEvent, StyleSheet } from "react-native";

import { Assets, DragDropContentViewProps } from "./types";
import { MIME_TYPES } from "./mimeTypes";

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

  onDragStartEvent = () => {
    this.props.onDragStart?.();
  };

  onDragEndEvent = () => {
    this.props.onDragEnd?.();
  };

  onEnterEvent = () => {
    this.props.onEnter?.();
  };

  onExitEvent = () => {
    this.props.onExit?.();
  };

  // Convert RegExp objects to serializable strings for native platforms
  private serializeAllowedMimeTypes = (
    allowedMimeTypes?: (string | RegExp)[]
  ): string[] | undefined => {
    if (!allowedMimeTypes) return undefined;

    return allowedMimeTypes.map((item) => {
      if (typeof item === "string") {
        return item;
      } else if (item instanceof RegExp) {
        return `__REGEX__${item.source}__FLAGS__${item.flags}`;
      }
      return "";
    });
  };

  render() {
    const { style, allowedMimeTypes, ...props } = this.props;
    const resolvedStyle = StyleSheet.flatten(style);

    return (
      <NativeExpoDragDropContentView
        {...props}
        includeBase64={props.includeBase64 || false}
        allowedMimeTypes={this.serializeAllowedMimeTypes(allowedMimeTypes)}
        style={resolvedStyle}
        //@ts-ignore
        onDrop={this.onDropEvent}
        onEnter={this.onEnterEvent}
        mimeTypes={MIME_TYPES}
        onExit={this.onExitEvent}
        onDragStart={this.onDragStartEvent}
        onDragEnd={this.onDragEndEvent}
        ref={this.nativeViewRef}
      />
    );
  }
}
