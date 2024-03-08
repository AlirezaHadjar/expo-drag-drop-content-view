/* eslint-disable prettier/prettier */
import React from "react";
import { StyleSheet, View } from "react-native";

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

const getBase64Image = (data: string) => {
  const extension =
    data?.split(";")?.[0]?.split(":")?.[1]?.split("/")?.[1] || "jpeg";
  const type = `image/${extension}`;
  const fileName = `image.${extension}`;

  return {
    uri: undefined,
    path: undefined,
    type,
    base64: data,
    fileName,
    width: 200,
    height: 200,
  };
};

const getImageKey = (index: number) => `image-${index}`;

const getAssets = async (dataTransfer: DataTransfer) => {
  const resolvedFiles: (OnDropEvent | null)[] = [];
  const filePromises: Promise<OnDropEvent | null>[] = [];
  const textData = dataTransfer.getData("text/plain");
  const htmlData = dataTransfer.getData("text/html");
  const isCustomDrag = textData === "Custom Drag";

  // Dragging from the file system
  if (dataTransfer.items && dataTransfer.items.length > 0) {
    for (let i = 0; i < dataTransfer.items.length; i++) {
      const item = dataTransfer.items[i];
      if (item.kind === "file") {
        const file = item.getAsFile();
        if (!file) continue;
        filePromises.push(handleFile(file));
      }
    }
  } else if (dataTransfer.files && dataTransfer.files.length > 0) {
    for (let i = 0; i < dataTransfer.files.length; i++) {
      const file = dataTransfer.files[i];
      filePromises.push(handleFile(file));
    }
  }

  // Dragging from current web page
  if (isCustomDrag) {
    const droppedImages: string[] = []; // base64 strings

    let index = 0;
    let key = getImageKey(index);

    while (dataTransfer.getData(key)) {
      const imageSrc = dataTransfer.getData(key);
      droppedImages.push(imageSrc);

      index++;
      key = getImageKey(index);
    }

    resolvedFiles.push(
      ...droppedImages.map((base64) => getBase64Image(base64))
    );
  }
  // Dragging from other web pages
  else if (htmlData) {
    // Extract the image source from the HTML data (you may need to adjust this based on your HTML structure)
    const parser = new DOMParser();
    const doc = parser.parseFromString(htmlData, "text/html");
    const base64 = doc.querySelector("img")?.getAttribute("src");

    if (base64) {
      const file = getBase64Image(base64);
      resolvedFiles.push(file);
    }
  }

  resolvedFiles.push(...(await Promise.all(filePromises)));

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
    if (assets.length > 0) this.props.onDropEvent?.({ assets });
  };

  handleDrag = async <T extends Event & { dataTransfer: DataTransfer }>(
    event: T
  ) => {
    const sources = this.props.draggableImageSources;
    const preview = sources?.at(-1);
    if (!preview || !sources) return;

    event.dataTransfer.setData("text/plain", "Custom Drag");
    sources.forEach((source, index) => {
      event.dataTransfer.setData(getImageKey(index), source);
    });

    const dragImage = new Image();
    dragImage.src = preview; // Set the path to your custom image

    const parentStyle = StyleSheet.flatten(this.props.style);

    // Limit the dimensions of the preview image
    const maxWidth = parentStyle?.width || 100;
    const maxHeight = parentStyle?.height || 100;

    dragImage.onload = () => {
      //@ts-expect-error
      dragImage.height = maxHeight;
      //@ts-expect-error
      dragImage.width = maxWidth;
      event.dataTransfer.setDragImage(dragImage, 0, 0);
    };
  };

  setupDragDropListeners() {
    const domElement = document.querySelector("#" + this.id);

    if (!domElement) return;

    domElement.addEventListener("dragstart", this.handleDrag as any);
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
