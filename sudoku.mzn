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
        
        
solve :: int_search([solvedSudokuBoard[i,j] | i in DOMAIN, j in DOMAIN],
                    first_fail, indomain_split, complete) satisfy;


output [ show(solvedSudokuBoard[i, j]) ++ (if j == 9 then "\n" else " " endif) | i in DOMAIN, j in DOMAIN ];