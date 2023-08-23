import { requireNativeViewManager } from 'expo-modules-core';
import * as React from 'react';

import { ExpoDragDropContentViewProps } from './ExpoDragDropContentView.types';

const NativeView: React.ComponentType<ExpoDragDropContentViewProps> =
  requireNativeViewManager('ExpoDragDropContentView');

export default function ExpoDragDropContentView(props: ExpoDragDropContentViewProps) {
  return <NativeView {...props} />;
}
