/* eslint-disable prettier/prettier */
import React from "react";
import { StyleSheet, View } from "react-native";

import { DragDropContentViewProps, DropAsset } from "./types";

let DragType: string = "";
type DragDataItem = { type: string; value: string };
let DragData: DragDataItem[] = [];

const handleFile = (file: File) => {
  return new Promise<DropAsset>((resolve) => {
    const reader = new FileReader();

    reader.onload = (e) => {
      const dataURL = e.target?.result;

      const media = new Image();
      media.src = dataURL as string;

      media.onload = () => {
        resolve({
          uri: undefined,
          path: undefined,
          type: file.type,
          base64: media.src,
          fileName: file.name,
          width: media.naturalWidth,
          height: media.naturalHeight,
        });
      };
      media.onerror = () => {
        resolve({
          uri: undefined,
          path: undefined,
          type: file.type,
          base64: media.src,
          fileName: file.name,
          width: media.naturalWidth,
          height: media.naturalHeight,
        });
      };
    };

    reader.readAsDataURL(file);
  });
};

const getBase64 = (data: string) => {
  const extension =
    data?.split(";")?.[0]?.split(":")?.[1]?.split("/")?.[1] || "jpeg";
  const kind =
    data?.split(";")?.[0]?.split(":")?.[1]?.split("/")?.[0] || "image";

  const type = `${kind}/${extension}`;
  const fileName = `${kind}.${extension}`;

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

const handleText = (text: string) => {
  return new Promise<DropAsset>((resolve) => {
    resolve({ type: "text", text });
  });
};

// MIME Type Filtering Utils
const isMimeTypeAllowed = (
  mimeType: string,
  allowedMimeTypes?: (string | RegExp)[]
): boolean => {
  if (allowedMimeTypes === undefined || allowedMimeTypes === null) {
    return true; // If undefined or null, allow all
  }
  if (allowedMimeTypes.length === 0) {
    return false; // If empty array, allow none
  }
  return allowedMimeTypes.some((allowedType) => {
    if (typeof allowedType === "string") {
      return allowedType === mimeType; // Exact string match
    } else if (allowedType instanceof RegExp) {
      return allowedType.test(mimeType); // RegExp test
    }
    return false;
  });
};

const getAssets = async (
  dataTransfer: DataTransfer,
  allowedMimeTypes?: (string | RegExp)[]
) => {
  const resolvedFiles: (DropAsset | null)[] = [];
  const filePromises: Promise<DropAsset | null>[] = [];
  const textData = dataTransfer.getData("text/plain");
  const htmlData = dataTransfer.getData("text/html");
  const isCustomDrag = DragType === "Custom Drag";

  if (textData && !isCustomDrag) {
    // For text, check if text/plain is allowed
    if (isMimeTypeAllowed("text/plain", allowedMimeTypes)) {
      filePromises.push(handleText(textData));
    }
  }

  // Dragging from the file system
  if (!isCustomDrag) {
    if (dataTransfer.items && dataTransfer.items.length > 0) {
      for (let i = 0; i < dataTransfer.items.length; i++) {
        const item = dataTransfer.items[i];
        if (item.kind === "file") {
          const file = item.getAsFile();
          if (!file) continue;

          // Check if the file's MIME type is allowed
          if (isMimeTypeAllowed(file.type, allowedMimeTypes)) {
            filePromises.push(handleFile(file));
          }
        }
      }
    } else if (dataTransfer.files && dataTransfer.files.length > 0) {
      for (let i = 0; i < dataTransfer.files.length; i++) {
        const file = dataTransfer.files[i];

        // Check if the file's MIME type is allowed
        if (isMimeTypeAllowed(file.type, allowedMimeTypes)) {
          filePromises.push(handleFile(file));
        }
      }
    }
  }

  // Dragging from current web page
  if (isCustomDrag) {
    const droppedSources: DragDataItem[] = []; // base64 strings

    DragData.forEach((data) => {
      // For custom drag, we need to extract MIME type from base64 data
      if (data.type === "text") {
        if (isMimeTypeAllowed("text/plain", allowedMimeTypes)) {
          droppedSources.push({ type: data.type, value: data.value });
        }
      } else {
        // Extract MIME type from base64 data
        const mimeType =
          data.value?.split(";")?.[0]?.split(":")?.[1] ||
          "application/octet-stream";
        if (isMimeTypeAllowed(mimeType, allowedMimeTypes)) {
          droppedSources.push({ type: data.type, value: data.value });
        }
      }
    });

    resolvedFiles.push(
      ...droppedSources.map((item) => {
        if (item.type === "text") return { type: item.type, text: item.value };
        return getBase64(item.value);
      })
    );
  }
  // Dragging from other web pages
  else if (htmlData) {
    // Extract the media source from the HTML data (you may need to adjust this based on your HTML structure)
    const parser = new DOMParser();
    const doc = parser.parseFromString(htmlData, "text/html");
    const base64 = doc.querySelector("img")?.getAttribute("src");

    if (base64) {
      // Extract MIME type from base64 data
      const mimeType = base64?.split(";")?.[0]?.split(":")?.[1] || "image/jpeg";
      if (isMimeTypeAllowed(mimeType, allowedMimeTypes)) {
        const file = getBase64(base64);
        resolvedFiles.push(file);
      }
    }
  }

  resolvedFiles.push(...(await Promise.all(filePromises)));

  DragData = [];
  DragType = "";

  // Filter out null values (failed handleFile calls)
  return resolvedFiles.filter((file) => file !== null) as DropAsset[];
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
    this.props.onEnter?.();
    this.target = event.target;
  };

  handleDragLeave = (event: Event) => {
    event.preventDefault();
    if (event.target !== this.target) return;

    this.props.onExit?.();
    this.target = null;
  };

  handleDragOver = (event: Event) => {
    event.preventDefault();
  };

  handleDrop = async <T extends Event & { dataTransfer: DataTransfer }>(
    event: T
  ) => {
    event.preventDefault();
    this.props.onDragEnd?.();

    const assets = await getAssets(
      event.dataTransfer,
      this.props.allowedMimeTypes
    );
    if (assets.length > 0) this.props.onDrop?.({ assets });
  };

  handleDragStart = async <T extends Event & { dataTransfer: DataTransfer }>(
    event: T
  ) => {
    this.props.onDragStart?.();
    const sources = this.props.draggableSources;
    const preview = sources?.at(-1);

    if (!preview || !sources) return;

    DragType = "Custom Drag";
    sources.forEach((source, index) => {
      DragData.push({ type: source.type, value: source.value });
    });

    // Both images and videos can be dragged
    const dragMedia = new Image();
    dragMedia.src = preview.value; // Set the path to your custom image

    const parentStyle = StyleSheet.flatten(this.props.style);

    // Limit the dimensions of the preview image
    const maxWidth = parentStyle?.width || 100;
    const maxHeight = parentStyle?.height || 100;

    dragMedia.onload = () => {
      //@ts-expect-error
      dragMedia.height = maxHeight;
      //@ts-expect-error
      dragMedia.width = maxWidth;
      event.dataTransfer.setDragImage(dragMedia, 0, 0);
    };
  };

  setupDragDropListeners() {
    const domElement = document.querySelector("#" + this.id);

    if (!domElement) return;

    domElement.addEventListener("dragstart", this.handleDragStart as any);
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
