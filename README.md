# Sistema de Logística Reversa de Peças

Projeto desenvolvido na disciplina **Projeto Integrador em Computação I**.

O objetivo do sistema é controlar o processo de devolução de peças automotivas, organizando informações que normalmente são registradas em planilhas ou processos manuais.

O sistema permite registrar devoluções, acompanhar o fluxo de status do processo, manter histórico das movimentações, registrar auditoria de alterações e gerar relatórios gerenciais para acompanhamento das devoluções.

---

# Tecnologias utilizadas

- PostgreSQL
- SQL
- PL/pgSQL
- Modelagem ER

---

# Estrutura do projeto


database/
01_schema → estrutura do banco de dados
02_seed → dados iniciais para demonstração
03_legacy_test_data → scripts antigos mantidos como referência
04_reports → consultas SQL para análise

docs/
documentação do projeto
fluxo do processo atual
descrição do sistema

diagramas/
diagrama entidade-relacionamento

dados_referencia/
planilhas base utilizadas no levantamento do sistema


---

# Estrutura do banco de dados

As principais entidades do sistema são:

- **usuarios** → usuários que operam o sistema
- **itens** → cadastro das peças
- **notas_fiscais** → notas fiscais de origem
- **devolucoes** → registro principal das devoluções
- **devolucao_itens** → itens envolvidos na devolução
- **status_devolucao** → estados do processo
- **status_transicoes** → regras do workflow
- **historico_status** → histórico das mudanças de status
- **logs_alteracao** → auditoria de alterações
- **evidencias** → arquivos anexados às devoluções

---

# Workflow do processo

O fluxo básico de status do processo é:


ABERTO
EM_ANALISE
AGUARDANDO_ENVIO
ENVIADO_FABRICA
ENCERRADO


As transições permitidas são controladas pela tabela **status_transicoes**.

Cada alteração gera um registro em **historico_status**.

---

# Relatórios

O sistema possui consultas SQL para análise do processo, incluindo:

- devoluções por status
- devoluções por motivo
- devoluções próximas do prazo
- histórico de movimentação
- painel consolidado de devoluções

A view principal do sistema é:


vw_painel_devolucoes


Ela consolida informações da devolução e calcula automaticamente o SLA.

---

# Como executar o projeto

1️⃣ Criar o banco PostgreSQL

2️⃣ Executar o script de estrutura:


schema_consolidado.sql


3️⃣ Inserir dados de demonstração:


seed.sql


4️⃣ Executar consultas de relatório:


relatorios.sql


---

# Resultado

O banco de dados desenvolvido permite controlar o processo de devolução de peças de forma estruturada, garantindo:

- rastreabilidade
- integridade das informações
- auditoria de alterações
- acompanhamento de prazos
- geração de relatórios gerenciais