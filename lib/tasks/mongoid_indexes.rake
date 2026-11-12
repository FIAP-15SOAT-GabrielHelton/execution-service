# Usado no deploy para criar os índices declarados nos documentos.
task create_indexes: :environment do
  Persistence::Executions::ExecutionDocument.create_indexes
end
