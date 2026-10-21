/** Column formatting for the command-line tools (Python's {x:>6} / {x:<6} / {x:6}). */
export const right = (v: unknown, w: number) => String(v).padStart(w);
export const left = (v: unknown, w: number) => String(v).padEnd(w);

/** UTF-8 console output on Windows code pages is handled by Node; this only flushes before exit. */
export function exit(code: number): never {
  process.exitCode = code;
  process.exit(code);
}
