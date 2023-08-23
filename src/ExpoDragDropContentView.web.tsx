import * as React from 'react';

import { ExpoDragDropContentViewProps } from './ExpoDragDropContentView.types';

export default function ExpoDragDropContentView(props: ExpoDragDropContentViewProps) {
  return (
    <div>
      <span>{props.name}</span>
    </div>
  );
}
