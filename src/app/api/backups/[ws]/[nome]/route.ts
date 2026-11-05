import { NextRequest, NextResponse } from "next/server";
import { abrir, apagar, nomeValido, podeEspaco, salvar } from "@/lib/backups";
import { erro, mesmaOrigem, ok, usuarioDaRequisicao } from "@/lib/sessao";

export const dynamic = "force-dynamic";

type Ctx = { params: { ws: string; nome: string } };

async function conferir(req: NextRequest, { params }: Ctx, gravar: boolean) {
  const u = await usuarioDaRequisicao(req);
  if (!u) return erro("Sua sessão terminou. Entre de novo.", 401);
  if (!nomeValido(params.nome)) return erro("Backup não encontrado.", 404);
  if (!(await podeEspaco(u.id, params.ws, gravar))) return erro("Você não tem permissão para isso.", 403);
  return null;
}

// Baixar um backup
export async function GET(req: NextRequest, ctx: Ctx) {
  const negado = await conferir(req, ctx, false);
  if (negado) return negado;
  const corpo = await abrir(ctx.params.ws, ctx.params.nome);
  if (!corpo) return erro("Backup não encontrado.", 404);
  return new NextResponse(corpo as BodyInit, {
    headers: { "Content-Type": "application/json", "Content-Disposition": `attachment; filename="${ctx.params.nome}"`, "Cache-Control": "no-store" },
  });
}

// Guardar um backup (o corpo é o JSON do backup)
export async function PUT(req: NextRequest, ctx: Ctx) {
  if (!mesmaOrigem(req)) return erro("Pedido recusado.", 403);
  const negado = await conferir(req, ctx, true);
  if (negado) return negado;
  const texto = await req.text();
  try { JSON.parse(texto); } catch { return erro("Backup inválido."); }
  try {
    await salvar(ctx.params.ws, ctx.params.nome, texto);
    return ok({ ok: true });
  } catch (e) {
    console.error("backup", e);
    return erro("Não consegui guardar o backup na nuvem.", 500);
  }
}

export async function DELETE(req: NextRequest, ctx: Ctx) {
  if (!mesmaOrigem(req)) return erro("Pedido recusado.", 403);
  const negado = await conferir(req, ctx, true);
  if (negado) return negado;
  await apagar(ctx.params.ws, ctx.params.nome);
  return ok({ ok: true });
}
