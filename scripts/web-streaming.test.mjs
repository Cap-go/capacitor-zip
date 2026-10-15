import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const webSource = readFileSync(new URL('../src/web.ts', import.meta.url), 'utf8');
assert.match(webSource, /HttpReader/);
assert.match(webSource, /new ZipReader\(new HttpReader\(options\.source\)\)/);

console.log('web-streaming.test.mjs: ok');
