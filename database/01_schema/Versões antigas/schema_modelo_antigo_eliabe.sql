/* =========================================================
   PROJETO INTEGRADOR - SISTEMA DE LOGÍSTICA REVERSA
   BANCO DE DADOS: PostgreSQL

   OBJETIVO:
   Estruturar o banco de dados para controle de devoluções,
   fluxo de status, auditoria e relatórios gerenciais.
   ========================================================= */

/* =========================================================
   0. LIMPEZA DO AMBIENTE (OPCIONAL)
   Use apenas se quiser recriar tudo do zero.
   ========================================================= */

DROP VIEW IF EXISTS vw_devolucoes_completas;
DROP FUNCTION IF EXISTS mudar_status_devolucao(INT, VARCHAR, INT, VARCHAR);

DROP TABLE IF EXISTS evidencias;
DROP TABLE IF EXISTS logs_alteracao;
DROP TABLE IF EXISTS status_movimentacao;
DROP TABLE IF EXISTS status_transicoes;
DROP TABLE IF EXISTS pecas_devolucao;
DROP TABLE IF EXISTS itens;
DROP TABLE IF EXISTS vendedores;
DROP TABLE IF EXISTS usuarios;

/* =========================================================
   1. ESTRUTURA PRINCIPAL DO BANCO DE DADOS
   ========================================================= */

/* ---------------------------------------------------------
   Tabela de usuários do sistema
   Representa quem acessa o sistema e executa ações no processo
   --------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS usuarios (
    id SERIAL PRIMARY KEY,
    login VARCHAR(50) UNIQUE,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL,
    senha_hash VARCHAR(255) NOT NULL,
    tipo_usuario VARCHAR(20) NOT NULL,
    cargo VARCHAR(50),
    departamento VARCHAR(50),
    ativo BOOLEAN DEFAULT TRUE,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_tipo_usuario
        CHECK (tipo_usuario IN ('FUNCIONARIO', 'SUPERVISOR'))
);

/* ---------------------------------------------------------
   Tabela de vendedores
   Representa o responsável comercial vinculado à devolução
   --------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS vendedores (
    id SERIAL PRIMARY KEY,
    codigo_vendedor VARCHAR(30) UNIQUE NOT NULL,
    nome VARCHAR(120) NOT NULL,
    usuario_referencia VARCHAR(100),
    email VARCHAR(120),
    departamento VARCHAR(100),
    ativo BOOLEAN DEFAULT TRUE
);

/* ---------------------------------------------------------
   Tabela de itens/produtos
   Cadastro mestre dos itens que podem ser devolvidos
   --------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS itens (
    id SERIAL PRIMARY KEY,
    codigo_item VARCHAR(50) UNIQUE NOT NULL,
    descricao_item VARCHAR(200) NOT NULL,
    marca VARCHAR(100),
    grupo_item VARCHAR(100),
    unidade_medida VARCHAR(30),
    situacao VARCHAR(30),
    preco_publico NUMERIC(12,2),

    CONSTRAINT chk_situacao_item
        CHECK (situacao IS NULL OR situacao IN ('ATIVO', 'INATIVO', 'BLOQUEADO'))
);

/* ---------------------------------------------------------
   Tabela principal do processo de devolução
   Cada registro representa uma devolução de item
   --------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS pecas_devolucao (
    id SERIAL PRIMARY KEY,
    item_id INT NOT NULL,
    quantidade INT NOT NULL DEFAULT 1,
    numero_nf_origem VARCHAR(60) NOT NULL,
    numero_nf_devolucao VARCHAR(60),
    vendedor_id INT NOT NULL,
    tipo_ocorrencia VARCHAR(50) NOT NULL,
    motivo_ocorrencia VARCHAR(255) NOT NULL,
    tipo_solucao VARCHAR(30),
    destino_final VARCHAR(30),
    evidencia_path VARCHAR(255),
    status_atual VARCHAR(30) NOT NULL,
    data_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    prazo_envio_fabrica DATE,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_peca_item
        FOREIGN KEY (item_id) REFERENCES itens(id),

    CONSTRAINT fk_peca_vendedor
        FOREIGN KEY (vendedor_id) REFERENCES vendedores(id),

    CONSTRAINT chk_tipo_ocorrencia
        CHECK (tipo_ocorrencia IN ('AVARIA', 'ITEM_FALTANDO', 'DESISTENCIA', 'DEFEITO')),

    CONSTRAINT chk_tipo_solucao
        CHECK (
            tipo_solucao IS NULL OR
            tipo_solucao IN ('TROCA', 'ESTORNO', 'SEM_REPOSICAO')
        ),

    CONSTRAINT chk_destino_final
        CHECK (
            destino_final IS NULL OR
            destino_final IN ('SCRAP', 'ESTOQUE', 'REPOSICAO', 'ESTORNO')
        ),

    CONSTRAINT chk_status_atual
        CHECK (status_atual IN (
            'REGISTRADA',
            'EM_ANALISE',
            'APROVADA',
            'REPROVADA',
            'AGUARDANDO_ENVIO',
            'ENVIADA_FABRICA',
            'RESSARCIDA',
            'CANCELADA',
            'FINALIZADA'
        ))
);

/* ---------------------------------------------------------
   Histórico de movimentação de status
   Registra a linha do tempo do processo
   --------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS status_movimentacao (
    id SERIAL PRIMARY KEY,
    peca_devolucao_id INT NOT NULL,
    status_anterior VARCHAR(30) NOT NULL,
    status_novo VARCHAR(30) NOT NULL,
    alterado_por INT NOT NULL,
    alterado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observacao VARCHAR(255),

    CONSTRAINT fk_mov_peca
        FOREIGN KEY (peca_devolucao_id) REFERENCES pecas_devolucao(id),

    CONSTRAINT fk_mov_user
        FOREIGN KEY (alterado_por) REFERENCES usuarios(id)
);

/* ---------------------------------------------------------
   Logs de auditoria
   Registra alterações realizadas no sistema
   --------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS logs_alteracao (
    id SERIAL PRIMARY KEY,
    entidade VARCHAR(60) NOT NULL,
    entidade_id INT NOT NULL,
    campo VARCHAR(60) NOT NULL,
    valor_anterior VARCHAR(255),
    valor_novo VARCHAR(255),
    alterado_por INT NOT NULL,
    alterado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_log_user
        FOREIGN KEY (alterado_por) REFERENCES usuarios(id)
);

/* ---------------------------------------------------------
   Tabela de evidências
   Permite múltiplos anexos por devolução
   --------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS evidencias (
    id SERIAL PRIMARY KEY,
    peca_devolucao_id INT NOT NULL,
    caminho_arquivo VARCHAR(255) NOT NULL,
    data_upload TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_evidencia_peca
        FOREIGN KEY (peca_devolucao_id) REFERENCES pecas_devolucao(id)
);

/* ---------------------------------------------------------
   Tabela de transições permitidas de status
   Define o workflow oficial do processo
   --------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS status_transicoes (
    id SERIAL PRIMARY KEY,
    status_atual VARCHAR(30) NOT NULL,
    proximo_status VARCHAR(30) NOT NULL,
    perfil_permitido VARCHAR(30),
    observacao_obrigatoria BOOLEAN DEFAULT FALSE,

    CONSTRAINT chk_status_atual_transicao
        CHECK (status_atual IN (
            'REGISTRADA',
            'EM_ANALISE',
            'APROVADA',
            'REPROVADA',
            'AGUARDANDO_ENVIO',
            'ENVIADA_FABRICA',
            'RESSARCIDA',
            'CANCELADA',
            'FINALIZADA'
        )),

    CONSTRAINT chk_proximo_status_transicao
        CHECK (proximo_status IN (
            'REGISTRADA',
            'EM_ANALISE',
            'APROVADA',
            'REPROVADA',
            'AGUARDANDO_ENVIO',
            'ENVIADA_FABRICA',
            'RESSARCIDA',
            'CANCELADA',
            'FINALIZADA'
        )),

    CONSTRAINT chk_perfil_permitido
        CHECK (
            perfil_permitido IS NULL OR
            perfil_permitido IN ('FUNCIONARIO', 'SUPERVISOR')
        ),

    CONSTRAINT uq_status_transicao
        UNIQUE (status_atual, proximo_status)
);

/* =========================================================
   2. ÍNDICES PARA CONSULTAS E DASHBOARDS
   ========================================================= */

CREATE INDEX IF NOT EXISTS idx_pecas_status
ON pecas_devolucao(status_atual);

CREATE INDEX IF NOT EXISTS idx_pecas_prazo
ON pecas_devolucao(prazo_envio_fabrica);

CREATE INDEX IF NOT EXISTS idx_pecas_vendedor
ON pecas_devolucao(vendedor_id);

CREATE INDEX IF NOT EXISTS idx_pecas_nf
ON pecas_devolucao(numero_nf_origem);

CREATE INDEX IF NOT EXISTS idx_status_mov_peca
ON status_movimentacao(peca_devolucao_id);

CREATE INDEX IF NOT EXISTS idx_logs_entidade
ON logs_alteracao(entidade, entidade_id);

/* =========================================================
   3. CARGA INICIAL DE DADOS
   ========================================================= */

INSERT INTO usuarios (login, nome, email, senha_hash, tipo_usuario, cargo, departamento)
VALUES
('samuel', 'Samuel', 'samuel@empresa.com', 'hash123', 'FUNCIONARIO', 'ANALISTA', 'LOGISTICA'),
('eliabe', 'Eliabe', 'eliabe@empresa.com', 'hash123', 'FUNCIONARIO', 'ASSISTENTE', 'LOGISTICA'),
('supervisor', 'Supervisor', 'supervisor@empresa.com', 'hash123', 'SUPERVISOR', 'SUPERVISOR', 'OPERACOES')
ON CONFLICT (email) DO NOTHING;

INSERT INTO vendedores (codigo_vendedor, nome, usuario_referencia, email, departamento)
VALUES
('V001', 'Carlos Silva', 'carlos', 'carlos@empresa.com', 'Vendas'),
('V002', 'Ana Souza', 'ana', 'ana@empresa.com', 'Vendas'),
('V003', 'Marcos Lima', 'marcos', 'marcos@empresa.com', 'Comercial')
ON CONFLICT (codigo_vendedor) DO NOTHING;

INSERT INTO itens
(codigo_item, descricao_item, marca, grupo_item, unidade_medida, situacao, preco_publico)
VALUES
('ALT001', 'Alternador 12V', 'Bosch', 'Elétrica', 'UN', 'ATIVO', 850.00),
('PFD233', 'Pastilha de Freio Dianteira', 'Cobreq', 'Freios', 'JOGO', 'ATIVO', 120.00),
('AMP555', 'Amortecedor Traseiro', 'Monroe', 'Suspensão', 'UN', 'ATIVO', 320.00),
('BBA111', 'Bomba D''água', 'Valeo', 'Arrefecimento', 'UN', 'ATIVO', 210.00),
('FAR222', 'Farol Dianteiro', 'Arteb', 'Iluminação', 'UN', 'ATIVO', 450.00)
ON CONFLICT (codigo_item) DO NOTHING;

INSERT INTO pecas_devolucao
(item_id, quantidade, numero_nf_origem, vendedor_id, tipo_ocorrencia, motivo_ocorrencia, evidencia_path, status_atual, prazo_envio_fabrica, numero_nf_devolucao, tipo_solucao, destino_final)
VALUES
(1, 1, 'NF-88991', 1, 'AVARIA', 'Peça chegou com dano aparente na carcaça', 'uploads/alt001.jpg', 'ENVIADA_FABRICA', CURRENT_DATE + INTERVAL '3 days', 'NFD-1001', 'TROCA', 'REPOSICAO'),
(1, 2, 'NF-88992', 1, 'DEFEITO', 'Produto apresentou falha após instalação', 'uploads/alt002.jpg', 'FINALIZADA', CURRENT_DATE + INTERVAL '2 days', 'NFD-2001', 'TROCA', 'REPOSICAO'),
(2, 1, 'NF-88993', 2, 'AVARIA', 'Produto chegou com embalagem danificada', 'uploads/pfd233.jpg', 'RESSARCIDA', CURRENT_DATE + INTERVAL '1 day', 'NFD-2002', 'ESTORNO', 'ESTORNO'),
(3, 3, 'NF-88994', 3, 'DESISTENCIA', 'Produto enviado incorretamente', 'uploads/amp555.jpg', 'EM_ANALISE', CURRENT_DATE + INTERVAL '4 days', NULL, NULL, NULL),
(4, 1, 'NF-88995', 2, 'ITEM_FALTANDO', 'Cliente informou falta de componente na entrega', 'uploads/bba111.jpg', 'REGISTRADA', CURRENT_DATE + INTERVAL '5 days', NULL, NULL, NULL),
(5, 1, 'NF-88996', 3, 'AVARIA', 'Lente do farol quebrada no transporte', 'uploads/far222.jpg', 'AGUARDANDO_ENVIO', CURRENT_DATE + INTERVAL '2 days', 'NFD-2003', 'TROCA', 'REPOSICAO');

INSERT INTO evidencias (peca_devolucao_id, caminho_arquivo)
SELECT id, evidencia_path
FROM pecas_devolucao
WHERE evidencia_path IS NOT NULL;

/* =========================================================
   4. REGRAS DE WORKFLOW (TRANSIÇÕES DE STATUS)
   ========================================================= */

INSERT INTO status_transicoes
(status_atual, proximo_status, perfil_permitido, observacao_obrigatoria)
VALUES
('REGISTRADA', 'EM_ANALISE', 'FUNCIONARIO', FALSE),
('REGISTRADA', 'CANCELADA', 'SUPERVISOR', TRUE),
('EM_ANALISE', 'APROVADA', 'SUPERVISOR', FALSE),
('EM_ANALISE', 'REPROVADA', 'SUPERVISOR', TRUE),
('EM_ANALISE', 'CANCELADA', 'SUPERVISOR', TRUE),
('APROVADA', 'AGUARDANDO_ENVIO', 'FUNCIONARIO', FALSE),
('APROVADA', 'CANCELADA', 'SUPERVISOR', TRUE),
('AGUARDANDO_ENVIO', 'ENVIADA_FABRICA', 'FUNCIONARIO', FALSE),
('AGUARDANDO_ENVIO', 'CANCELADA', 'SUPERVISOR', TRUE),
('ENVIADA_FABRICA', 'RESSARCIDA', 'SUPERVISOR', FALSE),
('ENVIADA_FABRICA', 'FINALIZADA', 'SUPERVISOR', FALSE),
('ENVIADA_FABRICA', 'CANCELADA', 'SUPERVISOR', TRUE),
('REPROVADA', 'CANCELADA', 'SUPERVISOR', TRUE),
('REPROVADA', 'EM_ANALISE', 'SUPERVISOR', TRUE),
('RESSARCIDA', 'FINALIZADA', 'SUPERVISOR', FALSE)
ON CONFLICT (status_atual, proximo_status) DO NOTHING;

/* =========================================================
   5. FUNÇÃO DE NEGÓCIO
   Valida workflow, perfil, observação e gera histórico/log
   ========================================================= */

CREATE OR REPLACE FUNCTION mudar_status_devolucao(
    p_peca_devolucao_id INT,
    p_novo_status VARCHAR(30),
    p_usuario_id INT,
    p_observacao VARCHAR(255)
)
RETURNS VOID AS
$$
DECLARE
    v_status_atual VARCHAR(30);
    v_perfil_usuario VARCHAR(20);
    v_perfil_permitido VARCHAR(30);
    v_obs_obrigatoria BOOLEAN;
BEGIN
    SELECT status_atual
    INTO v_status_atual
    FROM pecas_devolucao
    WHERE id = p_peca_devolucao_id;

    IF v_status_atual IS NULL THEN
        RAISE EXCEPTION 'Devolução com id % não encontrada.', p_peca_devolucao_id;
    END IF;

    IF v_status_atual = p_novo_status THEN
        RAISE EXCEPTION 'A devolução já está no status %.', p_novo_status;
    END IF;

    SELECT tipo_usuario
    INTO v_perfil_usuario
    FROM usuarios
    WHERE id = p_usuario_id;

    IF v_perfil_usuario IS NULL THEN
        RAISE EXCEPTION 'Usuário % não encontrado.', p_usuario_id;
    END IF;

    SELECT perfil_permitido, observacao_obrigatoria
    INTO v_perfil_permitido, v_obs_obrigatoria
    FROM status_transicoes
    WHERE status_atual = v_status_atual
      AND proximo_status = p_novo_status;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transição de status inválida: % -> %', v_status_atual, p_novo_status;
    END IF;

    IF v_perfil_permitido IS NOT NULL AND v_perfil_usuario <> v_perfil_permitido THEN
        RAISE EXCEPTION 'Usuário não tem permissão para esta transição.';
    END IF;

    IF v_obs_obrigatoria = TRUE AND (p_observacao IS NULL OR BTRIM(p_observacao) = '') THEN
        RAISE EXCEPTION 'Observação é obrigatória para esta transição.';
    END IF;

    UPDATE pecas_devolucao
    SET status_atual = p_novo_status,
        atualizado_em = CURRENT_TIMESTAMP
    WHERE id = p_peca_devolucao_id;

    INSERT INTO status_movimentacao
    (peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
    VALUES
    (p_peca_devolucao_id, v_status_atual, p_novo_status, p_usuario_id, p_observacao);

    INSERT INTO logs_alteracao
    (entidade, entidade_id, campo, valor_anterior, valor_novo, alterado_por)
    VALUES
    ('pecas_devolucao', p_peca_devolucao_id, 'status_atual', v_status_atual, p_novo_status, p_usuario_id);
END;
$$ LANGUAGE plpgsql;

/* =========================================================
   6. MOVIMENTAÇÕES INICIAIS DE TESTE
   ========================================================= */

INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'REGISTRADA', 'EM_ANALISE', 1, 'Peça encaminhada para análise inicial'
FROM pecas_devolucao
WHERE numero_nf_origem = 'NF-88991';

INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'EM_ANALISE', 'APROVADA', 3, 'Peça aprovada após análise técnica'
FROM pecas_devolucao
WHERE numero_nf_origem = 'NF-88991';

INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'APROVADA', 'AGUARDANDO_ENVIO', 1, 'Preparando envio para fábrica'
FROM pecas_devolucao
WHERE numero_nf_origem = 'NF-88991';

INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'AGUARDANDO_ENVIO', 'ENVIADA_FABRICA', 1, 'Item encaminhado para a fábrica'
FROM pecas_devolucao
WHERE numero_nf_origem = 'NF-88991';

INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'REGISTRADA', 'FINALIZADA', 1, 'Troca realizada e devolução encerrada'
FROM pecas_devolucao
WHERE numero_nf_origem = 'NF-88992';

INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'REGISTRADA', 'RESSARCIDA', 2, 'Cliente recebeu estorno financeiro'
FROM pecas_devolucao
WHERE numero_nf_origem = 'NF-88993';

INSERT INTO status_movimentacao
(peca_devolucao_id, status_anterior, status_novo, alterado_por, observacao)
SELECT id, 'REGISTRADA', 'EM_ANALISE', 1, 'Devolução em análise pelo setor técnico'
FROM pecas_devolucao
WHERE numero_nf_origem = 'NF-88994';

/* =========================================================
   7. VIEW GERENCIAL COMPLETA
   ========================================================= */

CREATE VIEW vw_devolucoes_completas AS
SELECT
    p.id AS devolucao_id,
    i.codigo_item,
    i.descricao_item,
    p.quantidade,
    p.numero_nf_origem,
    p.numero_nf_devolucao,
    v.nome AS vendedor,
    p.tipo_ocorrencia,
    p.motivo_ocorrencia,
    p.tipo_solucao,
    p.destino_final,
    p.status_atual,
    p.data_registro,
    p.prazo_envio_fabrica,
    (p.prazo_envio_fabrica - CURRENT_DATE) AS dias_para_prazo,
    CASE
        WHEN p.status_atual IN ('CANCELADA', 'RESSARCIDA', 'FINALIZADA') THEN 'ENCERRADA'
        WHEN p.prazo_envio_fabrica < CURRENT_DATE THEN 'ATRASADA'
        WHEN p.prazo_envio_fabrica <= CURRENT_DATE + INTERVAL '3 days' THEN 'ATENCAO'
        ELSE 'NO_PRAZO'
    END AS situacao_prazo
FROM pecas_devolucao p
LEFT JOIN vendedores v ON p.vendedor_id = v.id
LEFT JOIN itens i ON p.item_id = i.id;

/* =========================================================
   8. CONSULTAS DE CONFERÊNCIA
   ========================================================= */

SELECT id, numero_nf_origem, status_atual
FROM pecas_devolucao
ORDER BY id;

SELECT *
FROM vw_devolucoes_completas
ORDER BY devolucao_id;

SELECT *
FROM status_movimentacao
ORDER BY alterado_em;
