import { ViewProps } from "react-native";

export type DropAsset = {
  /**
   * @platform Android, iOS
   * @description The file uri in app-specific cache storage.
   */
  uri?: string | undefined;
  /**
   * @description The mime type of the file.
   */
  type: string;
  /**
   * @platform Android, iOS
   * @description The base64 string of the image
   * @optional
   */
  base64?: string;
  /**
   * @platform Android, iOS
   * @description The original file path.
   */
  path?: string | undefined;
  /**
   * @description Asset height
   */
  height?: number;
  /**
   * @description Asset width
   */
  width?: number;
  /**
   * @description Asset file name
   */
  fileName?: string;
  /**
   * @description If the dropped file is text, this key contains its value
   */
  text?: string;
};

export type Assets = { assets: DropAsset[] };

export type DragDropContentViewProps = ViewProps & {
  /**
   * @param Assets
   * @description Callback that is called when the user drops the files.
   */
  onDrop?: (event: Assets) => void;
  /**
   * @platform Android
   * @description Callback that is called for all `<DragDropContentView />` instances within the view port once any drag begins. Useful if you want to customize all drop areas as soon as any asset begins dragging
   */
  onDropListeningStart?: () => void;
  /**
   * @description Callback that is called when the user starts dragging an asset from inside the app
   */
  onDragStart?: () => void;
  /**
   * @description Callback that is called when the users finger is released (successfully or not)
   */
  onDragEnd?: () => void;
  /**
   * @description Callback that is called when the users finger enters the view with the files.
   */
  onEnter?: () => void;
  /**
   *
   * @description Callback that is called when the users finger leaves the view with the files.
   */
  onExit?: () => void;
  /**
   * @default false
   * @description If set to true, the base64 representation of the file will be included in the event.
   */
  includeBase64?: boolean;
  /**
   * @description Array of allowed MIME types. Supports both exact string matches and RegExp patterns. If undefined or null, all MIME types are allowed. If empty array, no MIME types are allowed.
   * @example ['image/jpeg', 'image/png', 'video/mp4'] // Exact matching
   * @example [new RegExp('^image/.*'), new RegExp('^video/.*')] // RegExp patterns to match all images and videos
   * @example ['image/jpeg', new RegExp('^video/.*'), 'application/pdf'] // Mixed exact and regex
   */
  allowedMimeTypes?: (string | RegExp)[];
  /**
   * @description The source of the image or/and video or/and text that can be dragged around the screen.
   * @description Pass Uri on iOS and Android, and base64 on Web.
   */
  draggableSources?: {
    type: "text" | "image" | "video" | "file";
    value: string;
  }[];
};
