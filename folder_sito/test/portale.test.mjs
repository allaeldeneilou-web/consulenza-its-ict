import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync, existsSync } from "node:fs";
import { execFileSync } from "node:child_process";

function build() {
  execFileSync(process.execPath, ["src/build.mjs"], { stdio: "pipe" });
}

test("il build genera versione.json", () => {
  build();
  assert.equal(existsSync("dist/versione.json"), true);
});

test("il build genera index.html", () => {
  build();
  assert.equal(existsSync("dist/index.html"), true);
});

test("versione.json contiene 6 corsi", () => {
  build();
  const versione = JSON.parse(readFileSync("dist/versione.json", "utf8"));
  assert.equal(versione.corsi, 6);
});

test("versione.json contiene il totale ore corretto", () => {
  build();
  const versione = JSON.parse(readFileSync("dist/versione.json", "utf8"));
  assert.equal(versione.ore, 320);
});

test("index.html mostra il totale ore corretto", () => {
  build();
  const html = readFileSync("dist/index.html", "utf8");
  assert.match(html, /320 h/);
});

test("index.html non mostra piu il totale errato", () => {
  build();
  const html = readFileSync("dist/index.html", "utf8");
  assert.doesNotMatch(html, /260 h/);
});