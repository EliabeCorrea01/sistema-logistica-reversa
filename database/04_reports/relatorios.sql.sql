-- ======================================================
-- RELATÓRIOS DO SISTEMA DE LOGÍSTICA REVERSA DE PEÇAS
-- ======================================================

-- 1) Painel geral das devoluções
SELECT *
FROM logistica_reversa.vw_painel_devolucoes
ORDER BY data_abertura DESC;


-- 2) Devoluções abertas
SELECT *
FROM logistica_reversa.vw_painel_devolucoes
WHERE nome_status = 'ABERTO';


-- 3) Devoluções em alerta
SELECT *
FROM logistica_reversa.vw_painel_devolucoes
WHERE status_prazo = 'ALERTA';


-- 4) Devoluções críticas
SELECT *
FROM logistica_reversa.vw_painel_devolucoes
WHERE status_prazo = 'CRITICO';


-- 5) Quantidade de devoluções por status
SELECT
    nome_status,
    COUNT(*) AS total
FROM logistica_reversa.vw_painel_devolucoes
GROUP BY nome_status
ORDER BY total DESC;


-- 6) Quantidade de devoluções por motivo
SELECT
    motivo,
    COUNT(*) AS total
FROM logistica_reversa.vw_painel_devolucoes
GROUP BY motivo
ORDER BY total DESC;


-- 7) Histórico de uma devolução
SELECT *
FROM logistica_reversa.historico_status
WHERE id_devolucao = 1
ORDER BY data_evento;