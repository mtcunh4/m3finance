import { NextRequest } from "next/server";
import { comUsuario } from "@/lib/db";
import { erro, erroDoBanco, mesmaOrigem, ok, usuarioDaRequisicao } from "@/lib/sessao";

export const dynamic = "force-dynamic";

// Todas as leituras e gravações do sistema passam por aqui: POST /api/fin com { acao, ws, store, ... }.
// Quem pode o quê (membro do espaço; owner e editor gravam) é decidido nas funções do banco.
const SQL: Record<string, string> = {
  espacos: "select public.meus_espacos() as r",
  listar: "select public.fin_listar($1::uuid, $2::text) as r",
  obter: "select public.fin_obter($1::uuid, $2::text, $3::text) as r",
  gravar: "select public.fin_gravar($1::uuid, $2::text, $3::jsonb) as r",
  excluir: "select public.fin_excluir($1::uuid, $2::text, $3::text[]) as r",
  limpar: "select public.fin_limpar($1::uuid, $2::text) as r",
};

export async function POST(req: NextRequest) {
  if (!mesmaOrigem(req)) return erro("Pedido recusado.", 403);
  const u = await usuarioDaRequisicao(req);
  if (!u) return erro("Sua sessão terminou. Entre de novo.", 401);
  const b = await req.json().catch(() => ({}));
  const sql = SQL[String(b.acao)];
  if (!sql) return erro("Ação desconhecida.", 404);
  const params: unknown[] =
    b.acao === "espacos" ? [] :
    b.acao === "obter" ? [b.ws, b.store, b.id ?? null] :
    b.acao === "gravar" ? [b.ws, b.store, JSON.stringify(Array.isArray(b.linhas) ? b.linhas : [])] :
    b.acao === "excluir" ? [b.ws, b.store, (Array.isArray(b.ids) ? b.ids : []).map(String)] :
    [b.ws, b.store];
  try {
    const r = await comUsuario(u.id, async (c) => (await c.query(sql, params)).rows[0]?.r ?? null);
    return ok(r === "" ? null : r);
  } catch (e) {
    return erroDoBanco(e);
  }
}
