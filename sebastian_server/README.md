# Sebastian Server

Sebastian AI Assistant의 **백엔드 API**입니다. [NestJS](https://nestjs.com/) 11 기반이며, SQLite(TypeORM)와 JWT 인증, Swagger 문서를 사용합니다.

## 요구 사항

- **Node.js** 22.x 권장 (`package.json`의 `@types/node`와 맞춤)
- **npm** 10.x (Node 22에 포함)

터미널에서 `npm`을 찾을 수 없다면 [nvm](https://github.com/nvm-sh/nvm) 등으로 Node를 설치한 뒤, 새 터미널을 열거나 `source ~/.zshrc`로 셸 설정을 다시 불러오세요.

## 설치

저장소 루트가 아니라 **이 디렉터리(`sebastian_server`)**에서 실행합니다.

```bash
cd sebastian_server
npm ci
```

`package-lock.json`이 없거나 잠금 파일을 쓰지 않을 때만 `npm install`을 사용하면 됩니다.

## 실행

```bash
# 개발 (파일 변경 시 자동 재시작)
npm run start:dev

# 일반 시작
npm run start

# 프로덕션 (먼저 빌드 필요)
npm run build
npm run start:prod
```

기본적으로 **HTTP 포트 3000**에서 수신합니다. (`src/main.ts`)

## API 문서 (Swagger)

서버 실행 후 브라우저에서 다음 주소를 엽니다.

- **Swagger UI:** [http://localhost:3000/api](http://localhost:3000/api)

문서 제목·설명은 `src/main.ts`의 `DocumentBuilder` 설정을 따릅니다.

## 주요 엔드포인트

| 메서드 | 경로 | 설명 |
|--------|------|------|
| `POST` | `/users/signup` | 회원가입 |
| `GET` | `/users` | 사용자 목록 |
| `GET` | `/users/me` | 로그인 사용자 정보 (Bearer JWT 필요) |
| `POST` | `/auth/login` | 로그인 (JWT 발급) |

컨트롤러: `src/user/users.controller.ts`, `src/auth/auth.controller.ts`

## 데이터베이스

- **엔진:** SQLite
- **파일:** 프로젝트 루트( `sebastian_server` 기준)의 `db.sqlite`
- **설정:** `src/app.module.ts` — `synchronize: true`로 개발 시 스키마가 DB에 맞춰 동기화됩니다. 운영 환경에서는 마이그레이션 전략을 따로 두는 것이 안전합니다.

## 빌드

```bash
npm run build
```

산출물은 `dist/`에 생성됩니다.

## 테스트·품질

```bash
npm run test          # 단위 테스트
npm run test:watch    # 감시 모드
npm run test:cov      # 커버리지
npm run test:e2e      # E2E (jest-e2e 설정)
npm run lint          # ESLint
npm run format        # Prettier
```

## 보안 참고

JWT 시크릿과 만료 시간은 `src/auth/auth.module.ts`, `src/auth/strategies/jwt.strategy/jwt.strategy.ts`에 코드로 고정되어 있습니다. **실서비스 전에는 환경 변수 등으로 분리**하는 것을 권장합니다.

## 라이선스

`package.json` 기준 **UNLICENSED** (비공개).
