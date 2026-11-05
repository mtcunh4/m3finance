-- =====================================================================
-- M3 Finance · estrutura do banco (PostgreSQL / Neon)
-- Migrado do Supabase (projeto painel-loteamentos, esquema "financeiro") em 05/11/2026.
-- Mesmas tabelas e colunas do sistema original. As regras de acesso ficam no banco:
-- cada função confere se quem está logado é membro do espaço e qual o papel
-- (owner e editor gravam; visualizador só lê). O servidor (Next.js) informa quem está
-- logado com set_config('app.uid', ...) antes de chamar a função; auth.uid() lê esse valor.
-- =====================================================================

-- As funções são conferidas só ao executar
SET check_function_bodies = false;

CREATE SCHEMA IF NOT EXISTS auth;
CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$ select nullif(current_setting('app.uid', true), '')::uuid $$;

-- ---------- usuários (no lugar do Supabase Auth) ----------
create table public.usuarios (
  id            uuid primary key default gen_random_uuid(),
  email         text not null unique,
  nome          text not null default '',
  senha_hash    text,
  ativo         boolean not null default true,
  criado_em     timestamptz not null default now(),
  ultimo_acesso timestamptz
);

-- registro de entradas e tentativas recusadas (limite de tentativas no login)
create table public.acessos (
  id      bigserial primary key,
  at      timestamptz not null default now(),
  user_id uuid,
  email   text,
  evento  text not null,
  detalhe text
);
create index acessos_at on public.acessos (at desc);

-- ---------- espaços de trabalho ----------
create table public.workspaces (
  id         uuid primary key default gen_random_uuid(),
  nome       text not null default 'Meu Espaço',
  owner_id   uuid references public.usuarios(id) on delete cascade,
  created_at timestamptz default now()
);

create table public.workspace_members (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id      uuid not null references public.usuarios(id) on delete cascade,
  papel        text not null default 'editor' check (papel in ('owner','editor','visualizador')),
  created_at   timestamptz default now(),
  unique (workspace_id, user_id)
);

create table public.convites_pendentes (
  id            uuid primary key default gen_random_uuid(),
  workspace_id  uuid not null references public.workspaces(id) on delete cascade,
  email         text not null,
  papel         text not null default 'editor' check (papel in ('editor','visualizador')),
  convidado_por uuid references public.usuarios(id),
  created_at    timestamptz default now(),
  unique (workspace_id, email)
);

-- ---------- dados financeiros (mesmas colunas do sistema original) ----------
create table public."abastecimentos" (
  "id" text primary key,
  "workspace_id" uuid not null references public.workspaces(id) on delete cascade,
  "data" date,
  "valor" numeric default 0,
  "litros" numeric default 0,
  "precoLitro" numeric,
  "categoriaId" text,
  "contaId" text,
  "obs" text,
  "created_at" timestamptz default now()
);
create index abastecimentos_ws on public."abastecimentos" (workspace_id);

create table public."bet_lancamentos" (
  "id" text primary key,
  "workspace_id" uuid not null references public.workspaces(id) on delete cascade,
  "tipo" text default 'Depósito',
  "valor" numeric default 0,
  "data" date,
  "obs" text,
  "created_at" timestamptz default now()
);
create index bet_lancamentos_ws on public."bet_lancamentos" (workspace_id);

create table public."cartoes" (
  "id" text primary key,
  "user_id" uuid references public.usuarios(id) on delete set null default auth.uid(),
  "nome" text,
  "banco" text,
  "bandeira" text,
  "ultimosDigitos" text,
  "limiteTotal" numeric default 0,
  "diaFechamento" integer default 5,
  "diaVencimento" integer default 12,
  "cor" text,
  "status" text default 'Ativo',
  "created_at" timestamptz default now(),
  "workspace_id" uuid not null references public.workspaces(id) on delete cascade
);
create index cartoes_ws on public."cartoes" (workspace_id);

create table public."categorias" (
  "id" text primary key,
  "user_id" uuid references public.usuarios(id) on delete set null default auth.uid(),
  "nome" text,
  "tipo" text,
  "subcategorias" jsonb default '[]'::jsonb,
  "created_at" timestamptz default now(),
  "workspace_id" uuid not null references public.workspaces(id) on delete cascade,
  check ("tipo" in ('receita','despesa'))
);
create index categorias_ws on public."categorias" (workspace_id);

create table public."comprasCartao" (
  "id" text primary key,
  "user_id" uuid references public.usuarios(id) on delete set null default auth.uid(),
  "cartaoId" text,
  "data" date,
  "descricao" text,
  "categoriaId" text,
  "valorTotal" numeric,
  "numParcelas" integer default 1,
  "obs" text,
  "created_at" timestamptz default now(),
  "workspace_id" uuid not null references public.workspaces(id) on delete cascade
);
create index comprascartao_ws on public."comprasCartao" (workspace_id);

create table public."config" (
  "user_id" uuid references public.usuarios(id) on delete set null,
  "nome" text default 'Controle Financeiro',
  "subtitulo" text default '',
  "logo" text,
  "moeda" text default 'BRL',
  "corDestaque" text default '#1d4ed8',
  "tema" text,
  "updated_at" timestamptz default now(),
  "workspace_id" uuid not null references public.workspaces(id) on delete cascade,
  unique (workspace_id)
);

create table public."consorcios" (
  "id" text primary key,
  "workspace_id" uuid not null references public.workspaces(id) on delete cascade,
  "nome" text default 'Consórcio',
  "carta" numeric default 0,
  "taxaAdm" numeric default 0,
  "numParcelas" integer default 1,
  "lanceEmbutido" numeric default 0,
  "lancePercentual" numeric default 0,
  "parcelasPagas" integer default 0,
  "status" text default 'Ativo',
  "obs" text,
  "created_at" timestamptz default now()
);
create index consorcios_ws on public."consorcios" (workspace_id);

create table public."contas" (
  "id" text primary key,
  "user_id" uuid references public.usuarios(id) on delete set null default auth.uid(),
  "banco" text,
  "agencia" text,
  "conta" text,
  "nomeConta" text,
  "saldoInicial" numeric default 0,
  "tipo" text default 'Conta corrente',
  "status" text default 'Ativa',
  "created_at" timestamptz default now(),
  "workspace_id" uuid not null references public.workspaces(id) on delete cascade
);
create index contas_ws on public."contas" (workspace_id);

create table public."contasPagar" (
  "id" text primary key,
  "user_id" uuid references public.usuarios(id) on delete set null default auth.uid(),
  "descricao" text,
  "categoriaId" text,
  "vencimento" date,
  "valor" numeric,
  "status" text default 'Em aberto',
  "dataPagamento" date,
  "formaPagamento" text,
  "created_at" timestamptz default now(),
  "workspace_id" uuid not null references public.workspaces(id) on delete cascade,
  "pagoDe" text
);
create index contaspagar_ws on public."contasPagar" (workspace_id);

create table public."contasReceber" (
  "id" text primary key,
  "user_id" uuid references public.usuarios(id) on delete set null default auth.uid(),
  "cliente" text,
  "descricao" text,
  "valor" numeric,
  "vencimento" date,
  "dataRecebimento" date,
  "status" text default 'Pendente',
  "created_at" timestamptz default now(),
  "workspace_id" uuid not null references public.workspaces(id) on delete cascade
);
create index contasreceber_ws on public."contasReceber" (workspace_id);

create table public."emprestimos" (
  "id" text primary key,
  "workspace_id" uuid not null references public.workspaces(id) on delete cascade,
  "tipo" text default 'Empréstimo',
  "nome" text default 'Empréstimo',
  "valorEmprestado" numeric default 0,
  "numParcelas" integer default 1,
  "valorParcela" numeric default 0,
  "taxaMensal" numeric,
  "dataPrimeiraParcela" date,
  "categoriaId" text,
  "contaId" text,
  "status" text default 'Ativo',
  "obs" text,
  "created_at" timestamptz default now()
);
create index emprestimos_ws on public."emprestimos" (workspace_id);

create table public."faturaPagamentos" (
  "id" text primary key,
  "user_id" uuid references public.usuarios(id) on delete set null default auth.uid(),
  "cartaoId" text,
  "mesReferencia" text,
  "valorPago" numeric,
  "data" date,
  "contaId" text,
  "obs" text,
  "created_at" timestamptz default now(),
  "workspace_id" uuid not null references public.workspaces(id) on delete cascade
);
create index faturapagamentos_ws on public."faturaPagamentos" (workspace_id);

create table public."historico" (
  "id" text primary key,
  "user_id" uuid references public.usuarios(id) on delete set null default auth.uid(),
  "tipo" text,
  "entidade" text,
  "descricao" text,
  "quando" timestamptz default now(),
  "workspace_id" uuid not null references public.workspaces(id) on delete cascade
);
create index historico_ws on public."historico" (workspace_id);

create table public."lancamentos" (
  "id" text primary key,
  "user_id" uuid references public.usuarios(id) on delete set null default auth.uid(),
  "tipo" text,
  "data" date,
  "descricao" text,
  "categoriaId" text,
  "valor" numeric,
  "contaId" text,
  "formaPagamento" text,
  "status" text,
  "dataRecebimento" date,
  "recorrente" boolean default false,
  "recorrenciaId" text,
  "recorrenciaFrequencia" text,
  "isTransferencia" boolean default false,
  "transferenciaId" text,
  "obs" text,
  "created_at" timestamptz default now(),
  "workspace_id" uuid not null references public.workspaces(id) on delete cascade,
  "mesReferencia" text,
  "recorrenciaSemPrazo" boolean default false,
  "subcategoria" text,
  "numero" integer,
  "totalParcelas" integer,
  "dataPagamento" date,
  "emprestimoId" text,
  "abastecimentoId" text,
  "tipoItem" text,
  "pagoDe" text,
  check ("tipo" in ('receita','despesa'))
);
create index lancamentos_ws on public."lancamentos" (workspace_id);

create table public."notas" (
  "id" text primary key,
  "workspace_id" uuid not null references public.workspaces(id) on delete cascade,
  "titulo" text default 'Sem título',
  "conteudo" text default '',
  "fixada" boolean default false,
  "created_at" timestamptz default now(),
  "updated_at" timestamptz default now()
);
create index notas_ws on public."notas" (workspace_id);

create table public."parcelas" (
  "id" text primary key,
  "user_id" uuid references public.usuarios(id) on delete set null default auth.uid(),
  "compraId" text,
  "cartaoId" text,
  "numero" integer,
  "totalParcelas" integer,
  "valor" numeric,
  "mesReferencia" text,
  "categoriaId" text,
  "descricao" text,
  "created_at" timestamptz default now(),
  "workspace_id" uuid not null references public.workspaces(id) on delete cascade
);
create index parcelas_ws on public."parcelas" (workspace_id);

-- ---------- funções ----------

-- papel de quem está logado no espaço (null se não for membro)
CREATE FUNCTION public._papel(p_ws uuid) RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select m.papel from public.workspace_members m join public.usuarios u on u.id = m.user_id
  where m.workspace_id = p_ws and m.user_id = auth.uid() and u.ativo
$$;

-- confere o acesso ao espaço; com p_gravar, só owner e editor
CREATE FUNCTION public._exigir_espaco(p_ws uuid, p_gravar boolean) RETURNS void
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare v text := public._papel(p_ws);
begin
  if v is null then raise exception 'Você não tem acesso a este espaço de trabalho.' using errcode = '42501'; end if;
  if p_gravar and v not in ('owner','editor') then raise exception 'Seu acesso a este espaço é só para visualizar.' using errcode = '42501'; end if;
end $$;

-- nome de tabela aceito
CREATE FUNCTION public._loja(p_store text) RETURNS void
    LANGUAGE plpgsql IMMUTABLE
    AS $$
begin
  if not (p_store = any(array['abastecimentos','bet_lancamentos','cartoes','categorias','comprasCartao','config','consorcios','contas','contasPagar','contasReceber','emprestimos','faturaPagamentos','historico','lancamentos','notas','parcelas'])) then raise exception 'Tabela desconhecida: %', p_store; end if;
end $$;

CREATE FUNCTION public.meus_espacos() RETURNS jsonb
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select coalesce(jsonb_agg(jsonb_build_object('workspace_id', w.id, 'nome', w.nome, 'papel', m.papel, 'sou_dono', w.owner_id = auth.uid())
    order by (w.owner_id = auth.uid()) desc, w.created_at asc), '[]'::jsonb)
  from public.workspace_members m join public.workspaces w on w.id = m.workspace_id join public.usuarios u on u.id = m.user_id
  where m.user_id = auth.uid() and u.ativo
$$;

-- todas as linhas da tabela no espaço
CREATE FUNCTION public.fin_listar(p_ws uuid, p_store text) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare r jsonb;
begin
  perform public._exigir_espaco(p_ws, false);
  perform public._loja(p_store);
  execute format('select coalesce(jsonb_agg(to_jsonb(t)), ''[]''::jsonb) from public.%I t where workspace_id = $1', p_store) into r using p_ws;
  return r;
end $$;

-- uma linha (config: a do espaço)
CREATE FUNCTION public.fin_obter(p_ws uuid, p_store text, p_id text) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare r jsonb;
begin
  perform public._exigir_espaco(p_ws, false);
  perform public._loja(p_store);
  if p_store = 'config' then
    select to_jsonb(t) into r from public.config t where workspace_id = p_ws;
  else
    execute format('select to_jsonb(t) from public.%I t where workspace_id = $1 and id = $2', p_store) into r using p_ws, p_id;
  end if;
  return r;
end $$;

-- grava (insere ou atualiza) uma lista de linhas e devolve como ficaram.
-- Só as colunas enviadas mudam; as outras recebem o valor padrão (linha nova) ou ficam como estão.
CREATE FUNCTION public.fin_gravar(p_ws uuid, p_store text, p_linhas jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare cols text[]; x jsonb; v jsonb; lista text; sets text; conflito text; outro boolean; res jsonb := '[]'::jsonb;
begin
  perform public._exigir_espaco(p_ws, true);
  perform public._loja(p_store);
  if jsonb_typeof(p_linhas) <> 'array' then raise exception 'Dados inválidos.'; end if;
  select array_agg(attname::text) into cols from pg_attribute
  where attrelid = format('public.%I', p_store)::regclass and attnum > 0 and not attisdropped;
  conflito := case when p_store = 'config' then 'workspace_id' else 'id' end;
  for x in select * from jsonb_array_elements(p_linhas) loop
    if jsonb_typeof(x) <> 'object' then raise exception 'Dados inválidos.'; end if;
    -- o espaço vem sempre do servidor; o dono da linha fica como estava (ou é quem grava, se for nova)
    x := (x - 'workspace_id' - 'user_id') || jsonb_build_object('workspace_id', p_ws);
    if p_store <> 'config' then
      if coalesce(x->>'id', '') = '' then raise exception 'Registro sem identificação.'; end if;
      execute format('select exists(select 1 from public.%I where id = $1 and workspace_id <> $2)', p_store) into outro using x->>'id', p_ws;
      if outro then raise exception 'Este registro pertence a outro espaço de trabalho.' using errcode = '42501'; end if;
    end if;
    select string_agg(quote_ident(k), ', '), string_agg(format('%I = excluded.%I', k, k), ', ') filter (where k <> conflito)
      into lista, sets from jsonb_object_keys(x) k where k = any(cols);
    execute format('insert into public.%I as t (%s) select %s from jsonb_populate_record(null::public.%I, $1) on conflict (%I) do update set %s returning to_jsonb(t)',
      p_store, lista, lista, p_store, conflito, coalesce(sets, format('%I = excluded.%I', conflito, conflito))) into v using x;
    res := res || jsonb_build_array(v);
  end loop;
  return res;
end $$;

CREATE FUNCTION public.fin_excluir(p_ws uuid, p_store text, p_ids text[]) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  perform public._exigir_espaco(p_ws, true);
  perform public._loja(p_store);
  if p_store = 'config' then return; end if;
  execute format('delete from public.%I where workspace_id = $1 and id = any($2)', p_store) using p_ws, p_ids;
end $$;

-- apaga tudo da tabela no espaço (a configuração fica)
CREATE FUNCTION public.fin_limpar(p_ws uuid, p_store text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  perform public._exigir_espaco(p_ws, true);
  perform public._loja(p_store);
  if p_store = 'config' then return; end if;
  execute format('delete from public.%I where workspace_id = $1', p_store) using p_ws;
end $$;

-- acesso aos backups na nuvem do espaço (gravar/excluir: owner e editor)
CREATE FUNCTION public.pode_espaco(p_ws uuid, p_gravar boolean) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select coalesce(public._papel(p_ws) in ('owner','editor') or (not p_gravar and public._papel(p_ws) is not null), false)
$$;

RESET check_function_bodies;
