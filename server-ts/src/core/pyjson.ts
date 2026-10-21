/**
 * Python json.loads / json.dumps(ensure_ascii=False) with Python's number handling, for the SQL generator
 * (tools/import-council-research.ts). JSON.parse cannot tell 6 from 6.0; Python keeps 6.0 as a float and writes it
 * back as "6.0", so the generated SQL depends on it. Numbers written with a '.' or exponent load as PyFloat.
 */
export class PyFloat {
  constructor(readonly value: number) {}
  toString(): string {
    return floatRepr(this.value);
  }
}

/** Python repr(float): shortest round-trip digits; fixed notation for 1e-4 <= |x| < 1e16, always with a '.0'. */
export function floatRepr(x: number): string {
  if (Number.isNaN(x)) return "nan";
  if (!Number.isFinite(x)) return x > 0 ? "inf" : "-inf";
  if (x === 0) return Object.is(x, -0) ? "-0.0" : "0.0";
  const [mant, e] = x.toExponential().split("e");
  const exp = Number(e);
  if (exp < -4 || exp >= 16) {
    return `${mant}e${exp < 0 ? "-" : "+"}${String(Math.abs(exp)).padStart(2, "0")}`;
  }
  const s = String(x);   // JS uses fixed notation in this range too
  return s.includes(".") ? s : s + ".0";
}

export function isNumber(v: unknown): v is number | PyFloat {
  return typeof v === "number" || v instanceof PyFloat;
}

export function numValue(v: number | PyFloat): number {
  return v instanceof PyFloat ? v.value : v;
}

/** json.loads, keeping float-ness. */
export function loads(text: string): any {
  let i = 0;
  const ws = () => { while (i < text.length && " \t\n\r".includes(text[i])) i++; };
  const fail = (m: string): never => { throw new SyntaxError(`${m} at position ${i}`); };
  const value = (): any => {
    ws();
    const c = text[i];
    if (c === "{") {
      i++;
      const o: Record<string, any> = {};
      ws();
      if (text[i] === "}") { i++; return o; }
      for (;;) {
        ws();
        if (text[i] !== '"') fail("expected key");
        const k = str();
        ws();
        if (text[i++] !== ":") fail("expected ':'");
        o[k] = value();
        ws();
        if (text[i] === ",") { i++; continue; }
        if (text[i] === "}") { i++; return o; }
        fail("expected ',' or '}'");
      }
    }
    if (c === "[") {
      i++;
      const a: any[] = [];
      ws();
      if (text[i] === "]") { i++; return a; }
      for (;;) {
        a.push(value());
        ws();
        if (text[i] === ",") { i++; continue; }
        if (text[i] === "]") { i++; return a; }
        fail("expected ',' or ']'");
      }
    }
    if (c === '"') return str();
    for (const [lit, v] of [["true", true], ["false", false], ["null", null], ["NaN", NaN], ["Infinity", Infinity], ["-Infinity", -Infinity]] as const)
      if (text.startsWith(lit, i)) { i += lit.length; return lit === "NaN" || lit.endsWith("Infinity") ? new PyFloat(v as number) : v; }
    const m = /^-?(0|[1-9]\d*)(\.\d+)?([eE][+-]?\d+)?/.exec(text.slice(i, i + 64));
    if (!m) fail("unexpected character");
    i += m![0].length;
    return m![2] || m![3] ? new PyFloat(Number(m![0])) : Number(m![0]);
  };
  const str = (): string => {
    const start = i;
    i++;
    while (text[i] !== '"') { if (text[i] === "\\") i++; i++; if (i >= text.length) fail("unterminated string"); }
    i++;
    return JSON.parse(text.slice(start, i));
  };
  const v = value();
  ws();
  if (i !== text.length) fail("extra data");
  return v;
}

/** json.dumps(v, ensure_ascii=False) with Python's default separators (', ' and ': '). */
export function dumps(v: any): string {
  if (v === null || v === undefined) return "null";
  if (v === true) return "true";
  if (v === false) return "false";
  if (v instanceof PyFloat) return Number.isNaN(v.value) ? "NaN" : !Number.isFinite(v.value) ? (v.value > 0 ? "Infinity" : "-Infinity") : floatRepr(v.value);
  if (typeof v === "number") return String(v);
  if (typeof v === "string") return JSON.stringify(v);
  if (Array.isArray(v)) return "[" + v.map(dumps).join(", ") + "]";
  return "{" + Object.entries(v).map(([k, x]) => `${JSON.stringify(k)}: ${dumps(x)}`).join(", ") + "}";
}
