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

## Qualidade

Todo push na branch `main` e todo pull request disparam o workflow [`ci`](.github/workflows/ci.yml) (job `verificar`), que roda, nesta ordem:

1. **Lint e formatação** — `npm run lint` (ESLint + `prettier --check`); hoje em zero problemas (não só zero erros — zero warnings também).
2. **Checagem de tipos** — `npm run typecheck` (`tsc --noEmit`).
3. **Testes de unidade e componente** — `npm test`: 47 testes em 7 suítes (Jest + Testing Library).
4. **Supabase CLI** — instala a CLI usada pelos dois passos seguintes.
5. **Banco local e migrations** — `supabase start`, que sobe um Postgres local via Docker e aplica todas as migrations. É o passo mais lento do pipeline, por baixar as imagens do Supabase; isso é esperado.
6. **Testes de banco (pgTAP)** — `supabase test db supabase/tests/*-test.sql`: 94 asserções em 8 arquivos, cobrindo RLS, agregados, direitos de LGPD, modo visitante e métricas. O glob é explícito porque `supabase test db` sem argumento também tentaria rodar `helpers.sql` como teste — ele não tem `plan()` e falharia sem nenhum defeito no código.
7. **Auditoria de dependências** — `npm audit --audit-level=high`. Hoje não há vulnerabilidade alta ou crítica. Existem 31 vulnerabilidades moderadas/baixas em dependências transitivas de ferramentas de build (cadeia interna do Jest, `glob`, `minimatch`, `@typescript-eslint`) sem correção que não exija um salto de major breaking (ex.: Jest 29, Expo 52); nenhuma chega ao limiar `high`, então o passo não precisa de supressão.
8. **Segredo vazado** — `gitleaks` varre o diff por segredos commitados.

Qualquer passo vermelho bloqueia o merge — mas só se a branch `main` estiver protegida. Configure em GitHub: Settings → Branches → Branch protection rule para `main`, exigindo o status check `verificar` e bloqueando push direto (sempre exigir pull request antes de mesclar).

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

Estes valores nunca devem entrar no `.env`/`.env.example` nem no bundle do app. Ficam **somente** configurados como GitHub Secrets, para uso em CI/CD.

**Ainda não estão configurados**, e o `ci.yml` atual não usa nenhum deles: a lista existe porque o workflow de publicação (migrations em produção e deploy na Vercel) é de uma fase posterior do projeto. Hoje o pipeline só valida.

- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_DB_PASSWORD`
- `SUPABASE_PROJECT_REF`
- `VERCEL_TOKEN`
- `VERCEL_ORG_ID`
- `VERCEL_PROJECT_ID`
