/* =========================================================
   DADOS DE TESTE
   SISTEMA DE LOGÍSTICA REVERSA
   ========================================================= */

/* ---------------------------------------------------------
   Usuários
   --------------------------------------------------------- */
INSERT INTO usuarios (login, nome, email, senha_hash, tipo_usuario, cargo, departamento)
VALUES
('samuel', 'Samuel', 'samuel@empresa.com', 'hash123', 'FUNCIONARIO', 'ANALISTA', 'LOGISTICA'),
('eliabe', 'Eliabe', 'eliabe@empresa.com', 'hash123', 'FUNCIONARIO', 'ASSISTENTE', 'LOGISTICA'),
('supervisor', 'Supervisor', 'supervisor@empresa.com', 'hash123', 'SUPERVISOR', 'SUPERVISOR', 'OPERACOES')
ON CONFLICT (email) DO NOTHING;

/* ---------------------------------------------------------
   Vendedores
   --------------------------------------------------------- */
INSERT INTO vendedores (codigo_vendedor, nome, usuario_referencia, email, departamento)
VALUES
('V001', 'Carlos Silva', 'carlos', 'carlos@empresa.com', 'Vendas'),
('V002', 'Ana Souza', 'ana', 'ana@empresa.com', 'Vendas'),
('V003', 'Marcos Lima', 'marcos', 'marcos@empresa.com', 'Comercial')
ON CONFLICT (codigo_vendedor) DO NOTHING;

/* ---------------------------------------------------------
   Itens
   --------------------------------------------------------- */
INSERT INTO itens
(codigo_item, descricao_item, marca, grupo_item, unidade_medida, situacao, preco_publico)
VALUES
('ALT001', 'Alternador 12V', 'Bosch', 'Elétrica', 'UN', 'ATIVO', 850.00),
('PFD233', 'Pastilha de Freio Dianteira', 'Cobreq', 'Freios', 'JOGO', 'ATIVO', 120.00),
('AMP555', 'Amortecedor Traseiro', 'Monroe', 'Suspensão', 'UN', 'ATIVO', 320.00)
ON CONFLICT (codigo_item) DO NOTHING;

/* ---------------------------------------------------------
   Devoluções
   --------------------------------------------------------- */
INSERT INTO pecas_devolucao
(item_id, quantidade, numero_nf_origem, vendedor_id, tipo_ocorrencia,
 motivo_ocorrencia, evidencia_path, status_atual, prazo_envio_fabrica,
 numero_nf_devolucao, tipo_solucao, destino_final)
VALUES
(1,1,'NF-88991',1,'AVARIA','Peça chegou com dano aparente na carcaça','uploads/alt001.jpg','ENVIADA_FABRICA',CURRENT_DATE + INTERVAL '3 days',NULL,NULL,NULL),

(1,2,'NF-88992',1,'DEFEITO','Produto apresentou falha após instalação','uploads/alt002.jpg','FINALIZADA',CURRENT_DATE + INTERVAL '2 days','NFD-2001','TROCA','REPOSICAO'),

(2,1,'NF-88993',2,'AVARIA','Produto chegou com embalagem danificada','uploads/pfd233.jpg','RESSARCIDA',CURRENT_DATE + INTERVAL '1 day','NFD-2002','ESTORNO','ESTORNO'),

(3,3,'NF-88994',3,'DESISTENCIA','Produto enviado incorretamente','uploads/amp555.jpg','EM_ANALISE',CURRENT_DATE + INTERVAL '4 days',NULL,NULL,NULL),

(2,1,'NF-88995',2,'ITEM_FALTANDO','Item não foi localizado na entrega','uploads/teste05.jpg','REGISTRADA',CURRENT_DATE + INTERVAL '5 days',NULL,NULL,NULL),

(1,1,'NF-88996',1,'AVARIA','Produto com amassado externo','uploads/teste06.jpg','AGUARDANDO_ENVIO',CURRENT_DATE + INTERVAL '2 days',NULL,NULL,NULL),

(1,1,'NF-89001',1,'AVARIA','Peça chegou com dano na carcaça','uploads/teste01.jpg','REGISTRADA',CURRENT_DATE + INTERVAL '5 days',NULL,NULL,NULL),

(2,2,'NF-89002',2,'DEFEITO','Produto apresentou falha após uso','uploads/teste02.jpg','EM_ANALISE',CURRENT_DATE + INTERVAL '3 days',NULL,NULL,NULL),

(3,1,'NF-89003',3,'DESISTENCIA','Cliente desistiu da compra','uploads/teste03.jpg','RESSARCIDA',CURRENT_DATE + INTERVAL '1 day','NFD-3001','ESTORNO','ESTORNO'),

(1,3,'NF-89004',1,'AVARIA','Embalagem danificada no transporte','uploads/teste04.jpg','FINALIZADA',CURRENT_DATE + INTERVAL '2 days','NFD-3002','TROCA','REPOSICAO'),

(2,1,'NF-89005',2,'DEFEITO','Componente parou de funcionar','uploads/teste05.jpg','AGUARDANDO_ENVIO',CURRENT_DATE + INTERVAL '2 days',NULL,'TROCA','REPOSICAO');

/* ---------------------------------------------------------
   Histórico de movimentação
   --------------------------------------------------------- */
INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'REGISTRADA', 'EM_ANALISE', 1, 'Peça encaminhada para análise inicial'
FROM pecas_devolucao WHERE numero_nf_origem = 'NF-88991';

INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'EM_ANALISE', 'APROVADA', 3, 'Peça aprovada após análise técnica'
FROM pecas_devolucao WHERE numero_nf_origem = 'NF-88991';

INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'APROVADA', 'AGUARDANDO_ENVIO', 1, 'Preparando envio para fábrica'
FROM pecas_devolucao WHERE numero_nf_origem = 'NF-88991';

INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'AGUARDANDO_ENVIO', 'ENVIADA_FABRICA', 1, 'Item encaminhado para a fábrica'
FROM pecas_devolucao WHERE numero_nf_origem = 'NF-88991';

INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'REGISTRADA', 'FINALIZADA', 1, 'Troca realizada e devolução encerrada'
FROM pecas_devolucao WHERE numero_nf_origem = 'NF-88992';

INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'REGISTRADA', 'RESSARCIDA', 2, 'Cliente recebeu estorno financeiro'
FROM pecas_devolucao WHERE numero_nf_origem = 'NF-88993';

INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'REGISTRADA', 'EM_ANALISE', 1, 'Devolução em análise pelo setor técnico'
FROM pecas_devolucao WHERE numero_nf_origem = 'NF-88994';

INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'REGISTRADA', 'EM_ANALISE', 1, 'Conferência de estoque'
FROM pecas_devolucao WHERE numero_nf_origem = 'NF-88995';

INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'REGISTRADA', 'AGUARDANDO_ENVIO', 1, 'Aguardando envio para fábrica'
FROM pecas_devolucao WHERE numero_nf_origem = 'NF-88996';

INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'REGISTRADA', 'EM_ANALISE', 1, 'Verificação de avaria'
FROM pecas_devolucao WHERE numero_nf_origem = 'NF-89001';

INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'REGISTRADA', 'EM_ANALISE', 1, 'Produto com defeito'
FROM pecas_devolucao WHERE numero_nf_origem = 'NF-89002';

INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'REGISTRADA', 'RESSARCIDA', 2, 'Cliente recebeu estorno'
FROM pecas_devolucao WHERE numero_nf_origem = 'NF-89003';

INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'REGISTRADA', 'EM_ANALISE', 1, 'Análise concluída'
FROM pecas_devolucao WHERE numero_nf_origem = 'NF-89004';

INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'EM_ANALISE', 'FINALIZADA', 1, 'Reposição realizada'
FROM pecas_devolucao WHERE numero_nf_origem = 'NF-89004';