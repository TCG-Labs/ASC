# Всестороннее ревью проекта ASC (Alamofire Swift Client)

**Дата:** 2026-04-06
**Ревьюер:** Claude Code (Opus 4.6)

---

## Использованные инструменты

| Инструмент | Что проверено |
|---|---|
| **Read** (18 файлов) | Все 16 source-файлов + Package.swift + release.yml |
| **Grep/Glob** | `@_exported`, `import Synchronization`, паттерны кода |
| **Bash (git)** | История коммитов, contributors, удалённые файлы, LOC |
| **GitHub MCP** | Issues, PRs (10), Releases, Tags, Branches |
| **Context7 Docs MCP** | Актуальные доки Alamofire и JWTDecode.swift |
| **GitHub Secret Scanning MCP** | Сканирование 15 файлов на секреты (GHAS не включен — ручной аудит) |
| **WebSearch** (Agent) | Актуальные версии зависимостей, CVE/advisory |
| **Agent (Explore)** x3 | Security audit, code quality metrics, file reads |
| **SwiftLint config analysis** | Анализ .swiftlint.yml (332 строки) |
| **CI/CD workflows** | release.yml, claude.yml, claude-code-review.yml |

---

## 1. Метрики проекта

| Метрика | Значение |
|---|---|
| Исходный код (Sources/) | **4,423 LOC** в 16 файлах |
| Тесты | **0 тестов** (Tests.swift пустой) |
| Покрытие | **0%** |
| Contributors | 5 (Mykyta Omelchenko — 51 commits, Nikita — 11, Vyacheslav — 9) |
| Коммитов | ~50 |
| Pull Requests | 10 (все closed/merged) |
| Open Issues | 0 |
| Releases/Tags | **0** (ни одного релиза!) |
| Branches | 3 (main, develop, refactor/interceptors-api) |
| Зависимости | 2 (Alamofire >= 5.10.2, JWTDecode 3.3.0 exact) |
| Min deployment | iOS 18.0 / macOS 15.0 |
| Swift tools | 6.2 |

---

## 2. Критические проблемы (P0)

### 2.1. Нулевое тестовое покрытие

Файл `Tests/ASCTests/Tests.swift` содержит только лицензию и import. **Ни одного теста.** Для сетевой библиотеки это критично — любой рефакторинг может сломать API без обнаружения.

PR #8 ("Improves test coverage and quality") был мержнут, но тесты оттуда были **удалены** в последующих коммитах (видно по `git log --diff-filter=D`). Тесты, mock-инфраструктура, `MockURLProtocol`, `MockTokenStorage` — всё потеряно.

**Рекомендация:** Написать unit-тесты для `RequestBuilder`, `ErrorMapper`, `JSONMessageExtractor`, `OAuthCredential`, `AuthInterceptor`.

### 2.2. Бесконечный цикл refresh при невалидном JWT

**Файл:** `Sources/ASC/Auth/OAuthAuthenticator.swift:38-40`

```swift
case .bearer(let token):
    expirationDate(token: token) ?? .now  // <- fallback на .now
```

Если JWT некорректный, `expiration = .now`, и `requiresRefresh` всегда `true` (т.к. `Date(timeIntervalSinceNow: 60 * 14) > .now`). Alamofire's `AuthenticationInterceptor` будет вызывать `refresh()` -> получать новый (тоже невалидный) токен -> снова refresh -> **бесконечный цикл**.

**Рекомендация:** Возвращать `nil` вместо `.now`, или добавить защиту от бесконечного refresh (counter / backoff).

### 2.3. Download-методы не маппят ошибки

**Файл:** `Sources/ASC/Client/NetworkClient.swift:148-205`

Оба метода `download(from:...)` и `download(_:to:...)` бросают сырые ошибки Alamofire, минуя `ErrorMapper`. Потребители получат `AFError` вместо `ASCError`, что нарушает контракт библиотеки.

**Рекомендация:** Обернуть ошибки в `handleResponse` или отдельный try/catch с `errorMapper.mapError`.

### 2.4. Ни одного релиза

0 тегов, 0 releases. Библиотеку невозможно подключить через SPM по версии. `release.yml` workflow настроен, но **ни разу не использовался**. Порог покрытия в release.yml: `< 5.0%` (строка 78), а комментарий рядом говорит `below 70% threshold` — **мёртвая защита**.

**Рекомендация:** Создать первый release (v0.1.0 или v1.0.0), исправить порог покрытия.

---

## 3. Безопасность

### 3.1. GitHub Secret Scanning

Запущено сканирование 15 ключевых файлов (auth, config, CI workflows, examples). GitHub Advanced Security **не включен** на репозитории — автоматическое сканирование невозможно. Ручной аудит: **чисто**.

### 3.2. Аудит безопасности (ручной)

| Проверка | Результат |
|---|---|
| Хардкоженные credentials в библиотеке | **Чисто** |
| Credentials в примерах | `example@mail.com` / `Qwerty123` в Example app (допустимо для demo) |
| HTTP URLs (без TLS) | **Чисто** — только HTTPS |
| Force unwraps | **0** в library code |
| SSL bypass | Нет — `ServerTrustManager` опционален, по умолчанию стандартная валидация |
| Логирование секретов | `privacy: .private` на всех логах + редакция `Authorization`, `Cookie`, `api-key` headers |
| .gitignore secrets | Комплексные паттерны (.env, credentials, *.p12, *secret*) |
| CI secrets | Корректно — через `${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}` |

### 3.3. Проблема: `privacy: .private` скрывает ВСЕ логи в Release

**Файл:** `Sources/ASC/EventMonitors/LoggingMonitor.swift:126,151,190,235,398`

Все данные логгера маркированы `privacy: .private`. В Release builds **все** значения заменяются на `<private>`, включая URL и status code. Это делает production-логирование **полностью бесполезным**.

**Рекомендация:** URL и status code — `.public`, headers и body — `.private`.

### 3.4. Рекомендация: включить GHAS

Включить GitHub Advanced Security в настройках репозитория для автоматического сканирования секретов на каждый push/PR. Для public-репозиториев — бесплатно.

---

## 4. Зависимости

### 4.1. Alamofire

| | Текущая | Последняя |
|---|---|---|
| Версия | >= 5.10.2, < 5.11.0 (`.upToNextMinor`) | **5.11.1** |
| CVE | Нет известных |
| Swift 6 | Полная поддержка |

**Проблема:** `.upToNextMinor(from: "5.10.2")` **блокирует** обновление до 5.11.x. Это чрезмерно строгое ограничение для library consumer.

**Рекомендация:** Изменить на `.upToNextMajor(from: "5.10.2")` для получения 5.11+.

### 4.2. JWTDecode.swift

| | Текущая | Последняя |
|---|---|---|
| Версия | **3.3.0 exact** | **4.0.0** |
| CVE | Нет известных |
| Что нового в 4.0 | **Полная Sendable conformance** |

**Проблема:** Exact pin `3.3.0` запрещает любое обновление. Версия 4.0.0 добавляет полную `Sendable` совместимость — это критично для проекта с strict concurrency (Swift 6.2).

**Рекомендация:** Обновить до `4.0.0` (`.upToNextMajor(from: "4.0.0")`).

---

## 5. Проблемы архитектуры и кода

### 5.1. Race condition в `NetworkReachability`

**Файл:** `Sources/ASC/Utils/NetworkReachability.swift:53`

`@unchecked Sendable` с мутабельным `var cancellables = Set<AnyCancellable>()` без синхронизации. `stopMonitoring()` (вызываемый из `deinit`) мутирует `cancellables`, а `setupMonitor` callback работает на `queue`.

`import Synchronization` уже есть в `LoggingMonitor.swift`, но **не используется** — видимо планировался, но забыт.

**Рекомендация:** Использовать `Mutex` (из `Synchronization`) или `NSLock` для защиты `cancellables`.

### 5.2. `DateFormatter` не thread-safe в `LoggingMonitor`

**Файл:** `Sources/ASC/EventMonitors/LoggingMonitor.swift:75-79`

`DateFormatter` не thread-safe по документации Apple. Хотя доступ идёт через shared queue, это хрупко.

**Рекомендация:** Заменить на `Date.FormatStyle` (iOS 15+) или `ISO8601DateFormatter` (thread-safe).

### 5.3. `Endpoint.parameterEncoder` — phantom property

**Файл:** `Sources/ASC/Core/Endpoint.swift:258`

`parameterEncoder` объявлен **только в extension**, но не в протоколе. Swift dispatch: если потребитель переопределит это свойство в своём struct, оно **не будет вызвано** при доступе через `any Endpoint` (статическая dispatch). `RequestBuilder` использует `request.parameterEncoder`, но если endpoint typed как protocol — будет всегда `nil`.

**Рекомендация:** Добавить `var parameterEncoder: ParameterEncoder? { get }` в протокол `Endpoint`.

### 5.4. `headers.add` не переопределяет defaults

**Файл:** `Sources/ASC/Core/RequestBuilder.swift:162`

`headers.add(header)` в Alamofire **добавляет** дубликат, не перезаписывает. Если endpoint хочет переопределить default header (например, custom `Content-Type`) — получит два заголовка.

**Рекомендация:** Заменить `headers.add(header)` на `headers.update(header)`.

### 5.5. `ErrorMapper.mapError` возвращает `any Error`

**Файл:** `Sources/ASC/Client/ErrorMapper.swift:57`

Для `explicitlyCancelled` возвращает `CancellationError()` вместо `ASCError.cancelled`. Потребитель с `catch let error as ASCError` не поймает отмену. Несогласованный API.

**Рекомендация:** Заменить `CancellationError()` на `ASCError.cancelled`.

### 5.6. Shared static queues между клиентами

**Файл:** `Sources/ASC/Client/NetworkClientConfiguration.swift:132-145`

`NetworkClientConfigurationDefaults` — все `NetworkClient` instances делят одни `rootQueue`, `requestQueue`, `serializationQueue`. Запросы из разных клиентов сериализуются неожиданно.

**Рекомендация:** Создавать per-instance queues в defaults (factory methods вместо static let).

### 5.7. `TokenStorage` default implementation — тихий nil

**Файл:** `Sources/ASC/Auth/TokenStorage.swift:41-44`

```swift
public extension TokenStorage {
    var authToken: AuthToken? { nil }
}
```

Если потребитель забудет реализовать `authToken`, код скомпилируется, но `AuthInterceptor.adapt` будет **всегда** бросать `.invalidToken`.

**Рекомендация:** Убрать default implementation, сделать `authToken` required.

### 5.8. `OAuthTokenStorage.executeRefreshToken()` default — no-op

**Файл:** `Sources/ASC/Auth/TokenStorage.swift:64`

```swift
public func executeRefreshToken() async throws { }
```

Если потребитель забудет реализовать refresh, токен никогда не обновится, но ошибки не будет — тихая деградация.

---

## 6. Документация

### 6.1. CLAUDE.md vs реальный код — расхождения

| Утверждение в CLAUDE.md | Реальность |
|---|---|
| `@_exported import Alamofire` в Typealiases.swift | **Неверно** — используется обычный `import Alamofire` |
| Coverage threshold 70% | Реально `< 5.0%` в release.yml |
| `debugPrint` в `OAuthCredential.expirationDate` | Реально `log.debug()` — не `debugPrint` |

### 6.2. Doc-comment vs код

**Файл:** `Sources/ASC/Auth/OAuthAuthenticator.swift:48`

Комментарий говорит "Require refresh if within 5 minutes of expiration", код использует 14 минут.

### 6.3. Отсутствие MIT header

`Sources/ASC/Extensions/Data+Extension.swift` и `Sources/ASC/Utils/Typealiases.swift` — нет MIT license header (Xcode-style header вместо MIT). Скрипт `scripts/add_license_headers.sh` существует, но не был применён к этим файлам.

---

## 7. CI/CD

### 7.1. `release.yml` — мёртвая валидация

**Файл:** `.github/workflows/release.yml:78`

```yaml
if (( $(echo "$COVERAGE < 5.0" | bc -l) )); then
    echo "Cannot release with coverage below 70% threshold"
```

Порог **5%** (de facto любой код пройдёт), комментарий обещает **70%**. При текущих 0 тестах — не сработает даже 5% threshold.

### 7.2. `release.yml` — `working-directory: ASC`

**Файл:** `.github/workflows/release.yml:14`

`working-directory: ASC` предполагает, что репозиторий checkout'ится в подпапку `ASC`. Но `actions/checkout@v4` по умолчанию клонирует в root. **Build сломается** если не настроен custom path.

### 7.3. Ветки не защищены

`main` и `develop` — `protected: false`. Прямые push'ы возможны без PR review.

---

## 8. Качество кода

| Метрика | Результат |
|---|---|
| TODO/FIXME/HACK | **0** |
| Force cast/try/unwrap | **0** в library |
| `@unchecked Sendable` | 4 (все обоснованы Alamofire API) |
| Закомментированный код | 1 большой блок (58 строк `executeWithProgress`) + 2 строки в OAuth |
| `print()`/`debugPrint()` в library | **0** (только в doc-comments) |
| Unused imports | `import Synchronization` в LoggingMonitor.swift:28 |
| Dead code | `UploadProgress` / `UploadProgressOrResponse` — public types, используются только в закомментированном коде |
| SwiftLint config | **Отличный** (59 opt-in rules, 6 custom rules, строгие лимиты) |

### Lines of Code по файлам

| Файл | LOC |
|---|---|
| Client/NetworkClient.swift | 605 |
| EventMonitors/LoggingMonitor.swift | 581 |
| Client/NetworkClientConfiguration.swift | 537 |
| Utils/NetworkReachability.swift | 338 |
| Core/Endpoint.swift | 306 |
| Core/ASCError.swift | 292 |
| Core/RequestBuilder.swift | 243 |
| Core/HTTPResponseType.swift | 221 |
| EventMonitors/NetworkResponseMonitor.swift | 199 |
| Auth/OAuthAuthenticator.swift | 196 |
| Client/ErrorMapper.swift | 159 |
| Core/UploadData.swift | 111 |
| Core/HTTPStatus.swift | 99 |
| Extensions/RetryPolicy+Extension.swift | 98 |
| Core/JSONMessageExtractor.swift | 91 |
| Auth/AuthInterceptor.swift | 84 |
| Auth/AuthToken.swift | 69 |
| Auth/TokenStorage.swift | 65 |
| Extensions/HTTPURLResponse+Extension.swift | 48 |
| Utils/Typealiases.swift | 43 |
| Extensions/Data+Extension.swift | 38 |
| **Итого** | **4,423** |

---

## 9. Сравнение с Alamofire best practices (по документации)

| Практика Alamofire | ASC | Статус |
|---|---|---|
| `OAuthAuthenticator` pattern | Реализован по шаблону из docs | OK |
| `didRequest(_:failDueToAuthenticationError:)` returns false | Соответствует "server CANNOT invalidate" | OK |
| `isRequest(_:authenticatedWith:)` returns true | Соответствует шаблону | OK |
| `RetryPolicy` exponential backoff | Корректные presets | OK |
| `Session` с interceptors | `Interceptor(interceptors:)` | OK |
| Upload progress tracking | Закомментирован, но паттерн соответствует docs | Partial |
| `EventMonitor.queue` property | Используется shared queue | OK |

---

## 10. Замечания мелкого приоритета

| Файл | Строка | Замечание |
|---|---|---|
| `OAuthAuthenticator.swift` | 42-43 | Unused variables: `basic(let username, let password)` и `custom(let token)` — можно `case .basic, .custom:` |
| `NetworkClient.swift` | 349 | `dataRequest.task?.priority` — task может быть nil на этом этапе (Alamofire создаёт task позже) |
| `NetworkClient.swift` | 161, 190 | Аналогично для download requests — priority не применится |
| `LoggingMonitor.swift` | 30 | Глобальный `let log` — потенциальный конфликт имён при import |
| `ErrorMapper.swift` | 107-109 | Non-status-code validation failure маппится в generic `.validationFailed` — теряется контекст |
| `JSONMessageExtractor.swift` | 54-89 | Рекурсивный обход JSON без ограничения глубины |
| `NetworkResponseMonitor.swift` | 182 | `[weak self]` на final class — бессмысленный overhead |
| `Data+Extension.swift` | 33 | `catch let error` — `error` не используется, заменить на `catch` |

---

## 11. Рекомендации по приоритетам

### P0 — Критично (блокирует production)

| # | Что | Файл |
|---|---|---|
| 1 | Написать unit-тесты (RequestBuilder, ErrorMapper, JSONMessageExtractor, OAuthCredential) | Tests/ |
| 2 | Исправить бесконечный refresh при невалидном JWT | OAuthAuthenticator.swift:38 |
| 3 | Добавить ErrorMapper в download-методы | NetworkClient.swift:148-205 |
| 4 | Создать первый release/tag | GitHub |

### P1 — Важно

| # | Что | Файл |
|---|---|---|
| 5 | Исправить race condition в NetworkReachability | NetworkReachability.swift:99 |
| 6 | Добавить `parameterEncoder` в протокол Endpoint | Endpoint.swift |
| 7 | `headers.add` -> `headers.update` | RequestBuilder.swift:162 |
| 8 | `CancellationError()` -> `ASCError.cancelled` | ErrorMapper.swift:59 |
| 9 | Обновить JWTDecode.swift 3.3.0 -> 4.0.0 | Package.swift |
| 10 | Alamofire `.upToNextMinor` -> `.upToNextMajor` | Package.swift:19 |
| 11 | Обновить doc-comment requiresRefresh (5 min -> 14 min) | OAuthAuthenticator.swift:48 |
| 12 | Защитить main/develop branches | GitHub settings |

### P2 — Улучшения

| # | Что | Файл |
|---|---|---|
| 13 | Исправить `privacy: .private` -> разграничить public/private | LoggingMonitor.swift |
| 14 | Заменить DateFormatter на Date.FormatStyle | LoggingMonitor.swift:75 |
| 15 | Удалить `import Synchronization` (unused) | LoggingMonitor.swift:28 |
| 16 | Добавить MIT headers в Data+Extension.swift, Typealiases.swift | Extensions/, Utils/ |
| 17 | Исправить release.yml: coverage threshold и working-directory | .github/workflows/ |
| 18 | Создать per-instance queues вместо shared static | NetworkClientConfigurationDefaults |
| 19 | Удалить dead code: `UploadProgress`, `UploadProgressOrResponse` или раскомментировать `executeWithProgress` | NetworkClient.swift |
| 20 | Исправить CLAUDE.md: убрать ложное `@_exported import` | Utils/CLAUDE.md |
| 21 | Ввести `NetworkClientProtocol` для тестируемости потребителей | Client/ |
| 22 | Включить GitHub Advanced Security для secret scanning | GitHub settings |

---

## 12. Общая оценка

| Категория | Оценка | Комментарий |
|---|---|---|
| **Архитектура** | 8/10 | Чистый, продуманный дизайн. Endpoint protocol отличный. |
| **Качество кода** | 7/10 | 0 force unwraps, строгий lint, но есть race conditions и API-баги |
| **Тестирование** | 1/10 | 0 тестов, 0% покрытия |
| **Безопасность** | 8/10 | Хорошие практики, но privacy .private убивает prod logging |
| **Документация** | 6/10 | Хорошие doc-comments, но CLAUDE.md расходится с кодом |
| **CI/CD** | 4/10 | Workflows есть, но сломаны и не используются, 0 releases |
| **Зависимости** | 6/10 | Устаревший JWTDecode pin, слишком строгий Alamofire pin |
| **Production readiness** | 4/10 | Блокировано отсутствием тестов и нерелизнутой версией |

### Итоговая оценка: 5.5/10

Хороший фундамент с серьёзными пробелами в тестировании, release management и нескольких runtime-багах. Архитектура и код-стиль выше среднего, но библиотека не готова к production без тестов и первого релиза.
