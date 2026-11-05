import { NextRequest } from "next/server";
import { listar, podeEspaco } from "@/lib/backups";
import { erro, ok, usuarioDaRequisicao } from "@/lib/sessao";

export const dynamic = "force-dynamic";

// Lista dos backups na nuvem do espaço: GET /api/backups/lista?ws=<espaço>
export async function GET(req: NextRequest) {
  const u = await usuarioDaRequisicao(req);
  if (!u) return erro("Sua sessão terminou. Entre de novo.", 401);
  const ws = req.nextUrl.searchParams.get("ws") ?? "";
  if (!(await podeEspaco(u.id, ws, false))) return erro("Você não tem acesso a este espaço de trabalho.", 403);
  try {
    return ok(await listar(ws));
  } catch (e) {
    console.error("backups", e);
    return erro((e as Error).message || "Não consegui listar os backups.", 500);
  }
}
