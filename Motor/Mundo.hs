module Motor.Mundo where

import qualified Data.Map as M
import Motor.Tipos
import Data.List (isPrefixOf)
import Data.Char (isSpace)

agruparPorSeparador :: [LineaConNumero] -> [[LineaConNumero]]
agruparPorSeparador [] = []
agruparPorSeparador xs =  
    let (bloque, resto) = span (\(_, l) -> trim l /= "--") xs
    in case resto of
         []               -> [bloque]
         (_ : restoResto) -> bloque : agruparPorSeparador restoResto
  where
    trim = reverse . dropWhile isSpace . reverse . dropWhile isSpace

-- 2. Procesar bloques (aquí implementarás la validación V1 de bloques)
procesarBloques :: [[LineaConNumero]] -> Either [ErrorMundo] MundoRaw
procesarBloques bloques = 
    -- TODO: Aquí recorres los bloques para armar el MundoRaw o reportar errores V1
    Right (MundoRaw Nothing Nothing Nothing [] [])

-- 3. Parseo de sintaxis principal
parsearSintaxis :: String -> Either [ErrorMundo] MundoRaw
parsearSintaxis contenido =  
    let  
        lineasConNum = zip [1..] (lines contenido)
        limpias      = filter esUtil lineasConNum
        bloques      = agruparPorSeparador limpias
    in  
        procesarBloques bloques
  where
    esUtil (_, l) =  
      let t = trim l  
      in not (null t) && head t /= '#'

    trim = reverse . dropWhile isSpace . reverse . dropWhile isSpace

-- 4. Validación semántica (acumula errores sumando listas)
validarSemantica :: MundoRaw -> [ErrorMundo]
validarSemantica mundo =  
     validarV2 mundo  
  ++ validarV3 mundo  
  ++ validarV4 mundo
  ++ validarV5 mundo
  -- ++ validarV... hasta V10

-- Stubs temporales para que compile (reemplázalos con tu lógica)
validarV2 :: MundoRaw -> [ErrorMundo]
validarV2 _ = []
validarV3 :: MundoRaw -> [ErrorMundo]
validarV3 _ = []
validarV4 :: MundoRaw -> [ErrorMundo]
validarV4 _ = []
validarV5 :: MundoRaw -> [ErrorMundo]
validarV5 _ = []

construirMundoFinal :: MundoRaw -> Mundo
construirMundoFinal _ = error "Implementar construirMundoFinal"

-- 5. Función principal pedida por el enunciado
leerMundo :: String -> Either [ErrorMundo] Mundo
leerMundo texto = do
  -- 1. Primero parseas la sintaxis (V1)
  mundoRaw <- parsearSintaxis texto  

  -- 2. Ejecutas todas las validaciones semánticas juntas
  let errores = validarSemantica mundoRaw

  -- 3. Decides según si la lista de errores está vacía o tiene cosas
  if null errsVacia errores
     then Right (construirMundoFinal mundoRaw)  
     else Left errores
  where
    errsVacia [] = True
    errsVacia _  = False

