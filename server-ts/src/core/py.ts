/**
 * Python-compatible primitives. The rules engine was written in Python; these reproduce the exact Python
 * behaviour wherever JavaScript differs, so the TypeScript port gives identical answers (see parity/).
 */

/** Python truthiness: empty list / dict / string, 0, null are false (JS treats [] and {} as true). */
export function truthy(v: unknown): boolean {
  if (Array.isArray(v)) return v.length > 0;
  if (v !== null && typeof v === "object") return Object.keys(v as object).length > 0;
  return Boolean(v);
}

/** Python `==`: deep equality for lists / dicts; 1 == 1.0; true == 1 (bool is an int in Python). */
export function eq(a: unknown, b: unknown): boolean {
  if (typeof a === "boolean" && typeof b === "number") return Number(a) === b;
  if (typeof b === "boolean" && typeof a === "number") return Number(b) === a;
  if (Array.isArray(a) && Array.isArray(b)) return a.length === b.length && a.every((x, i) => eq(x, b[i]));
  if (a && b && typeof a === "object" && typeof b === "object" && !Array.isArray(a) && !Array.isArray(b)) {
    const ka = Object.keys(a as object), kb = Object.keys(b as object);
    return ka.length === kb.length && ka.every((k) => eq((a as any)[k], (b as any)[k]));
  }
  return a === b;
}

/** Python `x in y`: membership by == for lists, substring for strings, key for dicts. */
export function contains(container: unknown, x: unknown): boolean {
  if (typeof container === "string") return typeof x === "string" && container.includes(x);
  if (Array.isArray(container)) return container.some((c) => eq(c, x));
  if (container && typeof container === "object") return Object.prototype.hasOwnProperty.call(container, String(x));
  throw new TypeError(`argument of type '${typeof container}' is not iterable`);
}

/**
 * Python round(x, n): round half to even on the exact binary value (JS toFixed rounds exact halves up).
 * round(0.0625, 3) == 0.062 in Python; (0.0625).toFixed(3) == "0.063".
 */
export function pyRound(x: number, n = 0): number {
  if (!Number.isFinite(x) || Math.abs(x) >= 1e21) return x;
  // toFixed(100) is the exact decimal value of the double (for the magnitudes used here)
  const exact = Math.abs(x).toFixed(100).replace(/0+$/, "");
  const frac = exact.split(".")[1] ?? "";
  if (frac.length === n + 1 && frac.endsWith("5")) {
    // exact tie: round half to even
    const down = Number(Math.abs(x).toFixed(100).slice(0, exact.indexOf(".") + 1 + n).replace(/\.$/, ""));
    const lastDigit = n === 0 ? Math.trunc(down) % 10 : Number(frac[n - 1]);
    const r = lastDigit % 2 === 0 ? down : down + Math.pow(10, -n);
    return Math.sign(x) * Number(r.toFixed(n));
  }
  return Number(x.toFixed(n)); // correctly rounded; not a tie, so the tie rule does not matter
}

/** Python str() of a value as used in f-strings (True / False / None, list repr). */
export function pyStr(v: unknown): string {
  if (v === null || v === undefined) return "None";
  if (v === true) return "True";
  if (v === false) return "False";
  if (Array.isArray(v)) return "[" + v.map(pyRepr).join(", ") + "]";
  if (typeof v === "object" && (v as object).toString !== Object.prototype.toString) return String(v);   // PyFloat (pyjson.ts)
  if (typeof v === "object") return "{" + Object.entries(v as object).map(([k, x]) => `${pyRepr(k)}: ${pyRepr(x)}`).join(", ") + "}";
  return String(v);
}

const REPR_ESC: Record<string, string> = { "\\": "\\\\", "\n": "\\n", "\r": "\\r", "\t": "\\t" };

/** Python repr(): strings quoted and escaped as Python does (double quotes when the text has ' but no "), else pyStr. */
export function pyRepr(v: unknown): string {
  if (typeof v !== "string") return pyStr(v);
  const quote = v.includes("'") && !v.includes('"') ? '"' : "'";
  let out = "";
  for (const ch of v) {
    const c = ch.codePointAt(0)!;
    if (REPR_ESC[ch]) out += REPR_ESC[ch];
    else if (ch === quote) out += "\\" + ch;
    else if (c < 0x20 || c === 0x7f) out += "\\x" + c.toString(16).padStart(2, "0");
    else out += ch;
  }
  return quote + out + quote;
}

/** urllib.parse.urlencode (quote_plus): only A-Z a-z 0-9 _ . - ~ stay literal; space -> '+'. */
export function urlencode(params: Record<string, unknown>): string {
  return Object.entries(params)
    .map(([k, v]) => `${quotePlus(String(k))}=${quotePlus(pyStr(v))}`)
    .join("&");
}

export function quotePlus(s: string): string {
  return encodeURIComponent(s)
    .replace(/[!'()*]/g, (c) => "%" + c.charCodeAt(0).toString(16).toUpperCase())
    .replace(/%20/g, "+");
}

/** Order-preserving de-duplication (dict.fromkeys). */
export function unique<T>(xs: Iterable<T>): T[] {
  return [...new Set(xs)];
}

/** Compare tuples the way Python sorts them (null/undefined first is NOT Python; callers pass strings/numbers). */
export function cmpTuple(a: unknown[], b: unknown[]): number {
  for (let i = 0; i < Math.min(a.length, b.length); i++) {
    const x = a[i] as any, y = b[i] as any;
    if (x === y) continue;
    if (typeof x === "boolean" || typeof y === "boolean") return Number(x) - Number(y);
    return x < y ? -1 : 1;
  }
  return a.length - b.length;
}

/** Python's ValueError / LookupError: the API turns these into HTTP 400. */
export class ValueError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ValueError";
  }
}

export class LookupError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "LookupError";
  }
}
