/* ---------------------------------------------------------
   INSERÇÃO DE DADOS
   --------------------------------------------------------- */

INSERT INTO pecas_devolucao
(item_id, quantidade, numero_nf_origem, vendedor_id, tipo_ocorrencia,
 motivo_ocorrencia, evidencia_path, status_atual, prazo_envio_fabrica,
 numero_nf_devolucao, tipo_solucao, destino_final)
VALUES
(1, 1, 'NF-89001', 1, 'AVARIA',
 'Peça chegou com dano na carcaça',
 'uploads/teste01.jpg',
 'REGISTRADA',
 CURRENT_DATE + INTERVAL '5 days',
 NULL, NULL, NULL),

(2, 2, 'NF-89002', 2, 'DEFEITO',
 'Produto apresentou falha após uso',
 'uploads/teste02.jpg',
 'EM_ANALISE',
 CURRENT_DATE + INTERVAL '3 days',
 NULL, NULL, NULL),

(3, 1, 'NF-89003', 3, 'DESISTENCIA',
 'Cliente desistiu da compra',
 'uploads/teste03.jpg',
 'RESSARCIDA',
 CURRENT_DATE + INTERVAL '1 day',
 'NFD-3001',
 'ESTORNO',
 'ESTORNO'),

(1, 3, 'NF-89004', 1, 'AVARIA',
 'Embalagem danificada no transporte',
 'uploads/teste04.jpg',
 'FINALIZADA',
 CURRENT_DATE + INTERVAL '2 days',
 'NFD-3002',
 'TROCA',
 'REPOSICAO'),

(2, 1, 'NF-89005', 2, 'DEFEITO',
 'Componente parou de funcionar',
 'uploads/teste05.jpg',
 'AGUARDANDO_ENVIO',
 CURRENT_DATE + INTERVAL '2 days',
 NULL,
 'TROCA',
 'REPOSICAO');

 SELECT id, numero_nf_origem, status_atual, tipo_ocorrencia
FROM pecas_devolucao
ORDER BY id;

/* ---------------------------------------------------------
   INSERÇÃO DE DADOS
   --------------------------------------------------------- */
INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
VALUES
(1,'REGISTRADA','EM_ANALISE',1,'Devolução recebida para análise'),
(1,'EM_ANALISE','ENVIADA_FABRICA',1,'Produto enviado para fabricante'),

(2,'REGISTRADA','EM_ANALISE',1,'Falha confirmada'),
(2,'EM_ANALISE','FINALIZADA',1,'Produto substituído'),

(3,'REGISTRADA','RESSARCIDA',2,'Cliente recebeu estorno'),

(4,'REGISTRADA','EM_ANALISE',1,'Equipe técnica avaliando'),

(5,'REGISTRADA','EM_ANALISE',1,'Conferência de estoque'),

(6,'REGISTRADA','AGUARDANDO_ENVIO',1,'Aguardando envio para fábrica'),

(7,'REGISTRADA','EM_ANALISE',1,'Verificação de avaria'),

(8,'REGISTRADA','EM_ANALISE',1,'Produto com defeito'),

(10,'REGISTRADA','EM_ANALISE',1,'Análise concluída'),
(10,'EM_ANALISE','FINALIZADA',1,'Reposição realizada');
SELECT * FROM status_movimentacao;


SELECT
    sm.peca_devolucao_id AS devolucao_id,
    p.numero_nf_origem,
    i.descricao_item,
    sm.status_anterior,
    sm.status_novo,
    u.nome AS alterado_por,
    sm.alterado_em,
    sm.observacao
FROM status_movimentacao sm
JOIN pecas_devolucao p
    ON sm.peca_devolucao_id = p.id
JOIN itens i
    ON p.item_id = i.id
JOIN usuarios u
    ON sm.alterado_por = u.id
ORDER BY sm.peca_devolucao_id, sm.alterado_em ASC;












