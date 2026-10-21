import assert from 'node:assert/strict';
import { runZipOrUnzip } from '../dist/esm/zip-operation.js';

function createMockPlugin(behavior) {
  const listeners = new Set();
  return {
    listeners,
    async addListener(_eventName, listenerFunc) {
      listeners.add(listenerFunc);
      return {
        remove: async () => {
          listeners.delete(listenerFunc);
        },
      };
    },
    zip: behavior.zip,
    unzip: behavior.unzip,
    emit(event) {
      for (const listener of listeners) {
        listener(event);
      }
    },
  };
}

const baseEvent = {
  source: '/a',
  destination: '/b',
  operation: 'zip',
  loaded: 1,
  total: 2,
  progress: 0.5,
  lengthComputable: true,
};

await (async () => {
  const plugin = createMockPlugin({
    zip: async (options) => {
      await new Promise((resolve) => setTimeout(resolve, 5));
      plugin.emit({ ...baseEvent, operationId: options.operationId, source: options.source, destination: options.destination });
      await new Promise((resolve) => setTimeout(resolve, 20));
      plugin.emit({
        ...baseEvent,
        operationId: options.operationId,
        source: options.source,
        destination: options.destination,
        loaded: 2,
        progress: 1,
      });
    },
    unzip: async () => {},
  });

  const opAEvents = [];
  const opBEvents = [];

  await Promise.all([
    runZipOrUnzip(plugin, 'zip', {
      source: '/src-a',
      destination: '/dest-a.zip',
      operationId: 'op-a',
      onProgress: (event) => opAEvents.push(event.operationId),
    }),
    runZipOrUnzip(plugin, 'zip', {
      source: '/src-b',
      destination: '/dest-b.zip',
      operationId: 'op-b',
      onProgress: (event) => opBEvents.push(event.operationId),
    }),
  ]);

  assert.deepEqual(opAEvents, ['op-a', 'op-a']);
  assert.deepEqual(opBEvents, ['op-b', 'op-b']);
  assert.equal(plugin.listeners.size, 0);
})();

await (async () => {
  const plugin = createMockPlugin({
    zip: async () => {
      throw new Error('zip failed');
    },
    unzip: async () => {},
  });

  let listenerCount = 0;
  const originalAdd = plugin.addListener.bind(plugin);
  plugin.addListener = async (...args) => {
    listenerCount += 1;
    return originalAdd(...args);
  };

  await assert.rejects(
    () =>
      runZipOrUnzip(plugin, 'zip', {
        source: '/x',
        destination: '/y.zip',
        operationId: 'fail-op',
        onProgress: () => {},
      }),
    /zip failed/,
  );

  assert.equal(listenerCount, 1);
  assert.equal(plugin.listeners.size, 0);
})();

console.log('progress-concurrent.test.mjs: ok');
