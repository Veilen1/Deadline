# 🎯 Deadline — Design Document

> **Estado del documento:** vivo y en construcción. Todo lo que está acá está sujeto a cambios durante el prototipado y el testeo. Las decisiones cerradas se marcan con ✅ y las que están abiertas o en revisión se marcan con 🟡.
>
> **Última actualización:** 20/11/2026
> **Versión:** 0.8.1 — Prototipo jugable

---

## 1. Concepto

**Arena shooter en tercera persona, en escenarios minimalistas de estética blanca, con temporizador fijo por run, economía basada en la precisión de los disparos y progresión incremental por zonas y desbloqueos.**

El jugador sobrevive oleadas de enemigos que se acercan, gana plata según dónde impacta (cabeza > torso > piernas), y vuelve al hub para invertir en armas, tiempo y habilidades que le permitan llegar más lejos en la siguiente run.

**Gancho en una línea:** *"Arena shooter minimalista donde cada headshot es plata y cada segundo cuenta. Sobreviví, mejorá, repetí."*

**Referencias de género:**
- **SUPERHOT** → estética minimalista, contraste de color, lectura clara de la acción.
- **Roguelites de arena** (tipo *Devil Daggers*, *Neon White*) → runs cortas, alta densidad de acción.
- **Incrementales** (tipo *Clicker Heroes*, *Adventure Capitalist*) → progresión numérica, prestigio, escalado.
- **Dead by Daylight** → inspiración puntual para la prueba de habilidad de recarga (adaptada a un input único, no a una barra sostenida).

---

## 2. Pilares de diseño

1. **La precisión es la moneda.** Cada impacto se traduce en plata según la zona del cuerpo. El jugador que apunta mejor progresa más rápido.
2. **El tiempo es un recurso comprable.** El temporizador es fijo por run, pero se extiende con power-ups, mejoras del árbol y decisiones tácticas dentro del combate.
3. **Las zonas son el eje de dificultad.** No se escala la vida de los enemigos; se escala su comportamiento y su composición. Cada zona introduce algo nuevo y tiene un techo claro.
4. **Cada run es una decisión de riesgo/recompensa.** El jugador puede retirarse antes de una zona y conservar lo ganado, pero pierde el bonus de completación.
5. **Legibilidad ante todo.** Colores, formas y minimapa están al servicio de que el jugador entienda qué pasa en pantalla sin perderse.

---

## 3. Bucle de juego

### 3.1 La Run

1. El jugador entra a una **zona** con un **temporizador** (base ~60s, ampliable).
2. Los **enemigos aparecen y se acercan** en tiempo real. El tiempo corre normal, sin cámara lenta.
3. El jugador **dispara en tercera persona**. El daño y la recompensa dependen de la zona de impacto:
   - **Cabeza:** daño alto, plata alta (x3)
   - **Torso:** daño medio, plata media (x1)
   - **Piernas:** daño bajo, plata baja (x0.5)
4. **Power-ups en el piso:** tiempo extra, munición, mejoras efímeras. Son visibles y hay que ir a buscarlos (riesgo/recompensa).
5. La **zona** se compone de **N oleadas**, con un **élite final** que marca el techo de dificultad.
6. La run termina cuando:
   - Se limpia la última oleada de la zona → se abre la puerta a la siguiente zona, **con bonus de completación**.
   - El jugador se retira antes → conserva lo ganado, **pierde el bonus de completación**.
   - El temporizador llega a 0 → fin de la run, sin bonus.
   - El jugador muere → fin de la run, **pierde una fracción de la plata** (ej. 30%) y conserva el resto.
7. Vuelve al **hub** con la plata ganada para invertir en el árbol.

### 3.2 Meta-progresión (entre runs)

Tres monedas con roles distintos, **no se mezclan**:

| Moneda | Se gana con... | Se gasta en... | Rol |
| :--- | :--- | :--- | :--- |
| **Plata** | Impactos en runs | Mejoras del árbol, compra de armas desbloqueadas, mejoras de armas | Táctica (run a run) |
| **XP** | Runs completadas, kills, hitos | Desbloqueo de nodos del árbol y armas | Estructural (árbol) |
| **Hitos / Logros** | Objetivos específicos (ej. "100 headshots") | Desbloqueo de armas y zonas nuevas | Aspiracional (contenido nuevo) |

---

## 4. Sistema de zonas

✅ **Decisión cerrada: las zonas son el eje de dificultad, no la vida de los enemigos.**

### 4.1 Estructura de una zona

- **Oleadas escalonadas** (3–5 por zona en el prototipo).
- **Élite final** que representa el techo de dificultad de la zona.
- **Puerta de salida** al limpiar la última oleada.
- **Retiro anticipado:** el jugador puede irse antes de la última oleada y conservar lo ganado, pero pierde el bonus de completación.
- **Velocidad de tránsito:** lento en la zona nueva, rápido en las ya desbloqueadas (mejorable en el árbol).

### 4.2 Progresión de zonas (planeado)

| Zona | Tono del ambiente | Introduce |
| :--- | :--- | :--- |
| **Zona 1** | Blanco neutro | Enemigo rojo (melee). Enseña el bucle. |
| **Zona 2** | Tono frío | Enemigo verde (se cubre) + élite. |
| **Zona 3** | Tono cálido | Enemigo azul (a distancia) + élite. |
| **Zona 4+** | Tonos más saturados/oscuros | Enemigo negro (bomba), combinaciones, élites compuestos. |

**El color del ambiente cambia con la peligrosidad.** Es una señal visual barata de producir y muy legible.

**Los enemigos nuevos se suman, no reemplazan.** Las zonas avanzadas son una mezcla de todo lo aprendido.

### 4.3 Enemigos base por color

| Color | Comportamiento | Rol táctico |
| :--- | :--- | :--- |
| **Rojo** | Se acerca a melee | Presión directa, obliga a moverse |
| **Verde** | Se cubre, aparece y desaparece | Obliga a reposicionarse y apuntar rápido |
| **Azul** | Dispara a distancia | Obliga a usar cobertura y priorizar blancos |
| **Negro** | Se inmola como bomba | Obliga a gestionar el espacio y el timing |

### 4.4 Élites (versiones exageradas del enemigo de la zona)

| Base | Élite | Comportamiento distintivo |
| :--- | :--- | :--- |
| **Rojo** | Juggernaut rojo | Más grande y lento, **salta sobre el jugador** y genera onda de choque al aterrizar. |
| **Verde** | Verde extremadamente pequeño | Difícil de ver y apuntar; se mueve rápido entre coberturas. |
| **Azul** | Azul de cadencia alta | Ráfagas de 3 tiros con precisión creciente; obliga a moverse en zigzag. |
| **Negro** | Negro que se divide | Al morir, se parte en dos bombas más chicas con explosión en cadena. |

**Los élites deben ser visualmente distintivos** (brillo, tamaño, animación de entrada). El jugador tiene que saber al instante que ese es el élite.

---

## 5. Combate y economía de precisión

- **Multiplicadores de recompensa:** cabeza x3, torso x1, piernas x0.5 (números base a tunear en prototipo).
- **Multiplicadores de daño:** cabeza x2.5, torso x1, piernas x0.6.
- **La plata se calcula por impacto, no por kill.** Un headshot que no mata igual paga.

### 5.1 Racha de headshots 🟡

- **Desbloqueo:** nodo del árbol (XP), no activa desde la run 1.
- **Funcionamiento:** 3 headshots consecutivos → multiplicador temporal de plata (ej. x1.5 durante 5s).
- **Reset:** solo se corta si el jugador **falla un disparo**. Impactar en torso o piernas no rompe la racha (decisión para no castigar la táctica).
- **Pendiente:** validar en prototipo si el multiplicador escala con más headshots o queda fijo.

---

## 6. Armas y munición

### 6.1 Progresión de armas ✅

**Desbloqueo por hito + compra + mejoras pequeñas.** Secuencia:

1. **Hito** desbloquea el acceso al arma (ej. "llegá a la zona 2", "100 headshots acumulados").
2. **Compra** con plata de runs para tenerla en el arsenal.
3. **Mejoras pequeñas** (daño, cadencia, capacidad) con plata, hasta que la siguiente arma se vuelva necesaria.

### 6.2 Munición ✅

- **Limitada por cargador y reserva.**
- **Piso de seguridad:** recarga pasiva lenta cuando no se dispara, o pistola secundaria infinita de daño bajo. El jugador nunca queda indefenso.
- **Fuentes de munición:** drops de enemigos (inmediato) + habilidad del árbol (controlado).
- **Regla de balance:** si el jugador termina una zona con más del 40% de la reserva, la zona es demasiado fácil o el cargador es demasiado grande.

### 6.3 Prueba de habilidad de recarga ✅

- **Mecánica:** al recargar, aparece un **área verde** dentro de un círculo. El jugador **aprieta en el momento justo**. El área verde se cierra automáticamente.
- **Resultado:** si acierta → recarga + bonus (ej. +20% daño por 5s). Si falla → recarga normal, sin bonus.
- **Dificultad por arma:** el tamaño del área verde varía según el arma (armas más poderosas = área más chica).
- **Desbloqueo:** nodo del árbol. Antes de desbloquearlo, la recarga es lenta y sin bonus.
- **Mejoras del árbol:** reducen el cooldown y/o agrandan el área verde.
- **Cooldown considerable** para evitar spam.

---

## 7. Árbol de habilidades

| Rama | Nodos ejemplo | Moneda |
| :--- | :--- | :--- |
| **Tiempo** | +segundos iniciales, +duración de power-ups, +drop rate | XP + plata |
| **Economía** | +% plata por headshot, +% plata general, imán de drops, **racha de headshots** | XP + plata |
| **Munición** | +capacidad, recarga pasiva más rápida, **prueba de habilidad**, -cooldown, +área verde | XP + plata |
| **Movilidad** | +velocidad de tránsito en zonas desbloqueadas, dash corto | XP + plata |
| **Armas** | Mejoras por arma (daño, cadencia, precisión) | Plata |

**El árbol tiene un techo claro** para que el **prestigio** sea la respuesta natural cuando el jugador llegue.

### 7.1 Prestigio / Rebirth 🟡 (post-prototipo)

- **Resetea:** capa de run (plata, mejoras compradas).
- **Conserva:** desbloqueos por hito y armas.
- **Otorga:** multiplicador permanente de plata o XP.
- **No está en el prototipo inicial**, pero el árbol se diseña con este techo en mente.

---

## 8. Minimapa ✅

- **Centrado en el jugador.**
- **Flechas para enemigos y power-ups** (capa de información táctica, no navegación principal).
- **Poco llamativo** por diseño: en un escenario blanco, el contraste de color de los enemigos ya hace el trabajo principal. El minimapa es el seguro, no el motor.

---

## 9. Stack técnico ✅

- **Motor:** Godot 4.x.
- **Lenguaje:** GDScript (prototipado rápido). C# si se prefiere.
- **Exportación:** `.exe` para Windows (requisito de Steam).
- **IA como par de programación:** sí para sistemas aislados (player controller, spawner, UI, hitboxes). **No** para la lógica central (timer, economía, árbol) sin entenderla.
- **Git desde el día uno.** Obligatorio, especialmente si se usan agentes de IA con acceso al proyecto.

---

## 10. Alcance del prototipo

**Objetivo:** validar el bucle central en ~2 semanas.

**Incluye:**
- Habitación blanca.
- Un enemigo (rojo) que camina hacia el jugador.
- Arma con hitboxes cabeza/torso/piernas.
- Timer de 60s.
- Tienda simple con 3 upgrades.
- Zona 1 y Zona 2 (con un enemigo nuevo en la 2 y un élite final).
- Minimapa básico.
- Sin prestigio, sin árbol completo, sin prueba de habilidad (o con una versión mínima si el tiempo lo permite).

**Fuera del prototipo:** prestigio, racha de headshots, prueba de habilidad completa, zonas 3+.

---

## 11. Decisiones abiertas 🟡

1. **Nombre del juego.** Pendiente.
2. **Multiplicadores exactos** de plata y daño (a definir en la etapa de números).
3. **Cantidad exacta de oleadas** por zona (a definir en la etapa de números).
4. **Precios de los primeros upgrades** (a definir en la etapa de números).
5. **Timer base y escalado** (a definir en la etapa de números).
6. **Comportamiento exacto de la racha de headshots** (fijo vs. escalable).
7. **Curva de prestigio** (post-prototipo).

---

## 12. Roadmap inmediato

1. **✅ Cerrar idea general** (este documento).
2. **⬜ Plan de implementación** — orden de sistemas a construir en Godot.
3. **⬜ Tabla de números del prototipo** — plata por impacto, precios, timer, oleadas.
4. **⬜ Prototipo jugable** — bucle cerrado en ~2 semanas.
5. **⬜ Testeo con 5 personas** — 10 runs cada una.
6. **⬜ Iteración según feedback.**

---

## 13. Notas

- Este documento es **de referencia y discusión**, no un contrato. Los sistemas cerrados pueden reabrirse si el prototipo demuestra que no funcionan.
- La prioridad es **validar el bucle central** antes de agregar capas de progresión complejas. Si el bucle de "disparar → ganar plata → comprar → volver a jugar" no es divertido, ningún sistema adicional lo va a salvar.
- Se recomienda mantener un **changelog de decisiones de diseño** a medida que el proyecto avance.

## 14. Estado del prototipo (v0.2.0)

> Esta sección documenta lo efectivamente implementado. El resto del documento sigue siendo el diseño de referencia.

### Cómo ejecutar

```powershell
godot --path .
```

La escena inicial es el menú principal. **F5** desde Godot abre el menú.

### Controles

| Acción | Control |
|---|---|
| Moverse | `WASD` |
| Mirar | Mouse |
| Disparar | Click izquierdo |
| Saltar | `Espacio` |
| Pausa / volver | `Escape` |

### Sistemas implementados

- **Loop completo:** menú → hub → run → fin de run → hub.
- **Combate hitscan:** raycast desde la cámara, hitboxes de cabeza/torso/piernas y tracer visual.
- **Economía:** plata por impacto según zona; multiplicadores de daño y plata.
- **Oleadas:** 3 por zona (`4`, `5`, `3` + élite), spawner con puntos de aparición.
- **Zonas:** Zona 1 blanca y Zona 2 fría, con transición, banner y timer pausado durante el cambio.
- **Élite:** enemigo grande con salto telegrafiado, diana en el piso, onda de impacto y barra de vida.
- **Enemigo verde (Zona 2):** alterna persecución y escudo; daño reducido salvo headshot.
- **Hub:** mejoras de tiempo, daño y vida con costos escalonados.
- **Guardado en disco:** plata, mejoras y tiempo; configuración separada.
- **Configuración:** FOV, sensibilidad, invertir Y, tamaño de interfaz, volumen, pantalla completa, V-Sync, minimapa y dificultad.
- **Configuración en pausa:** overlay sobre la partida, con FOV/sensibilidad/minimapa en vivo.
- **Minimapa:** radar centrado en el jugador, con flechas para enemigos y élites.
- **HUD:** plata, zona, timer, oleada, vida, barra de élite, minimapa y mirilla.
- **Audio:** disparo y pasos genéricos, generados proceduralmente.
- **Límites de arena:** paredes invisibles de 4 m y bordes visuales; no se puede caer.

### Balance actual

**Jugador**

| Stat | Valor |
|---|---:|
| Vida | 100 |
| Velocidad | 5 m/s |
| Salto | 0.9 m |
| Daño base del arma | 20 |
| Plata base por impacto | $10 |
| Cadencia | 1 disparo por click |

**Enemigos**

| Enemigo | Vida | Daño | Notas |
|---|---:|---:|---|
| Rojo | 100 | 15 / 0.7 s | Melee básico |
| Verde | 100 | 15 / 0.7 s | Escudo: 25% de daño y plata, salvo cabeza |
| Élite | 800 | 30 por salto | Salto telegrafiado, radio 3.5 m |

**Zonas**

| Dato | Valor |
|---|---:|
| Timer base | 60 s |
| Oleadas | 4 / 5 / 3 + élite |
| Espera entre oleadas | 2.5 s |
| Bonus por zona | $50 |

**Mejoras del hub**

| Mejora | Bonus | Costo base | Aumento |
|---|---:|---:|---:|
| Timer | +10 s | $50 | +$25 |
| Daño | +5 | $60 | +$30 |
| Vida | +20 | $70 | +$35 |

**Dificultad**

| Dificultad | Vida enemiga | Daño enemigo |
|---|---:|---:|
| Fácil | ×0.8 | ×0.75 |
| Normal | ×1.0 | ×1.0 |
| Difícil | ×1.25 | ×1.3 |

### Economía y penalización

- La plata es persistente entre runs.
- Morir, abandonar la run desde la pausa (hub, menú o reiniciar) o cerrar el juego en plena run aplica una **penalización del 30% de la plata recaudada en esa run**.
- El 30% se calcula sobre lo recaudado, no sobre el total acumulado. Se configura con `death_penalty` en `GameState`.
- Terminar por timer o completar las dos zonas **no** aplica penalización.
- El fin de run por muerte muestra la penalización aplicada.
- Antes de volver al lobby o reiniciar desde la pausa, se muestra un aviso con el monto exacto: “Si vuelves al lobby ahora perderás $X (30% de $Y recaudados en esta run)”.

### Guardado

| Archivo | Contenido |
|---|---|
| `user://deadline_progress.cfg` | Plata, mejoras compradas y timer base |
| `user://deadline_settings.cfg` | Ajustes de pantalla, controles, audio, HUD y dificultad |

- En Windows: `%APPDATA%\Godot\app_userdata\Deadline\`.
- No se guarda una run en curso; al reabrir se empieza desde el hub.
- `Borrar progreso` está en Configuración y pide confirmación. En pausa se deshabilita para no romper la run.

### Diagnóstico

- `user://deadline_diag.log` se reescribe en cada arranque y registra hitches de frame mayores a `350 ms` y los hitos de fin de run, pausa y transiciones.
- Los stalls se separan en `stall` (ventana con foco) y `stall_bg` (sin foco, solo si superan `1 s`), con `process_ms`, `physics_ms`, `draw_calls` y `mem_mb`. Si `process_ms` es chico y el frame es enorme, el bloqueo no está en los scripts.
- También se registran `focus`, `zone_load`, `scene_swap` y `save_slow` con su duración.
- Si el juego se traba, ese archivo permite ver en qué etapa ocurrió y cuánto duró el frame bloqueado.
- Al perder el foco en plena run se abre la pausa automáticamente: el cronómetro no corre mientras la ventana está afuera.

### Flujo de ramas y versiones

- `main`: releases estables.
- `dev`: integración de features.
- Una rama por feature: `feature/<nombre>` desde `dev`, commits atómicos, merge `--no-ff` a `dev`.
- Tags: `v0.1.0` (core loop, zonas, hub, guardado), `v0.2.0` (minimapa, configuración, penalización y límites), `v0.3.0` (tienda, perfil, estilo y árbol), `v0.4.0` (armas con skins, audio, HUD y pulido), `v0.5.0` (núcleos, desafíos, contratos, bendiciones y ciclos), `v0.5.1` (perfil desplazable, monedas en el árbol y toasts), `v0.6.0` (arenas verticales, telegrafía y eventos), `v0.6.1` (hitmarker y calaveras por tipo), `v0.7.0` (mezcla de audio, dash aéreo y combos), `v0.7.1` (pausa por foco, caché de escenas y diagnóstico), `v0.8.0` (eventos variables, pistola/AK, balas 3D y torreta) y `v0.8.1` (HUD de 4 armas y atajo 4).

### Limitaciones conocidas

- Hay tres zonas: blanca, celeste y violeta. Tienen coberturas, plataformas, torres, telegrafía de spawn y un evento de arena por zona, elegido al azar entre dos variantes.
- Hay tres armas con munición independiente y regeneración, pero no recarga manual.
- El volumen general ya no es la única perilla: hay sliders separados de música y efectos.
- Cada zona tiene su propio loop de ambiente; la capa de combate es compartida y entra con las oleadas.
- La dificultad se aplica a los enemigos que aparecen después del cambio; los ya vivos no se recalculan.
- Los élites comparten mecánicas base; la Zona 3 suma un élite tirador.
- No hay guardado de run en curso, multijugador, controller ni localización.
- No hay leaderboard ni semilla diaria; la dificultad se ajusta manualmente hasta 10.
- Los eventos de arena son uno fijo por zona; faltan variantes y combinaciones.
- Los menús y modelos son provisorios.

### Próximos pasos

1. Nuevas variantes de enemigo (torreta móvil, corredor con escudo).
2. Mezcla fina de audio y variación de la capa de combate.
3. Localización y soporte de controller.

---

## 15. v0.3.0 — Tienda, perfil, estilo y árbol

### Armas y munición

- Recurso `WeaponData` con daño, plata por impacto, alcance, cadencia, cargador, regeneración y delay de regeneración.
- Arma inicial: **Cobra** (pistola semiautomática, 18 daño, 6 disparos/s máx., 8 balas, 3.5 balas/s, delay 0.18 s). Un click por disparo.
- **AK-47** desbloqueable al terminar la primera run (20 daño, 4 disparos/s, 12 balas, regen 3/s). Es el primer desbloqueo y queda en el arsenal.
- Disparo automático manteniendo el click; la pistola exige soltar y volver a apretar.
- Cada disparo lanza una **bala 3D emisiva** con estela larga desde la boca del arma hasta el impacto; el daño sigue siendo hitscan.
- Los viewmodels son **modelos 3D** (AK-47, Cobra, Avispa, Trueno) con muzzle propio para el flash.
- La pistola Cobra tiene cooldown de `0.2 s` (~5 clicks/s) para que no se pueda spamear.
- HUD de munición: contador `actual / máximo` y barra.
- Al quedarse sin balas se puede seguir apuntando; la regeneración repone munición tras el delay.
- Los bonus de cargador/regeneración/cadencia se aplican al empezar la run.

### Árbol de habilidades

- Pantalla propia desde el hub con nodo central y cuatro ramas cardinales.
- **Núcleo de daño** central (nivel máximo 5) y, alrededor:
  - Norte: `Precisión` (3) → `Ejecutor` (1).
  - Este: `Cadencia` (5) → `Cargador` (3).
  - Sur: `Vitalidad` (5) → `Armadura` (1).
  - Oeste: `Reloj de arena` (3) → `Recarga viva` (5).
- Los nodos son cuadrados con el nivel actual; al pasar el mouse o seleccionarlos se muestra título, descripción, efecto por nivel, costo y una barra de pips 5/3/1.
- Solo se habilitan nodos adyacentes a uno ya desbloqueado.
- Los niveles y bonus se guardan; el árbol anterior se migra automáticamente.
- Los efectos se aplican al empezar la run: daño, crítico, devolución de bala, cadencia, cargador, vida, reducción de daño, tiempo y regeneración.

### UX/UI

- El árbol, la tienda y el perfil usan la dirección visual azul noche + dorado/turquesa.
- Ver `docs/UX_NOTES.md` para principios, referencias y próximos pasos.
- Pendiente: tema global en menú/pausa/configuración, transiciones y feedback de UI.

### Tienda de armas

- Accesible desde el hub.
- Armas actuales:
  - **Cobra** (pistola): 18 daño, 6/s máx., 8 balas, regen 3.5/s. Gratis e inicial, semiautomática.
  - **AK-47**: 20 daño, 4/s, 12 balas, regen 3/s. Gratis; se desbloquea al terminar la primera run.
  - **Avispa** (SMG): 12 daño, 8/s, 24 balas, regen 5/s. $260.
  - **Trueno** (escopeta slug): 55 daño, 1.1/s, 6 balas, regen 1.2/s. $420.
- Se compran con plata, se equipan y la próxima run usa el arma equipada.
- Persistencia de armas compradas y equipada.
- La UI muestra daño, cadencia, cargador y regeneración por arma.

### Perfil del jugador

- Accesible desde el menú principal.
- Nombre editable (máx. 20 caracteres).
- Estadísticas persistentes: plata actual, plata total recaudada, runs iniciadas/completadas, muertes/abandonos, veces sin tiempo, enemigos eliminados, nodos desbloqueados, armas compradas y arma equipada.
- El perfil se guarda automáticamente.

### Estilo Ultrakill

- Medidor de estilo/combo con rangos `D → ULTRAKILL`.
- Sube al impactar y matar; decae al dejar de atacar.
- HUD abajo a la derecha con rango, combo y barra.
- FOV y shake de cámara aumentan con el rango.
- Headshots críticos: chispas, estilo extra y feedback visual.
- Ver `docs/STYLE_REFERENCE.md`.

---

## 16. v0.4.0 — armas, audio y pulido

### Árbol con símbolos y tooltip

- Cada nodo tiene un **símbolo** propio: `✦` daño, `◎` precisión, `★` ejecutor, `»` cadencia, `≡` cargador, `♥` vitalidad, `◆` armadura, `◷` tiempo y `↻` regeneración.
- Al pasar el mouse por un cuadrado aparece un **tooltip lateral** con nombre, descripción, efecto por nivel, pips de nivel y costo.
- **Click directo en el cuadrado** sube de nivel. Ya no hay botón de desbloqueo arriba a la derecha.
- Los nodos muestran símbolo + nivel y cambian de color según estado.

### Tema global

- `ThemeManager` aplica un tema azul noche + dorado/turquesa a menú, hub, configuración, pausa, fin de run, tienda, árbol y perfil.
- Botones, paneles, inputs, sliders, checkboxes y barras comparten estilo y estados de hover/pressed/focus.
- El HUD de partida mantiene texto oscuro sobre la arena blanca para legibilidad; el pulido del HUD queda como deuda.

### Transiciones

- Autoload `Transitions` con fade de 0.18 s al salir y 0.25 s al entrar.
- Pausa, fin de run y configuración aparecen con fade.
- El tooltip del árbol también aparece con un fade corto.
- Todas las pantallas usan la transición; no hay cambios secos de escena.
- Si llega otro pedido durante un fade, se encola en lugar de perderse; un watchdog de 3 s libera el overlay si algo queda colgado.
- Al mostrar fin de run o la pausa, el cursor se fuerza visible y se coloca sobre el botón principal (`Input.warp_mouse`), así el primer click no se pierde.

### Sonidos

- Disparo y pasos regenerados más suaves: menos click filoso, más cuerpo grave y ruido filtrado.
- Sonidos de UI globales: hover y click automáticos en todos los botones.
- Sonidos de dash, subida de rango y cambio de arma.
- Volúmenes ajustados para que caminar/disparar no sean agresivos.
- Los sonidos de UI respetan el volumen general de Configuración.

### Audio de combate y música ambiente

- Autoload `AudioDirector`: mezcla central y respeta el volumen master de Configuración.
- **Música ambiente** procedural en loop de 8 s, con drone grave y brillo suave; suena en menús, hub y run sin cortes entre escenas.
- **Impacto** posicional al golpear enemigos, con variación de pitch y un mínimo entre repeticiones para no saturar.
- **Crítico** con campanita brillante sobre el impacto.
- **Muerte de enemigo** con caída grave y ruido.
- **Daño al jugador** con pulso sordo.
- **Compra o subida de nivel** con un chime suave de dos notas.
- Los sonidos de combate se instancian como `AudioStreamPlayer3D` en la posición del impacto y se liberan al terminar.

### HUD tematizado

- Paneles oscuros translúcidos detrás de plata/zona, timer/oleada, vida/arma/munición, barra del élite y estilo.
- Texto claro sobre panel oscuro, manteniendo legibilidad sobre la arena blanca.
- Etiqueta de arma equipada y color de munición dentro del HUD.
- Indicador de **cooldown del dash** abajo al centro, que se llena al estar listo.
- Fila de **slots de armas** (`1`, `2`, `3`) con el arma activa resaltada en dorado.

### Movimiento

- **Dash:** `Shift`, burst rápido con cooldown, shake de cámara y líneas de velocidad en primera persona.
- **Slide:** `Ctrl`, acelera y baja la cámara durante un instante.
- Ambos respetan la pausa y suenan con un whoosh suave.
- El dash suma un pequeño kick de FOV para reforzar la sensación de velocidad.

### Cambio de armas

- `1`, `2`, `3` cambian entre las armas compradas.
- La HUD muestra el arma equipada, su munición y el slot activo.
- Cada arma tiene **skin propia** (rifle, SMG y escopeta) con colores y acentos distintos.
- Al cambiar se anima el viewmodel: baja, rota y vuelve con un pequeño rebote.
- Cada disparo enciende un **muzzle flash** en la punta del arma.
- La munición es **independiente por arma**: cada cargador conserva lo que le queda y no se rellena al cambiar. La regeneración de cada arma sigue funcionando con su propia cadencia y retardo.

### Ritmo de oleadas

- El tiempo entre oleadas bajó de `2.5 s` a `1.2 s` para que la run sea más frenética.

---

## 17. Post v0.4.0 — Zona 3 y tirador

### Zona 3

- Tercera zona con estética violeta oscura, piso lavanda y seis puntos de aparición.
- Oleadas `5 / 6 / 4` con `0.7 s` entre rondas y bonus de completación de `$50`.
- **Tirador:** enemigo violeta con cabeza naranja que mantiene distancia (`6–11 m`), strafea y dispara proyectiles.
- Antes de disparar se detiene y enciende un **ojo naranja** que crece durante `0.5 s`: esa es la ventana para atacarlo o esquivar.
- Los proyectiles son esferas naranjas que viajan a `22 m/s`, dañan al impactar y se destruyen contra paredes o enemigos.
- **Élite tirador:** escala `1.5`, `700` de vida, dispara más seguido y alimenta la barra de élite del HUD.

### Bonus de tiempo

- **Completar una zona otorga +5 s** de timer para la siguiente. El bonus se aplica antes de la transición y se puede ajustar con `zone_time_bonus` en `main.gd`.
- El bonus hace sostenible una run de tres zonas con el timer base de la run.

---

## 18. Balance v0.5 — más presión, menos margen

### Timer y economía

- Timer base `60 → 50 s`; bonus por zona `+10 → +5 s`. Una run completa pasa de `80` a `60 s` de timer efectivo.
- Migración de saves: los guardados viejos restan `10 s` al timer base y conservan el tiempo comprado.
- Plata por impacto: rifle `10 → 5`, Avispa `6 → 2`, Trueno `25 → 12` (los headshots siguen multiplicando ×3).
- Bonus de completación: `50 → 35` en Zonas 1/2 y `80 → 50` en Zona 3.

### Enemigos y oleadas

- Enemigos base: velocidad `3.0 → 3.5`, daño melee `15 → 18`, rango `2.0 → 2.2` y cadencia `0.7 → 0.6`.
- Oleadas más seguidas: `1.2 → 0.8 s` en Zonas 1/2 y `1.1 → 0.7 s` en Zona 3.
- Tirador: intervalo `2.2 → 1.9`, carga `0.55 → 0.5`, proyectil `19 → 22 m/s` y daño `12 → 14`.
- Élite tirador: intervalo `1.5 → 1.3` y daño `18 → 22`.
- Élite de salto: intervalo `3.5 → 3.0` y daño `30 → 36`.

### Sabueso explosivo

- `45` de vida y velocidad `6.0`: más rápido que el jugador caminando.
- Corre directo y al entrar en `2.6 m` enciende una **mecha de `0.45 s`** con luz roja.
- Detona en un radio de `3.0 m` por `26` de daño. Si lo matás antes, no explota.
- Se mezcla en Zona 2 (1 de cada 3 enemigos) y en Zona 3 (alternado con tiradores).

### Ejecutor

- Ya no devuelve una bala por headshot: ahora tiene **25% de probabilidad de no gastar munición**.
- El tooltip muestra el porcentaje real.

### Movimiento

- Dash: cooldown `0.7 → 0.9`, duración `0.14 → 0.13`.
- Slide: cooldown `0.8 → 1.0`, duración `0.45 → 0.42`.
- La intención es que esquivar sea una decisión y no un estado permanente.

---

## 19. v0.5.0 — Progresión y rejugabilidad

### Núcleos

- `◈ Núcleos` es la moneda exclusiva del árbol de habilidades. La plata queda para armas y la conversión.
- Se ganan `+1` por élite, `+1` por zona completada y `+3` por run completada, más contrato y grado.
- Los costos del árbol son exponenciales (`×1.35` por nivel).
- **Reloj de arena** suma `+8 s` de timer base por nivel; los saves viejos reciben la diferencia automáticamente.
- Conversión manual de `$250 → ◈1` desde el árbol para darle uso a la plata sobrante.
- Los saves viejos conservan sus niveles; la economía nueva empieza desde cero.

### Desafíos

- Pantalla propia desde el hub con progreso, recompensa y botón de reclamo.
- **Avispa:** se desbloquea con `40 headshots`.
- **Trueno:** se desbloquea al completar una run.
- Desafíos de núcleos por élites, sabuesos, zonas, headshots y runs completadas.
- La tienda muestra las armas bloqueadas, su requisito y el progreso actual.
- Al completar un desafío aparece un **toast arriba a la derecha** con el desbloqueo y la condición cumplida. Los desafíos de núcleos avisan que la recompensa se reclama desde la pantalla.
- Las estadísticas quedan en el perfil, que ahora es desplazable con el botón **Volver** fijo.

### Contratos

- Antes de jugar se eligen 3 contratos aleatorios o una run estándar.
- Modificadores disponibles: velocidad enemiga, daño recibido, regeneración de munición, timer inicial, vida máxima, vida enemiga y daño enemigo.
- Pagan `+2` o `+3` núcleos **solo si se completa la run**.

### Bendiciones

- Al completar una zona (excepto la última) se elige **1 de 3** mejoras que duran el resto de la run.
- Daño `+15%`, cadencia `+12%`, regeneración `+1.5/s`, vida `+20`, crítico `+15%` y velocidad `+10%`.
- Se acumulan si se repite la misma y se muestran en el HUD.

### Ciclos y grado

- La **dificultad** se ajusta con `−` y `+` desde el hub, entre 1 y 10, y **no es permanente**: podés bajarla cuando quieras.
- Cada nivel suma `+12%` vida enemiga, `+8%` daño enemigo, `+4%` velocidad y `+25%` núcleos al completar.
- Al cambiarla aparece un toast con los porcentajes y el multiplicador de núcleos.
- El **grado de run** (`S/A/B/C`) sale de la precisión, las kills y si se completó.
- `S/A/B` pagan `3/2/1` núcleos extra; el mejor grado queda guardado.
- La dificultad se ajusta con botones `−` y `+` (1–10) y no es definitiva; cada cambio muestra un toast con vida/daño/velocidad enemiga y el multiplicador de núcleos.

### Diagnóstico

- `user://deadline_diag.log` registra frames de más de `350 ms` y los hitos de fin de run, pausa y transiciones.
- Sirve para revisar un freeze con el estado exacto del juego.

---

## 20. v0.5.1 — perfil, monedas y toasts

- El perfil ahora tiene scroll y la barra superior fija con **Volver** siempre visible.
- El árbol muestra `$` (plata) y `◈` (núcleos) juntos para evaluar la conversión.
- Los desafíos completados disparan un **toast arriba a la derecha** con el desbloqueo y la condición cumplida.
- Los toasts no se repiten y no avisan armas que ya estaban compradas antes.

---

## 21. v0.6.0 — arenas verticales, telegrafía y eventos

### Jump pads

- Nuevo `JumpPad`: al pisarlo lanza al jugador hacia arriba con un pequeño empuje hacia el `-Z` local.
- El jugador conserva el impulso vertical aunque esté en el piso (`launch()` en `player.gd`).
- Sonido, luz y pulso visual teal para leerlos rápido.
- El empuje horizontal se puede orientar rotando el pad en cada arena.

### Identidad física por zona

- **Zona 1:** cuatro coberturas bajas de `0.8 m`, un jump pad central y un núcleo sobre una cobertura.
- **Zona 2:** plataforma elevada de `1.2 m` con núcleo, jump pad de acceso y coberturas alrededor.
- **Zona 3:** dos torres de `2.4 m` con núcleos, jump pads laterales y coberturas para cortar línea de tiro.
- Todas las piezas usan `arena_block` y `arena_platform`, reutilizables y escalables.

### Núcleos de arena

- `CorePickup`: esfera dorada que gira y flota sobre las plataformas.
- Al recogerla da `+1 ◈`, muestra un toast y se elimina hasta la próxima run.
- Premia usar la verticalidad sin frenar la acción.

### Enemigos y coberturas

- Los enemigos hacen un **salto corto** al chocar con coberturas bajas para no quedar trabados.
- Tiradores y sabuesos usan la misma lógica de escalada.
- Las torres de Zona 3 siguen siendo riesgosas porque los tiradores disparan desde el piso.

### Telegrafía de aparición

- Antes de cada oleada se marcan los puntos de aparición con una **calavera roja**, un anillo y un haz de luz.
- Los enemigos salen **2 segundos después**; el HUD muestra la oleada al empezar el aviso.
- Aplica también a la primera oleada de cada zona y al élite.
- Si la run termina durante el aviso, los enemigos no llegan a spawnear.

### Eventos de arena

- Cada zona elige **al azar entre dos variantes** al empezar la run; la identidad de color se mantiene.
- **Zona 1 — Reactor inestable:** `150` de vida; pulsa `8` de daño cada `3 s` en un radio de `6 m`. Recompensa `+2 ◈`.
- **Zona 1 — Fábrica de minas:** `190` de vida; suelta `2` minas cada `3.4 s` que se arman en `0.9 s` y explotan al acercarte (`20` de daño, radio `3.4 m`). Recompensa `+3 ◈`.
- **Zona 2 — Campo de hielo:** `200` de vida; ralentiza al jugador al `60%` dentro de `7 m`. El dash sigue permitiendo escapar. Recompensa `+2 ◈`.
- **Zona 2 — Ancla gravitatoria:** `200` de vida; cada `2.6 s` tira del jugador hacia el núcleo dentro de `9 m`. El empuje se disipa en menos de medio segundo. Recompensa `+3 ◈`.
- **Zona 3 — Torreta de supresión:** `220` de vida; dispara proyectiles cada `1.4 s`. Recompensa `+3 ◈`.
- **Zona 3 — Núcleo sanitario:** `170` de vida; cura `22` de vida a los enemigos dentro de `8 m` cada `2.4 s`, con un `+N` verde. Recompensa `+3 ◈`.
- Se pueden destruir disparándoles y muestran nombre y vida en una etiqueta 3D.
- Al aparecer y al destruirse muestran un toast; su vida/daño escalan con dificultad, ciclo y contrato.
- El **minimapa** marca cada evento con un rombo del color del evento para priorizar objetivos.

---

## 22. Rediseño de menús

### Jerarquía visual

- **Primario (dorado):** una sola acción importante por pantalla: `JUGAR`, `Reanudar`, `Reintentar`, `Empezar run`.
- **Secundario (azul):** acciones de apoyo: configuración, perfil, dificultad, abrir tienda/árbol, comprar.
- **Texto (sin caja):** salir, volver al hub/menú, navegación de bajo peso.
- Los botones primarios tienen borde dorado y texto claro; los secundarios borde azul y hover turquesa.

### Hub

- Barra superior con título y recursos en tarjetas de **Plata** y **Núcleos**.
- Tarjeta principal **Siguiente run** con contrato, dificultad, timer, bonos y el CTA `JUGAR`.
- Tarjetas laterales de **Progresión**, **Arsenal** y **Objetivos** con icono, descripción y acción.
- Barra inferior con atajos y acceso discreto al menú principal.

### Otras pantallas

- Menú principal, pausa y fin de run ahora viven en una tarjeta con una única acción principal.
- Todas las pantallas usan el mismo header: título, recursos y **← Volver**.
- El tema global se propaga también a los menús dentro de la partida (CanvasLayer/Node3D), no solo a las escenas de UI.

---

## 23. v0.6.1 — hitmarker y telegrafía por tipo

### Hitmarker

- Una **X sobre la mirilla** confirma cada impacto en enemigos.
- Color por zona del cuerpo:
  - **Cabeza:** dorado, con un pequeño golpe de escala extra.
  - **Torso:** blanco.
  - **Piernas:** turquesa.
- Se desvanece en `0.22 s`, tiene contorno oscuro para leerse sobre la arena blanca y se reinicia con cada impacto.

### Calaveras por tipo

- Cada enemigo tiene su calavera en el punto exacto donde va a aparecer, con color y nombre:
  - **BÁSICO** rojo.
  - **GUARDIA** verde.
  - **TIRADOR** violeta.
  - **SABUESO** naranja.
  - **ÉLITE** dorado, más grande.
- El anillo, el haz de luz y la luz del aviso usan el mismo color.
- Sigue habiendo 2 segundos entre el aviso y la aparición.

---

## 24. Audio y mezcla

### Buses y sliders

- Buses independientes **Music** y **SFX**, ambos enviados al Master.
- Configuración ahora tiene tres controles:
  - **Volumen general**.
  - **Música** (default `80%`).
  - **Efectos de sonido** (default `100%`).
- El loop ambiente va a **Music**; disparos, pasos, dash, armas, UI, impactos y eventos van a **SFX**.
- Los sliders aplican en el acto y se guardan en `deadline_settings.cfg`.

### Sonidos nuevos

- **Disparo enemigo**: los tiradores y la torreta de Zona 3 ahora tienen un zap posicional propio.
- **Aparición de evento**: alarma grave al aparecer un reactor, campo o torreta.
- **Destrucción de evento**: boom grave al romperlo.
- **Ambiente por zona**: el loop cambia de tono y sube un poco de volumen en Zona 2 y 3; el hub/menú vuelven al tono neutral.

### Música por zona y capa de combate

- **Menú/Zona 1:** drone neutro original.
- **Zona 2:** pad frío con shimmer alto.
- **Zona 3:** drone oscuro con segunda menor y pulso lento.
- Dos reproductores de ambiente hacen **crossfade de 0.6 s** al cambiar de zona.
- Una **capa de combate** a `90 BPM` entra con cada oleada y baja cuando la limpiás; suma presión sin tapar los SFX.
- El hub y el menú principal vuelven al loop neutro y apagan la capa de combate.

---

## 25. Dash aéreo y combos

- El dash ahora distingue suelo y aire:
  - **Suelo:** velocidad `16`, duración `0.13` y cooldown `0.9`.
  - **Aire:** velocidad `18`, duración `0.16`, una carga por salto y cooldown corto de `0.35`.
- La carga aérea se recupera al tocar el piso.
- El HUD muestra **AIRE ●/○** junto al medidor de dash; se apaga cuando no queda carga.
- La estela y el FOV cambian a turquesa/cian y a un kick más fuerte en el aire.
- **Salto desde slide:** +25% de altura, corta el slide y deja un pequeño kick de FOV.
- El sonido del dash aéreo sube de tono para diferenciarlo.

---

## 26. Enemigos 3D, élites y pilares

### Modelos y animaciones

- Los cuatro enemigos humanoides y el sabueso usan modelos 3D riggeados en Blender.
- **Básico:** `Idle`, `Walk`, `Attack`, `Hit`, `Death`.
- **Guardia:** las anteriores más `Guard`, con escudo físico a dos manos.
- **Cowboy/tirador:** las anteriores más `Shoot`, con capa animada por huesos (`cape_1/2/3`).
- **Sabueso:** rig cuadrupedal con cola, cuatro patas y mecha; `Idle`, `Run`, `Fuse`, `Hit`, `Death`.
- Todos miran al jugador en el plano, caminan/corren hacia él y se desploman al morir antes de liberarse.
- La mecha del sabueso queda encendida siempre; al entrar en rango se agranda el brillo rojo y detona.

### Élites

- **Verdugo (Zona 1):** salto telegrafiado con diana en el piso y onda de impacto; a media vida entra en furia y salta más seguido.
- **Bastión (Zona 2):** embestida con escudo. Marca la carga con la burbuja encendida, arranca en línea recta y cierra con una onda; el escudo reduce el daño al cuerpo salvo en la cabeza.
- **Alcaide (Zona 3):** ráfaga de tres proyectiles en abanico, con el mismo telegraph del tirador.
- Cada élite tiene armadura procedural propia y tinte dorado: cuernos y púas (verdugo), cresta y hombreras grandes (bastión), ala de sombrero, bandolera y tercer ojo (alcaide).
- Los tres alimentan la barra de élite del HUD y comparten la etiqueta `ELITE`.

### Pilares

- Tres variantes de pilar reemplazan parte de las coberturas planas:
  - **Columna** redonda con basa, capitel y anillo dorado.
  - **Obelisco** cuadrado con runas emisivas en las cuatro caras.
  - **Columna rota** baja, con escombros y remate irregular.
- La colisión de cada pilar coincide con su silueta (cilindros y cajas), incluida la basa y el remate.

---

## 27. Altares de evento

- Cada evento de arena tiene ahora un modelo propio, salvo la torreta que conserva su glb:
  - **Reactor inestable:** núcleo vertical con anillos, aletas metálicas y remate.
  - **Campo de hielo:** cristal doble con anillos orbitales y basa de piedra.
  - **Fábrica de minas:** horno bajo con banda emisiva, tolva, chimenea y rampa de salida.
  - **Ancla gravitatoria:** basa con tres postes y núcleo flotante rodeado por anillos.
  - **Núcleo sanitario:** orbe verde con cruz y anillos sobre un pedestal.
- Las piezas emisivas respiran con una pulsación suave; los anillos de hielo, ancla y cura giran.
- La colisión deja de ser una única caja genérica: cada altar usa cilindros, esferas y cajas alineadas con su silueta, incluidas la basa, la chimenea y la rampa.

### Cierre de zona

- Al morir el último enemigo de una zona, el juego espera `0.7 s` antes de abrir la bendición o el resumen de fin de run; así la muerte se ve completa y la pausa no aparece como un congelamiento.
- La pantalla de bendición muestra una cuenta regresiva de `10 s`; si no recibe ninguna elección, toma la primera opción para evitar que la run quede trabada.
- La torreta y su colisión quedan como estaban.

### Renderer

- En Windows el juego usa **Vulkan** (con fallback a D3D12/OpenGL). D3D12 provocaba stalls largos en los cierres de zona y en Reintentar; Vulkan, con caché de pipelines, no los reproduce.

---

*Documento vivo. Cualquier cambio de dirección debe reflejarse acá.*