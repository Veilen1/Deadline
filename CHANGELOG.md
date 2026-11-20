# Changelog

Todas las versiones relevantes del prototipo.

## No publicado

### Agregado
- Armas con datos: daño, cadencia, cargador, munición y regeneración por segundo.
- HUD de munición con barra y contador.
- Árbol de habilidades con nodos, conexiones y desbloqueo por adyacencia.
- Nodos de daño, vida, timer, cadencia, cargador y regeneración de munición.
- Documento de notas de UX/UI y referencias.

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
