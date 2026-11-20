# 🎯 Deadline — Design Document

> **Estado del documento:** vivo y en construcción. Todo lo que está acá está sujeto a cambios durante el prototipado y el testeo. Las decisiones cerradas se marcan con ✅ y las que están abiertas o en revisión se marcan con 🟡.
>
> **Última actualización:** 19/11/2026
> **Versión:** 0.1 — Pre-prototipo

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

### Flujo de ramas y versiones

- `main`: releases estables.
- `dev`: integración de features.
- Una rama por feature: `feature/<nombre>` desde `dev`, commits atómicos, merge `--no-ff` a `dev`.
- Tags: `v0.1.0` (core loop, zonas, hub, guardado) y `v0.2.0` (minimapa, configuración, penalización y límites).

### Limitaciones conocidas

- Solo hay dos zonas.
- No hay variedad de armas, munición ni recarga.
- El volumen es general; no hay sliders separados de música/efectos.
- La dificultad se aplica a los enemigos que aparecen después del cambio; los ya vivos no se recalculan.
- Los élites comparten el patrón de salto; los enemigos verdes son los únicos con escudo.
- No hay guardado de run en curso, multijugador, controller ni localización.
- Los menús y modelos son provisorios.

### Próximos pasos

1. Zona 3 y nuevas variantes de enemigo.
2. Armas, munición y recarga.
3. Música y sliders separados de audio.
4. Balance fino con la dificultad y los costos del hub.
5. Localización y soporte de controller.

---

## 15. v0.3.0 — Tienda, perfil, estilo y árbol

### Armas y munición

- Recurso `WeaponData` con daño, plata por impacto, alcance, cadencia, cargador, regeneración y delay de regeneración.
- Arma inicial: **Rifle básico** (20 daño, 4 disparos/s, 12 balas, 3 balas/s, delay 0.25 s).
- Disparo automático manteniendo el click y respuesta inmediata al click.
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
  - **Rifle básico**: 20 daño, 4/s, 12 balas, regen 3/s. Gratis e inicial.
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

## 16. Post v0.3.0 — iconografía, tema global, transiciones y sonidos

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

### Sonidos

- Disparo y pasos regenerados más suaves: menos click filoso, más cuerpo grave y ruido filtrado.
- Sonidos de UI globales: hover y click automáticos en todos los botones.
- Sonidos de dash, subida de rango y cambio de arma.
- Volúmenes ajustados para que caminar/disparar no sean agresivos.
- Los sonidos de UI respetan el volumen general de Configuración.

### HUD tematizado

- Paneles oscuros translúcidos detrás de plata/zona, timer/oleada, vida/arma/munición, barra del élite y estilo.
- Texto claro sobre panel oscuro, manteniendo legibilidad sobre la arena blanca.
- Etiqueta de arma equipada y color de munición dentro del HUD.

### Movimiento

- **Dash:** `Shift`, burst rápido con cooldown y shake de cámara.
- **Slide:** `Ctrl`, acelera y baja la cámara durante un instante.
- Ambos respetan la pausa y suenan con un whoosh suave.

### Cambio de armas

- `1`, `2`, `3` cambian entre las armas compradas.
- La HUD muestra el arma equipada y la munición correspondiente.
- El cambio rellena el cargador del arma nueva (provisorio para el prototipo).

---

*Documento vivo. Cualquier cambio de dirección debe reflejarse acá.*