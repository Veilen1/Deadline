# Estilo tipo Ultrakill — referencia y decisiones

> La búsqueda web no está disponible en este entorno. Estas notas se basan en mecánicas conocidas de Ultrakill y en referencias de acción rápida (Devil May Cry, Doom Eternal, Bulletstorm): combos, rangos, feedback y castigo por inactividad.

## Qué buscamos

- **Hiperactividad:** el juego premia atacar rápido, encadenar golpes y no quedarse quieto.
- **Estilo visible:** un medidor de combo/rango que sube al pegar y decae si el jugador deja de atacar.
- **Cámara reactiva:** FOV y shake aumentan en rangos altos; el jugador “siente” el combo.
- **Críticos con impacto:** headshots con números más fuertes, chispas y bonus de estilo.
- **Legibilidad:** el estilo no debe tapar la acción ni la munición.

## Implementación actual

- Autoload `StyleSystem`.
- Puntos por impacto: `daño * 0.1`; +2.5 extra en headshot.
- Puntos por kill: +4.
- Combo: sube con cada impacto/kill; si pasan 2.6 s sin atacar, vuelve a 0 y los puntos decaen 3.5/s.
- Rangos: `D, C, B, A, S, SS, SSS, ULTRAKILL`.
- Umbrales: `0, 6, 14, 26, 42, 64, 92, 130`.
- HUD abajo a la derecha: rango, combo (`S · x12`) y barra de progreso del rango.
- Cámara: FOV base + 1.6° por rango; shake corto al subir de rango.
- Críticos: headshot emite `critical_hit`, genera chispas y suma estilo extra.
- El estilo es por run y se reinicia al empezar.

## Referencias de diseño

- **Ultrakill:** estilo/rank, velocidad, feedback constante, feedback de armas y muertes.
- **Devil May Cry:** rangos de estilo y castigo por repetir/pausar.
- **Doom Eternal:** feedback de disparo, munición y presión constante.
- **Bulletstorm:** puntos por creatividad/combos.

## Próximas iteraciones

1. Dash/slide y movimiento más vertical para acompañar la hiperactividad.
2. Cambio de armas en run (1/2/3) y combos por arma.
3. Efectos de pantalla por rango: viñeta, aberración cromática sutil, sangre/chispas.
4. Bonus de estilo por variedad (headshots, kills, armas distintas).
5. Sonidos de subida de rango y feedback de crítico.
6. Ajustar umbrales y decaimiento con testeo real.
