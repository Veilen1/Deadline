# Changelog

Todas las versiones relevantes del prototipo.

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
