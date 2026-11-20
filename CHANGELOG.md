# Changelog

Todas las versiones relevantes del prototipo.

## No publicado

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
