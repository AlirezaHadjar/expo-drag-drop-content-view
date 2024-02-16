import { ViewProps } from "react-native";

export type OnDropEvent = {
  /**
   * @platform Android, iOS
   * @description The file uri in app-specific cache storage.
   */
  uri: string | undefined;
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
  path: string | undefined;
  /**
   * @description Asset height
   */
  height: number;
  /**
   * @description Asset width
   */
  width: number;
  /**
   * @description Asset file name
   */
  fileName: string;
};

export type Assets = { assets: OnDropEvent[] };

export type DragDropContentViewProps = ViewProps & {
  /**
   *
   * @param Assets
   * @default undefined
   * @description Callback that is called when the user drops the files.
   */
  onDropEvent?: (event: Assets) => void;
  /**
   *
   * @platform iOS
   * @default undefined
   * @description Callback that is called when the users finger enters the view with the files.
   */
  onDropStartEvent?: () => void;
  /**
   *
   * @platform iOS
   * @default undefined
   * @description Callback that is called when the users finger leaves the view with the files.
   */
  onDropEndEvent?: () => void;
  /**
   * @default false
   * @description If set to true, the base64 representation of the file will be included in the event.
   */
  includeBase64?: boolean;
  /**
   * @default os decided
   * @platform Android
   * @description Sets the color of the drop target highlight.
   * @link https://developer.android.com/reference/androidx/draganddrop/DropHelper.Options.Builder#setHighlightColor(int)
   *
   * Note: Opacity, if provided, is ignored.
   */
  highlightColor?: string | null;
  /**
   * @default os decided ~ 20px
   * @platform Android
   * @description Sets the corner radius of the drop target highlight.
   * @link https://developer.android.com/reference/androidx/draganddrop/DropHelper.Options.Builder#setHighlightCornerRadiusPx(int)
   */
  highlightBorderRadius?: number;
};
