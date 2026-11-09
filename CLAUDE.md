# MiraQuest App (Flutter)

App gamificado de questões para concursos de TI (lacuna/cloze, múltipla escolha, certo/errado) com XP, vidas e sequência de dias. API: `D:\Desenvolvimento\Projetos\miraquest.api` (Spring Boot).

## Estrutura (`lib/`)
- `main.dart` — tema Material 3 (cores fixas `_primary`/`_accent`, fonte Outfit via google_fonts).
- `models/` — `QuestaoModel`, `MateriaModel`, `UsuarioModel`, `VerificarRespostaModel` (todos com `fromJson` tolerante).
- `services/api_service.dart` — único ponto de acesso HTTP (`http`); base URL hoje constante `http://10.0.2.2:8080` (emulador Android).
- `services/session_store.dart` — `Sessao` + `SessionStore` (`SecureSessionStore` usa flutter_secure_storage; fakes nos testes).
- `screens/` — `login_screen` (entrar/criar conta), `home_screen` (progresso, sair, lista de matérias vinda de `GET /api/materias`), `licao_screen` (5 questões).
- `main.dart` também tem o `AuthGate`: lê a sessão, mostra login ou home, trata logout.

## Regras importantes
- A API **não envia a resposta correta**. O app usa `QuestaoModel.opcoes` (já embaralhada pela API) e só descobre acerto/erro via `ApiService.verificarResposta`.
- CERTO_ERRADO tem botões fixos na UI (`opcoes` vem vazia).
- Login por e-mail/senha; `ApiService.token` vai em `Authorization: Bearer`. HTTP 401 → `NaoAutorizadoException` → a home faz logout. `usuarioId` vem da sessão.
- No Windows, plugins nativos exigem Developer Mode ligado para `flutter run`/build.

## Convenções
- Dart/Flutter padrão (`flutter_lints`), `ApiService` injetável nas telas para testes com fake.
- Textos de UI em português.

## Comandos
- `flutter analyze` · `flutter test` · `flutter run`

## Backlog
URL da API por configuração (`--dart-define`), paleta "Pôr do sol".
