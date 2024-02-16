import { DragDropContentView } from "expo-drag-drop-content-view";
import { useState } from "react";
import { FlatList, useWindowDimensions } from "react-native";

import { IDragDropContentView } from "./src/components";

const count = 10;
const countInRow = 2;
const gap = 60;
const array = new Array(count).fill(0);

export default function App() {
  const { width: SCREEN_WIDTH } = useWindowDimensions();
  const [isDragging, setIsDragging] = useState(false);
  const boxSize = SCREEN_WIDTH / 2 - (countInRow - 1) * gap;
  return (
    <DragDropContentView
      onDropStartEvent={() => setIsDragging(true)}
      onDropEndEvent={() => setIsDragging(false)}
      style={{
        flex: 1,
        justifyContent: "center",
        alignItems: "center",
        opacity: isDragging ? 0.3 : 1,
      }}
    >
      <FlatList
        data={array}
        contentContainerStyle={{
          justifyContent: "center",
          alignItems: "center",
          gap,
          paddingVertical: gap,
          width: SCREEN_WIDTH,
        }}
        columnWrapperStyle={{
          gap,
        }}
        renderItem={({ index }) => (
          <IDragDropContentView style={{ width: boxSize, height: boxSize }} />
        )}
        numColumns={2}
      />
    </DragDropContentView>
  );
}
