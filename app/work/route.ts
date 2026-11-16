import { pbkdf2 } from "node:crypto";
import { hostname } from "node:os";
import { promisify } from "node:util";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

const doWork = promisify(pbkdf2);

export async function GET() {
  // PBKDF2 runs on Node's worker pool, leaving the HTTP event loop responsive.
  await doWork("icp3-work", "icp3-salt", 1_000_000, 32, "sha256");
  return new Response(`Hostname: ${hostname()}\n`, {
    headers: { "Content-Type": "text/plain; charset=utf-8", "Cache-Control": "no-store" },
  });
}
