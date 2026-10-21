/** Minimal argv parser for the command-line tools: positionals, --key value, --key=value, boolean and repeatable flags. */
export interface ArgSpec {
  booleans?: string[];
  repeatable?: string[];
  defaults?: Record<string, string>;
}

export interface Args {
  _: string[];
  [k: string]: any;
}

export function parseArgs(argv: string[], spec: ArgSpec = {}): Args {
  const out: Args = { _: [], ...(spec.defaults ?? {}) };
  for (const k of spec.repeatable ?? []) out[k] = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (!a.startsWith("--") || a === "--") {
      out._.push(a);
      continue;
    }
    let [key, val] = a.slice(2).split(/=(.*)/s, 2) as [string, string | undefined];
    if (spec.booleans?.includes(key)) {
      out[key] = true;
      continue;
    }
    if (val === undefined) {
      if (i + 1 >= argv.length) throw new Error(`--${key} needs a value`);
      val = argv[++i];
    }
    if (spec.repeatable?.includes(key)) out[key].push(val);
    else out[key] = val;
  }
  return out;
}

/** Print an error and exit with code 2 (argparse's usage error). */
export function usage(text: string, error?: string): never {
  console.error(text.trim() + (error ? `\n\nerror: ${error}` : ""));
  process.exit(2);
}
