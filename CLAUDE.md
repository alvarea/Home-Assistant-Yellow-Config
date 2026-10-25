# HOMY — configuración de Home Assistant de Agustín
 
Responde siempre en español. Soy ingeniero informático con conocimientos de domótica y programación: sé preciso y no expliques lo básico. Objetivo: mantener la instalación de HA actualizada, añadir integraciones y llegar a un dashboard profesional para toda la familia.
 
La planificación y el backlog se diseñan en el proyecto **IT-HA de Claude Cowork**. Aquí (Claude Code) se implementan las tareas. Datos personales y URL de acceso remoto: `CLAUDE.local.md` (fuera de git; este repo es **público** en GitHub).
 
**Antes de diseñar un mecanismo propio para una necesidad operativa nueva (gestión de tareas, concurrencia, estado...), evalúa primero si una herramienta estándar del sector ya la resuelve** — aunque suponga sustituir algo que ya funciona. Este mismo fichero es un ejemplo: el backlog pasó de Markdown en iCloud a GitHub Issues precisamente por este criterio.
 
**Docs del proyecto Cowork (propuestas, investigaciones puntuales): no son accesibles desde aquí** — viven en el sistema de docs de Cowork (`project_read`), al que Code no llega. Lo que Code necesita para trabajar está en este fichero o en `~/claude/HOMY/` (ver abajo). Si una tarea exige algo que solo está en un doc de Cowork, pídeselo a Agustín.
 
**`~/claude` es un enlace simbólico** a `/Users/agustin/Library/Mobile Documents/com~apple~CloudDocs/claude` (iCloud Drive, una carpeta por proyecto de Cowork). Es una carpeta compartida con Cowork y fuera del repo, así que nunca se copia aquí. Revisa `~/claude/HOMY/` antes de rediagnosticar un problema.
 
## Instalación
- **Home Assistant Yellow** (4 GB RAM, SSD externo), ethernet, IP fija 192.168.0.10. HA 2026.10.1. Los antiguos "add-ons" se llaman ahora **apps**.
- **Zigbee**: más de 70 dispositivos con ZHA en la radio del Yellow.
- **Thread/Matter**: HA Connect ZBT-2 (OTBR), red Matter-over-Thread en crecimiento.
- **ESPHome**: unos 30 Sonoff/ESP32 por WiFi con IP fija (`esphome/`). La app ESPHome está en 2026.9.0. Migración de firmware 2024.2.2 → 2026.x en curso, por lotes; detalle en `esphome-migracion-firmware.md` (doc de Cowork — pide el resumen a Agustín si hace falta, Code no lo puede leer directo).
- **Red**: router Movistar (DHCP y reservas) + APs Aruba Instant (2.4 GHz domótica, 5 GHz ordenadores/móviles) + AP TP-Link en el jardín.
- **Recorder**: MariaDB (`db_url: !secret mariadb_url`), `purge_keep_days: 90`. El histórico largo son las **estadísticas nativas**, solo para sensores con `state_class`.
  - Sensores numéricos y plantillas nuevos que deban archivarse llevan `state_class: measurement` (`total_increasing` en energía).
  - No quitar `state_class` ni excluir del recorder un sensor con histórico.
  - No crear sensores espejo de entidades on/off (decidido para `family_*`).
  - InfluxDB se eliminó el 2026-10-10: no proponerlo salvo que lo pida.
## Estructura del repo
- Raíz: `configuration.yaml` y ficheros incluidos (`automations.yaml`, `scripts.yaml`, `template.yaml`, `sensor.yaml`, `binary_sensor.yaml`, `input_*.yaml`, `groups.yaml`, `scenes.yaml`…).
- `packages/`: funcionalidades autocontenidas (p. ej. `packages/lavadora.yaml`, alarma `alarm_homy`).
- `esphome/`: un YAML por dispositivo.
- `dashboard_*.yaml`: exportaciones de dashboards (en HA están en modo UI/storage).
- `cp*.ssh`: scripts que copian ficheros del repo a `/Volumes/config/`.
- `homeassistant.md` y `*_deprecated.yaml`: código antiguo excluido; solo como referencia.
## Acceso a HA (por orden de preferencia)
1. **MCP de HA** (servidor MCP integrado de HA): estados y control.
   - Solo ve las entidades **expuestas a Assist**. Todo ESPHome y Matter está expuesto.
   - El filtro por nombre exige el nombre exacto: filtra mejor por área o por dominio.
   - Si algo no aparece, probablemente no está expuesto: dímelo.
2. **Navegador integrado** (nunca Claude in Chrome) para la UI: logs, apps, integraciones, reparaciones y configuración.
   - Usa **siempre la URL de Nabu Casa** (en `CLAUDE.local.md`), nunca 192.168.0.10.
   - Para operaciones masivas, API websocket desde la página: `document.querySelector('home-assistant').hass.callWS`.
   - Para exportar dashboards al repo, léelos con `lovelace/config` desde el navegador. El Samba sirve una copia antigua de `.storage/` (caché del Mac).
3. **Ficheros**:
   - Este repo: `~/Dev/HOMY-Home-Assistant-Config`, remoto `alvarea/Home-Assistant-Yellow-Config`.
   - `/Volumes/config`: carpeta config de HA montada por Samba (LaunchAgent). Si no aparece: Finder ⌘K → `smb://192.168.0.10/config`. `/config` es la ruta interna del contenedor.
   - `alvarea/HOMY-Home-Assistant-Config` es un repo antiguo congelado desde 2022: no usarlo.
## Acceso a GitHub (dos ámbitos distintos, no confundir)
- **Código**: solo lectura. No hagas commit ni push salvo que te lo pida.
- **Issues del backlog**: escritura permitida desde el 25-10-2026 — ver sección Backlog abajo.
## Flujo de cambios de código
1. Todo cambio se hace en **este repo**, nunca directamente en HA ni en el editor visual de ESPHome.
2. Copia los ficheros modificados a `/Volumes/config/` (ESPHome: `/Volumes/config/esphome/`), **avisándome antes de cada copia**.
3. Valida en HA: comprobar configuración y recargar o reiniciar, o instalar ESPHome por OTA. Las recargas no necesitan OK; el reinicio y el OTA sí.
4. Si funciona, **el commit lo hago yo** desde VS Code. No hagas commit ni push salvo que te lo pida.
   - Los cambios pequeños van directos a main.
   - Los YAML preparados pero sin probar los dejo sin commit a propósito: no insistas.
   - Git de solo lectura: usa `git --no-optional-locks status`, `log` y `diff`, sin `fetch`, para no dejar `.lock` que rompan VS Code.
5. `secrets.yaml` (y `esphome/secrets.yaml`) no están en git. No muestres ni copies su contenido; usa siempre `!secret`.
## Reglas
- **Pide OK antes de cualquier cambio en HA**: configuración, apps, integraciones, ESPHome, Thread/Zigbee, exposición de entidades, **reinicios** y cualquier acción sobre dispositivos o scripts.
  - **Las recargas de configuración** (automatizaciones, scripts, plantillas, bayesian…) **no necesitan OK**, y las consultas de solo lectura tampoco.
- **Antes de reiniciar HA, comprueba si hay un riego en marcha** (timers de riego activos, válvulas o sectores encendidos, bomba del pozo) y avísame antes de pedir el OK.
- Si me das comandos para ejecutar, de uno en uno, cada uno en su bloque.
- En operaciones largas (comisionados, OTA, reinicios), dame avances cada 15-30 s.
- Al añadir dispositivos ESPHome o Matter nuevos, ofréceme exponerlos **solo a Assist**, no a Alexa. El diálogo "+ Exponer entidades" expone a ambos a la vez.
- Cuando cambie algo importante de la instalación, recuérdame actualizar este fichero y las instrucciones de Cowork (skill `actualizar-instrucciones-homy`).
## Convenciones de código
- Plantillas en formato moderno: `friendly_name` no existe. `name` determina el entity_id y debe mantener el snake_case original.
- `counter.reload` no existe aquí: los contadores nuevos se crean como helper de UI para no reiniciar.
- Las entidades usan las iniciales de cada miembro de la familia: **AAC** (Agustín), **PAF** (Paloma), **AAF** (Agu), **MFC** (Malen). Tabla completa en `CLAUDE.local.md`.
  - ⚠️ El notify de AAF es `notify.mobile_app_a2f`, no `..._aaf`. Está decidido no renombrarlo.
  - Otros notify: `notify.mobile_app_ipad` (iPad WallPanel) y `notify.mobile_app_macbook_aac`.
- Usa siempre las áreas definidas en HA (ver abajo).
## Particularidades conocidas
- El Aruba no reenvía bien broadcast ni multicast entre cable y WiFi:
  - El dashboard de ESPHome muestra dispositivos OFFLINE aunque funcionan; el OTA va por IP fija.
  - Las integraciones con descubrimiento por broadcast fallan; se usan alternativas unicast (p. ej. Gree por HACS).
- Comisionado Matter de IKEA a pilas: hay una receta del "corte BLE" en los docs del proyecto (proxy BLE en `esphome_dual_sw1`).
## Subsistemas con chat propio en Cowork
- **Alarma HOMY** (motor propio `alarm_homy`, en producción desde 12-10, chat ALA). **Las puertas y ventanas abiertas siempre bloquean el armado.** Desde el 20-10-2026 los cambios en sus YAML (`packages/alarm_homy*.yaml`, `custom_templates/alarm_homy.jinja`, `dashboard_alarma_homy.yaml`) los hago yo (Code); el chat ALA solo diagnostica y anota fallos.
- **Lavadora Bosch**: `packages/lavadora.yaml`, enchufe GRILLPLATS, `sensor.lavadora_estado` (chat LAV).
- **Energía** (tarifa Octopus Go, submedición): chat ENE.
## Backlog
Dos mecanismos en convivencia, según si el subproyecto ya se migró o no:
 
### GitHub Issues (migrados: solo ALA por ahora)
- Repo: `alvarea/home-assistant-yellow-config`.
- **Solo REST, nunca GraphQL** — la GraphQL API de GitHub está bloqueada en estas sesiones (`gh issue list`, `gh label list` y cualquier cosa de GitHub Projects v2 fallan con HTTP 403). Usa siempre `gh api repos/{owner}/{repo}/...`, nunca los subcomandos de alto nivel `gh issue`/`gh label`.
- Labels de 3 ejes, con prefijo (no uses los labels estándar de GitHub — `bug`, `enhancement`, etc., borrados a propósito el 25-10-2026):
  - `type:bug` · `type:task` · `type:improvement` · `type:cleansing`
  - `status:in-progress` · `status:needs-decision` · `status:manual-action` · `status:parked` (no hay `status:todo`: una issue abierta sin label de estado ya es "pendiente normal")
  - `subproject:ala` · `subproject:ene` · `subproject:esph` · `subproject:zha` · `subproject:mat` · `subproject:bat` · `subproject:tes` · `subproject:lav` · `subproject:pla` · `subproject:meteo` · `subproject:main`
- Al implementar una tarea: añade el label `status:*` que corresponda si no avanza de forma lineal, y cierra la issue (`gh api -X PATCH .../issues/{n} -f state=closed -f state_reason=completed`) cuando esté hecha y validada.
- Project "HOMY Backlog" (uno solo para todo, no por subproyecto) — es solo visualización, las issues se crean/editan por API, el Project las recoge solo via el workflow "Auto-add to project".
### Ficheros iCloud (el resto: ENE, ESPH, ZHA, MAT, BAT, TES, LAV, PLA, METEO, RESTO)
- Un documento por subproyecto (`backlog-<área>.md`) en `~/claude/HOMY/`, con el índice y los prefijos de ID en `backlog-ha-general.md`. Se gestiona con la skill `print-backlog`.
- **Soy el único escritor de estos ficheros** (decisión 22-10-2026, por choques de escritura con Cowork). Para ejecutar una tarea por su ID, léela en su documento justo antes de implementarla. Al terminarla, ofrécele a Agustín `backlog done <ID>`.
## Áreas de HA (nombre exacto entre [ ])
- **[Planta Baja]**:
  - [Dormitorio M&D], [Dormitorio AAF], [Dormitorio PAF], [Dormitorio Plancha]
  - [Cocina] (incluye el lavadero), [Pasillo], [Salón]
  - Baños: sin área
  - [Entrada]: puerta principal `binary_sensor.aqara_puerta_entrada_principal`, `media_player.echo_alexa_entrada` y el tag reader de la alarma `tagreader_9a0be4`
- **[Planta Alta]**:
  - [Estudio_Sala] / [Estudio_Setup] (despacho de Agustín)
  - [Rack CPD] (comunicaciones, HA Yellow y sirena; dentro del estudio)
  - [Armario], [Desvan]
- **[Jardín]**:
  - [Entrada Garaje] (cargador V2C Trydan), [Riego Jardín], [Piscina], [Porche]
  - Cancela, trastero y control de piscina: sin área
- Para la alarma: los dormitorios están en planta baja, así que de noche hay movimiento en pasillo, baños y cocina. La planta alta está vacía de noche y es la zona vigilada en modo Noche.
 