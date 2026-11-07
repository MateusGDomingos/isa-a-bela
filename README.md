# Isa a Bela

App Expo (React Native + TypeScript) para finanças pessoais, tarefas e calendário, com backend Supabase. Roda no iPhone via Expo Go e também exporta para web.

## Versão do Expo SDK

Expo SDK 58. Pacote `expo` instalado: `58.0.23` (conforme `package.json`/`node_modules`). O binário da CLI local (`npx expo --version`) reporta `58.1.19` — essa é a versão interna da ferramenta de linha de comando, não a do SDK.

## Como rodar

1. Instale as dependências:

   ```bash
   npm install
   ```

2. Copie `.env.example` para `.env` e preencha as variáveis (veja a tabela abaixo).

3. Inicie o servidor de desenvolvimento:

   ```bash
   npm start
   ```

4. Leia o QR code exibido no terminal com o app **Expo Go** (iOS/Android) para abrir o projeto no celular.

## Como rodar os testes

```bash
npm test        # Jest com cobertura
npm run typecheck
npm run lint
```

## Variáveis de ambiente

Veja `.env.example`. Todas são públicas (prefixo `EXPO_PUBLIC_`) e ficam embutidas no bundle do app — nenhuma delas deve ser um segredo.

| Variável                            | Descrição                                            |
| ----------------------------------- | ---------------------------------------------------- |
| `EXPO_PUBLIC_SUPABASE_URL`          | endereço do projeto Supabase                         |
| `EXPO_PUBLIC_SUPABASE_KEY`          | chave pública (anon/publishable), protegida pela RLS |
| `EXPO_PUBLIC_SITE_URL`              | link da Vercel (retorno da confirmação de e-mail)    |
| `EXPO_PUBLIC_PRIVACY_CONTROLLER`    | nome do responsável, exibido na política             |
| `EXPO_PUBLIC_PRIVACY_CONTACT_EMAIL` | e-mail para pedidos de LGPD                          |

## Segredos (apenas em GitHub Secrets)

Estes valores nunca devem entrar no `.env`/`.env.example` nem no bundle do app. Ficam **somente** configurados como GitHub Secrets, para uso em CI/CD:

- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_DB_PASSWORD`
- `SUPABASE_PROJECT_REF`
- `VERCEL_TOKEN`
- `VERCEL_ORG_ID`
- `VERCEL_PROJECT_ID`
