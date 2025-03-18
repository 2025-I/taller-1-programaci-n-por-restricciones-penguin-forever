# Modelado del Sudoku como un Problema de Satisfacción de Restricciones (CSP)

## 1. Definición del Modelo CSP

### 1.1. Variables del Problema
En el Sudoku, cada celda de la cuadrícula \(9 \times 9\) representa una variable. Estas variables se denotan como:  

$X_{i,j} \quad \text{con} \quad i, j \in \{1, 2, \ldots, 9\}$

donde $i$ indica la fila y $j$ la columna. **Total de variables**: $81$.

### 1.2. Dominios
Cada variable $X_{i,j}$ puede tomar valores del conjunto:  

$D(X_{i,j}) = \{1, 2, 3, 4, 5, 6, 7, 8, 9\}$

Si una celda tiene un valor predefinido, su dominio se restringe únicamente a ese valor.

### 1.3. Restricciones
Las restricciones garantizan que no se repitan números en filas, columnas ni subcuadrículas \(3 \times 3\):  

1. **Restricciones de fila**:  

$\forall i \in \{1, \ldots, 9\}, \; \text{alldifferent}(X_{i,1}, X_{i,2}, \ldots, X_{i,9})$

2. **Restricciones de columna**:  

$\forall j \in \{1, \ldots, 9\}, \; \text{alldifferent}(X_{1,j}, X_{2,j}, \ldots, X_{9,j})$

3. **Restricciones de subcuadrícula**:  
Para cada bloque $B_{k,l}$ donde $k, l \in \{1, 2, 3\}$:
$\text{alldifferent}(X_{3k-2, 3l-2}, X_{3k-2, 3l-1}, \ldots, X_{3k, 3l})$

---

## 2. Implementación en MiniZinc

### 2.1. Código del Modelo (`sudoku.mzn`)
```minizinc
% Solución de Sudoku con MiniZinc

% Función para evaluar diferencias
include "alldifferent.mzn";

set of int: DOMAIN = 1..9;  % Números del 1 al 9


% Definición del array bidimensional del archivo .dzn
array[DOMAIN, DOMAIN] of int: exampleSudokuBoard; 


% Definición del tablero donde se calculará la solución
array [DOMAIN, DOMAIN] of var DOMAIN: solvedSudokuBoard;


% Restricciones para asegurar que los valores en cada fila y columna sean únicos
constraint forall(i in DOMAIN)
    (alldifferent([solvedSudokuBoard[i, j] | j in DOMAIN]));
    
constraint forall(i in DOMAIN)
    (alldifferent([solvedSudokuBoard[j, i] | j in DOMAIN]));
    
    
% Definición de los rangos para las subcuadrículas de 3x3
set of int: BLOCK1 = 1..3;  % Primer bloque de filas/columnas (1-3)
set of int: BLOCK2 = 4..6;  % Segundo bloque de filas/columnas (4-6)
set of int: BLOCK3 = 7..9;  % Tercer bloque de filas/columnas (7-9)


% Restricciones para asegurar que los valores en cada subcuadrícula de 3x3 sean únicos
constraint alldifferent([solvedSudokuBoard[i,j] | i in BLOCK1, j in BLOCK1]);
constraint alldifferent([solvedSudokuBoard[i,j] | i in BLOCK1, j in BLOCK2]);
constraint alldifferent([solvedSudokuBoard[i,j] | i in BLOCK1, j in BLOCK3]);
constraint alldifferent([solvedSudokuBoard[i,j] | i in BLOCK2, j in BLOCK1]);
constraint alldifferent([solvedSudokuBoard[i,j] | i in BLOCK2, j in BLOCK2]);
constraint alldifferent([solvedSudokuBoard[i,j] | i in BLOCK2, j in BLOCK3]);
constraint alldifferent([solvedSudokuBoard[i,j] | i in BLOCK3, j in BLOCK1]);
constraint alldifferent([solvedSudokuBoard[i,j] | i in BLOCK3, j in BLOCK2]);
constraint alldifferent([solvedSudokuBoard[i,j] | i in BLOCK3, j in BLOCK3]);


% Restricción para asegurar que los valores predefinidos en el tablero inicial se mantengan en la solución
constraint forall(i,j in DOMAIN) (
    if exampleSudokuBoard[i,j] != 0 
      then solvedSudokuBoard[i,j] = exampleSudokuBoard[i,j]
    else true
    endif
);
        
        
solve satisfy;


output [ show(solvedSudokuBoard[i, j]) ++ (if j == 9 then "\n" else " " endif) | i in DOMAIN, j in DOMAIN ];
```

## 3. Estrategias de búsqueda

### 3.1. Estrategia por Defecto
**Descripción:**  
Utiliza la búsqueda interna del solver sin especificar heurísticas, confiando en las optimizaciones internas del mismo.

**Ventajas:**  
- Sencilla de implementar.  
- Se aprovechan las optimizaciones internas del solver.

**Desventajas:**  
- Falta de personalización en la estrategia de búsqueda.  
- Puede no ser óptima en problemas con restricciones muy complejas.

![Texto alternativo](./docs/images/SudokuBaseArbol.png)
![Texto alternativo](./docs/images/SudokuBaseTiempo.png)

---

### 3.2. Estrategia: *first_fail + indomain_min*
**Descripción:**  
Esta estrategia selecciona primero la variable con el dominio más restringido (*first_fail*) y asigna el valor mínimo disponible (*indomain_min*).

**Ventajas:**  
- Reduce las ramas del árbol de búsqueda al priorizar las variables más críticas.  
- Ofrece una asignación ordenada y predecible.

**Desventajas:**  
- En dominios pequeños (como el 1..9 de Sudoku), el beneficio puede ser marginal.  
- La búsqueda determinista puede generar backtracking extenso si las asignaciones iniciales no conducen rápidamente a una solución.

![Texto alternativo](./docs/images/SudokuEstrategia1Arbol.png)
![Texto alternativo](./docs/images/SudokuEstrategia1Tiempo.png)

---

### 3.3. Estrategia: *first_fail + indomain_split*
**Descripción:**  
Utiliza *first_fail* para seleccionar variables críticas y aplica *indomain_split* para dividir el dominio en dos mitades, facilitando la asignación de valores.

**Ventajas:**  
- Puede disminuir la profundidad del árbol de búsqueda en problemas con dominios amplios.  
- Resuelve primero las variables más restringidas.

**Desventajas:**  
- En Sudoku, donde el dominio es reducido, la división del dominio tiene un impacto limitado.  
- Puede generar una exploración dispersa y menos determinista del espacio de soluciones.

![Texto alternativo](./docs/images/SudokuEstrategia2Arbol.png)
![Texto alternativo](./docs/images/SudokuEstrategia2Tiempo.png)

---

## Tabla Comparativa

| Estrategia                      | Ventajas                                          | Desventajas                                        |
|---------------------------------|---------------------------------------------------|----------------------------------------------------|
| **Por Defecto**                 | Sencillez y optimizaciones internas              | Falta de personalización y eficiencia variable     |
| **first_fail + indomain_min**   | Reducción de ramas y orden predictible           | Beneficio marginal en dominios pequeños, backtracking excesivo |
| **first_fail + indomain_split** | Reducción de profundidad en dominios amplios       | Poco efectivo en Sudoku, exploración dispersa      |

