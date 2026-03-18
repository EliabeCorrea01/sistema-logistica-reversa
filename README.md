Sistema de Logística Reversa de Peças

Projeto desenvolvido na disciplina Projeto Integrador em Computação I, com foco na modelagem e implementação de um banco de dados relacional em PostgreSQL para controle de devoluções de peças.

🎯 Objetivo

Modelar e implementar uma base de dados capaz de suportar o processo de logística reversa com:

controle de devoluções

rastreabilidade de etapas

auditoria de alterações

controle de prazos (SLA)

suporte à análise gerencial

🧠 Contexto e Evolução

O projeto evoluiu de um modelo conceitual bem estruturado para uma base com características de sistema real, incorporando regras de negócio diretamente no banco.

🔹 Base Inicial (Samuel)

A modelagem inicial foi desenvolvida pelo Samuel, com excelente qualidade conceitual, contemplando:

definição das entidades principais

estrutura inicial de devoluções

organização consistente dos dados

Essa base foi essencial para a evolução do projeto.

🔹 Evolução e Refinamento (Eliabe)

A partir dessa base, foram implementadas melhorias com foco em controle de processo, integridade de dados e segurança.

🏗️ Processo e Workflow

implementação de máquina de estados para controle de status

definição de transições válidas entre etapas

impedimento de saltos indevidos no fluxo

histórico completo de status (data + usuário)

🔐 Segurança e Integridade

validação de dados via domínios (CNPJ, e-mail)

controle de acesso baseado em papéis

bloqueio de usuários após tentativas inválidas

📊 Auditoria

event log para registro de eventos relevantes

logs automáticos com valores antes/depois

proteção contra alteração/exclusão dos registros

⏱️ SLA (Regras de Negócio)

implementação de regras de prazo no banco

classificação automática:

dentro do prazo

alerta

crítico

retorno direto nas consultas SQL

📈 Organização

separação por camadas:

schema

seed

reports

docs

estrutura preparada para integração com aplicações futuras

🗂️ Estrutura do Projeto

database/
├── 01_schema/
│  └── schema_consolidado.sql
│
├── 02_seed/
│  └── seed.sql
│
├── 03_reports/
│  └── relatorios.sql
│
└── legacy_modelos/
   ├── dados_teste_legacy.sql
   └── inserts_teste_legacy.sql

docs/
├── 00_estrutura_recomendada.docx
├── 01_descricao_projeto.docx
├── 02_quinzenas.docx
└── 03_fluxo_processo_atual.docx

diagramas/
└── diagrama_er.png

⚙️ Tecnologias

PostgreSQL

SQL

🚀 Execução

Criar o banco de dados no PostgreSQL

Executar o schema
database/01_schema/schema_consolidado.sql

Executar o seed
database/02_seed/seed.sql

Executar os relatórios
database/03_reports/relatorios.sql

📊 Funcionalidades

gestão de devoluções

controle de itens

workflow de status

auditoria de alterações

controle de SLA

relatórios gerenciais

📌 Considerações Técnicas

regras de negócio implementadas no banco (redução de dependência da aplicação)

foco em integridade e consistência dos dados

modelo preparado para escalabilidade e integração futura

👥 Autores

Samuel — modelagem conceitual inicial

Eliabe — evolução estrutural, segurança e regras de negócio
