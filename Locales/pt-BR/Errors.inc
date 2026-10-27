{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{  Portuguese (Brazil) error messages.                          }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2007 Devrace Ltd.                       }
{    Written by Serge Buzadzhy                                  }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

  FIBErrorMessages: array[TFIBClientError] of string = (
    'Erro desconhecido.',
    'Recurso não suportado.',
    'Não permitido.',
    'Erro de acesso ao arquivo temporário.',
    'Tempo limite da conexão com o banco de dados esgotado.',
    'Não é possível definir o banco de dados.',
    'Não é possível definir a transação.',
    'Operação cancelada a pedido do usuário.',
    'A constante DPB (isc_dpb_%s) não é suportada.',
    'A constante DPB (%s) é desconhecida.',
    'A constante TPB (isc_tpb_%s) não é suportada.',
    'A constante TPB (%s) é desconhecida.',
    '%s: Não é possível executar a operação -- o banco de dados não está aberto.',
    'Não é possível executar a operação -- o banco de dados está aberto.',
    'O nome do banco de dados não foi informado.',
    '%s: A transação não está ativa.',
    '%s: A transação está ativa.',
    'Os valores de Timeout não podem ser negativos.',
    '%s: Nenhum banco de dados está listado no componente de transação.',
    '%s: Atualização no banco de dados errado.',
    '%s: Atualização na transação errada.',
    'Banco de dados não atribuído para %s.',
    'Transação não atribuída para %s.',
    'Índice XSQLDA fora do intervalo.',
    'O nome XSQLDA não existe (%s).',
    'Fim do arquivo.',
    'Início do arquivo.',
    '%s: Handle de comando inválido.',
    'Não é possível %s porque o dataset %s está aberto.',
    'Não é possível %s porque o dataset %s está fechado.',
    'Tipo de dados SQL desconhecido (%d).',
    'Índice de coluna inválido (o índice excede o intervalo permitido).',
    'Índice de parâmetro inválido (o índice excede o intervalo permitido).',
    'Conversão de dados inválida.',
    'A coluna não pode receber null (%s)',
    'Não é possível ler o stream Blob.',
    'Não é possível gravar no stream Blob.',
    'Não é possível %s porque a consulta está vazia.',
    'Não é possível executar "open" em um comando que não é SELECT. Use ExecQuery.',
    'Sem acesso ao campo "%s".',
    'O campo "%s" é somente leitura.',
    'Campo "%s" não encontrado.',
    'O dataset não está no modo Edit ou Insert. (%s)',
    'Não está em edição.',
    'Não é possível inserir no dataset. (%s)',
    'Não é possível gravar (post). (%s)',
    'Não é possível atualizar (update). (%s)',
    'Não é possível excluir do dataset. (%s)',
    'Não é possível atualizar o registro (refresh). (%s)',
    'Buffer não definido.',
    'Referências circulares não são permitidas. (%s)',
    'Erro de análise SQL em '+':%s ' + CRLF + CRLF + '%s',
    'Cancelado pelo usuário.',
    'O dataset é unidirecional.',
    'Não é possível criar o recurso compartilhado. (erro do Windows %d)',
    'Erro da API do Windows. (erro do Windows %d [$%.8x])',
    'As listas de colunas não correspondem.',
    'Os tipos das colunas não correspondem. (Do índice: %d, para o índice: %d)',
    'Uma transação compartilhada só pode ser finalizada de forma forçada e com uma ação igual ao seu TimeoutAction.',
    'A coluna "%s" não é um campo array', // feNotIsArrayField
    'A dimensão %d não existe em "%s"', // feWrongDimension
    'Dialeto SQL inválido', // feSQLDialectInvalid
    'Biblioteca cliente do Firebird não encontrada. Instale o cliente do Firebird para usar esta funcionalidade', // feIBMissing
    '%s é uma função do InterBase 6. Atualize para o InterBase 6 para usar esta funcionalidade',
    'Não é possível executar a operação -- o serviço não está conectado',
    'Não é possível executar a operação -- o serviço está conectado',
    'O nome do servidor não foi informado',
    'Parâmetros de consulta ausentes ou incorretos',
    'Parâmetros de inicialização ausentes ou incorretos',
    'Valor inesperado no buffer de saída',
    'ServiceStart genérico não se aplica: use os procedimentos específicos para definir os parâmetros de configuração',
    'Constante SPB não suportada',
    'Constante SPB desconhecida',
    'Tamanho do campo muito pequeno. Campo %s.%s',
    '%s. Não é possível usar o cache limitado. '#13#10 +
      'CachedUpdates deve ser False,'#13#10 +
      'O Select deve ter a cláusula "Order by",'#13#10 +
      'Todos os campos de ordenação devem existir na seção de campos'#13#10 +
      'O Select não pode usar parâmetros com o prefixo "NEW_"'#13#10 +
      'UpdateTransaction deve ser igual a Transaction ou AutoCommit=True',
    'Erro em %s. FieldList está vazio.',
    '%s não pode usar o campo "%s"',
    '%s é uma função do Firebird 2. Atualize para o Firebird 2 para usar esta funcionalidade',
    '%s não é suportado pelo %s',
    '%s não é suportado pela biblioteca cliente %s',
    'Coluna array %s.%s não encontrada',
    'Array %s.%s: o nome %s é muito longo',
    'O array %s.%s tem %d dimensão(ões), foram informados %d índice(s)',
    'Array %s.%s: não é possível converter "%s" para o tipo dos elementos',
    'Array %s.%s: o tipo de elemento %d não é suportado',
    'Array %s.%s: a string "%s" tem mais de %d bytes',
    'Array %s.%s: o valor não é um array',
    'O array %s.%s tem %d dimensão(ões), o valor tem %d',
    'Array %s.%s: o valor tem %d bytes em vez de %d',
    'Array %s.%s: o índice %d está fora dos limites %d:%d da dimensão %d',
    'Array %s.%s: os limites %d:%d da dimensão %d não cabem em TISC_ARRAY_BOUND',
    'Array %s.%s: a dimensão %d tem %d elemento(s), o valor tem %d',
    'O parâmetro %s não é um array',
    'A página de código %d não está disponível neste sistema',
    'Não é possível converter o caractere entre conjuntos de caracteres: "%s" para a página de código %d',
    '%s: Não foi possível encontrar ou analisar a cláusula ORDER BY.',
    '%s.' + CRLF + 'O campo %s é usado na ordenação, mas não está nos campos do SelectSQL',
    '%s: Não é possível carregar os metadados.',
    'O valor de %s tem %d bytes, o máximo é %d'
  );
