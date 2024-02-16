/* eslint-disable prettier/prettier */
import React from "react";
import { View } from "react-native";

import { DragDropContentViewProps, OnDropEvent } from "./types";

const handleFile = (file: File) => {
  return new Promise<OnDropEvent>((resolve) => {
    const reader = new FileReader();

    reader.onload = (e) => {
      const dataURL = e.target?.result;

      const img = new Image();
      img.src = dataURL as string;

      img.onload = () => {
        resolve({
          uri: undefined,
          path: undefined,
          type: file.type,
          base64: img.src,
          fileName: file.name,
          width: img.naturalWidth,
          height: img.naturalHeight,
        });
      };
    };

    reader.readAsDataURL(file);
  });
};

const getAssets = async (dataTransfer: DataTransfer) => {
  const filePromises: Promise<OnDropEvent | null>[] = [];

  if (dataTransfer.items) {
    for (let i = 0; i < dataTransfer.items.length; i++) {
      const item = dataTransfer.items[i];
      if (item.kind === "file") {
        const file = item.getAsFile();
        if (!file) continue;
        filePromises.push(handleFile(file));
      }
    }
  } else {
    for (let i = 0; i < dataTransfer.files.length; i++) {
      const file = dataTransfer.files[i];
      filePromises.push(handleFile(file));
    }
  }

  const resolvedFiles = await Promise.all(filePromises);

  // Filter out null values (failed handleFile calls)
  return resolvedFiles.filter((file) => file !== null) as OnDropEvent[];
};

export default class ExpoDragDropContentView extends React.PureComponent<DragDropContentViewProps> {
  private nativeViewRef = React.createRef<View>();

  private id: string =
    "id-" + (Math.random() * 10000000000).toFixed(0).toString();
  private target: EventTarget | null = null;

  componentDidMount() {
    this.setupDragDropListeners();
  }

  componentWillUnmount() {
    this.removeDragDropListeners();
  }

  handleDragEnter = (event: Event) => {
    event.preventDefault();
    this.props.onDropStartEvent?.();
    this.target = event.target;
  };

  handleDragLeave = (event: Event) => {
    event.preventDefault();
    if (event.target !== this.target) return;

    this.props.onDropEndEvent?.();
    this.target = null;
  };

  handleDragOver = (event: Event) => {
    event.preventDefault();
  };

  handleDrop = async <T extends Event & { dataTransfer: DataTransfer }>(
    event: T
  ) => {
    event.preventDefault();
    this.props.onDropEndEvent?.();

    const assets = await getAssets(event.dataTransfer);
    this.props.onDropEvent?.({ assets });
  };

  setupDragDropListeners() {
    const domElement = document.querySelector("#" + this.id);

    if (!domElement) return;

    domElement.addEventListener("dragenter", this.handleDragEnter);
    domElement.addEventListener("dragleave", this.handleDragLeave);
    domElement.addEventListener("dragover", this.handleDragOver);
    domElement.addEventListener("drop", this.handleDrop as any);
  }

  removeDragDropListeners() {
    const domElement = document.querySelector("#" + this.id);

    if (!domElement) return;

    domElement.removeEventListener("dragenter", this.handleDragEnter);
    domElement.removeEventListener("dragleave", this.handleDragLeave);
    domElement.removeEventListener("dragover", this.handleDragOver);
    domElement.removeEventListener("drop", this.handleDrop as any);
  }

  render() {
    return <View {...this.props} id={this.id} ref={this.nativeViewRef} />;
  }
}
