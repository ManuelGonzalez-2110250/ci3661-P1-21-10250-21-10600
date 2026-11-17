module Motor.Reconocedor (
    ReadS,
    espacios,
    caracter,
    leerClaveValor
) where

import Prelude hiding (ReadS)
import Data.Char (isSpace)

-- | Tipo base de los reconocedores
type ReadS a = String -> [(a, String)]

-- | Consume cero o más espacios en blanco
espacios :: ReadS ()
espacios s = [((), dropWhile isSpace s)]

-- | Lee un carácter si cumple un predicado
caracter :: (Char -> Bool) -> ReadS Char
caracter p (c:cs) | p c = [(c, cs)]
caracter _ _            = []

-- | Reconoce una línea con formato "CLAVE: valor" y devuelve ambos
leerClaveValor :: ReadS (String, String)
leerClaveValor s = 
    [ ((clave, valor), restoFinal) 
    | ((), r1) <- espacios s
    , (clave, r2) <- leerHastaDosPuntos r1
    , (_, r3) <- caracter (== ':') r2
    , ((), r4) <- espacios r3
    , let (valor, restoFinal) = break (== '\n') r4
    ]
  where
    -- Función auxiliar para leer todo hasta encontrar un ':'
    leerHastaDosPuntos :: String -> [(String, String)]
    leerHastaDosPuntos str = 
        let (c, resto) = break (== ':') str
        in if null resto then [] else [(c, resto)]