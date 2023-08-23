import { NativeModulesProxy, EventEmitter, Subscription } from 'expo-modules-core';

// Import the native module. On web, it will be resolved to ExpoDragDropContentView.web.ts
// and on native platforms to ExpoDragDropContentView.ts
import ExpoDragDropContentViewModule from './ExpoDragDropContentViewModule';
import ExpoDragDropContentView from './ExpoDragDropContentView';
import { ChangeEventPayload, ExpoDragDropContentViewProps } from './ExpoDragDropContentView.types';

// Get the native constant value.
export const PI = ExpoDragDropContentViewModule.PI;

export function hello(): string {
  return ExpoDragDropContentViewModule.hello();
}

export async function setValueAsync(value: string) {
  return await ExpoDragDropContentViewModule.setValueAsync(value);
}

const emitter = new EventEmitter(ExpoDragDropContentViewModule ?? NativeModulesProxy.ExpoDragDropContentView);

export function addChangeListener(listener: (event: ChangeEventPayload) => void): Subscription {
  return emitter.addListener<ChangeEventPayload>('onChange', listener);
}

export { ExpoDragDropContentView, ExpoDragDropContentViewProps, ChangeEventPayload };
