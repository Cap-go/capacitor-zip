import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const webSource = readFileSync(new URL('../src/web.ts', import.meta.url), 'utf8');
assert.match(webSource, /HttpRangeReader/);
assert.match(webSource, /preventHeadRequest:\s*true/);
assert.match(webSource, /new HttpReader\(options\.source, httpReaderOptions\)/);

console.log('web-streaming.test.mjs: ok');
