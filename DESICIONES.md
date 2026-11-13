## D1. ¿Cómo representan el mundo y los identificadores?
Contexto: Al no especificarse el tipo del mundo ni el tipo de identificadores, se debe crear un tipo propio
Opciones: Se puede representar de varias formas como un ripo estático, diccionario de salas, grafos, una lista de salas..., en cuanto a los
identificadores se puede crear un tipo concreto para cada identificador o se puede manejar directamente desde el Motor.Mundo
Decisión: Se representó de manera similar a un grafo con Map y se combinó concpetos de ambas formas de manejar los identificadores
Consecuencias: en cuanto a el mundo Se consiguió facilitar sustancialmente las funciones de verificación de V9 y v10, pero para poder verificarlas más facilemnte
se tiene que crear la estructura mundo antes de ejecutar dichas verificaciones, por lo que se tienen que crear valores base, para que si fallan
algunas verificaciones, todavía se pueda verificar V9 y V10 correctamente. lo que garantiza que se cumpla en este caso es la salida de errores o 
grafo, solo retornará un mundo si es que existen 0 errores. 
en cuanto a los identificadores Hay múltiples beneficios de representarlo como en tipo, dado que garantiza que se cumple lo que se pide, pero para algunos, durante la verificaciñon era más conveniente no usar los tipos (para simplificar la lógica) por lo que se optó por eso, se puede ver un ejemplo de esto para el manejo de direcciones. Si se fuese a hacer algo distinto capaz sería realizar las funciones tomando en cuenta los tipos,
pese a ser la "opción compleja" de tal forma que muchas de las verificaciones queden implícitas por se haskell quien las maneja.

## D2. ¿Qué guarda el Estado?
Contexto: 
Opciones: 
Decisión: 
Consecuencias: 

## D3. ¿Cómo logran reportar todos los errores de validación y no solo el primero?
Contexto: Se pide que los errores de validación sean completos, per usar Either (left right) retornará siempre al llegar a un caso left, no verificando el resto
Opciones: se podría verificar errores en conjunto en una sola función que corre todo o se puede dividir en múltiples funciones usando la concatenación
Decisión: se optó por concatenar usando ++ los errores
Consecuencias: Al tener una lógica más separada, si existe un error con una verificación en concreto es más fácil saber que falla, al tener una lógica separada del resto de verificaciones, existe el problema de que el código es más dificil de leer, dado que si quieres saber que hace el conjunto entero, debes moverte de un lado a otro del código buscando la función en concreto que hace el trabajo. En este caso creo que lo que haría diferente es organizar el códigop para que se pueda leer de arriba a abajo, sabiendo que hace todo.

## D4. ¿Cómo diseñaron el reconocedor?
Contexto: 
Opciones: 
Decisión: 
Consecuencias: 

## D5. Las decisiones propias de su variante.
Contexto: Se añade un variate adicional dependiendo del módulo de la suma del carnet, en este caso si hay turnos límites
Opciones: Se puede dejar una cantidad de turnos exageradamente alta para manejar turnos cuando no se especifica o se puede colocar un valor imposible
Decisión: se colocó el valor imposible -1
Consecuencias: 

## D6
Contexto: 
Opciones: 
Decisión: 
Consecuencias: 
