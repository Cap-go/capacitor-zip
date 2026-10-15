import assert from 'node:assert/strict';
import {
  computeZipProgressRatio,
  estimateUncompressedBytesLoaded,
  ZipProgressEmitThrottle,
} from '../dist/esm/progress.js';

assert.equal(computeZipProgressRatio({ loaded: 0, total: 0, filesCompleted: 0, filesTotal: 0, operationComplete: true }), 1);
assert.equal(computeZipProgressRatio({ loaded: 0, total: 0, filesCompleted: 0, filesTotal: 0 }), 0);
assert.equal(estimateUncompressedBytesLoaded(50, 100, 1000), 500);

const throttle = new ZipProgressEmitThrottle();
assert.equal(throttle.shouldEmit(0.1, false), true);
throttle.recordEmit(0.1);
assert.equal(throttle.shouldEmit(0.1001, false), false);
assert.equal(throttle.shouldEmit(0.1, true), true);

console.log('progress-unit.test.mjs: ok');
