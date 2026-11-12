module Motor.Mundo where

import qualified Data.Map as M
import Motor.Tipos
import Data.List (isPrefixOf)
import Data.Char (isSpace, toLower, isLower, isDigit)
import qualified Data.Set as S

-- Función auxiliar para limpiar espacios
trim :: String -> String
trim = reverse . dropWhile isSpace . reverse . dropWhile isSpace

-- Función auxiliar, para saber si la dirección es válida
esDireccionValida :: String -> Bool
esDireccionValida dir = case map toLower dir of
    "norte"     -> True
    "sur"       -> True
    "este"      -> True
    "oeste"     -> True
    "arriba"    -> True
    "abajo"     -> True
    _           -> False

-- Función auxiliar de caracteres válidos
esCaracterValido :: Char -> Bool
esCaracterValido c = 
    isLower c || 
    isDigit c || 
    c == '_'  || 
    c `elem` "áéíóúüñ"

-- función auxiliar que ve si todos son válidos
esIdentificadorValido :: String -> Bool
esIdentificadorValido s = 
    not (null s) && all esCaracterValido s

-- Función auxiliar, para ver si hay más de una palabra  y es válido
validarIdentificadorUnicoYValido :: LineaConNumero -> String -> [ErrorMundo]
validarIdentificadorUnicoYValido (numLinea, valor) nombreCampo =
    let tokens = words valor
    in case tokens of
         []  -> [ErrorSintaxis numLinea ("El campo " ++ nombreCampo ++ " no puede estar vacío")]
         [x] -> 
             if not (esIdentificadorValido x)
                then [ErrorSintaxis numLinea ("El identificador '" ++ x ++ "' en " ++ nombreCampo ++ " debe estar en minúsculas y solo puede contener letras, acentos, números y '_'")]
                else []
         _   -> [ErrorSintaxis numLinea ("El campo " ++ nombreCampo ++ " no puede contener espacios o múltiples palabras: " ++ valor)]
         
-- Funciones auxiliar para extraer datos
buscarUnico :: String -> [LineaConNumero] -> Maybe (Int, String)
buscarUnico claveBuscada lineas = 
    case [ (n, v) | (n, l) <- lineas, Just (c, v) <- [separarClaveValor l], c == claveBuscada ] of
        (x:_) -> Just x
        []    -> Nothing

extraerTodas :: String -> [LineaConNumero] -> [(Int, String)]
extraerTodas claveBuscada lineas = 
    [ (n, v) | (n, l) <- lineas, Just (c, v) <- [separarClaveValor l], c == claveBuscada ]

-- Extrae objetos solo si la primera línea del bloque es un OBJETO
extraerObjetosGlobales :: [[LineaConNumero]] -> [(Int, String)]
extraerObjetosGlobales [] = []
extraerObjetosGlobales (bloque:resto) =
    case bloque of
        ((numLinea, lineaTexto) : _) ->
            case separarClaveValor lineaTexto of
                Just ("OBJETO", valor) -> (numLinea, valor) : extraerObjetosGlobales resto
                _                      -> extraerObjetosGlobales resto
        [] -> extraerObjetosGlobales resto

--se agrupoa por "bloques" definidos por --
agruparPorSeparador :: [LineaConNumero] -> [[LineaConNumero]]
agruparPorSeparador [] = []
agruparPorSeparador xs =  
    let (bloque, resto) = span (\(_, l) -> trim l /= "--") xs
    in case resto of
         []             -> [bloque]
         (_ : restoResto) -> bloque : agruparPorSeparador restoResto

-- Función para extrar la información del mundo para un bosquejo del mundo
extraerMundoRaw :: [[LineaConNumero]] -> MundoRaw
extraerMundoRaw bloques = 
    let todasLasLineas = concat bloques
    -- Buscamos y filtramos según la clave de cada línea
    in MundoRaw 
       { rawTitulo  = buscarUnico "MUNDO" todasLasLineas
       , rawInicio  = buscarUnico "INICIO" todasLasLineas
       , rawMeta    = buscarUnico "META" todasLasLineas
       , rawSalas   = extraerTodas "SALA" todasLasLineas
       , rawObjetos = extraerObjetosGlobales bloques
       , rawSalidas = extraerTodas "SALIDA" todasLasLineas
       , rawTurnos  = buscarUnico "TURNOS" todasLasLineas
       }

-- Se toman los bloques seàrados y se ve si las líneas cumplen los requisitos
procesarBloques :: [[LineaConNumero]] -> Either [ErrorMundo] MundoRaw
procesarBloques bloques = 
    let todosLosErrores = concatMap validarLineasBloque bloques
    in if null todosLosErrores
          then Right (extraerMundoRaw bloques)
          else Left todosLosErrores

-- Se lee "el archivo", todas las líneas, se filtran comentario y líneas vacías y se enumeran líneas
obtenerBloques :: String -> [[LineaConNumero]]
obtenerBloques contenido =  
    let  
        lineasConNum = zip [1..] (lines contenido)
        limpias      = filter esUtil lineasConNum
    in  
        agruparPorSeparador limpias
  where
    esUtil (_, l) =  
      let t = trim l  
      in not (null t) && head t /= '#'
      
-- Ve cada línea y se busca : para separar  el comando del resto
separarClaveValor :: String -> Maybe (String, String)
separarClaveValor str =  
    case break (== ':') str of
      (clave, ':' : valor) -> Just (trim clave, trim valor)
      _                    -> Nothing

-- Se ve por el caso dependiendo del comando que se llama en cada ":"
validarLineasBloque :: [LineaConNumero] -> [ErrorMundo]
validarLineasBloque [] = []
validarLineasBloque ((numLinea, lineaTexto) : restoLineas) = 
    case separarClaveValor lineaTexto of
      Nothing -> 
          [ErrorSintaxis numLinea ("Línea mal formada (falta ':'): " ++ lineaTexto)] ++ validarLineasBloque restoLineas
          
      Just (clave, valor) -> 
          let parValor = (numLinea, valor)
              erroresClave = case clave of
                "MUNDO"  -> validarTextoSimple parValor
                "INICIO" -> validarInicio parValor
                "SALA"   -> validarSala parValor
                "DESC"   -> validarTextoSimple parValor
                "META"   -> validarMeta parValor
                "SALIDA" -> validarSalida parValor
                "OBJETO" -> validarObjeto parValor
                "TURNOS" -> validarNumero parValor
                _        -> [ErrorSintaxis numLinea ("Clave desconocida: " ++ clave)]
          in erroresClave ++ validarLineasBloque restoLineas

--se verifica si hay contenido
validarTextoSimple :: LineaConNumero -> [ErrorMundo]
validarTextoSimple (numLinea, valor) =
    if null valor 
       then [ErrorSintaxis numLinea "El valor no puede estar vacío"] 
       else []
       
--se verifica si hay contenido
validarNumero :: LineaConNumero -> [ErrorMundo]
validarNumero (numLinea, valor) =
    if not (null valor) && all isDigit valor
       then [] 
       else [ErrorSintaxis numLinea ("Número no válido para turnos: " ++ valor)]
       
--se verifica si la meta tiene un identificador válido
validarMeta :: LineaConNumero -> [ErrorMundo]
validarMeta (numLinea, valor) = 
    let tokens = words (map toLower valor)
    in case tokens of
        -- Caso  llevar <objeto> a <sala>
        ["llevar", obj, "a", sala] 
            | not (esIdentificadorValido obj)  -> [ErrorSintaxis numLinea ("El objeto '" ++ obj ++ "' no es un identificador válido")]
            | not (esIdentificadorValido sala) -> [ErrorSintaxis numLinea ("La sala '" ++ sala ++ "' no es un identificador válido")]
            | otherwise                        -> []
        -- caso llegar a <sala>
        ["llegar", "a", sala]
            | not (esIdentificadorValido sala) -> [ErrorSintaxis numLinea ("La sala '" ++ sala ++ "' no es un identificador válido")]
            | otherwise                        -> []
        -- si no es parte de la estructura
        _ -> [ErrorSintaxis numLinea ("Formato de Meta inválido: " ++ valor)]

-- se verifica si los casos de salida tiene verificadores válidos
validarSalida :: LineaConNumero -> [ErrorMundo]
validarSalida (numLinea, valor) = 
    let tokens = words valor
    in case tokens of
        -- Caso 1: <dir> -> <sala>
        [dir, "->", sala] 
            | not (esDireccionValida dir)      -> [ErrorSintaxis numLinea ("Dirección desconocida: " ++ dir)]
            | not (esIdentificadorValido sala) -> [ErrorSintaxis numLinea ("La sala de destino '" ++ sala ++ "' no es un identificador válido")]
            | otherwise                        -> []
        
        -- Caso 2: <dir> -> <sala> requiere <objeto>
        [dir, "->", sala, "requiere", obj] 
            | not (esDireccionValida dir)      -> [ErrorSintaxis numLinea ("Dirección desconocida: " ++ dir)]
            | not (esIdentificadorValido sala) -> [ErrorSintaxis numLinea ("La sala de destino '" ++ sala ++ "' no es un identificador válido")]
            | not (esIdentificadorValido obj)  -> [ErrorSintaxis numLinea ("El objeto requerido '" ++ obj ++ "' no es un identificador válido")]
            | otherwise                        -> []
        
        -- si no es parte de la estructura
        _ -> [ErrorSintaxis numLinea ("Formato de SALIDA inválido: " ++ valor)]

-- validar objeto
validarObjeto :: LineaConNumero -> [ErrorMundo]
validarObjeto par = validarIdentificadorUnicoYValido par "OBJETO"

-- vaidar sala
validarSala :: LineaConNumero -> [ErrorMundo]
validarSala par = validarIdentificadorUnicoYValido par "SALA"

-- validar inicio
validarInicio :: LineaConNumero -> [ErrorMundo]
validarInicio par = validarIdentificadorUnicoYValido par "INICIO"
    
    
-- se cambia el formato (y se combina) las direcciones
parsearDireccion :: String -> Direccion
parsearDireccion dir = case map toLower dir of
    "norte"  -> Norte
    "sur"    -> Sur
    "este"   -> Este
    "oeste"  -> Oeste
    "arriba" -> Norte
    "abajo"  -> Sur
    _        -> Norte -- por defecto, si no hay errores no debe por que tomarse

-- se cambia a un formato estandar la salida
parsearSalidaLinea :: String -> Maybe Salida
parsearSalidaLinea texto = 
    let tokens = words texto
    in case tokens of
        [dir, "->", sala] -> 
            Just $ Salida { salidaDir = parsearDireccion dir, salidaDestino = sala, salidaRequiere = Nothing }
        [dir, "->", sala, "requiere", obj] -> 
            Just $ Salida { salidaDir = parsearDireccion dir, salidaDestino = sala, salidaRequiere = Just obj }
        _ -> Nothing

-- se cambia a un formato estandar la meta
parsearMetaFinal :: Maybe (Int, String) -> Meta
parsearMetaFinal Nothing = LlegarASala ""
parsearMetaFinal (Just (_, valor)) = 
    let tokens = words (map toLower valor)
    in case tokens of
        ["llevar", obj, "a", sala] -> LlevarObjetoASala obj sala
        ["llegar", "a", sala]      -> LlegarASala sala
        _                          -> LlegarASala ""

-- Se construye la sala
construirSalaDesdeBloque :: [LineaConNumero] -> Maybe Sala
construirSalaDesdeBloque bloque = do
    -- se bucsa el nomre
    (_, nombreSala) <- buscarUnico "SALA" bloque
    -- se busca la descripción
    let descSala = case buscarUnico "DESC" bloque of
            Just (_, d) -> d
            Nothing     -> ""
    -- se extraen todas las salidas
    let salidas = [ s | (_, l) <- bloque, Just (c, val) <- [separarClaveValor l], c == "SALIDA", Just s <- [parsearSalidaLinea val] ]
    -- se extraen los objetos de la sala
    let objetosLocales = [ val | (_, l) <- bloque, Just (c, val) <- [separarClaveValor l], c == "OBJETO" ]
    
    return Sala 
        { salaId = nombreSala
        , salaDesc = descSala
        , salaSalidas = salidas
        , salaObjetos = objetosLocales
        }

-- Función de construir el mundo
construirMundoFinal :: MundoRaw -> [[LineaConNumero]] -> Mundo
construirMundoFinal mundoRaw bloques =
    let 
        --se traen valores del raw
        titulo = case rawTitulo mundoRaw of
            Just (_, t) -> t
            Nothing     -> "Mundo Sin Título"
        inicio = case rawInicio mundoRaw of
            Just (_, i) -> i
            Nothing     -> ""
        meta = parsearMetaFinal (rawMeta mundoRaw)
        listaObjetos = [ (objId, Objeto objId "") | (_, objId) <- rawObjetos mundoRaw ]
        mapObjetos = M.fromList listaObjetos
        
        --se extraen las salas y se mapean
        bloquesSalas = extraerBloquesSalas bloques
        listasSalas = [ (salaId s, s) | BloqueSala _ lineas <- bloquesSalas, Just s <- [construirSalaDesdeBloque lineas] ]
        mapSalas = M.fromList listasSalas
        turnos = case rawTurnos mundoRaw of
                   Just (_, t) -> read t :: Int 
                   Nothing     -> -1
    in 
        Mundo
        { mundoTitulo = titulo
        , mundoInicio = inicio
        , mundoMeta = meta
        , mundoSalas = mapSalas
        , mundoObjetos = mapObjetos
        , mundoTurnos = turnos
        }    
    
--Validación de todo 
validarSemantica :: MundoRaw -> [[LineaConNumero]] -> ([ErrorMundo], Maybe Mundo)
validarSemantica mundoRaw bloques =
    let
        erroresEstaticos =
                   validarV2 mundoRaw  
                ++ validarV3 mundoRaw  
                ++ validarV4 mundoRaw
                ++ validarV5 bloques
                ++ validarV6 mundoRaw bloques
                ++ validarV7 bloques
                ++ validarV8 mundoRaw

        mundoConstruido = construirMundoFinal mundoRaw bloques
        erroresGrafo = validarGrafos mundoConstruido
        todosLosErrores = erroresEstaticos ++ erroresGrafo
    in
        (todosLosErrores, if null todosLosErrores then Just mundoConstruido else Nothing)

verificarDuplicados :: [(Int, String)] -> S.Set String -> String -> [ErrorMundo]
verificarDuplicados [] _ _ = [] 
verificarDuplicados ((numLinea, nombre) : resto) vistas tipoEntidad
    | nombre `S.member` vistas = 
        let errorDuplicado = case tipoEntidad of
              "SALA"   -> SalaDuplicada numLinea nombre
              "OBJETO" -> ObjetoDuplicado numLinea nombre
              _        -> ErrorSintaxis numLinea (tipoEntidad ++ " duplicado: " ++ nombre)
        in errorDuplicado : verificarDuplicados resto vistas tipoEntidad
    | otherwise = 
        verificarDuplicados resto (S.insert nombre vistas) tipoEntidad
--validar duplicados
validarV2 :: MundoRaw -> [ErrorMundo]
validarV2 mundo = 
    verificarDuplicados (rawSalas mundo) S.empty "SALA" ++
    verificarDuplicados (rawObjetos mundo) S.empty "OBJETO"

existeSala :: String -> [(Int, String)] -> Bool
existeSala _ [] = False  
existeSala nombreBuscado ((_, nombreSala) : resto)
    | nombreBuscado == nombreSala = True 
    | otherwise                   = existeSala nombreBuscado resto

--verificar el formato
parsearSalidaRaw :: (Int, String) -> Maybe (Int, String, String)
parsearSalidaRaw (numLinea, valor) = 
    let tokens = words valor
    in case tokens of
        [dir, "->", sala]                 -> Just (numLinea, dir, sala)
        [dir, "->", sala, "requiere", _]  -> Just (numLinea, dir, sala)
        _                                 -> Nothing

--verificar una salida a una sala que no existe
validarV3 :: MundoRaw -> [ErrorMundo]
validarV3 mundo = 
    let 
        errorInicio = case rawInicio mundo of
            Nothing -> [ErrorSintaxis 0 "El mundo no tiene un punto de INICIO declarado"]
            Just (numLinea, nombreInicio) -> 
                if existeSala nombreInicio (rawSalas mundo)
                   then []  
                   else [SalaInexistenteEnSalida numLinea nombreInicio]

        salasValidas = S.fromList [nombre | (_, nombre) <- rawSalas mundo]
        salidasDestinos = [ (num, dir, sala) | raw <- rawSalidas mundo, Just (num, dir, sala) <- [parsearSalidaRaw raw] ]
        
        verificarDestinos [] _ = []
        verificarDestinos ((num, dir, salaDestino) : resto) validas
            | salaDestino `S.member` validas = verificarDestinos resto validas
            | otherwise = [SalaInexistenteEnSalida num salaDestino] ++ verificarDestinos resto validas

        erroresDestinos = verificarDestinos salidasDestinos salasValidas
    in 
        errorInicio ++ erroresDestinos

-- V4: Valida que los objetos exigidos en las salidas existan globalmente
parsearObjetoRequeridoEnSalida :: (Int, String) -> Maybe (Int, String)
parsearObjetoRequeridoEnSalida (numLinea, valor) = 
    let tokens = words valor
    in case tokens of
        (_ : "->" : _ : "requiere" : obj : _) -> Just (numLinea, obj)
        _                                     -> Nothing

validarV4 :: MundoRaw -> [ErrorMundo]
validarV4 mundo =
    let 
        objetosValidos = S.fromList [nombre | (_, nombre) <- rawObjetos mundo]
        requeridosSalidas = [ parseado | raw <- rawSalidas mundo, Just parseado <- [parsearObjetoRequeridoEnSalida raw] ]
        
        verificarRequeridos [] _ = []
        verificarRequeridos ((numLinea, objReq) : resto) validas
            | objReq `S.member` validas = verificarRequeridos resto validas
            | otherwise = [ObjetoRequeridoInexistente numLinea objReq] ++ verificarRequeridos resto validas
    in 
        verificarRequeridos requeridosSalidas objetosValidos
        
--direcciones equivalentes y ponerlas en minúsuclas        
normalizarDireccion :: String -> String
normalizarDireccion dir = case map toLower dir of
    "arriba" -> "norte"
    "abajo"  -> "sur"
    other    -> other
    
--buscar que bloques tiene sala    
extraerBloquesSalas :: [[LineaConNumero]] -> [BloqueSala]
extraerBloquesSalas [] = []
extraerBloquesSalas (bloque:resto) =
    let salaEncontrada = buscarUnico "SALA" bloque
    in BloqueSala salaEncontrada bloque : extraerBloquesSalas resto

--ver que direcciones en la sala son únicas
validarDireccionesUnicasEnSala :: [LineaConNumero] -> S.Set String -> [ErrorMundo]
validarDireccionesUnicasEnSala [] _ = []
validarDireccionesUnicasEnSala ((numLinea, textoLinea) : resto) direccionesVistas =
    case separarClaveValor textoLinea of
        Just ("SALIDA", valorSalida) ->
            let tokens = words valorSalida
            in case tokens of
                (dir : "->" : _) ->
                    let dirNorm = normalizarDireccion dir
                    in if dirNorm `S.member` direccionesVistas
                        then [SalidaDuplicadaEnSala numLinea ("Salida duplicada o equivalente hacia la dirección '" ++ dir ++ "' en esta sala")]
                             ++ validarDireccionesUnicasEnSala resto direccionesVistas
                        else validarDireccionesUnicasEnSala resto (S.insert dirNorm direccionesVistas)
                _ -> validarDireccionesUnicasEnSala resto direccionesVistas
        _ -> validarDireccionesUnicasEnSala resto direccionesVistas


--una sala con dos salidas en la misma dirección
validarV5 :: [[LineaConNumero]] -> [ErrorMundo]
validarV5 bloques =
    let bloquesSalas = extraerBloquesSalas bloques
    in concat [ validarDireccionesUnicasEnSala lineas S.empty 
              | BloqueSala (Just _) lineas <- bloquesSalas ]

--se consiguen los objetos locales 
extraerObjetosLocalesDeBloque :: [[LineaConNumero]] -> [LineaConNumero]
extraerObjetosLocalesDeBloque [] = []
extraerObjetosLocalesDeBloque (bloque:resto) =
    let esBloqueSala = case bloque of
            ((_, texto) : _) -> case separarClaveValor texto of
                Just ("SALA", _) -> True
                _                -> False
            [] -> False
    in if esBloqueSala
          then [ (num, val) | (num, l) <- bloque, Just ("OBJETO", val) <- [separarClaveValor l] ] 
               ++ extraerObjetosLocalesDeBloque resto
          else extraerObjetosLocalesDeBloque resto

-- Validar objetos locales con los objetos globales válidos
verificarObjetosLocales :: [LineaConNumero] -> S.Set String -> [ErrorMundo]
verificarObjetosLocales [] _ = []
verificarObjetosLocales ((numLinea, nombreObj) : resto) objetosGlobales
    | nombreObj `S.member` objetosGlobales = 
        verificarObjetosLocales resto objetosGlobales
    | otherwise = 
        [ObjetoEnSalaInexistente numLinea ("El objeto '" ++ nombreObj ++ "' usado en la sala nunca fue declarado globalmente como OBJETO")] 
        ++ verificarObjetosLocales resto objetosGlobales

--una sala que contiene un objeto no definido
validarV6 :: MundoRaw -> [[LineaConNumero]] -> [ErrorMundo]
validarV6 mundo bloques =
    let 
        objetosValidos = S.fromList [nombre | (_, nombre) <- rawObjetos mundo]
        objetosLocales = extraerObjetosLocalesDeBloque bloques
    in 
        verificarObjetosLocales objetosLocales objetosValidos

--ver si los objetos que hay en una sala ya existen con el resto de salas 
verificarObjetosLocalesDuplicados :: [LineaConNumero] -> S.Set String -> [ErrorMundo]
verificarObjetosLocalesDuplicados [] _ = []
verificarObjetosLocalesDuplicados ((numLinea, nombreObj) : resto) objetosVistos
    | nombreObj `S.member` objetosVistos = 
        [ObjetoEnMultiplesSalas numLinea nombreObj] ++ verificarObjetosLocalesDuplicados resto objetosVistos
    | otherwise = 
        verificarObjetosLocalesDuplicados resto (S.insert nombreObj objetosVistos)
        
-- ver si un objeto fue colocado en más de una sala
validarV7 :: [[LineaConNumero]] -> [ErrorMundo]
validarV7 bloques =
    let objetosLocales = extraerObjetosLocalesDeBloque bloques
    in verificarObjetosLocalesDuplicados objetosLocales S.empty

parsearMetaRaw :: (Int, String) -> Maybe (Int, String, String)
parsearMetaRaw (numLinea, valor) = 
    let tokens = words (map toLower valor)
    in case tokens of
        ["llevar", obj, "a", sala] -> Just (numLinea, obj, sala)
        _                          -> Nothing
        
--ver si el inicio o meta tiene obejtos o salas inexistentes
validarV8 :: MundoRaw -> [ErrorMundo]
validarV8 mundo =
    case rawMeta mundo of
        Nothing -> []
        Just (numLinea, valorMeta) ->
            let 
                tokens = words (map toLower valorMeta)
                salasValidas = S.fromList [nombre | (_, nombre) <- rawSalas mundo]
                objetosValidos = S.fromList [nombre | (_, nombre) <- rawObjetos mundo]

                -- se revisa internamente si existe la sala
                chequearSala sala = 
                    if sala `S.member` salasValidas 
                       then [] 
                       else [InicioMetaInexistente numLinea ("La sala '" ++ sala ++ "' especificada en la META nunca fue declarada")]

                -- se revisa internamente si existe el objeto
                chequearObjeto obj = 
                    if obj `S.member` objetosValidos 
                       then [] 
                       else [InicioMetaInexistente numLinea ("El objeto '" ++ obj ++ "' especificado en la META nunca fue declarado")]
            in 
                case tokens of
                    -- Caso 1 llevar <obj> a <sala>
                    ["llevar", obj, "a", sala] -> chequearObjeto obj ++ chequearSala sala
                    
                    -- Caso 2 llegar a <sala>
                    ["llegar", "a", sala]      -> chequearSala sala
                    
                    -- Cualquier otro formato
                    _                          -> []

-- DFS
obtenerSalasAlcanzables :: String -> M.Map String Sala -> S.Set String
obtenerSalasAlcanzables salaInicio mapaSalas = dfs [salaInicio] S.empty
  where
    dfs [] visitadas = visitadas
    dfs (actual:resto) visitadas
      | actual `S.member` visitadas = dfs resto visitadas
      | otherwise = 
          case M.lookup actual mapaSalas of
            Nothing -> dfs resto (S.insert actual visitadas)
            Just sala -> 
                let destinos = [ salidaDestino s | s <- salaSalidas sala ]
                in dfs (destinos ++ resto) (S.insert actual visitadas)
                
-- ver si la sala no es alcanzable desde inicio siguiendo salidas
validarV9 :: Mundo -> [ErrorMundo]
validarV9 mundo =
    let 
        inicio = mundoInicio mundo
        mapaSalas = mundoSalas mundo
        
        -- se obtienen las salas con DFS
        salasAlcanzables = obtenerSalasAlcanzables inicio mapaSalas
        
        -- se ven las salas del mundo
        salasTotales = M.keysSet mapaSalas
        
        -- se ven si hay difetencia
        inalcanzables = S.difference salasTotales salasAlcanzables
    in 
        [ SalaInalcanzable salaId | salaId <- S.toList inalcanzables ]

simularRecorridoConInventario :: String -> M.Map String Sala -> S.Set String
simularRecorridoConInventario salaInicio mapaSalas = puntoFijo S.empty
  where
    -- Bucle principal: repite la exploración mientras el inventario siga creciendo
    puntoFijo inventarioActual =
      let inventarioNuevo = explorarConInventario salaInicio inventarioActual
      in if inventarioNuevo == inventarioActual
         then inventarioActual  -- Ya llegamos a un punto fijo (no hay nuevos objetos)
         else puntoFijo inventarioNuevo -- Encontramos más objetos, volvemos a explorar

    -- Realiza una exploración completa (BFS) usando un inventario fijo
    explorarConInventario :: String -> S.Set String -> S.Set String
    explorarConInventario inicio inventarioBase = bfs [inicio] S.empty inventarioBase
      where
        bfs [] visitadas invAcc = invAcc
        bfs (actual:resto) visitadas invAcc
          | actual `S.member` visitadas = bfs resto visitadas invAcc
          | otherwise =
              case M.lookup actual mapaSalas of
                Nothing -> bfs resto (S.insert actual visitadas) invAcc
                Just sala ->
                  let 
                      -- Recolectamos los objetos de esta sala con el inventario acumulado
                      nuevosObjetos = S.fromList (salaObjetos sala)
                      invAcc' = S.union invAcc nuevosObjetos
                      
                      -- Vemos qué salidas podemos cruzar CON EL INVENTARIO ACTUALIZADO
                      salidasValidas = [ salidaDestino s | s <- salaSalidas sala, puedeCruzar s invAcc' ]
                  in 
                      -- Añadimos los destinos válidos a la cola, marcamos la sala como visitada y pasamos el inventario actualizado
                      bfs (salidasValidas ++ resto) (S.insert actual visitadas) invAcc'

    -- Verifica si el jugador tiene el objeto requerido para cruzar una salida
    puedeCruzar :: Salida -> S.Set String -> Bool
    puedeCruzar salida inventario = 
        case salidaRequiere salida of
            Nothing  -> True
            Just obj -> obj `S.member` inventario
            
            
validarV10 :: Mundo -> [ErrorMundo]
validarV10 mundo =
    let 
        inicio = mundoInicio mundo
        mapaSalas = mundoSalas mundo
        
        -- Ejecutamos la simulación que recolecta objetos alcanzables legalmente
        objetosConseguibles = simularRecorridoConInventario inicio mapaSalas
        
        -- Todos los objetos globales declarados en el mundo
        objetosGlobales = M.keysSet (mundoObjetos mundo)
        
        -- Inconseguibles son los que no pudieron ser recolectados legalmente
        inconseguibles = S.difference objetosGlobales objetosConseguibles
    in 
        [ ObjetoInconseguible objId | objId <- S.toList inconseguibles ]

validarGrafos :: Mundo -> [ErrorMundo]
validarGrafos mundo =
     validarV9 mundo
  ++ validarV10 mundo

--Función principal
leerMundo :: String -> Either [ErrorMundo] Mundo
leerMundo texto = do
  -- se obtienen bloques
  let bloques = obtenerBloques texto
  
  -- se procesan los bloques en un "mundo" que es solo datos sueltos
  mundoRaw <- procesarBloques bloques  

  -- se consigue un mundo probable y los errores
  let (erroresTotales, maybeMundo) = validarSemantica mundoRaw bloques

  --si hay un error, se retornan los errores, si no se retorna el mundo
  if not (null erroresTotales)
     then Left erroresTotales
     else case maybeMundo of
            Just m  -> Right m
            Nothing -> Left [ErrorSintaxis 0 "Error desconocido al procesar el mundo"]

