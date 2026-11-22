# Changelog

Todas las versiones relevantes del prototipo.

## No publicado

### Agregado
- **Enemigo básico con modelo 3D riggeado**: esqueleto humanoide, pesos rígidos por pieza y animaciones `Idle`, `Walk`, `Attack`, `Hit` y `Death`.
- El enemigo mira al jugador, camina hacia él y reproduce `Attack`/`Hit` según el estado; la muerte reproduce el desplome antes de liberarse.
- El modelo del básico reemplaza las cajas de su escena, manteniendo las hitboxes de cabeza/torso/piernas.

## v0.8.1 — 2026-11-22

### Corregido
- El HUD de armas muestra las **4 armas** del arsenal (antes solo 3) y la escopeta equipada ya aparece resaltada.
- La tecla **4** selecciona la escopeta; los atajos 1–4 coinciden con las cuatro armas.

## v0.8.0 — 2026-11-22

### Agregado
- **Eventos de arena variables:** cada zona elige al azar entre dos eventos al empezar la run.
  - **Zona 1:** Reactor inestable o **Fábrica de minas**.
  - **Zona 2:** Campo de hielo o **Ancla gravitatoria**.
  - **Zona 3:** Torreta de supresión o **Núcleo sanitario**.
- **Fábrica de minas:** suelta minas que parpadean mientras se arman y explotan al acercarte o al agotar su vida.
- **Ancla gravitatoria:** tira del jugador hacia el núcleo cada pocos segundos; el empuje se disipa rápido y no anula el control.
- **Núcleo sanitario:** cura a los enemigos dentro del radio y muestra un `+N` verde sobre cada uno.
- **Minimapa:** los eventos de arena aparecen como un rombo del color del evento.
- `ArenaEventRegistry` centraliza títulos, vida, recompensa, radio, colores y tiempos de cada evento.

### Cambiado
- Los eventos de arena ya no están fijados en la escena de la zona: se configuran al arrancar desde el pool de la zona.
- La run empieza con la **pistola Cobra** (semiautomática, ~5 clicks/s) en vez del rifle.
- El **AK-47** (antes Rifle básico) se desbloquea y se agrega al arsenal al terminar la primera run.
- La tienda muestra el modo de disparo (`auto` / `semi`).

### Integrado
- **Viewmodels 3D**: AK-47, Cobra, Avispa y Trueno reemplazan los modelos de cajas.
- AK con manos negras y muñequera turquesa; el resto de las armas queda solo con el modelo por ahora.
- **Bala 3D emisiva** con estela larga y velocidad legible (90 m/s).
- **Torreta de Zona 3** con base, cabezal, cañón, tambor y ojo emisivo; apunta al jugador.
- La torreta dispara desde la altura de su cañón y muestra la etiqueta a 1.75 m.

### Agregado
- **Bala 3D** con proyectil, anillo emisivo y estela corta; reemplaza el haz de luz.
- Desafío **Primer fusil** con el progreso de runs iniciadas.
- Escala y muzzle propios para cada arma integrada.

## v0.7.1 — 2026-11-22

### Corregido
- La run se **pausa automáticamente** al perder el foco de la ventana: el cronómetro deja de correr y no se vuelve a una pelea en curso.
- La zona anterior se libera **antes** de instanciar la nueva. Antes convivían ambas durante un frame, duplicando geometría, enemigos y luces en el cambio de zona.
- Las transiciones de escena reutilizan la escena ya cargada en vez de volver a leerla del disco.
- `Settings.apply_display()` ya no cambia el modo de ventana si no hace falta y respeta una ventana maximizada.

### Agregado
- El log de diagnóstico ahora distingue **stall** (con foco) de **stall_bg** (sin foco) y registra `focus`, `process_ms`, `physics_ms`, `draw_calls` y `mem_mb`.
- Se registran `zone_load` y `scene_swap` con su duración en ms.
- Se registra `save_slow` a partir de `15 ms` en vez de `30 ms`.

## v0.7.0 — 2026-11-20

### Agregado
- Buses separados **Music** y **SFX** con volúmenes independientes.
- Sliders de **Música** y **Efectos de sonido** en Configuración, además del volumen general.
- Sonido posicional de disparo para tiradores y torretas.
- Sonidos de aparición y destrucción de eventos de arena.
- Variación de tono/volumen del ambiente según la zona.
- **Dash aéreo** con una carga propia que se recupera al aterrizar.
- Indicador **AIRE ●/○** en el HUD.
- Estela turquesa y kick de FOV distintos para el dash aéreo.
- **Salto potenciado desde slide**: +25% de altura.
- Salto separado en `try_jump()` para poder testearlo y reutilizarlo.
- **Música dedicada por zona**: loops frío y oscuro para Zona 2 y 3.
- **Capa de combate** con pulso rítmico que entra con las oleadas y baja al limpiarlas.
- Crossfade de `0.6 s` entre ambientes de zona.

### Cambiado
- El disparo, los pasos, el dash, el cambio de arma, la UI y los efectos ahora se rutean a **SFX**.
- El loop ambiente se rutea a **Music**; el hub y el menú principal lo devuelven al tono neutral.
- Valores por defecto: música `80%`, efectos `100%`, master `100%`.
- El dash en el aire ahora consume una carga y no depende solo del cooldown del dash terrestre.
- La música por zona reemplaza la variación de pitch por loops dedicados.

## v0.6.1 — 2026-11-20

### Agregado
- Hitmarker en forma de X sobre la mirilla al impactar un enemigo.
- Colores por zona: cabeza dorada, torso blanco y piernas turquesa.
- Calaveras de aparición diferenciadas por tipo de enemigo, con color y nombre.
- Élite con calavera dorada más grande y etiqueta **ÉLITE**.

## v0.6.0 — 2026-11-20

### Agregado
- Jump pads que impulsan al jugador y permiten acceder a plataformas.
- Coberturas bajas, plataformas elevadas y torres en las tres zonas.
- Núcleos de arena recogibles sobre las plataformas, con toast y +1 núcleo.
- Salto corto de enemigos contra coberturas para que no queden trabados.
- Telegrafía de aparición: calavera roja, anillo y haz de luz en cada punto 2 s antes de la oleada.
- Eventos de arena por zona: Reactor de pulso, Campo de hielo y Torreta de supresión.
- Eventos destructibles con vida, etiqueta, recompensa en núcleos y toast de inicio/cierre.
- Ralentización del jugador para el Campo de hielo (el dash sigue disponible para escapar).

### Cambiado
- La dificultad dejó de ser un ciclo fijo: ahora se ajusta con botones `−` y `+` entre 1 y 10, y se puede bajar.
- El botón **Subir ciclo** pasó a **Subir dificultad**, con su par **Bajar dificultad**.
- Al cambiarla aparece un toast con vida/daño/velocidad enemiga y el multiplicador de núcleos.
- **Reloj de arena** ahora da `+8 s` por nivel (antes `+5`). Los saves viejos reciben la diferencia automáticamente.
- **Hub rediseñado** con barra de recursos, tarjeta principal de próxima run y tarjetas de Progresión, Arsenal y Objetivos.
- **Jerarquía de botones global:** acción primaria dorada, secundaria azul y acciones de texto discretas.
- Menú principal, pausa y fin de run reorganizados en tarjetas con una única acción principal.
- El tema global ahora se aplica también a menús que cuelgan de `CanvasLayer`/`Node3D` (pausa, fin de run y HUD).
- Todos los botones de volver quedaron unificados como **← Volver**.

## v0.5.1 — 2026-11-20

### Agregado
- Toasts arriba a la derecha al completar un desafío, con el desbloqueo y la condición cumplida.
- Monedas actuales (`$`) junto a los núcleos (`◈`) en el árbol, con el botón de conversión a la vista.

### Corregido
- El perfil ahora tiene el contenido desplazable y el botón **Volver** fijo arriba, siempre visible.

## v0.5.0 — 2026-11-20

### Agregado
- Log de diagnóstico `user://deadline_diag.log` con hitches de frame e hitos de fin de run, pausa y transiciones.
- Núcleos (`◈`) como moneda exclusiva del árbol de habilidades, con costos exponenciales por nivel.
- Pantalla de Desafíos con progreso, recompensas y reclamo de núcleos.
- Desafíos que desbloquean la Avispa (40 headshots) y el Trueno (completar una run).
- La tienda muestra las armas bloqueadas y su requisito.
- Conversión de `$250` a `1` núcleo desde el árbol.
- Estadísticas de headshots, élites, sabuesos y zonas en el perfil.
- Bendiciones por zona: al completar una zona se elige 1 de 3 mejoras que duran toda la run.
- Bendiciones de daño, cadencia, regeneración, vida, crítico y velocidad, acumulables.
- Indicador de bendiciones activas en el HUD.
- Ciclos de dificultad opcionales (hasta 10) con más vida, daño y velocidad enemiga.
- Grado de run `S/A/B/C` según precisión, kills y completación, con núcleos extra.
- Ciclo y mejor grado visibles en el hub, el perfil y el fin de run.
- Zona 3 violeta con oleadas `5 / 6 / 4` y seis puntos de aparición.
- Enemigo tirador: mantiene distancia, strafea y dispara proyectiles telegrafiados con un ojo brillante.
- Élite tirador con más vida, cadencia y barra de élite.
- Proyectiles enemigos visibles que se destruyen contra paredes y enemigos.
- Bonus de **+10 s** al completar cada zona.
- Sabueso explosivo con mecha telegrafiada y explosión en área.
- Mezcla de enemigos por zona: sabuesos en Zona 2 y alternados con tiradores en Zona 3.

### Cambiado
- Timer base de `60 s` a `50 s` y bonus por zona de `+10 s` a `+5 s`.
- Migración de saves: los viejos pierden 10 s de base y conservan el tiempo comprado.
- Plata por impacto: rifle `10 → 5`, Avispa `6 → 2`, Trueno `25 → 12`.
- Bonus de completación: `50 → 35` (Zonas 1/2) y `80 → 50` (Zona 3).
- Enemigos base: velocidad `3.0 → 3.5`, daño `15 → 18`, rango `2.0 → 2.2`, cadencia `0.7 → 0.6`.
- Oleadas más seguidas: `1.2 → 0.8 s` y `1.1 → 0.7 s` en Zona 3.
- Tirador: intervalo `2.2 → 1.9`, carga `0.55 → 0.5`, proyectil `19 → 22 m/s`, daño `12 → 14`.
- Élite tirador: intervalo `1.5 → 1.3`, daño `18 → 22`.
- Élite de salto: intervalo `3.5 → 3.0`, daño `30 → 36`.
- Ejecutor: de devolver 1 bala por headshot a **25% de probabilidad de no gastar munición**.
- Dash: cooldown `0.7 → 0.9`, duración `0.14 → 0.13`.
- Slide: cooldown `0.8 → 1.0`, duración `0.45 → 0.42`.

## v0.4.0 — 2026-11-20

### Agregado
- Símbolos por nodo del árbol y tooltip lateral con descripción, nivel y pips.
- Subida de nivel haciendo click directo en el nodo.
- Tema global azul noche, dorado y turquesa para todas las pantallas.
- Transiciones con fade entre escenas, pausa, fin de run, configuración y tooltip.
- Sonidos de UI (hover/click) auto-conectados a todos los botones.
- Disparo y pasos regenerados con un timbre más suave y menos agresivo.
- HUD tematizado con paneles oscuros y etiqueta de arma.
- Dash (`Shift`), slide (`Ctrl`) y cambio de armas (`1/2/3`).
- Sonidos de dash, subida de rango y cambio de arma.
- Skins propias para rifle, SMG y escopeta con muzzle flash.
- Animación de cambio de arma en el viewmodel.
- Munición independiente por arma, sin relleno al cambiar.
- Líneas de velocidad y kick de FOV durante el dash.
- Indicador de cooldown de dash y slots de armas en el HUD.
- Tiempo entre oleadas reducido de `2.5 s` a `1.2 s`.
- Música ambiente procedural en loop continuo entre escenas.
- Sonidos posicionales de impacto, crítico y muerte, más daño al jugador.
- Chime de compra y subida de nivel.

### Corregido
- El menú de fin de run ahora libera el cursor y lo coloca sobre **Reintentar** al aparecer, así el primer click responde sin esperar a mover el mouse.
- La pausa también deja el cursor sobre **Reanudar**.
- `Transitions` ya no descarta pedidos mientras hay un fade en curso: los encola y tiene un watchdog de 3 s para liberar el overlay si una transición queda colgada.
- El guardado de fin de run se difiere al frame siguiente para no demorar el menú.

## v0.3.0 — 2026-11-19

### Agregado
- Armas con datos: daño, cadencia, cargador, munición y regeneración por segundo.
- HUD de munición con barra y contador.
- Tienda de armas con compra, equipamiento y persistencia.
- Armas nuevas: Avispa (SMG) y Trueno (escopeta slug).
- Pantalla de perfil con nombre editable y estadísticas persistentes.
- Medidor de estilo/combo con rangos D–ULTRAKILL, FOV/shake por rango y chispas en críticos.
- Árbol de habilidades rediseñado: nodo central de daño, cuatro ramas cardinales, nodos cuadrados con nivel, hover con descripción y barras de nivel 5/3/1.
- Niveles y bonus persistentes, con migración desde el árbol anterior.
- Documentos de referencia de UX y estilo Ultrakill.

## v0.2.0 — 2026-11-19

### Agregado
- Minimapa centrado en el jugador, con flechas para enemigos, verdes y élites.
- Pantalla de configuración con FOV, sensibilidad, invertir Y, tamaño de interfaz, volumen, pantalla completa, V-Sync, minimapa y dificultad.
- Acceso a configuración desde la pausa, con cambios de FOV, sensibilidad y minimapa aplicados en vivo.
- Persistencia de configuración en `user://deadline_settings.cfg`.
- Penales por muerte/abandono: 30% de la plata recaudada en la run.
- Etiqueta de penalización en la pantalla de fin de run.
- Límites físicos de arena en Zona 1 y Zona 2.
- Documentación del estado del prototipo.

### Corregido
- La espera entre oleadas ya no avanza mientras el juego está pausado.
- El timer de transición entre zonas también respeta la pausa.

### Cambiado
- Salir al hub, al menú principal o reiniciar desde la pausa cuenta como abandono/muerte.
- Cerrar el juego en plena run también aplica la penalización.
- `Borrar progreso` se movió del hub a Configuración y queda deshabilitado durante una run.

## v0.1.0 — 2026-11-19

### Agregado
- Loop central: menú, hub, run, fin de run y reintento.
- Jugador en primera persona con movimiento, cámara, salto y arma placeholder.
- Combate hitscan con hitboxes de cabeza/torso/piernas, tracer y economía por impacto.
- Vida del jugador, ataque enemigo y fin de run por muerte o timer.
- Zona 1 con oleadas, spawner y élite de salto con diana y onda de impacto.
- Zona 2 fría con enemigo verde de escudo y élite verde.
- HUD con plata, timer, vida, oleada, zona, barra de élite y mirilla.
- Tienda del hub con mejoras de timer, daño y vida.
- Guardado de progreso en `user://deadline_progress.cfg`.
- Borrado de progreso con confirmación.
- Sonidos genéricos de disparo y pasos.
- Números de daño flotantes.
