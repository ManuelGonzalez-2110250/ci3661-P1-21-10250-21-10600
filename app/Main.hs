module Main (main) where

import Motor.Tipos
import Motor.Mundo (leerMundo)
import Motor.Comandos (leerComando)
import Motor.Nucleo
import System.Environment (getArgs)
import System.Exit (exitSuccess, exitWith, ExitCode(..))
import System.IO (hFlush, stdout, isEOF)
import System.Directory (doesFileExist)
import Text.Read (readMaybe)

main :: IO ()
main = do
    args <- getArgs
    case args of
        ["-validar", archivo] -> validarMundo archivo
        [archivo]             -> jugar archivo
        _                     -> putStrLn "Uso: aventura MUNDO | aventura -validar MUNDO"

-- | Modo Validar: Solo compila el mundo y dice si está bien o mal.
validarMundo :: FilePath -> IO ()
validarMundo archivo = do
    contenido <- readFile archivo
    case leerMundo contenido of
        Left errs -> do
            mapM_ (putStrLn . ("Error: " ++) . show) errs
            exitWith (ExitFailure 1)
        Right _ -> do
            putStrLn "Mundo válido."
            exitSuccess

-- | Modo Jugar: Inicia el juego.
jugar :: FilePath -> IO ()
jugar archivo = do
    contenido <- readFile archivo
    case leerMundo contenido of
        Left errs -> do
            -- Si el mundo tiene errores, los imprime y termina con código 1
            mapM_ (putStrLn . ("Error: " ++) . show) errs
            exitWith (ExitFailure 1)
        Right mundo -> do
            putStrLn $ "Bienvenido a: " ++ mundoTitulo mundo
            putStrLn $ "Salidas iniciales: "
            bucleJuego mundo (estadoInicial mundo)

-- | El bucle infinito de IO hasta que se gane, se acaben los turnos o el usuario salga.
bucleJuego :: Mundo -> Estado -> IO ()
bucleJuego mundo est = do
    putStr "> "
    hFlush stdout
    eof <- isEOF
    if eof 
        then return () -- Si la entrada redirigida se acaba, termina limpiamente.
        else do
            linea <- getLine
            case leerComando linea of
                Nothing -> do
                    putStrLn "Comando no reconocido. Escribe 'ayuda'."
                    bucleJuego mundo est
                
                Just Salir -> putStrLn "¡Adiós!"
                
                Just (Guardar archivoGuardado) -> do
                    writeFile archivoGuardado (show est)
                    putStrLn $ "Partida guardada en " ++ archivoGuardado
                    bucleJuego mundo est
                
                Just (Cargar archivoCargado) -> do
                    existe <- doesFileExist archivoCargado
                    if not existe
                        then do
                            putStrLn "El archivo de partida no existe."
                            bucleJuego mundo est
                        else do
                            contenidoGuardado <- readFile archivoCargado
                            case readMaybe contenidoGuardado of
                                Nothing -> do
                                    putStrLn "El archivo de partida está corrupto."
                                    bucleJuego mundo est
                                Just est' -> do
                                    putStrLn "Partida cargada."
                                    bucleJuego mundo est'
                
                Just cmd -> do
                    let (msgs, est') = ejecutar cmd est
                    mapM_ putStrLn msgs
                    
                    -- Verificamos condiciones de victoria o derrota
                    if metaCumplida est'
                        then do
                            putStrLn "*** ¡Has ganado! ***"
                            exitSuccess
                        else if sinTurnos est'
                            then do
                                putStrLn "*** Se acabó el tiempo ***"
                                exitSuccess
                            else
                                bucleJuego mundo est'