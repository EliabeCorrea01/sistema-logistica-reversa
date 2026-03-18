-- =========================================================
-- PROJETO INTEGRADOR EM COMPUTAÇÃO I
-- Sistema de Logística Reversa de Peças
-- BANCO DE DADOS CONSOLIDADO
-- SGBD: PostgreSQL
-- =========================================================

CREATE SCHEMA IF NOT EXISTS logistica_reversa;
SET search_path TO logistica_reversa;

-- =========================================================
-- EXTENSÕES
-- =========================================================
CREATE EXTENSION IF NOT EXISTS citext;

-- =========================================================
-- DOMÍNIOS PADRONIZADOS
-- =========================================================
CREATE DOMAIN cnpj_dom AS VARCHAR(14)
CHECK (VALUE ~ '^[0-9]{14}$');

CREATE DOMAIN email_dom AS CITEXT
CHECK (
    VALUE ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'
    AND length(VALUE) <= 254
);

CREATE DOMAIN dinheiro_dom AS NUMERIC(12,2)
CHECK (VALUE >= 0);

-- =========================================================
-- FUNÇÕES BASE
-- =========================================================
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_protege_log_auditoria()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION
        'Registros de auditoria são imutáveis. Operação % negada na tabela %.',
        TG_OP, TG_TABLE_NAME;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_valida_unidade_usuario()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM usuarios_unidade uu
        WHERE uu.id_usuario = NEW.id_usuario_responsavel
          AND uu.id_unidade = NEW.id_unidade
          AND uu.ativo = TRUE
    ) THEN
        RAISE EXCEPTION 'Usuário % não está vinculado à unidade %.',
            NEW.id_usuario_responsavel, NEW.id_unidade;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_valida_fechamento_devolucao()
RETURNS TRIGGER AS $$
DECLARE
    v_terminal BOOLEAN;
BEGIN
    IF NEW.data_fechamento IS NOT NULL
       OR (TG_OP = 'UPDATE' AND OLD.data_fechamento IS NOT NULL) THEN

        SELECT sd.status_terminal
          INTO v_terminal
          FROM status_devolucao sd
         WHERE sd.id_status = NEW.id_status_atual;

        IF COALESCE(v_terminal, FALSE) = FALSE THEN
            RAISE EXCEPTION
                'Não é permitido manter devolução fechada com status não terminal (id_status=%).',
                NEW.id_status_atual;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =========================================================
-- BLOCO 1 - SEGURANÇA, ACESSO E ORGANIZAÇÃO
-- =========================================================
CREATE TABLE papeis (
    id_papel        BIGSERIAL PRIMARY KEY,
    nome_papel      VARCHAR(50) NOT NULL UNIQUE,
    descricao       TEXT,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE usuarios (
    id_usuario          BIGSERIAL PRIMARY KEY,
    id_papel            BIGINT NOT NULL,
    nome                VARCHAR(150) NOT NULL,
    login               CITEXT NOT NULL UNIQUE,
    email               email_dom NOT NULL UNIQUE,
    senha_hash          VARCHAR(255) NOT NULL
                            CONSTRAINT ck_usuarios_senha_hash_len
                            CHECK (length(senha_hash) >= 60),
    tentativas_falha    INTEGER NOT NULL DEFAULT 0
                            CONSTRAINT ck_usuarios_tentativas
                            CHECK (tentativas_falha >= 0),
    bloqueado_ate       TIMESTAMP,
    ultimo_login        TIMESTAMP,
    ativo               BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuarios_papeis
        FOREIGN KEY (id_papel)
        REFERENCES papeis (id_papel)
        ON DELETE RESTRICT
);

CREATE TABLE unidades_empresa (
    id_unidade      BIGSERIAL PRIMARY KEY,
    nome_unidade    VARCHAR(150) NOT NULL UNIQUE,
    sigla           VARCHAR(30),
    descricao       TEXT,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE usuarios_unidade (
    id_usuario_unidade  BIGSERIAL PRIMARY KEY,
    id_usuario          BIGINT NOT NULL,
    id_unidade          BIGINT NOT NULL,
    ativo               BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_usuario_unidade UNIQUE (id_usuario, id_unidade),
    CONSTRAINT fk_usuarios_unidade_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuarios (id_usuario)
        ON DELETE RESTRICT,
    CONSTRAINT fk_usuarios_unidade_unidade
        FOREIGN KEY (id_unidade)
        REFERENCES unidades_empresa (id_unidade)
        ON DELETE RESTRICT
);

-- =========================================================
-- BLOCO 2 - CADASTROS DE NEGÓCIO
-- =========================================================
CREATE TABLE itens (
    id_item             BIGSERIAL PRIMARY KEY,
    codigo_item         VARCHAR(50) NOT NULL UNIQUE,
    descricao           TEXT NOT NULL,
    categoria           VARCHAR(50),
    marca               VARCHAR(50),
    modelo              VARCHAR(50),
    grupo_item          VARCHAR(50),
    unidade_medida      VARCHAR(20),
    situacao            VARCHAR(30),
    preco_publico       dinheiro_dom,
    ativo               BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE notas_fiscais (
    id_nf               BIGSERIAL PRIMARY KEY,
    numero_nf           VARCHAR(20) NOT NULL UNIQUE,
    data_emissao        DATE NOT NULL,
    xml_path            TEXT,
    cnpj_cliente        cnpj_dom,
    valor_total         dinheiro_dom NOT NULL,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE motivos (
    id_motivo           BIGSERIAL PRIMARY KEY,
    descricao           VARCHAR(100) NOT NULL UNIQUE,
    ativo               BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE status_devolucao (
    id_status           BIGSERIAL PRIMARY KEY,
    nome_status         VARCHAR(50) NOT NULL UNIQUE,
    ordem_fluxo         INTEGER NOT NULL UNIQUE CHECK (ordem_fluxo > 0),
    status_terminal     BOOLEAN NOT NULL DEFAULT FALSE,
    ativo               BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sla_config (
    id_sla              BIGSERIAL PRIMARY KEY,
    id_motivo           BIGINT,
    id_status           BIGINT,
    dias_amarelo        INTEGER NOT NULL CHECK (dias_amarelo >= 0),
    dias_vermelho       INTEGER NOT NULL CHECK (dias_vermelho >= dias_amarelo),
    ativo               BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sla_motivo
        FOREIGN KEY (id_motivo)
        REFERENCES motivos (id_motivo)
        ON DELETE RESTRICT,
    CONSTRAINT fk_sla_status
        FOREIGN KEY (id_status)
        REFERENCES status_devolucao (id_status)
        ON DELETE RESTRICT
);

CREATE UNIQUE INDEX uq_sla_contexto_ativo
ON sla_config (
    COALESCE(id_motivo, -1),
    COALESCE(id_status, -1)
)
WHERE ativo = TRUE;

-- =========================================================
-- BLOCO 3 - PROCESSO PRINCIPAL DE DEVOLUÇÃO
-- =========================================================
CREATE TABLE devolucoes (
    id_devolucao            BIGSERIAL PRIMARY KEY,
    id_nf                   BIGINT NOT NULL,
    id_usuario_responsavel  BIGINT NOT NULL,
    id_unidade              BIGINT NOT NULL,
    id_status_atual         BIGINT NOT NULL,
    id_motivo               BIGINT NOT NULL,
    tipo_solucao            VARCHAR(30),
    destino_final           VARCHAR(30),
    numero_nf_devolucao     VARCHAR(20),
    prazo_envio_fabrica     DATE,
    observacao              TEXT,
    data_abertura           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_fechamento         TIMESTAMP,
    ativo                   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_devolucoes_datas
        CHECK (data_fechamento IS NULL OR data_fechamento >= data_abertura),
    CONSTRAINT ck_devolucoes_tipo_solucao
        CHECK (
            tipo_solucao IS NULL OR
            tipo_solucao IN ('TROCA','RESSARCIMENTO','REPARO','SEM_SOLUCAO')
        ),
    CONSTRAINT ck_devolucoes_destino_final
        CHECK (
            destino_final IS NULL OR
            destino_final IN ('FABRICA','ESTOQUE','DESCARTE','CLIENTE')
        ),
    CONSTRAINT fk_devolucoes_nf
        FOREIGN KEY (id_nf)
        REFERENCES notas_fiscais (id_nf)
        ON DELETE RESTRICT,
    CONSTRAINT fk_devolucoes_usuario
        FOREIGN KEY (id_usuario_responsavel)
        REFERENCES usuarios (id_usuario)
        ON DELETE RESTRICT,
    CONSTRAINT fk_devolucoes_unidade
        FOREIGN KEY (id_unidade)
        REFERENCES unidades_empresa (id_unidade)
        ON DELETE RESTRICT,
    CONSTRAINT fk_devolucoes_status
        FOREIGN KEY (id_status_atual)
        REFERENCES status_devolucao (id_status)
        ON DELETE RESTRICT,
    CONSTRAINT fk_devolucoes_motivo
        FOREIGN KEY (id_motivo)
        REFERENCES motivos (id_motivo)
        ON DELETE RESTRICT
);

CREATE TABLE devolucao_itens (
    id_dev_item         BIGSERIAL PRIMARY KEY,
    id_devolucao        BIGINT NOT NULL,
    id_item             BIGINT NOT NULL,
    quantidade          INTEGER NOT NULL CHECK (quantidade > 0),
    valor_unitario      dinheiro_dom,
    valor_total_item    NUMERIC(12,2)
                            GENERATED ALWAYS AS
                            (quantidade * COALESCE(valor_unitario, 0)) STORED,
    condicao            VARCHAR(50),
    ativo               BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_dev_itens_devolucao
        FOREIGN KEY (id_devolucao)
        REFERENCES devolucoes (id_devolucao)
        ON DELETE RESTRICT,
    CONSTRAINT fk_dev_itens_item
        FOREIGN KEY (id_item)
        REFERENCES itens (id_item)
        ON DELETE RESTRICT
);

-- =========================================================
-- BLOCO 4 - WORKFLOW E HISTÓRICO
-- =========================================================
CREATE TABLE status_transicoes (
    id_transicao             BIGSERIAL PRIMARY KEY,
    id_status_atual          BIGINT NOT NULL,
    id_proximo_status        BIGINT NOT NULL,
    id_papel_permitido       BIGINT NOT NULL,
    observacao_obrigatoria   BOOLEAN NOT NULL DEFAULT FALSE,
    ativo                    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_transicao_status_diferentes
        CHECK (id_status_atual <> id_proximo_status),
    CONSTRAINT uq_transicao_fluxo
        UNIQUE (id_status_atual, id_proximo_status, id_papel_permitido),
    CONSTRAINT fk_transicoes_status_atual
        FOREIGN KEY (id_status_atual)
        REFERENCES status_devolucao (id_status)
        ON DELETE RESTRICT,
    CONSTRAINT fk_transicoes_proximo_status
        FOREIGN KEY (id_proximo_status)
        REFERENCES status_devolucao (id_status)
        ON DELETE RESTRICT,
    CONSTRAINT fk_transicoes_papel
        FOREIGN KEY (id_papel_permitido)
        REFERENCES papeis (id_papel)
        ON DELETE RESTRICT
);

CREATE TABLE historico_status (
    id_hist                 BIGSERIAL PRIMARY KEY,
    id_devolucao            BIGINT NOT NULL,
    id_status_anterior      BIGINT,
    id_status_novo          BIGINT NOT NULL,
    id_usuario              BIGINT NOT NULL,
    data_alteracao          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observacao              TEXT,
    CONSTRAINT fk_historico_devolucao
        FOREIGN KEY (id_devolucao)
        REFERENCES devolucoes (id_devolucao)
        ON DELETE RESTRICT,
    CONSTRAINT fk_historico_status_anterior
        FOREIGN KEY (id_status_anterior)
        REFERENCES status_devolucao (id_status)
        ON DELETE RESTRICT,
    CONSTRAINT fk_historico_status_novo
        FOREIGN KEY (id_status_novo)
        REFERENCES status_devolucao (id_status)
        ON DELETE RESTRICT,
    CONSTRAINT fk_historico_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuarios (id_usuario)
        ON DELETE RESTRICT
);

-- =========================================================
-- BLOCO 5 - AUDITORIA, EVIDÊNCIAS E XML
-- =========================================================
CREATE TABLE evento_log (
    id_evento            BIGSERIAL PRIMARY KEY,
    tipo_evento          VARCHAR(100) NOT NULL,
    id_usuario           BIGINT NOT NULL,
    id_devolucao         BIGINT,
    descricao            TEXT,
    data_evento          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_evento_log_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuarios (id_usuario)
        ON DELETE RESTRICT,
    CONSTRAINT fk_evento_log_devolucao
        FOREIGN KEY (id_devolucao)
        REFERENCES devolucoes (id_devolucao)
        ON DELETE RESTRICT
);

CREATE TABLE logs_alteracao (
    id_log               BIGSERIAL PRIMARY KEY,
    entidade             VARCHAR(100) NOT NULL,
    id_registro          BIGINT NOT NULL,
    campo                VARCHAR(100) NOT NULL,
    valor_anterior       TEXT,
    valor_novo           TEXT,
    id_usuario           BIGINT NOT NULL,
    data_alteracao       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_logs_alteracao_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuarios (id_usuario)
        ON DELETE RESTRICT
);

CREATE TABLE evidencias (
    id_evidencia         BIGSERIAL PRIMARY KEY,
    id_dev_item          BIGINT NOT NULL,
    caminho_arquivo      TEXT NOT NULL,
    tipo_arquivo         VARCHAR(50),
    descricao            TEXT,
    id_usuario_upload    BIGINT NOT NULL,
    data_upload          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ativo                BOOLEAN NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_evidencias_dev_item
        FOREIGN KEY (id_dev_item)
        REFERENCES devolucao_itens (id_dev_item)
        ON DELETE RESTRICT,
    CONSTRAINT fk_evidencias_usuario
        FOREIGN KEY (id_usuario_upload)
        REFERENCES usuarios (id_usuario)
        ON DELETE RESTRICT
);

CREATE TABLE xml_importacao (
    id_import            BIGSERIAL PRIMARY KEY,
    arquivo_xml          TEXT NOT NULL,
    id_nf                BIGINT,
    id_devolucao         BIGINT,
    status_import        VARCHAR(20) NOT NULL,
    mensagem_resultado   TEXT,
    id_usuario           BIGINT NOT NULL,
    data_importacao      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_xml_importacao_status
        CHECK (status_import IN ('SUCESSO', 'ERRO', 'PENDENTE')),
    CONSTRAINT fk_xml_importacao_nf
        FOREIGN KEY (id_nf)
        REFERENCES notas_fiscais (id_nf)
        ON DELETE RESTRICT,
    CONSTRAINT fk_xml_importacao_devolucao
        FOREIGN KEY (id_devolucao)
        REFERENCES devolucoes (id_devolucao)
        ON DELETE RESTRICT,
    CONSTRAINT fk_xml_importacao_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuarios (id_usuario)
        ON DELETE RESTRICT
);

-- =========================================================
-- TRIGGERS
-- =========================================================
CREATE TRIGGER trg_papeis_updated_at
BEFORE UPDATE ON papeis
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_usuarios_updated_at
BEFORE UPDATE ON usuarios
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_unidades_updated_at
BEFORE UPDATE ON unidades_empresa
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_usuarios_unidade_updated_at
BEFORE UPDATE ON usuarios_unidade
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_itens_updated_at
BEFORE UPDATE ON itens
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_notas_fiscais_updated_at
BEFORE UPDATE ON notas_fiscais
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_motivos_updated_at
BEFORE UPDATE ON motivos
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_status_devolucao_updated_at
BEFORE UPDATE ON status_devolucao
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_sla_config_updated_at
BEFORE UPDATE ON sla_config
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_devolucoes_updated_at
BEFORE UPDATE ON devolucoes
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_devolucao_itens_updated_at
BEFORE UPDATE ON devolucao_itens
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_status_transicoes_updated_at
BEFORE UPDATE ON status_transicoes
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_evidencias_updated_at
BEFORE UPDATE ON evidencias
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_xml_importacao_updated_at
BEFORE UPDATE ON xml_importacao
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_logs_alteracao_imutavel
BEFORE UPDATE OR DELETE ON logs_alteracao
FOR EACH ROW EXECUTE FUNCTION fn_protege_log_auditoria();

CREATE TRIGGER trg_evento_log_imutavel
BEFORE UPDATE OR DELETE ON evento_log
FOR EACH ROW EXECUTE FUNCTION fn_protege_log_auditoria();

CREATE TRIGGER trg_historico_status_imutavel
BEFORE UPDATE OR DELETE ON historico_status
FOR EACH ROW EXECUTE FUNCTION fn_protege_log_auditoria();

CREATE TRIGGER trg_devolucoes_valida_unidade
BEFORE INSERT OR UPDATE OF id_usuario_responsavel, id_unidade
ON devolucoes
FOR EACH ROW EXECUTE FUNCTION fn_valida_unidade_usuario();

CREATE TRIGGER trg_devolucoes_valida_fechamento
BEFORE INSERT OR UPDATE OF data_fechamento, id_status_atual
ON devolucoes
FOR EACH ROW EXECUTE FUNCTION fn_valida_fechamento_devolucao();

-- =========================================================
-- ÍNDICES
-- =========================================================
CREATE INDEX idx_usuarios_id_papel
    ON usuarios (id_papel);

CREATE INDEX idx_usuarios_unidade_id_usuario
    ON usuarios_unidade (id_usuario);

CREATE INDEX idx_usuarios_unidade_id_unidade
    ON usuarios_unidade (id_unidade);

CREATE INDEX idx_devolucoes_id_nf
    ON devolucoes (id_nf);

CREATE INDEX idx_devolucoes_id_usuario_responsavel
    ON devolucoes (id_usuario_responsavel);

CREATE INDEX idx_devolucoes_id_unidade
    ON devolucoes (id_unidade);

CREATE INDEX idx_devolucoes_id_status_atual
    ON devolucoes (id_status_atual);

CREATE INDEX idx_devolucoes_id_motivo
    ON devolucoes (id_motivo);

CREATE INDEX idx_devolucoes_data_abertura
    ON devolucoes (data_abertura DESC);

CREATE INDEX idx_devolucoes_prazo_envio_fabrica
    ON devolucoes (prazo_envio_fabrica);

CREATE INDEX idx_dev_itens_id_devolucao
    ON devolucao_itens (id_devolucao);

CREATE INDEX idx_dev_itens_id_item
    ON devolucao_itens (id_item);

CREATE INDEX idx_historico_devolucao
    ON historico_status (id_devolucao, data_alteracao DESC);

CREATE INDEX idx_historico_status_anterior
    ON historico_status (id_status_anterior);

CREATE INDEX idx_historico_status_novo
    ON historico_status (id_status_novo);

CREATE INDEX idx_historico_status_usuario
    ON historico_status (id_usuario);

CREATE INDEX idx_status_transicoes_status_atual
    ON status_transicoes (id_status_atual);

CREATE INDEX idx_status_transicoes_proximo_status
    ON status_transicoes (id_proximo_status);

CREATE INDEX idx_status_transicoes_papel
    ON status_transicoes (id_papel_permitido);

CREATE INDEX idx_evento_devolucao
    ON evento_log (id_devolucao);

CREATE INDEX idx_evento_usuario
    ON evento_log (id_usuario);

CREATE INDEX idx_logs_entidade_registro
    ON logs_alteracao (entidade, id_registro);

CREATE INDEX idx_logs_usuario
    ON logs_alteracao (id_usuario);

CREATE INDEX idx_evidencias_dev_item
    ON evidencias (id_dev_item);

CREATE INDEX idx_evidencias_usuario_upload
    ON evidencias (id_usuario_upload);

CREATE INDEX idx_xml_status_import
    ON xml_importacao (status_import);

CREATE INDEX idx_xml_id_nf
    ON xml_importacao (id_nf);

CREATE INDEX idx_xml_id_devolucao
    ON xml_importacao (id_devolucao);

CREATE INDEX idx_xml_id_usuario
    ON xml_importacao (id_usuario);

CREATE INDEX idx_sla_motivo
    ON sla_config (id_motivo);

CREATE INDEX idx_sla_status
    ON sla_config (id_status);

-- =========================================================
-- VIEW DE GESTÃO
-- =========================================================
CREATE OR REPLACE VIEW vw_painel_devolucoes AS
SELECT
    d.id_devolucao,
    nf.numero_nf,
    u.nome AS responsavel,
    un.nome_unidade AS unidade,
    s.nome_status,
    m.descricao AS motivo,
    d.tipo_solucao,
    d.destino_final,
    d.numero_nf_devolucao,
    d.prazo_envio_fabrica,
    d.data_abertura,
    (CURRENT_DATE - d.data_abertura::date) AS dias_aberto,
    COALESCE(sla.dias_amarelo, 5) AS alerta,
    COALESCE(sla.dias_vermelho, 10) AS critico,
    CASE
        WHEN (CURRENT_DATE - d.data_abertura::date) >= COALESCE(sla.dias_vermelho, 10)
            THEN 'CRITICO'
        WHEN (CURRENT_DATE - d.data_abertura::date) >= COALESCE(sla.dias_amarelo, 5)
            THEN 'ALERTA'
        ELSE 'NORMAL'
    END AS status_prazo
FROM devolucoes d
JOIN notas_fiscais nf ON d.id_nf = nf.id_nf
JOIN usuarios u ON d.id_usuario_responsavel = u.id_usuario
JOIN unidades_empresa un ON d.id_unidade = un.id_unidade
JOIN status_devolucao s ON d.id_status_atual = s.id_status
JOIN motivos m ON d.id_motivo = m.id_motivo
LEFT JOIN LATERAL (
    SELECT sc.dias_amarelo, sc.dias_vermelho
    FROM sla_config sc
    WHERE sc.ativo = TRUE
      AND (sc.id_motivo = d.id_motivo OR sc.id_motivo IS NULL)
      AND (sc.id_status = d.id_status_atual OR sc.id_status IS NULL)
    ORDER BY
      ((sc.id_motivo IS NOT NULL)::INT + (sc.id_status IS NOT NULL)::INT) DESC,
      sc.id_sla DESC
    LIMIT 1
) sla ON TRUE;