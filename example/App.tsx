import { StyleSheet, Text, View } from 'react-native';

import * as ExpoDragDropContentView from 'expo-drag-drop-content-view';

export default function App() {
  return (
    <View style={styles.container}>
      <Text>{ExpoDragDropContentView.hello()}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },
});
