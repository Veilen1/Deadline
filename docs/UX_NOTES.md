# Notas de UX/UI y referencias

> La búsqueda web no está disponible en este entorno. Estas notas se basan en principios de usabilidad y en patrones conocidos de juegos como Hades, Doom Eternal, Dead Cells, Call of Duty, Vampire Survivors y Deep Rock Galactic.

## Principios generales

- **Legibilidad antes que decoración.** El jugador tiene que entender estado, amenaza y próxima acción en menos de un segundo.
- **Una acción primaria por pantalla.** `Jugar`, `Desbloquear`, `Volver`. El resto son secundarias.
- **Feedback inmediato.** Cada click debe cambiar algo visible: color, sonido, número, barra o texto.
- **Prevención de errores.** Acciones destructivas con confirmación y consecuencias exactas (ej. “perderás $30”).
- **Consistencia.** Mismos colores para los mismos estados: bloqueado, disponible, desbloqueado, peligro.
- **Transiciones cortas.** 150–250 ms para cambios de pantalla y aparición de popups; nunca bloquear al jugador más de lo necesario.
- **Pausa segura.** Menús y avisos deben congelar la run y no permitir dobles acciones.
- **Contraste y accesibilidad.** No depender solo del color; usar texto, forma y posición.

## Menús y navegación

- Jerarquía clara: menú principal → hub → árbol/tienda → run.
- Foco visible y navegación con teclado.
- Confirmaciones para salir de una run, borrar progreso y compras caras.
- Mostrar costos y estado actual antes de comprar.
- Evitar pantallas que se reemplacen sin transición; usar fundidos o desplazamientos suaves.

## Árbol de habilidades

- **Adyacencia espacial:** un nodo solo se habilita si está conectado a uno desbloqueado.
- **Tres estados visibles:** bloqueado, disponible, desbloqueado.
- **Detalle al seleccionar:** título, descripción, efecto numérico, costo y estado.
- **No ocultar requisitos.** Las líneas y los estados deben explicar por qué un nodo está bloqueado.
- **Pocos nodos por pantalla.** Ramas con 2–4 nodos para que se lea el conjunto.
- **Feedback de compra:** el nodo cambia de estado, el dinero baja y aparece un mensaje breve.
- **Referencia:** Hades (claridad de elección), Dead Cells (meta-árbol), Vampire Survivors (elección de mejora).

## Armas y combate

- **Munición legible:** contador y barra visibles, cerca del HUD central/derecho.
- **Cadencia perceptible:** sonido, tracer, animación y daño acompañan cada disparo.
- **Regeneración con ritmo:** pausa breve después de disparar y recarga visible; el jugador entiende por qué no puede disparar.
- **Estados de fallo:** sin balas, bloqueado, sin plata. Nunca un click “muerto” sin explicación.
- **Referencia:** Doom Eternal (feedback de arma/munición), Call of Duty (HUD y cadencia), FPS modernos.

## Dirección visual propuesta

- Paleta principal: azul noche (`#0b1320`), dorado (`#f2c14e`), turquesa (`#4fd1c5`) y gris azulado para lo bloqueado.
- Superficies en capas: fondo, panel, tarjeta, acento. Evitar blanco y negro planos.
- Animaciones cortas: fade/scale de 150–250 ms; pulso suave en nodos y botones.
- El árbol usa esta dirección y el tema ya se extendió a menú, hub, pausa, configuración, tienda y perfil.

## Lectura del HUD y del viewmodel

- El HUD usa paneles oscuros translúcidos sobre la arena blanca para sostener contraste sin tapar la acción.
- La información de armas vive arriba a la derecha; abajo al centro quedan los slots y el medidor de dash, y abajo a la derecha el estilo.
- El minimapa ocupa la esquina inferior izquierda para no competir con los indicadores de combate.
- Cada arma tiene una silueta y una paleta propia; el cambio se anima para que el jugador registre qué equipó.
- El dash se comunica con líneas de velocidad, kick de FOV y un medidor que se recarga.

## Próximas tareas de UX/UI

1. **Eventos de arena:** terminales, compuertas o zonas a defender sin frenar la acción.
2. **Mapas:** seguir iterando layouts verticales y legibilidad de plataformas.
3. **Menús:** jerarquía primaria/secundaria aplicada; falta testear navegación con teclado/controller y resoluciones chicas.
4. **Audio:** sliders separados de música/efectos y mezcla por zona.
5. **Movimiento:** dash aéreo y combos de slide/salto.
6. **Contenido:** torreta fija y nuevas variantes de enemigo.
