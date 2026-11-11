module Motor.Tipos where

import qualified Data.Map as M

-- Direcciones permitidas en el juego
data Direccion 
  = Norte | Sur | Este | Oeste | Arriba | Abajo
  deriving (Eq, Ord, Show, Read)

-- Un Objeto del juego
data Objeto = Objeto 
  { objId   :: String
  , objDesc :: String
  } deriving (Eq, Show)

-- Una Salida desde una sala hacia otra
data Salida = Salida 
  { salidaDir      :: Direccion
  , salidaDestino  :: String         -- ID de la sala a la que lleva
  , salidaRequiere :: Maybe String   -- Objeto opcional necesario para cruzar
  } deriving (Eq, Show)

-- Una Sala (Vértice del grafo)
data Sala = Sala 
  { salaId      :: String
  , salaDesc    :: String
  , salaSalidas :: [Salida]
  , salaObjetos :: [String]         -- IDs de los objetos que están en esta sala
  } deriving (Eq, Show)

-- Tipos de Meta posibles según el enunciado
data Meta 
  = LlegarASala String               -- llegar a <sala>
  | LlevarObjetoASala String String  -- llevar <objeto> a <sala>
  deriving (Eq, Show)

-- El Mundo completo (El Grafo en sí)
data Mundo = Mundo 
  { mundoTitulo  :: String
  , mundoInicio  :: String
  , mundoMeta    :: Meta
  -- Usamos Map para buscar salas y objetos por su ID en O(log n)
  , mundoSalas   :: M.Map String Sala
  , mundoObjetos :: M.Map String Objeto
  } deriving (Eq, Show)

-- Errores del mundo (para cumplir con V1 a V10)
data ErrorMundo 
  = ErrorSintaxis Int String         -- V1: Línea y descripción
  | ObjetoDuplicado String           -- V2
  | SalaDuplicada String             -- V2
  | SalaInexistenteEnSalida String   -- V3
  | ObjetoRequeridoInexistente String-- V4
  | SalidaDuplicadaEnSala String     -- V5
  | ObjetoEnSalaInexistente String   -- V6
  | ObjetoEnMultiplesSalas String    -- V7
  | InicioMetaInexistente String     -- V8
  | SalaInalcanzable String          -- V9
  | ObjetoInconseguible String       -- V10
  deriving (Eq, Show)

-- El Estado actual de la partida (para cuando el usuario esté jugando)
data Estado = Estado 
  { estadoMundo      :: Mundo
  , estadoSalaActual :: String       -- ID de la sala donde está el jugador
  , estadoInventario :: [String]     -- IDs de los objetos que lleva el jugador
  , turnosRestantes  :: Int          -- Turnos restantes del jugador
  } deriving (Eq, Show)
  
  --tipos auxiliares
type LineaConNumero = (Int, String)

data MundoRaw = MundoRaw
  { rawTitulo :: Maybe String
  , rawInicio :: Maybe String
  , rawMeta   :: Maybe String
  , rawSalas  :: [(Int, [String])]  -- Línea de inicio del bloque y sus líneas internas
  , rawObjetos:: [(Int, [String])]
  } deriving (Show)

data Comando
  = Ir Direccion
  | Mirar
  | Tomar String
  | Soltar String
  | Examinar String
  | Inventario
  | Ayuda
  | Salir
  | Guardar String
  | Cargar String
  deriving (Show, Eq)

-- Función auxiliar para mostrar direcciones en minúscula
mostrarDireccion :: Direccion -> String
mostrarDireccion Norte  = "norte"
mostrarDireccion Sur    = "sur"
mostrarDireccion Este   = "este"
mostrarDireccion Oeste  = "oeste"
mostrarDireccion Arriba = "arriba"
mostrarDireccion Abajo  = "abajo"