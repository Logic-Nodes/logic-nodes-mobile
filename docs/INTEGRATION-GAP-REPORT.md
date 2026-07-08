# OmniTrack — Bloqueantes de backend y brechas vs informe final

> **Última actualización:** 2026-07-07  
> **Informe de proyecto (TB1):** [`logic-nodes-report/README.md`](../../logic-nodes-report/README.md) — LogicNodes / OmniTrack, UPC 202610, NRC 6770  
> **API producción:** `https://logic-nodes-server.onrender.com`  
> **Swagger:** `https://logic-nodes-server.onrender.com/docs/`  
> **Última actualización:** 2026-07-08  
> **PRs abiertos:** mobile [#3](https://github.com/Logic-Nodes/logic-nodes-mobile/pull/3) (rebase pendiente) · backend [#4](https://github.com/Logic-Nodes/logic-nodes-server/pull/4) (**conflictos** — rebase obligatorio)

---

## 0. Estado ejecutivo (2026-07-08)

### Qué entró en `main` (ya no repetir en PRs)

| Repo | Merge en `main` | Ya cubierto |
|------|-----------------|-------------|
| **mobile** | PR #2 | Billing + permiso `INTERNET` |
| **server** | PR #3 + commit IoT | Billing refactor, PATCH trips, tracking público, módulo IoT/desconexión |

### Delta real de las ramas abiertas

| PR | Sigue aportando | Acción |
|----|-----------------|--------|
| **mobile #3** | Commit `2603bd8`: fleet, trips, profile, analytics, offline, demo tour, reporte (~113 archivos) | **Rebase** sobre `origin/main` y merge |
| **server #4** | Migración billing segura, `seed:demo`, analytics US035, device-tokens/jobs FCM, docs | **Rebase** sobre `main`, resolver conflictos con IoT; no duplicar billing/trips/disconnect |

| Capa | Estado | Nota |
|------|--------|------|
| **Mobile (rama + local)** | ✅ ~90% código | US026/US027 y español UI en working tree sin commit |
| **Backend (rama)** | 🟡 Rebase necesario | Parte duplicada con `main`; conservar seed + migración + FCM |
| **Producción Render** | 🔴 Sin desplegar | `migrate:billing` + `seed:demo` tras merge server limpio |
| **Local E2E** | ✅ 19/19 API | Backend `127.0.0.1:3001` |
| **Push FCM** | 🟡 Código listo | Simulador iOS no recibe push real |
| **Stripe (US040)** | ⬜ Fuera de alcance | Stub en backend/mobile |

Este documento es la **fuente única de bloqueantes de backend**. Lista errores, endpoints faltantes e infraestructura pendiente que impiden cerrar el informe final.

### ¿Está todo completo?

**En código:** mobile casi listo (US026/US027 + español en working tree). Server requiere rebase limpio.  
**En producción:** no — falta merge server + `migrate:billing` + `seed:demo` en Render.

### Credenciales demo (tras `seed:demo` en prod)

| Campo | Valor |
|-------|-------|
| Email | `demo.mobile.2026@omnitrack.io` |
| Password | `DemoMobile123!` |
| Tracking público | `DEMO7K9M2` |

### Relanzar demo en simulador

**Producción (Render):**
```bash
cd logic-nodes-mobile
flutter run --dart-define=DEMO_AUTO_LOGIN=true --dart-define=DEMO_TOUR=true
```

**Local E2E (recomendado sin iPhone físico):**
```bash
# Terminal 1 — backend
cd logic-nodes-server
npm run migrate          # primera vez
npm run seed:demo        # datos demo
npm run dev              # http://127.0.0.1:3001

# Terminal 2 — smoke API (opcional)
npm run test:e2e-local   # debe pasar 19/19

# Terminal 3 — mobile
cd logic-nodes-mobile
flutter run \
  --dart-define=OMNITRACK_API_BASE_URL=http://127.0.0.1:3001 \
  --dart-define=DEMO_AUTO_LOGIN=true \
  --dart-define=DEMO_TOUR=true
```

Perfil VS Code: **"iOS · Local E2E (backend + demo)"**.

> **Nota:** en `.env` del backend local usar `DB_SSL=false` y `PORT=3001`.

---

## 1. Referencia al informe final del proyecto

El informe académico define **41 user stories (US001–US041)** en 7 épicas, más requisitos de arquitectura en el **Capítulo IV** (SQLite offline, MQTT, FCM, Stripe, Maps, despliegue).

| Épica | US | Alcance reporte | Repositorio principal |
|-------|-----|-----------------|----------------------|
| **E1** Landing | US001–008 | Página pública, contacto, CTA web/app | `logic-nodes-landing-page` |
| **E2** Auth | US009–012 | Registro, login, logout, recovery | `logic-nodes-webapp`, `logic-nodes-mobile` |
| **E3** Flota | US013–023 | CRUD vehículos/dispositivos IoT | web + mobile |
| **E4** Viajes | US024–028 | Crear, estados, reprogramar, tracking, temp en vivo | web + mobile |
| **E5** Alertas | US029–031 | Alertas térmicas, desconexión IoT, roles | web + mobile |
| **E6** Dashboard | US032–037 | Lista, detalle, gráficas, filtros, PDF | web + mobile |
| **E7** Billing | US038–041 | Suscripción, pagos, renovación | web + mobile |

**Cap. IV — Arquitectura (extracto relevante):**

- App móvil Flutter con **SQLite local** y modo offline-first
- **Broker MQTT** para telemetría IoT
- **FCM** para notificaciones push
- **Stripe** para pagos *(fuera de alcance actual)*
- **Google Maps** para rutas
- Despliegue en Render / Kubernetes

**Evaluación TB1:** el informe original cubrió landing + web + backend. **Mobile quedó fuera del alcance de evaluación** pero las US009–041 y el cap. IV aplican igualmente a la app.

---

## 2. Resumen — qué falta para cerrar el informe

| Categoría bloqueante | Ítems | US afectadas | Responsable | Estado código |
|---------------------|-------|--------------|-------------|---------------|
| **A — Errores 500 en producción** | 5 endpoints billing | US038–040 | `logic-nodes-server` + BD Render | ✅ Fix en rama; 🔴 prod sin migrar |
| **B — Endpoints que no existen** | PATCH, tracking, jobs | US026, US027, US030 | `logic-nodes-server` | ✅ Implementados en rama |
| **C — Contrato API incorrecto** | 3 rutas analytics | US035 (web) | `logic-nodes-server` | ✅ Corregido en rama |
| **D — Infra / jobs** | MQTT, FCM, cron | US028, US029, US030, US041 | server + servicios | 🟡 FCM/MQTT opcionales por env |
| **E — Datos vacíos en prod** | Sin seed operativo | US032–034 (demo) | `logic-nodes-server` | ✅ Script listo; 🔴 no ejecutado en Render |
| **F — Otros productos** | Landing, web gaps | US001–008, varias web | otros repos | Sin cambio |
| **G — Pantallas mobile faltantes** | US026, US027 UI | US026, US027 | `logic-nodes-mobile` | ✅ Implementadas |

### Estado mobile (2026-07-07)

| Métrica | Valor |
|---------|-------|
| US009–041 completas en mobile (funcional) | **25 / 33** (76%) |
| Código listo + bloqueado solo por deploy prod | **+3** (US038–040 billing) |
| Backend listo, falta UI mobile | **2** (US026, US027) |
| Parciales (IoT/push/RBAC) | **3** (US028, US031, US041) |
| SQLite offline (cap. IV) | ✅ Implementado (`sqflite`) |
| FCM cliente | ✅ `firebase_messaging` + registro token |
| Push en simulador iOS | ⚠️ No fiable — ver sección 9 |

> **Mobile ya hizo todo lo implementable sin deploy ni iPhone físico.** Lo pendiente en rojo requiere merge backend en Render, seed, o dispositivo real para push.

---

## 3. ERRORES DE BACKEND — catálogo completo

### 3.1 Críticos — HTTP 500 en producción (Render)

Verificado **2026-07-07** contra `https://logic-nodes-server.onrender.com` (**rama main aún sin merge**).

| ID | Método | Endpoint | HTTP prod | Error PostgreSQL | Fix en rama `feat/billing-contract` |
|----|--------|----------|-----------|------------------|-------------------------------------|
| **B-01** | GET | `/api/v1/plans` | **500** | `relation "plans" does not exist` | ✅ `001_billing_safe.sql` |
| **B-02** | GET | `/api/v1/subscription/user-id/:userId` | **500** | `column s.renewal does not exist` | ✅ Idem |
| **B-03** | GET | `/api/v1/payments/user-id/:userId` | **500** | Mismo error `renewal` | ✅ Idem |
| **B-04** | PUT | `/api/v1/subscription/:id/plan` | **500** | Idem billing schema | ✅ Idem |
| **B-05** | DELETE | `/api/v1/subscription/:id` | **500** | Idem billing schema | ✅ Idem |

**Fix en Render (pendiente):**

```bash
npm run migrate:billing
npm run seed:demo
```

**US del informe:** US038, US039, US040  
**Mobile:** código completo — **bloqueado en prod hasta deploy**.

---

### 3.2 Contrato API incorrecto — analytics

| ID | Endpoint | Estado rama | US |
|----|----------|---------------|-----|
| **B-06** | `GET /analytics/trips` | ✅ Devuelve array dashboard | US032, US035 |
| **B-07** | `GET /analytics/alerts` | ✅ Devuelve array dashboard | US029, US035 |
| **B-08** | `GET /analytics/incidents-by-month` | ✅ Shape ampliado | US035 |

**Prod:** pendiente merge. **Mobile:** no bloqueado.

---

### 3.3 Endpoints — estado tras rama backend

| ID | Funcionalidad | US | Estado rama | Prod | Prioridad deploy |
|----|---------------|-----|-------------|------|------------------|
| **B-09** | Reprogramar viaje | US026 | ✅ `PATCH /api/v1/trips/:id` | 🔴 | Alta |
| **B-10** | Código tracking público | US027 | ✅ `tracking_code` + `GET /trips/public/:code` | 🔴 404 | Alta |
| **B-11** | Alertas auto desconexión IoT | US030 | ✅ Job cada 5 min | 🔴 | Alta |
| **B-12** | Ingesta IoT (MQTT) | US028 | ✅ Si `MQTT_BROKER_URL` | 🟡 Sin broker | Alta |
| **B-13** | Vincular tarjeta / Stripe | US040 | 🟡 Stub | ⬜ Fuera alcance | — |
| **B-14** | Push notificaciones | US029, US041 | ✅ FCM + `POST /device-tokens` | 🔴 Sin env FCM | Media |
| **B-15** | Aviso renovación automático | US041 | ✅ Cron 12h | 🔴 | Media |
| **B-16** | Formulario contacto landing | US006 | ❌ | ❌ | Baja |
| **B-17** | PDF server-side | US037 | ❌ (cliente OK) | — | Baja |
| **B-18** | Google Maps rutas | Cap. IV | ❌ | — | Media |
| **B-19** | RBAC estricto por rol | US031 | 🟡 Parcial | — | Media |
| **B-20** | App rol conductor | Cap. IV | ❌ | — | Baja |

---

### 3.4 Infraestructura del informe

| ID | Componente (Cap. IV) | Estado rama | Prod / simulador |
|----|---------------------|-------------|------------------|
| **B-21** | Broker MQTT | ✅ Subscriber opcional | Sin broker real |
| **B-22** | Firebase Cloud Messaging | ✅ `firebase-admin` + mobile SDK | Simulador iOS: push no fiable |
| **B-23** | Stripe | ⬜ Fuera de alcance | — |
| **B-24** | Job renovación suscripción | ✅ Cron | Pendiente deploy |
| **B-25** | Job alertas desconexión | ✅ Cron | Pendiente deploy |
| **B-26** | Motor reglas alertas térmicas | 🟡 Parcial | Depende MQTT |

---

### 3.5 Problemas operativos en producción

| ID | Problema | Observación | Impacto |
|----|----------|-------------|---------|
| **B-27** | Cold start Render | Sign-in 20–30 s | Timeout posible |
| **B-28** | BD sin datos de prueba | `GET /trips` → `[]` | ✅ `npm run seed:demo` listo; no ejecutado |
| **B-29** | Rutas incidents/notifications raíz | **404** por diseño | Documentar |

---

### 3.6 Desalineaciones web ↔ backend

| ID | Problema | Fix |
|----|----------|-----|
| **B-30** | Dashboard analytics contrato viejo | Merge backend o alinear web |
| **B-31** | Temperatura en vivo simulada | MQTT + telemetría |
| **B-32** | Sin refresh token en 401 | Implementar en web |
| **B-33** | Sin pantalla forgot/reset password | Falta UI web |

---

## 4. MOBILE — qué NO puede hacer (y por qué)

| Bloqueante | US | Qué mobile NO puede hacer | Estado |
|-----------|-----|---------------------------|--------|
| **B-01–B-05** prod | US038–040 | Billing en producción | Código ✅; prod 🔴 |
| **B-09** sin deploy | US026 | Reprogramar viaje | Backend ✅; **sin pantalla mobile** |
| **B-10** sin deploy | US027 | Consultar por código tracking | Backend ✅; **sin pantalla mobile** |
| **B-11** sin deploy | US030 | Alertas auto desconexión en prod | Job listo; prod 🔴 |
| **B-12** sin MQTT | US028 | Temp real continua | Polling telemetría vacía |
| **B-13** Stripe | US040 | Tarjeta real | Fuera de alcance |
| **B-14** simulador | US029 | Push alerta térmica en iOS sim | Código ✅; ver sección 9 |
| **B-15** sin deploy | US041 | Aviso push renovación | Cron listo; prod 🔴 |
| **B-28** sin seed prod | US032–034 | Demo con datos reales en prod | Script listo |

### Lo que mobile SÍ tiene listo

| US | Estado | Nota |
|----|--------|------|
| US009–012 | ✅ | Auth + logout-all |
| US013–025 | ✅ | Fleet, trips CRUD, filtros |
| US026–027 | ✅ | Pantallas reschedule + tracking público |
| US029 | ✅ | Alertas API; push limitado en simulador |
| US032–037 | ✅ | Dashboard, gráficas, PDF, SQLite |
| US038–040 | 🟡 | Código listo; prod billing 🔴 |
| US041 | 🟡 | Banner posible tras billing; push en sim |

---

## 5. Matriz informe final — US vs estado

Leyenda: ✅ Listo | 🟡 Parcial / código / deploy pendiente | 🔴 Bloqueado | ⬜ Fuera alcance mobile

| US | Título | Épica | Mobile | Bloqueante / nota |
|----|--------|-------|--------|-------------------|
| US001–005 | Landing | E1 | ⬜ | landing |
| US006 | Contacto | E1 | ⬜ | B-16 |
| US007–008 | CTA / stores | E1 | ⬜ | landing |
| US009–012 | Auth | E2 | ✅ | B-27 cold start |
| US013–023 | Flota IoT | E3 | ✅ | B-11 escenario auto |
| US024–025 | Viajes | E4 | ✅ | B-28 datos prod |
| US026 | Reprogramar | E4 | ✅ | `PATCH /trips/:id` + pantalla reschedule |
| US027 | Tracking código | E4 | ✅ | `GET /trips/public/:code` + pantalla pública |
| US028 | Temp en vivo | E4 | 🟡 | B-12, B-21, B-28 |
| US029 | Alertas temp | E5 | ✅ | B-14 push sim limitado |
| US030 | Desconexión IoT | E5 | 🟡 | B-11 deploy |
| US031 | Roles | E5 | 🟡 | B-19 |
| US032–037 | Dashboard | E6 | ✅ | B-28 demo prod |
| US038–040 | Billing | E7 | 🟡 | B-01–B-05 deploy; Stripe ⬜ |
| US041 | Renovación | E7 | 🟡 | B-14–B-15 deploy + sim push |

---

## 6. Checklist para cerrar (orden de prioridad)

### P0 — Desbloquear prod (hoy)

- [ ] Merge PR backend [#4](https://github.com/Logic-Nodes/logic-nodes-server/pull/4) → `main`
- [ ] Render: `npm run migrate:billing && npm run seed:demo`
- [ ] Render: `FIREBASE_SERVICE_ACCOUNT_JSON` (JSON minificado)
- [ ] Verificar: `GET /plans` → 200, `GET /trips/public/DEMO7K9M2` → 200
- [ ] Merge PR mobile [#3](https://github.com/Logic-Nodes/logic-nodes-mobile/pull/3)

### P1 — Completar mobile (opcional informe)

- [x] Pantalla reprogramar viaje (US026) — `trip_reschedule_screen.dart`
- [x] Pantalla tracking público (US027) — `public_tracking_screen.dart`

### P2 — Validación push

- [ ] **iPhone físico** o **emulador Android** con Google Play Services
- [ ] En simulador iOS: validar registro token en logs + `[push]` en backend

### P3 — Fuera de alcance acordado

- [ ] Stripe real (US040) — excluido
- [ ] MQTT broker real — opcional demo académica

---

## 7. Referencias

| Recurso | Ruta |
|---------|------|
| Informe TB1 | [`logic-nodes-report/README.md`](../../logic-nodes-report/README.md) |
| Plan backend | [`logic-nodes-server/docs/BACKEND-GAP-RESOLUTION.md`](../../logic-nodes-server/docs/BACKEND-GAP-RESOLUTION.md) |
| Billing SQL | `logic-nodes-server/db/billing.sql` |
| Seed demo | `logic-nodes-server/scripts/seed-demo.mjs` |
| Push mobile | `logic-nodes-mobile/lib/core/services/push_notification_service.dart` |
| Push backend | `logic-nodes-server/src/shared/infrastructure/push/push-sender.js` |
| SQLite offline | `logic-nodes-mobile/lib/core/storage/local_database.dart` |

---

## 8. Mensaje para el equipo

> **Código:** mobile ~85% y backend de brechas críticas **implementado en ramas**.  
> **Producción:** sigue en rojo hasta merge + migrate + seed en Render (verificado: plans 500, tracking 404).  
> **Simulador iOS sin iPhone físico:** demo académica viable con auto-login y tour; **push no es criterio de cierre en simulador** — el código FCM está integrado y se valida por API/logs.  
> **Para “100% informe” en prod:** ejecutar checklist P0; opcionalmente añadir pantallas US026/US027 en mobile.

---

## 9. Nota: push en simulador iOS (sin iPhone físico)

| Escenario | ¿Funciona? |
|-----------|------------|
| Login, fleet, viajes, alertas, dashboard, PDF | ✅ Sí |
| SQLite offline | ✅ Sí |
| Registro FCM token → `POST /device-tokens` | 🟡 A veces en sim; más fiable en Android emu |
| Recibir notificación push en pantalla | ❌ Simulador iOS no es fiable |
| Backend envía push (`firebase-admin`) | ✅ Con `FIREBASE_SERVICE_ACCOUNT_JSON` en Render |
| Validar US041 sin dispositivo | ✅ Logs backend + banner renovación tras billing deploy |

**Conclusión:** para la evaluación académica con solo simulador iOS, documentar que FCM está integrado end-to-end en código y validar el flujo por API; la recepción visual de push queda como limitación del entorno, no del proyecto.

---

*Actualizar cuando se despliegue en Render, se mergeen PRs o cambien contratos en prod.*
