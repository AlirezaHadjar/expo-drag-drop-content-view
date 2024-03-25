import { useEffect } from "react";
import { PermissionsAndroid, Platform } from "react-native";

export const usePermission = () => {
  useEffect(() => {
    const fn = async () => {
      try {
        await PermissionsAndroid.requestMultiple([
          "android.permission.READ_MEDIA_IMAGES",
          "android.permission.READ_MEDIA_VIDEO",
        ]);
      } catch (_) {}
    };
    if (Platform.OS === "android") fn();
  }, []);
};
