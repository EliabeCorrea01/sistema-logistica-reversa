-- 1. Criação do Schema Personalizado
CREATE SCHEMA "Base de Dados Automec";

-- 2. Definição do caminho de busca para o novo Schema
SET search_path TO "Base de Dados Automec";

-- =============================================================================
-- GRUPO 1: ADMINISTRATIVO
-- =============================================================================

CREATE TABLE "Base de Dados Automec".papeis (
    id_papel SERIAL PRIMARY KEY,
    nome_papel VARCHAR(50) NOT NULL,
    descricao TEXT
);

CREATE TABLE "Base de Dados Automec".usuarios (
    id_usuario SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha_hash TEXT NOT NULL,
    ativo BOOLEAN DEFAULT TRUE,
    id_papel INT REFERENCES "Base de Dados Automec".papeis(id_papel),
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "Base de Dados Automec".unidades_empresa (
    id_unidade SERIAL PRIMARY KEY,
    nome_unidade VARCHAR(100) NOT NULL,
    cnpj VARCHAR(18) UNIQUE,
    email_alerta VARCHAR(100),
    cidade VARCHAR(100),
    estado CHAR(2)
);

CREATE TABLE "Base de Dados Automec".usuarios_unidade (
    id_usuario_unidade SERIAL PRIMARY KEY,
    id_usuario INT REFERENCES "Base de Dados Automec".usuarios(id_usuario),
    id_unidade INT REFERENCES "Base de Dados Automec".unidades_empresa(id_unidade)
);

-- =============================================================================
-- GRUPO 2: OPERACIONAL
-- =============================================================================

CREATE TABLE "Base de Dados Automec".itens (
    id_item SERIAL PRIMARY KEY,
    codigo_item VARCHAR(50) UNIQUE NOT NULL,
    descricao TEXT NOT NULL,
    categoria VARCHAR(50),
    marca VARCHAR(50),
    modelo VARCHAR(100),
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE "Base de Dados Automec".notas_fiscais (
    id_nf SERIAL PRIMARY KEY,
    numero_nf VARCHAR(20) NOT NULL,
    data_emissao DATE NOT NULL,
    xml_path TEXT,
    cnpj_cliente VARCHAR(18),
    valor_total DECIMAL(12,2)
);

-- =============================================================================
-- GRUPO 3: PROCESSO DE DEVOLUÇÃO
-- =============================================================================

CREATE TABLE "Base de Dados Automec".status (
    id_status SERIAL PRIMARY KEY,
    nome_status VARCHAR(50) NOT NULL,
    ordem_fluxo INT
);

CREATE TABLE "Base de Dados Automec".motivos (
    id_motivo SERIAL PRIMARY KEY,
    descricao VARCHAR(100) NOT NULL,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE "Base de Dados Automec".devolucoes (
    id_devolucao SERIAL PRIMARY KEY,
    id_nf INT REFERENCES "Base de Dados Automec".notas_fiscais(id_nf),
    id_vendedor INT REFERENCES "Base de Dados Automec".usuarios(id_usuario),
    id_unidade INT REFERENCES "Base de Dados Automec".unidades_empresa(id_unidade),
    data_abertura TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_fechamento TIMESTAMP,
    status_id INT REFERENCES "Base de Dados Automec".status(id_status),
    motivo_id INT REFERENCES "Base de Dados Automec".motivos(id_motivo),
    observacao TEXT
);

CREATE TABLE "Base de Dados Automec".devolucao_itens (
    id_dev_item SERIAL PRIMARY KEY,
    id_devolucao INT REFERENCES "Base de Dados Automec".devolucoes(id_devolucao),
    id_item INT REFERENCES "Base de Dados Automec".itens(id_item),
    quantidade INT NOT NULL,
    condicao VARCHAR(50),
    valor_item DECIMAL(12,2)
);

CREATE TABLE "Base de Dados Automec".historico_status (
    id_hist SERIAL PRIMARY KEY,
    id_devolucao INT REFERENCES "Base de Dados Automec".devolucoes(id_devolucao),
    status_id INT REFERENCES "Base de Dados Automec".status(id_status),
    usuario_id INT REFERENCES "Base de Dados Automec".usuarios(id_usuario),
    data_alteracao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observacao TEXT
);

-- =============================================================================
-- GRUPO 4: SISTEMA
-- =============================================================================

CREATE TABLE "Base de Dados Automec".sla_config (
    id_sla SERIAL PRIMARY KEY,
    dias_amarelo INT DEFAULT 3,
    dias_vermelho INT DEFAULT 5,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE "Base de Dados Automec".xml_importacao (
    id_import SERIAL PRIMARY KEY,
    arquivo_xml TEXT,
    data_import TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status_import VARCHAR(20),
    usuario_id INT REFERENCES "Base de Dados Automec".usuarios(id_usuario)
);

CREATE TABLE "Base de Dados Automec".evento_log (
    id_evento SERIAL PRIMARY KEY,
    tipo_evento VARCHAR(50),
    usuario_id INT REFERENCES "Base de Dados Automec".usuarios(id_usuario),
    data_evento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    descricao TEXT
);

-- =============================================================================
-- COMENTÁRIOS PARA O DICIONÁRIO DE DADOS (Documentação no Banco)
-- =============================================================================

COMMENT ON SCHEMA "Base de Dados Automec" IS 'Schema principal do sistema de devoluções da Automec Chevrolet';
COMMENT ON TABLE "Base de Dados Automec".devolucoes IS 'Registro central de processos de devolução';
COMMENT ON TABLE "Base de Dados Automec".sla_config IS 'Configurações de prazos para o semáforo do dashboard';