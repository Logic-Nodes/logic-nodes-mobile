# OmniTrack — Bloqueantes de backend y brechas vs informe final

> **Última actualización:** 2026-07-06  
> **Informe de proyecto (TB1):** [`logic-nodes-report/README.md`](../../logic-nodes-report/README.md) — LogicNodes / OmniTrack, UPC 202610, NRC 6770  
> **API producción:** `https://logic-nodes-server.onrender.com`  
> **Swagger:** `https://logic-nodes-server.onrender.com/docs/`  
> **Script billing:** `logic-nodes-server/db/billing.sql`

Este documento es la **fuente única de bloqueantes de backend**. Lista todos los errores, endpoints faltantes e infraestructura pendiente que impiden cerrar el informe final, y **qué no puede hacer mobile** por culpa de cada bloqueante.

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
- **Stripe** para pagos
- **Google Maps** para rutas
- Despliegue en Render / Kubernetes

**Evaluación TB1:** el informe original cubrió landing + web + backend. **Mobile quedó fuera del alcance de evaluación** pero las US009–041 y el cap. IV aplican igualmente a la app.

---

## 2. Resumen — qué falta para cerrar el informe

| Categoría bloqueante | Ítems | US afectadas | Responsable |
|---------------------|-------|--------------|-------------|
| **A — Errores 500 en producción** | 5 endpoints billing | US038–040 | `logic-nodes-server` + BD Render |
| **B — Endpoints que no existen** | 8+ funcionalidades | US026, US027, US030, US041, US006, US040 | `logic-nodes-server` |
| **C — Contrato API incorrecto** | 3 rutas analytics | US035 (web) | `logic-nodes-server` |
| **D — Infra / jobs sin implementar** | MQTT, FCM, cron, Stripe | US028, US029, US030, US041 | `logic-nodes-server` + servicios externos |
| **E — Datos vacíos en prod** | Sin seed operativo | US032–034 (demo) | `logic-nodes-server` + BD |
| **F — Otros productos** | Landing, web gaps | US001–008, varias web | otros repos |

### Estado mobile (2026-07-06) — lo que SÍ está hecho

| Métrica | Valor |
|---------|-------|
| US009–041 completas en mobile | **25 / 33** (76%) |
| Código listo, bloqueado por backend | **+3** (US038–040 billing) |
| Parciales por backend | **3** (US028, US031, US041) |
| Imposibles sin backend nuevo | **3** (US026, US027, US030) |
| SQLite offline (cap. IV) | ✅ Implementado (`sqflite`) |

> **Mobile ya hizo todo lo que está en sus manos.** Lo que sigue en rojo abajo **no se puede terminar en mobile** hasta que backend/infra lo resuelva.

---

## 3. ERRORES DE BACKEND — catálogo completo

### 3.1 Críticos — HTTP 500 en producción (Render)

Verificado **2026-07-06** contra `https://logic-nodes-server.onrender.com`.

| ID | Método | Endpoint | HTTP | Error PostgreSQL | Causa raíz |
|----|--------|----------|------|------------------|------------|
| **B-01** | GET | `/api/v1/plans` | **500** | `relation "plans" does not exist` | Tabla `plans` no migrada en BD prod |
| **B-02** | GET | `/api/v1/subscription/user-id/:userId` | **500** | `column s.renewal does not exist` | Tabla `subscriptions` sin columna `renewal` |
| **B-03** | GET | `/api/v1/payments/user-id/:userId` | **500** | Mismo error `renewal` | Idem B-02 |
| **B-04** | PUT | `/api/v1/subscription/:id/plan` | **500** | Idem billing schema | Idem B-01/B-02 |
| **B-05** | DELETE | `/api/v1/subscription/:id` | **500** | Idem billing schema | Idem B-01/B-02 |

**Fix requerido:**

```bash
# Ejecutar en BD de producción Render:
# logic-nodes-server/db/billing.sql
```

Crea tablas `plans`, `subscriptions` (con `renewal`), `payments` y datos seed de planes.

**US del informe bloqueadas:** US038, US039, US040  
**Mobile:** código completo en `remote_billing_datasource.dart` + `subscription_screen.dart` — **no puede probarse en prod hasta B-01–B-05**.

---

### 3.2 Contrato API incorrecto — analytics (200 pero forma distinta)

| ID | Endpoint | Respuesta real prod | Respuesta que espera el informe/web | US |
|----|----------|---------------------|-------------------------------------|-----|
| **B-06** | `GET /analytics/trips` | `{ byStatus: [{status,count}] }` | Array `DashboardTrip[]` con detalle | US032, US035 |
| **B-07** | `GET /analytics/alerts` | `{ byStatus, byType }` | Array `DashboardAlert[]` | US029, US035 |
| **B-08** | `GET /analytics/incidents-by-month` | `[{ month, count }]` | `{ month, temperatureIncidents, movementIncidents }` | US035 |

**Fix requerido (elegir una):**

- **Opción A:** Ampliar queries SQL en `logic-nodes-server` para devolver el shape del informe.
- **Opción B:** Documentar contrato real y alinear web (mobile ya usa `/trips` y `/alerts` operativos).

**Mobile:** no bloqueado (ya adaptado). **Web:** dashboard roto (`dashboard.api.ts`).

---

### 3.3 Endpoints que el informe pide pero NO existen en la API

| ID | Funcionalidad (informe) | US | Qué falta en backend | Prioridad |
|----|-------------------------|-----|----------------------|-----------|
| **B-09** | Reprogramar viaje | US026 | `PATCH /api/v1/trips/:id` (cambiar fecha/origen) | Alta |
| **B-10** | Código tracking público | US027 | Campo `trackingCode` en `trips` + `GET /api/v1/trips/public/:code` | Alta |
| **B-11** | Alertas auto desconexión IoT | US030 | Job/cron que evalúe `devices.online` + última telemetría → crea alerta | Alta |
| **B-12** | Ingesta IoT continua (MQTT) | US028 | Broker MQTT → `POST /api/v1/telemetry` automático | Alta |
| **B-13** | Vincular tarjeta / Stripe | US040 | `POST /api/v1/subscription/:id/payment-method` + integración Stripe | Media |
| **B-14** | Push notificaciones | US029, US041 | Registro FCM device tokens + `POST /notifications/:id/send` real | Media |
| **B-15** | Aviso renovación automático | US041 | Cron que lea `subscription.renewal` y dispare notificación | Media |
| **B-16** | Formulario contacto landing | US006 | `POST /api/v1/contact` o integración email | Baja |
| **B-17** | PDF server-side | US037 | `GET /api/v1/trips/:id/report.pdf` (opcional; web/mobile generan en cliente) | Baja |
| **B-18** | Google Maps rutas | Cap. IV | Integración Maps API en backend o cliente con API key | Media |
| **B-19** | RBAC estricto por rol | US031 | Middleware que valide permisos por endpoint | Media |
| **B-20** | App rol conductor | Cap. IV | Flujo/API dedicado para conductor | Baja |

---

### 3.4 Infraestructura del informe sin implementar

| ID | Componente (Cap. IV) | Estado backend | Impacto |
|----|---------------------|----------------|---------|
| **B-21** | Broker MQTT / ingesta IoT | ❌ No existe | US028, US030, US034 sin datos reales en vivo |
| **B-22** | Firebase Cloud Messaging | ❌ No existe | US029, US041 sin push |
| **B-23** | Stripe Connect / pagos | ❌ No existe | US040 link tarjeta |
| **B-24** | Job renovación suscripción | ❌ No existe | US041 |
| **B-25** | Job alertas desconexión | ❌ No existe | US030 |
| **B-26** | Motor de reglas alertas térmicas | ❌ Parcial | US029 depende de ingesta IoT (B-12) |

---

### 3.5 Problemas operativos en producción (no son bugs de código)

| ID | Problema | Observación | Impacto |
|----|----------|-------------|---------|
| **B-27** | Cold start Render | `POST /authentication/sign-in` tarda 20–30 s | Timeout en clientes con límite bajo |
| **B-28** | BD sin datos de prueba | `GET /trips` → `[]`, telemetría → `[]` | Demos vacías; gráficas sin puntos |
| **B-29** | `GET /incidents` raíz | **404** (diseño: solo `/incidents/alert/:id`) | No es bug; documentar para clientes |
| **B-29** | `GET /notifications` raíz | **404** (diseño: solo `/notifications/alert/:id`) | Idem |

---

### 3.6 Desalineaciones web ↔ backend (afectan informe, no mobile)

| ID | Problema | Archivo web | Fix |
|----|----------|-------------|-----|
| **B-30** | Dashboard analytics usa contrato viejo | `dashboard.api.ts` | Usar `/trips`, `/alerts` o fix B-06–B-08 |
| **B-31** | Temperatura en vivo simulada | `useLiveTemperature.ts` | Conectar a B-12 + `/telemetry` |
| **B-32** | Sin refresh token en 401 | `api/client.ts` | Implementar refresh (mobile ya lo tiene) |
| **B-33** | Sin pantalla forgot/reset password | — | API existe; falta UI web |

---

## 4. MOBILE — qué NO puede hacer por culpa de cada bloqueante

Esta sección es exclusiva para el equipo mobile: **funcionalidad bloqueada → causa backend → US del informe**.

| Bloqueante backend | US informe | Qué mobile NO puede hacer (aunque tenga código) | Archivos mobile afectados |
|-------------------|------------|--------------------------------------------------|---------------------------|
| **B-01–B-05** Billing 500 | US038, US039, US040 | Ver planes, suscripción, historial de pagos, cambiar/cancelar plan **en producción** | `subscription_screen.dart`, `billing_controller.dart` |
| **B-09** Sin PATCH trips | US026 | Reprogramar fecha/origen de un viaje ya creado | No hay pantalla posible |
| **B-10** Sin tracking público | US027 | Pantalla cliente "consultar pedido por código" | No hay pantalla posible |
| **B-11** Sin job desconexión | US030 | Mostrar alertas automáticas cuando un dispositivo deja de transmitir | Solo alertas manuales vía API |
| **B-12** Sin MQTT | US028 | Temperatura **real** en vivo continua; solo lectura/polling de telemetría vacía | `trip_analytics_detail_screen.dart`, gráficas |
| **B-13** Sin Stripe | US040 | Vincular tarjeta de pago real | `link_payment_method_screen.dart` (stub local) |
| **B-14** Sin FCM | US029 | Push cuando ocurre alerta térmica | — |
| **B-15** Sin cron renovación | US041 | Aviso push/email antes de renovar suscripción | Banner solo posible si B-01–B-05 funciona |
| **B-19** RBAC incompleto | US031 | Pantalla admin gestión usuarios/permisos completa | Parcial: solo roles en JWT |
| **B-28** Sin seed prod | US032–034 | Demos con viajes/telemetría reales en prod | Muestra listas vacías o cache SQLite |

### Lo que mobile SÍ tiene listo (no bloqueado)

| US | Estado mobile | Nota |
|----|---------------|------|
| US009–012 | ✅ | Auth completo + logout-all |
| US013–025 (salvo 026–027) | ✅ | Fleet CRUD, trips CRUD, filtros |
| US029 | ✅ | Alertas list/detail/ack/close + incidents/notifications |
| US032–037 | ✅ | Dashboard, gráficas, PDF cliente, SQLite offline |
| US038–040 | 🟡 | Código listo; **bloqueado por B-01–B-05 en prod** |

---

## 5. Matriz informe final — US vs bloqueante backend

Leyenda: ✅ Mobile listo | 🟡 Parcial / código listo | 🔴 Bloqueado por backend | ⬜ Fuera de alcance mobile (landing/web)

| US | Título (informe) | Épica | Mobile | Bloqueante backend |
|----|------------------|-------|--------|-------------------|
| US001–005 | Landing secciones | E1 | ⬜ | — (landing) |
| US006 | Formulario contacto | E1 | ⬜ | **B-16** |
| US007 | CTA webapp | E1 | ⬜ | — (landing) |
| US008 | Descarga app stores | E1 | ⬜ | — (landing + stores) |
| US009 | Registro | E2 | ✅ | — |
| US010 | Login | E2 | ✅ | B-27 (cold start) |
| US011 | Logout | E2 | ✅ | — |
| US012 | Recovery password | E2 | ✅ | — |
| US013–023 | Flota IoT | E3 | ✅ | B-11 afecta US022 escenario auto |
| US024–025 | Crear/estados viaje | E4 | ✅ | B-28 (datos vacíos prod) |
| US026 | Reprogramar viaje | E4 | 🔴 | **B-09** |
| US027 | Código tracking | E4 | 🔴 | **B-10** |
| US028 | Temp en vivo | E4 | 🟡 | **B-12**, B-21, B-28 |
| US029 | Alertas temperatura | E5 | ✅ | B-14 (push), B-12 (generación auto) |
| US030 | Alertas desconexión | E5 | 🔴 | **B-11**, B-25 |
| US031 | Roles y permisos | E5 | 🟡 | **B-19** |
| US032–037 | Dashboard | E6 | ✅ | B-28 (datos demo) |
| US038–040 | Billing | E7 | 🟡 | **B-01–B-05**, B-13 |
| US041 | Aviso renovación | E7 | 🟡 | **B-01–B-05**, **B-14**, **B-15** |

---

## 6. Checklist backend para desbloquear mobile (orden de prioridad)

### P0 — Crítico (1–2 días)

- [ ] **B-01–B-05:** Ejecutar `db/billing.sql` en Render
- [ ] **B-28:** Seed: 1 merchant, 1 trip, telemetría, alertas, planes activos
- [ ] Verificar `GET /plans`, `GET /subscription/user-id/:id`, `GET /payments/user-id/:id` → **200**

### P1 — Alto (1–2 semanas)

- [ ] **B-09:** `PATCH /trips/:id` → desbloquea US026
- [ ] **B-10:** `trackingCode` + ruta pública → desbloquea US027
- [ ] **B-11 + B-25:** Worker desconexión IoT → desbloquea US030
- [ ] **B-12 + B-21:** MQTT → telemetría real → desbloquea US028

### P2 — Medio (2–4 semanas)

- [ ] **B-06–B-08:** Alinear analytics o documentar contrato
- [ ] **B-13 + B-23:** Stripe payment-method → US040 completo
- [ ] **B-14 + B-15 + B-24:** FCM + cron renovación → US041
- [ ] **B-19:** RBAC middleware → US031 completo

### P3 — Bajo

- [ ] **B-16:** Contacto landing US006
- [ ] **B-18:** Google Maps
- [ ] **B-27:** Mitigar cold start (plan Render, keep-alive, o worker)

---

## 7. Referencias del ecosistema

| Recurso | Ruta |
|---------|------|
| **Informe final TB1** | [`logic-nodes-report/README.md`](../../logic-nodes-report/README.md) |
| API routes | `logic-nodes-server/src/shared/interfaces/http/router.js` |
| Swagger spec | `logic-nodes-server/src/shared/interfaces/http/swagger-spec.js` |
| Billing SQL fix | `logic-nodes-server/db/billing.sql` |
| Mobile offline SQLite | `logic-nodes-mobile/lib/core/storage/local_database.dart` |
| Web dashboard (roto) | `logic-nodes-webapp/src/api/dashboard.api.ts` |
| Web temp simulada | `logic-nodes-webapp/src/hooks/useLiveTemperature.ts` |

---

## 8. Mensaje para el equipo

> **Mobile está al 76% del informe (25/33 US) y al ~85% con código escrito (28/33).**  
> Todo lo implementable sin backend ya está hecho: fleet, trips, alertas, analytics, PDF, perfil, SQLite offline.  
> **Lo que falta en mobile es consecuencia directa de los bloqueantes B-01 a B-30 listados arriba.**  
> Hasta que `logic-nodes-server` no resuelva billing en prod (B-01–B-05) y cree los endpoints/jobs faltantes (B-09–B-16), mobile **no puede** cerrar US026, US027, US030, US038–041 en producción.

---

*Actualizar este documento cuando se migre billing, se añadan endpoints o cambien contratos en prod.*
