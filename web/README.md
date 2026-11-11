# 관리자 웹 (React + Vite + MUI)

모노레포 루트에 `sebastian_app/`, `sebastian_server/`, **`web/`** 이 나란히 두는 구조입니다. Flutter 앱에는 관리자 UI·코드가 없고, 이 폴더에서만 관리합니다.

백엔드는 **`sebastian_server/src/admin`** 모듈이 다음 엔드포인트를 제공합니다.

| 메서드 | 경로 | 헤더 | 설명 |
|---|---|---|---|
| POST | `/admin/login` | — | `{ username, password }` → `{ token }` (관리자 JWT) |
| GET | `/admin/users` | `x-admin-key` | 사용자 목록 |
| POST | `/admin/users` | `x-admin-key` | 사용자 추가 |
| POST | `/admin/users/:id/reset-password` | `x-admin-key` | 비밀번호 초기화 |

`/admin/login`이 반환하는 `token`은 **관리자 전용 JWT**이며, 이후 API 요청의 `x-admin-key` 헤더에 그대로 넣습니다. (선택) `.env`의 `ADMIN_API_KEY`를 쓰는 경우에도 동일 헤더로 호환됩니다.

## 준비

1. **서버** `sebastian_server/.env` — 필수 항목 없음. (선택) `ADMIN_USERNAME` / `ADMIN_PASSWORD` / `JWT_SECRET` / `ADMIN_API_KEY` — `.env.example` 참고.
2. 서버가 **3000 포트**에서 떠 있어야 합니다 (`npm run start:dev`).

## 실행

### 권장: 모노레포 루트에서 한 번에

`[vite] http proxy error` / `ECONNREFUSED` 는 **Nest가 3000에서 안 떠 있을 때** 발생합니다.

```bash
# 저장소 루트 (sebastian-ai-assistant/)
npm install
npm run dev
```

서버가 준비된 뒤에만 Vite(5173)가 시작됩니다.

### 수동 (터미널 두 개)

1. `cd sebastian_server && npm run start:dev`  
2. 서버 로그에 `listening` 확인 후 → `cd web && npm run dev`

브라우저 `http://localhost:5173` → 기본 계정 **`admin` / `admin1234`** 로 로그인.

개발 모드에서 Vite는 `/admin`을 `VITE_DEV_API_TARGET`(기본 `http://localhost:3000`)으로 프록시합니다 (`vite.config.js`).

## 스택

- React 18 + Vite 5
- MUI 6 + `@mui/x-data-grid`
- React Router 7
- TanStack Query 5
- axios

## 배포

빌드 후 정적 호스팅할 경우, API와 같은 도메인 뒤에 두거나 리버스 프록시로 `/admin`을 Nest에 넘기세요. 다른 오리진이면 서버 CORS 설정이 필요합니다.
