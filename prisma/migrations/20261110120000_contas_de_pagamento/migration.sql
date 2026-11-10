-- Contas de pagamento (só para conferência: não mexem no saldo das contas bancárias).
-- config."contasPagamento": lista com os nomes das contas cadastradas.
-- "pagamentos": histórico de cada pagamento de uma despesa / conta a pagar (data, valor, conta).
-- faturaPagamentos."pagoDe": de qual conta de pagamento saiu o pagamento da fatura.
alter table public.config add column if not exists "contasPagamento" jsonb;
alter table public.lancamentos add column if not exists "pagamentos" jsonb;
alter table public."contasPagar" add column if not exists "pagamentos" jsonb;
alter table public."faturaPagamentos" add column if not exists "pagoDe" text;
