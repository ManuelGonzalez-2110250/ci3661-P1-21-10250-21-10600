module Motor.Nucleo (estadoInicial, ejecutar, metaCumplida) where

import Motor.Tipos
import qualified Data.Map as M
import Data.List (find)

-- | Crea el estado inicial a partir del mundo cargado.
estadoInicial :: Mundo -> Estado
estadoInicial m = Estado
    { estadoMundo = m
    , estadoSalaActual = mundoInicio m
    , estadoInventario = []
    , turnosRestantes = 0 -- Nos toco la variante de turnos, se pone el valor inicial aquí
    }

-- | Busca una salida en una dirección específica.
buscarSalida :: Direccion -> [Salida] -> Maybe Salida
buscarSalida dir = find (\s -> salidaDir s == dir)

-- | Genera la descripción de la sala actual.
describirSala :: Estado -> [String]
describirSala st = 
    let m = estadoMundo st
        salaId = estadoSalaActual st
        -- M.! nunca falla aquí porque la validación V8 asegura que la sala existe
        sala = (mundoSalas m) M.! salaId 
        objs = salaObjetos sala
        salidas = salaSalidas sala
    in [ "Estás en: " ++ salaId
       , salaDesc sala
       , if null objs then "No ves objetos aquí." else "Ves: " ++ unwords objs
       , "Salidas: " ++ unwords (map (mostrarDireccion . salidaDir) salidas)
       ]

-- | Ejecuta un comando y devuelve los mensajes y el nuevo estado.
ejecutar :: Comando -> Estado -> ([String], Estado)
ejecutar cmd st = case cmd of
    Mirar -> (describirSala st, st)
    
    Ir dir -> 
        let m = estadoMundo st
            salaId = estadoSalaActual st
            sala = (mundoSalas m) M.! salaId
        in case buscarSalida dir (salaSalidas sala) of
            Nothing -> (["No hay salida hacia " ++ mostrarDireccion dir], st)
            Just salida -> 
                case salidaRequiere salida of
                    Just req | req `notElem` estadoInventario st ->
                        (["La salida hacia " ++ mostrarDireccion dir ++ " está bloqueada. Necesitas: " ++ req], st)
                    _ ->
                        let nuevaSalaId = salidaDestino salida
                            st' = st { estadoSalaActual = nuevaSalaId }
                        in (["Te mueves hacia " ++ mostrarDireccion dir] ++ describirSala st', st')
                        
    Tomar obj ->
        let m = estadoMundo st
            salaId = estadoSalaActual st
            sala = (mundoSalas m) M.! salaId
        in if obj `elem` salaObjetos sala
           then 
               -- Quitamos el objeto de la sala y lo agregamos al inventario
               let nuevaSala = sala { salaObjetos = filter (/= obj) (salaObjetos sala) }
                   nuevoMundo = m { mundoSalas = M.insert salaId nuevaSala (mundoSalas m) }
                   nuevoInv = obj : estadoInventario st
                   st' = st { estadoMundo = nuevoMundo, estadoInventario = nuevoInv }
               in (["Tomaste: " ++ obj], st')
           else (["No hay " ++ obj ++ " en esta sala."], st)
           
    Soltar obj ->
        if obj `elem` estadoInventario st
        then
            -- Quitamos el objeto del inventario y lo ponemos en la sala
            let m = estadoMundo st
                salaId = estadoSalaActual st
                sala = (mundoSalas m) M.! salaId
                nuevaSala = sala { salaObjetos = obj : salaObjetos sala }
                nuevoMundo = m { mundoSalas = M.insert salaId nuevaSala (mundoSalas m) }
                nuevoInv = filter (/= obj) (estadoInventario st)
                st' = st { estadoMundo = nuevoMundo, estadoInventario = nuevoInv }
            in (["Soltaste: " ++ obj], st')
        else (["No tienes " ++ obj ++ " en tu inventario."], st)
        
    Examinar obj ->
        let m = estadoMundo st
            salaId = estadoSalaActual st
            sala = (mundoSalas m) M.! salaId
            enSala = obj `elem` salaObjetos sala
            enInv = obj `elem` estadoInventario st
        in if enSala || enInv
           then case M.lookup obj (mundoObjetos m) of
                   Just o -> ([obj ++ ": " ++ objDesc o], st)
                   Nothing -> (["El objeto " ++ obj ++ " no está definido en este mundo."], st)
           else (["No ves " ++ obj ++ " por aquí."], st)
           
    Inventario ->
        let inv = estadoInventario st
        in if null inv
           then (["Llevas el inventario vacío."], st)
           else (["Llevas: " ++ unwords inv], st)
           
    Ayuda -> ([ "Comandos: ir <dir>, mirar, tomar <obj>, soltar <obj>, examinar <obj>, inventario, ayuda, salir"
              , "Direcciones: norte, sur, este, oeste, arriba, abajo" ], st)
              
    Salir -> (["Saliendo del juego..."], st)
    
    -- El Main intercepta Guardar y Cargar
    Guardar _ -> (["Error interno: Guardar debe manejarse en Main."], st)
    Cargar _  -> (["Error interno: Cargar debe manejarse en Main."], st)

-- | Verifica si el jugador ha ganado.
metaCumplida :: Estado -> Bool
metaCumplida st =
    case mundoMeta (estadoMundo st) of
        LlegarASala s -> estadoSalaActual st == s
        LlevarObjetoASala o s -> estadoSalaActual st == s && o `elem` estadoInventario st