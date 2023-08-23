import { FlatList, View, useWindowDimensions } from "react-native";
import { IDragDropContentView } from "./src/components";

const count = 10;
const countInRow = 2;
const gap = 60;
const array = new Array(count).fill(0);

export default function App() {
  const { width: SCREEN_WIDTH } = useWindowDimensions();
  const boxSize = SCREEN_WIDTH / 2 - (countInRow - 1) * gap;
  const columnCount = Math.ceil(count / countInRow);
  const containerHeight = columnCount * boxSize + (columnCount - 1) * gap;
  return (
    <View
      style={{
        flex: 1,
        justifyContent: "center",
        alignItems: "center",
      }}
    >
      <FlatList
        data={array}
        contentContainerStyle={{
          justifyContent: "center",
          alignItems: "center",
          gap: gap,
          paddingVertical: gap,
          width: SCREEN_WIDTH,
        }}
        columnWrapperStyle={{
          gap: gap,
        }}
        renderItem={() => (
          <IDragDropContentView style={{ width: boxSize, height: boxSize }} />
        )}
        numColumns={2}
      />
    </View>
  );
}
