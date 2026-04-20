# Modelo Rumor AC


## Descripcion
Observar el ciclo de vida de un rumor (nacimiento, expansión y declive) dentro de una población estática.

---

## Estados de las celdas
| Estado | Valor interno | Color |
|---|---|---|
| Ignorante | `0` | Verde |
| Chismoso | `1` | Rojo |
| No chismoso | `2` | Amarillo |

---
## Reglas del autómata

### Vecindario
Moore

## Reglas y Transiciones de Estado
 
### Ignorante (0) -> Chismoso (1)
 
```
k = vecinos_chismosos / 8
P = 1 - (1 - B)^k        donde B = 0.5
```
A más vecinos chismosos, mayor probabilidad de contagio.
---
 
### Ignorante (0) -> No chismoso (2) *(salto directo)*
 
Si la regla anterior **no se cumple** pero `k > 0`:
 
```
P = 0.05
```
 
La persona escucha el rumor pero decide no repetirlo.
 
---
### Chismoso (1) -> No chismoso (2)
El rumor pierde novedad cuando el vecindario ya está saturado:
```
P = vecinos_chismosos / 8
```
 
---

### Parametros ajustables
| Parametro | Descripción | Valor por defecto | Rango |
|---|---|---|---|
| `B` | Probabilidad de convertirse en vecino chismoso | `0.30` | `[0.0, 1.0]` |
| `G` | Probabilidad de volverse en vecino no chismoso | `0.10` | `[0.0, 1.0]` |

---
## Controles
| Acción | Efecto |
|---|---|
| Clic | Marca la celda como chismoso |
| `SPACE` | Pausa / reanuda la simulación |
| `R` | Reinnicia la simulación |
