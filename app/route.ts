import { hostname } from "node:os";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export function GET() {
  return new Response(`Hostname: ${hostname()}\n`, {
    headers: { "Content-Type": "text/plain; charset=utf-8", "Cache-Control": "no-store" },
  });
}
