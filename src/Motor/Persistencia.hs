module Motor.Persistencia (guardarPartida, cargarPartida) where

import Motor.Tipos
import System.IO
import Text.Read (readMaybe)
import Control.Exception (try)

-- | Guarda el estado en un archivo forzando UTF-8.
guardarPartida :: FilePath -> Estado -> IO (Either String ())
guardarPartida archivo est = do
    resultado <- tryIO $ do
        h <- openFile archivo WriteMode
        hSetEncoding h utf8
        hPutStr h (show est)
        hClose h
    case resultado of
        Left _ -> return $ Left "No se pudo escribir el archivo de partida."
        Right _ -> return $ Right ()

-- | Carga la partida desde un archivo, validando el mundo y forzando UTF-8.
cargarPartida :: FilePath -> Mundo -> IO (Either String Estado)
cargarPartida archivo mundoActual = do
    resultado <- tryIO $ do
        h <- openFile archivo ReadMode
        hSetEncoding h utf8
        contenido <- hGetContents h
        -- Forzamos evaluación para que se cierre el archivo
        let parsed = readMaybe contenido :: Maybe Estado
        case parsed of
            Nothing -> hClose h >> return Nothing
            Just est -> hClose h >> return (Just est)
            
    case resultado of
        Left _ -> return $ Left "El archivo de partida no existe o no se puede leer."
        Right Nothing -> return $ Left "El archivo de partida está corrupto."
        Right (Just est) -> 
            -- Validar que la partida sea del mismo mundo
            if mundoTitulo (estadoMundo est) /= mundoTitulo mundoActual
                then return $ Left "La partida pertenece a otro mundo."
                else return $ Right est

-- Función auxiliar para capturar excepciones de IO
tryIO :: IO a -> IO (Either IOError a)
tryIO action = do
    result <- try action
    return $ case result of
        Left ex  -> Left ex
        Right a  -> Right a