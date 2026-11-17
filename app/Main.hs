module Main (main) where

import Motor.Tipos
import Motor.Mundo (leerMundo)
import Motor.Comandos (leerComando)
import Motor.Nucleo
import Motor.Persistencia (guardarPartida, cargarPartida)
import System.Environment (getArgs)
import System.Exit (exitSuccess, exitWith, ExitCode(..))
import System.IO (hFlush, stdout, isEOF, hSetEncoding, utf8, stdin, openFile, IOMode(..), hGetContents, hClose)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stdin utf8

    args <- getArgs
    case args of
        ["-validar", archivo] -> validarMundo archivo
        [archivo]             -> jugar archivo
        _                     -> putStrLn "Uso: aventura MUNDO | aventura -validar MUNDO"

validarMundo :: FilePath -> IO ()
validarMundo archivo = do
    h <- openFile archivo ReadMode
    hSetEncoding h utf8
    contenido <- hGetContents h
    let resultado = leerMundo contenido
    case resultado of
        Left errs -> do
            mapM_ (putStrLn . ("Error: " ++) . show) errs
            hClose h
            exitWith (ExitFailure 1)
        Right _ -> do
            hClose h
            putStrLn "Mundo válido."
            exitSuccess

jugar :: FilePath -> IO ()
jugar archivo = do
    h <- openFile archivo ReadMode
    hSetEncoding h utf8
    contenido <- hGetContents h
    let resultado = leerMundo contenido
    case resultado of
        Left errs -> do
            mapM_ (putStrLn . ("Error: " ++) . show) errs
            hClose h
            exitWith (ExitFailure 1)
        Right mundo -> do
            hClose h
            putStrLn $ "Bienvenido a: " ++ mundoTitulo mundo
            bucleJuego mundo (estadoInicial mundo)

bucleJuego :: Mundo -> Estado -> IO ()
bucleJuego mundo est = do
    putStr "> "
    hFlush stdout
    eof <- isEOF
    if eof 
        then return () 
        else do
            linea <- getLine
            case leerComando linea of
                Nothing -> do
                    putStrLn "Comando no reconocido. Escribe 'ayuda'."
                    bucleJuego mundo est
                
                Just Salir -> putStrLn "¡Adiós!"
                
                Just (Guardar archivoGuardado) -> do
                    res <- guardarPartida archivoGuardado est
                    case res of
                        Left err -> putStrLn err
                        Right _  -> putStrLn $ "Partida guardada en " ++ archivoGuardado
                    bucleJuego mundo est
                
                Just (Cargar archivoCargado) -> do
                    res <- cargarPartida archivoCargado mundo
                    case res of
                        Left err -> do
                            putStrLn err
                            bucleJuego mundo est
                        Right est' -> do
                            putStrLn "Partida cargada."
                            bucleJuego mundo est'
                
                Just cmd -> do
                    let (msgs, est') = ejecutar cmd est
                    mapM_ putStrLn msgs
                    
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