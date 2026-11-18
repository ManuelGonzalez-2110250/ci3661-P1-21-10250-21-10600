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
Contexto: En un juego de aventuras, el mundo inicial es inmutable y puro, pero durante la partida el jugador altera su entorno (se mueve, recoge objetos, gasta turnos). Necesitábamos una estructura que encapsule estos cambios sin tener que reescribir el archivo de texto original.
Opciones: 1) Copiar el Mundo entero en cada paso del juego y modificar el mapa de salas.
2) Guardar en el Estado solo el mundo base y una lista de diferencias (ej. "el objeto X ya no está en la sala Y").
3) Mantener el Mundo dentro del Estado y usar los tipos inmutables de Haskell (Map) para reflejar los objetos que se mueven.
Decisión: Elegimos la opción 3. Nuestro tipo Estado contiene el Mundo completo (estadoMundo), la salaActual y el inventario. Cuando el jugador toma un objeto, no creamos listas de diferencias, sino que creamos una copia del Mundo donde el mapa de salas se actualiza restando el objeto de la sala y sumándolo al inventario del Estado.
Consecuencias: Ganamos mucha simplicidad al no tener que cruzar los datos del inventario con el mundo base cada vez que se ejecuta un comando. Perdemos un poco de eficiencia en memoria, pero como los Data.Map en Haskell comparten estructura (persistent data structures), el costo real es mínimo. Si el mundo fuera gigantesco (miles de salas), esta decisión sería ineficiente.

## D3. ¿Cómo logran reportar todos los errores de validación y no solo el primero?
Contexto: Se pide que los errores de validación sean completos, per usar Either (left right) retornará siempre al llegar a un caso left, no verificando el resto
Opciones: se podría verificar errores en conjunto en una sola función que corre todo o se puede dividir en múltiples funciones usando la concatenación
Decisión: se optó por concatenar usando ++ los errores
Consecuencias: Al tener una lógica más separada, si existe un error con una verificación en concreto es más fácil saber que falla, al tener una lógica separada del resto de verificaciones, existe el problema de que el código es más dificil de leer, dado que si quieres saber que hace el conjunto entero, debes moverte de un lado a otro del código buscando la función en concreto que hace el trabajo. En este caso creo que lo que haría diferente es organizar el códigop para que se pueda leer de arriba a abajo, sabiendo que hace todo.

## D4. ¿Cómo diseñaron el reconocedor?
Contexto: El enunciado prohíbe terminantemente usar librerías de parseo como parsec o expresiones regulares. Debíamos crear nuestro propio reconocedor para leer el archivo del mundo (líneas con formato CLAVE: valor), pero además necesitábamos rastrear el número de línea exacto para reportar los errores de sintaxis (V1).
Opciones: 1) Crear un newtype alrededor de ReadS que mantuviera un estado con el número de línea.
2) Usar ReadS puro (como vimos en la Clase 5) devolviendo listas de tuplas (valor, resto) y añadir el número de línea por fuera.
3) Usar funciones de listas como break para separar por el carácter : y llevar la cuenta de las líneas con zip [1..].
Decisión: Para el módulo Motor.Reconocedor construimos combinadores básicos usando ReadS directo (con funciones como espacios y caracter). Sin embargo, para procesar el archivo completo (en Motor.Mundo), decidimos usar zip [1..] (lines contenido) para enumerar las líneas y break (== ':') para separar clave y valor. La ambigüedad se resuelve devolviendo listas vacías [] si el texto no calza con el formato.
Consecuencias: Ganamos un control absoluto y explícito del número de línea (lo cual es vital para los mensajes de error V1). El costo es que nuestro reconocedor no es tan elegante ni general como parsec, pero es 100% propio, robusto y cumple perfectamente con las restricciones del profesor.

## D5. Las decisiones propias de su variante.
Contexto: Se añade un variate adicional dependiendo del módulo de la suma del carnet, en este caso si hay turnos límites
Opciones: Se puede dejar una cantidad de turnos exageradamente alta para manejar turnos cuando no se especifica o se puede colocar un valor imposible
Decisión: se colocó el valor imposible -1
Consecuencias: 

## D6
Contexto: A nuestr equipo le correspondió la Variante 2 (Turnos). El juego debe terminar si el jugador se queda sin tiempo, pero no todos los comandos deberían afectar el reloj por igual. Además, ¿qué pasa si el jugador comete un error?
Opciones: 1) Que absolutamente todos los comandos (incluyendo mirar o ayuda) gasten un turno.
2) Que solo los comandos que modifican el estado del juego referentes al movimiento gasten turno.
3) Que los comandos que fallan (ej. intentar ir a una pared) también gasten turno para castigar al jugador.
Decisión: Elegimos la opción 2. Solo los movimientos exitosos restan un turno. Los comandos de información (mirar, inventario, examinar, ayuda) no gastan turno. Además, si el jugador intenta ir a una salida bloqueada o falla al tomar un objeto, no se le resta el turno.
Consecuencias: Ganamos jugabilidad. El jugador puede explorar, leer descripciones e inventariar sin miedo a perder la partida, pero se ve obligado a planificar bien sus rutas y acciones físicas. Perdemos la presión de tiempo sobre la lectura, pero consideramos que castigar los errores de tipeo o de exploración con pérdida de turnos hacía el juego injusto.
