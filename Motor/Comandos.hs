module Motor.Comandos (leerComando) where

import Motor.Tipos
import Data.Char (toLower)

leerComando :: String -> Maybe Comando
leerComando str = 
    case words (map toLower str) of
        [] -> Nothing
        (c:ds) -> case c of
            "norte"  -> Just (Ir Norte)
            "sur"    -> Just (Ir Sur)
            "este"   -> Just (Ir Este)
            "oeste"  -> Just (Ir Oeste)
            "arriba" -> Just (Ir Arriba)
            "abajo"  -> Just (Ir Abajo)
            "ir" -> case ds of
                ("norte":_)  -> Just (Ir Norte)
                ("sur":_)    -> Just (Ir Sur)
                ("este":_)   -> Just (Ir Este)
                ("oeste":_)  -> Just (Ir Oeste)
                ("arriba":_) -> Just (Ir Arriba)
                ("abajo":_)  -> Just (Ir Abajo)
                _            -> Nothing
            "mirar"      -> Just Mirar
            "tomar"      -> Just (Tomar (unwords ds))
            "coger"      -> Just (Tomar (unwords ds)) -- Sinónimo
            "soltar"     -> Just (Soltar (unwords ds))
            "examinar"   -> Just (Examinar (unwords ds))
            "inventario" -> Just Inventario
            "inv"        -> Just Inventario -- Sinónimo
            "ayuda"      -> Just Ayuda
            "salir"      -> Just Salir
            "guardar"    -> Just (Guardar (unwords ds))
            "cargar"     -> Just (Cargar (unwords ds))
            _            -> Nothing