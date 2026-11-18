# README

## Ejecución

1. Para poder ejecutar el programa se necesita de "cabal" si no se tiene instalado, se debe realizar el comando correspondiente para su instalación

2. Se ejecutan los comandos **'cabal update'** y **'cabal build'** para compilar

3. Se ejecuta el comando **'cabal run aventura -- -validar <ruta>/<mundo.txt>'** donde **<ruta>** es la ruta al directorio donde se guardan los mundos y **<mundo.txt>** es un archivo .txt donde se guardan los contenidos de un mundo, el comando verifica si un mundo se puede jugar, o por el contrario se debe corregir

4. Si un mundo pasa la validación se usa **'cabal run aventura -- <ruta>/<mundo.txt>'** para ejecutar el juego

## Comandos

Una vez ejecutado el juego se disponen de los siguintes comandos:


|    Comando               |Descripción                                                                                                                  |
|--------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| ` ir <dirección>`        | Mueve al jugador por esa salida, si existe y no está bloqueada. Las direcciones son norte, sur, este, oeste, arriba y abajo.|
| ` mirar`                 |Describe la sala actual: su descripción, los objetos que hay y las salidas.                                                  |
| ` tomar <objeto>`        |Pasa un objeto de la sala al inventario. Sinónimo: coger.                                                                    |
| ` soltar <objeto> `      | Deja un objeto del inventario en la sala actual.                                                                            |
| ` examinar <objeto>`     | Muestra la descripción de un objeto del inventario o de la sala.                                                            |
| ` inventario`            |Lista lo que lleva el jugador. Sinónimo: inv.                                                                                |
| ` guardar <archivo>`     | Guarda la partida en un archivo.                                                                                            |
| ` cargar <archivo>`      |Recupera una partida guardada.                                                                                               |
| ` ayuda`                 |Muestra los comandos disponibles.                                                                                            |
| ` salir`                 |Termina el programa.                                                                                                         |
