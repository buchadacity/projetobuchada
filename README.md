# Campo — serviços e materiais da equipe

Site feito para abrir no Chrome do Android. O GitHub Pages publica o site; o Supabase guarda as notas, fotos e materiais em nuvem e valida o login. Os dois serviços têm funções diferentes.

## O que o site faz

- Registra as modalidades de serviço, data e hora editáveis, OS, tipo e número do medidor, leitura, foto, localização e observações.
- Permite pesquisar por dados das notas e materiais, editar notas salvas e excluir uma nota com confirmação.
- Salva a foto em armazenamento privado na nuvem e oferece o botão **Baixar foto** em cada nota.
- Mantém o estoque da viatura e calcula o que falta para a quantidade necessária.
- Exporta um backup JSON das notas, fotos e materiais.

## Configurar a conta única e o banco (uma vez)

Não é preciso programar. A configuração inicial é feita em páginas de configuração:

1. Crie uma conta no [Supabase](https://supabase.com/) e um projeto novo. Ele será o banco de dados e o espaço privado das fotos.
2. No painel do projeto, abra **SQL Editor → New query**. Abra o arquivo `supabase.sql` deste projeto, copie todo o conteúdo, cole na consulta e escolha **Run**. Isso cria as tabelas, as regras de acesso e o espaço privado para fotos.
3. No painel, abra **Authentication → Users → Add user** e crie o único usuário da equipe. Para o login curto `007`, use o email interno `007@equipe.local` e uma senha com pelo menos 6 caracteres. Marque o email como confirmado, se essa opção aparecer. Esse endereço é só um identificador do login; não recebe mensagens. A senha fica no serviço de autenticação, nunca nos arquivos do site. O Supabase recomenda senhas com pelo menos 8 caracteres; o PIN de quatro números informado não atende ao mínimo padrão.
4. No painel Supabase, abra **Project Settings → API** (ou **Data API**) e copie o **Project URL** e a **publishable key** (em projetos antigos, chamada `anon` key). No arquivo `config.js`, substitua `https://SEU-PROJETO.supabase.co` e `SUA_CHAVE_PUBLICA` pelos valores copiados. Não use uma `service_role` ou chave secreta nesse arquivo.
5. Se este site já tinha notas guardadas no mesmo aparelho, entre nele uma vez depois de configurar. O site tentará transferir os dados antigos locais para a conta e então salvará dali em diante na nuvem.

Usando o mesmo login nos aparelhos da equipe, todos acessam o mesmo conjunto de notas e materiais. Como haverá apenas uma conta compartilhada, qualquer pessoa com esse login poderá ver, alterar e excluir os dados.

## Publicar no GitHub Pages

1. Entre no GitHub e crie um repositório novo. Pode chamá-lo, por exemplo, `campo-equipe`.
2. Envie os arquivos deste projeto para o repositório, incluindo `config.js` já preenchido com a URL e a chave pública.
3. No repositório, abra **Settings → Pages**. Em **Build and deployment**, escolha **Deploy from a branch**, selecione `main` e a pasta `/(root)`, e salve.
4. Aguarde o endereço aparecer nessa página de configuração e abra-o no Chrome do Android.
5. Permita localização quando o Chrome perguntar. Para um atalho, abra o menu do Chrome e toque em **Adicionar à tela inicial**.

## Fotos e dados

As notas, os materiais e as fotos ficam online na conta Supabase da equipe. O botão de download na nota salva a foto para o celular. A exportação cria também um arquivo de backup com as fotos incluídas. O site precisa de internet para gravar e consultar o banco.

## Segurança

O login é validado pelo Supabase e as tabelas e fotos têm acesso restrito à conta autenticada. A chave pública no `config.js` é própria para uso no site e as regras do banco limitam o acesso. Nunca publique uma chave `service_role` ou senha nos arquivos.

Login de quatro números é fácil de adivinhar. Para dados de clientes, escolha uma senha mais longa e difícil de prever. O site aceita que a equipe digite `007` como login; por trás, o Supabase usa o endereço interno indicado acima.
