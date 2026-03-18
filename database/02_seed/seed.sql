SET search_path TO logistica_reversa;

INSERT INTO papeis (nome_papel, descricao) VALUES
('ADMIN', 'Administrador do sistema'),
('OPERADOR', 'Operador de logística'),
('SUPERVISOR', 'Supervisor da unidade');

INSERT INTO usuarios (id_papel, nome, login, email, senha_hash)
VALUES
(
 (SELECT id_papel FROM papeis WHERE nome_papel='ADMIN'),
 'Administrador Sistema',
 'admin',
 'admin@empresa.com',
 '$2a$12$123456789012345678901234567890123456789012345678901234567890'
),
(
 (SELECT id_papel FROM papeis WHERE nome_papel='OPERADOR'),
 'João Operador',
 'operador',
 'operador@empresa.com',
 '$2a$12$123456789012345678901234567890123456789012345678901234567890'
),
(
 (SELECT id_papel FROM papeis WHERE nome_papel='SUPERVISOR'),
 'Maria Supervisora',
 'supervisor',
 'supervisor@empresa.com',
 '$2a$12$123456789012345678901234567890123456789012345678901234567890'
);

INSERT INTO unidades_empresa (nome_unidade, sigla, descricao)
VALUES
('Unidade Central', 'UC', 'Unidade principal de logística'),
('Filial São Paulo', 'FSP', 'Centro de distribuição SP');

INSERT INTO usuarios_unidade (id_usuario, id_unidade)
VALUES
(
 (SELECT id_usuario FROM usuarios WHERE login='admin'),
 (SELECT id_unidade FROM unidades_empresa WHERE sigla='UC')
),
(
 (SELECT id_usuario FROM usuarios WHERE login='operador'),
 (SELECT id_unidade FROM unidades_empresa WHERE sigla='UC')
),
(
 (SELECT id_usuario FROM usuarios WHERE login='supervisor'),
 (SELECT id_unidade FROM unidades_empresa WHERE sigla='UC')
);

INSERT INTO status_devolucao (nome_status, ordem_fluxo, status_terminal)
VALUES
('ABERTO', 1, FALSE),
('EM_ANALISE', 2, FALSE),
('AGUARDANDO_ENVIO', 3, FALSE),
('ENVIADO_FABRICA', 4, FALSE),
('ENCERRADO', 5, TRUE),
('CANCELADO', 6, TRUE);

INSERT INTO motivos (descricao) VALUES
('Defeito de fabricação'),
('Produto errado'),
('Avaria no transporte'),
('Garantia');

INSERT INTO sla_config (id_motivo, id_status, dias_amarelo, dias_vermelho)
VALUES (NULL, NULL, 5, 10);

INSERT INTO status_transicoes
(id_status_atual, id_proximo_status, id_papel_permitido)
VALUES
(
 (SELECT id_status FROM status_devolucao WHERE nome_status='ABERTO'),
 (SELECT id_status FROM status_devolucao WHERE nome_status='EM_ANALISE'),
 (SELECT id_papel FROM papeis WHERE nome_papel='OPERADOR')
),
(
 (SELECT id_status FROM status_devolucao WHERE nome_status='EM_ANALISE'),
 (SELECT id_status FROM status_devolucao WHERE nome_status='AGUARDANDO_ENVIO'),
 (SELECT id_papel FROM papeis WHERE nome_papel='OPERADOR')
),
(
 (SELECT id_status FROM status_devolucao WHERE nome_status='AGUARDANDO_ENVIO'),
 (SELECT id_status FROM status_devolucao WHERE nome_status='ENVIADO_FABRICA'),
 (SELECT id_papel FROM papeis WHERE nome_papel='SUPERVISOR')
),
(
 (SELECT id_status FROM status_devolucao WHERE nome_status='ENVIADO_FABRICA'),
 (SELECT id_status FROM status_devolucao WHERE nome_status='ENCERRADO'),
 (SELECT id_papel FROM papeis WHERE nome_papel='SUPERVISOR')
);

INSERT INTO itens
(codigo_item, descricao, categoria, marca, modelo, unidade_medida, preco_publico)
VALUES
('PEC001', 'Bomba de combustível', 'Motor', 'Bosch', 'BC123', 'UN', 450.00),
('PEC002', 'Filtro de óleo', 'Motor', 'Mann', 'FO456', 'UN', 80.00),
('PEC003', 'Pastilha de freio', 'Freio', 'TRW', 'PF789', 'UN', 150.00);

INSERT INTO notas_fiscais
(numero_nf, data_emissao, cnpj_cliente, valor_total)
VALUES
('NF10001', CURRENT_DATE - INTERVAL '10 days', '12345678000199', 680.00);

INSERT INTO devolucoes
(
 id_nf,
 id_usuario_responsavel,
 id_unidade,
 id_status_atual,
 id_motivo,
 observacao
)
VALUES
(
 (SELECT id_nf FROM notas_fiscais WHERE numero_nf='NF10001'),
 (SELECT id_usuario FROM usuarios WHERE login='operador'),
 (SELECT id_unidade FROM unidades_empresa WHERE sigla='UC'),
 (SELECT id_status FROM status_devolucao WHERE nome_status='ABERTO'),
 (SELECT id_motivo FROM motivos WHERE descricao='Defeito de fabricação'),
 'Cliente relatou falha após instalação'
);

INSERT INTO devolucao_itens
(id_devolucao, id_item, quantidade, valor_unitario, condicao)
VALUES
(
 (SELECT id_devolucao FROM devolucoes LIMIT 1),
 (SELECT id_item FROM itens WHERE codigo_item='PEC001'),
 1,
 450.00,
 'DEFEITO'
);

INSERT INTO historico_status
(id_devolucao, id_status_novo, id_usuario, observacao)
VALUES
(
 (SELECT id_devolucao FROM devolucoes LIMIT 1),
 (SELECT id_status FROM status_devolucao WHERE nome_status='ABERTO'),
 (SELECT id_usuario FROM usuarios WHERE login='operador'),
 'Devolução registrada no sistema'
);

INSERT INTO evento_log
(tipo_evento, id_usuario, id_devolucao, descricao)
VALUES
(
 'CRIACAO_DEVOLUCAO',
 (SELECT id_usuario FROM usuarios WHERE login='operador'),
 (SELECT id_devolucao FROM devolucoes LIMIT 1),
 'Registro inicial da devolução'
);

INSERT INTO logs_alteracao
(entidade, id_registro, campo, valor_anterior, valor_novo, id_usuario)
VALUES
(
 'devolucoes',
 (SELECT id_devolucao FROM devolucoes LIMIT 1),
 'status',
 'NULL',
 'ABERTO',
 (SELECT id_usuario FROM usuarios WHERE login='operador')
);

INSERT INTO evidencias
(id_dev_item, caminho_arquivo, tipo_arquivo, descricao, id_usuario_upload)
VALUES
(
 (SELECT id_dev_item FROM devolucao_itens LIMIT 1),
 '/uploads/foto_defeito.jpg',
 'image/jpeg',
 'Foto do defeito apresentado na peça',
 (SELECT id_usuario FROM usuarios WHERE login='operador')
);

INSERT INTO xml_importacao
(arquivo_xml, id_nf, id_devolucao, status_import, mensagem_resultado, id_usuario)
VALUES
(
 '<xml>NF DEMO</xml>',
 (SELECT id_nf FROM notas_fiscais WHERE numero_nf='NF10001'),
 (SELECT id_devolucao FROM devolucoes LIMIT 1),
 'SUCESSO',
 'XML importado com sucesso',
 (SELECT id_usuario FROM usuarios WHERE login='admin')
);