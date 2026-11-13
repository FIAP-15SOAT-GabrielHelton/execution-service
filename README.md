# Execution Service — 15SOAT - Fase 4 - Tech Challenge - Grupo 161

Microsserviço de **execução** da Oficina Mecânica. Mantém a fila das Ordens de Serviço aprovadas e registra o andamento do trabalho: início, cada serviço executado, conclusão ou falha.

Faz parte de um conjunto de três microsserviços coordenados por uma Saga coreografada. A visão geral — arquitetura, diagrama e todos os repositórios — está no README do [`os-service`](https://github.com/FIAP-15SOAT-GabrielHelton/os-service#arquitetura).

## Responsabilidade

- Coloca a OS na fila de execução ao receber o evento `work_order.approved`.
- Expõe a fila e o andamento para os funcionários (`/api/v1/executions`).
- Avisa os outros serviços quando a execução começa, termina ou falha.

**Banco próprio:** MongoDB (o banco NoSQL do projeto). Cada execução é um documento por OS, com os serviços embutidos — o dado é lido e gravado sempre inteiro, sem joins, o que casa com o modelo de documentos. Nenhum outro serviço acessa este banco.

## Papel na Saga

A Saga é **coreografada**: cada serviço reage a eventos e publica os seus, sem orquestrador central. A justificativa e o diagrama completo estão no [README do `os-service`](https://github.com/FIAP-15SOAT-GabrielHelton/os-service#saga) e na [RFC-005](https://github.com/FIAP-15SOAT-GabrielHelton/os-service/blob/main/docs/fase4/RFC-005-microsservicos-e-saga.md).

| Consome | Reação |
| :--- | :--- |
| `work_order.approved` | Cria a execução na fila, com os serviços da OS |

| Publica | Quando | Efeito nos outros serviços |
| :--- | :--- | :--- |
| `execution.started` | A execução é iniciada | OS em execução |
| `execution.completed` | Todos os serviços foram finalizados | OS aguardando pagamento; o Billing cria a cobrança |
| `execution.failed` | A execução é marcada como falha | **Dispara a compensação:** o OS Service cancela a OS e devolve as peças ao estoque, e o Billing cancela o orçamento |

Status da execução: `queued → in_progress → completed`, com a saída `failed`.

## Endpoints

| Método | Caminho | O que faz |
| :--- | :--- | :--- |
| GET | `/api/v1/executions?status=queued` | Fila de execução, mais antigas primeiro |
| GET | `/api/v1/executions/:work_order_id` | Detalhe de uma execução |
| PATCH | `/api/v1/executions/:work_order_id/start` | Inicia a execução |
| PATCH | `/api/v1/executions/:work_order_id/items/:line_item_id/start` | Inicia um serviço |
| PATCH | `/api/v1/executions/:work_order_id/items/:line_item_id/finish` | Finaliza um serviço |
| PATCH | `/api/v1/executions/:work_order_id/complete` | Conclui (exige todos os serviços finalizados) |
| PATCH | `/api/v1/executions/:work_order_id/fail` | Marca como falha (`reason` obrigatório) |

Todas exigem o JWT de um funcionário — o mesmo token emitido pelo OS Service.

## Execução local

```bash
cp .env.example .env
docker compose up
```

A API sobe em `http://localhost:3002`. O serviço `consumer` (`bin/consumer`) é o processo que escuta os eventos da Saga.

## Documentação da API

- Swagger UI: `http://localhost:3002/api-docs`.
- Spec OpenAPI versionada: [`swagger/v1/swagger.json`](swagger/v1/swagger.json).

## Testes e qualidade

```bash
docker compose run --rm -e RAILS_ENV=test -e COVERAGE=1 \
  -e MONGODB_URI=mongodb://mongo:27017/execution_service_test web bundle exec rspec
```

- RSpec com cobertura mínima de 80% exigida pelo SimpleCov (hoje acima de 95%).
- O fluxo completo em BDD, que atravessa os três serviços, fica no [`os-service`](https://github.com/FIAP-15SOAT-GabrielHelton/os-service/blob/main/spec/features/fluxo_da_ordem_de_servico.feature).
- SonarQube Cloud: [painel do projeto](https://sonarcloud.io/project/overview?id=FIAP-15SOAT-GabrielHelton_execution-service), com quality gate no CI.

## CI/CD

- **CI** ([`ci.yml`](.github/workflows/ci.yml)): a cada PR, roda RuboCop, os testes e a análise do SonarQube. A `main` é protegida: só recebe código por PR com `lint` e `test` verdes.
- **CD** ([`cd_deploy.yml`](.github/workflows/cd_deploy.yml)): publica a imagem e implanta no EKS — `web`, `consumer`, Service e HPA (manifests em [`k8s/`](k8s/)). Não há migrations, porque o MongoDB não tem schema. O disparo é manual, pelas credenciais temporárias da AWS Academy, normalmente via [`deploy-orchestrator-fase4`](https://github.com/FIAP-15SOAT-GabrielHelton/deploy-orchestrator-fase4).

## Observabilidade

New Relic (APM com rastreamento distribuído), configurado em [`config/newrelic.yml`](config/newrelic.yml).

## Limitações conhecidas

- O MongoDB roda no cluster sem volume persistente e sem autenticação, acessível só de dentro do cluster. Serve ao ambiente efêmero da AWS Academy; fora dele, o caminho é um StatefulSet com volume e usuário, ou o DocumentDB.
- A publicação de eventos é best-effort: se o RabbitMQ estiver fora no momento, o evento se perde. O próximo passo seria um transactional outbox.
