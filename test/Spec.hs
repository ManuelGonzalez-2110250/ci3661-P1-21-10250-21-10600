module Main (main) where

import Test.Hspec
import Motor.Tipos
import Motor.Mundo (leerMundo)
import Motor.Comandos (leerComando)
import Motor.Nucleo
import qualified Data.Map as M
import Data.List (isInfixOf)

-- DEFINIMOS EL MUNDO DE PRUEBA A NIVEL GLOBAL
-- Así todos los bloques 'describe' pueden acceder a él.
salaA :: Sala
salaA = Sala "a" "Sala A" [Salida Norte "b" Nothing] ["carnet", "espada"]

salaB :: Sala
salaB = Sala "b" "Sala B" [] []

mundoSimulado :: Mundo
mundoSimulado = Mundo "Test" "a" (LlegarASala "b") 
                (M.fromList [("a", salaA), ("b", salaB)]) 
                (M.fromList []) 
                (-1) -- Sin límite de turnos por defecto

main :: IO ()
main = hspec $ do

  describe "Motor.Comandos (leerComando)" $ do
    it "reconoce 'norte' como Ir Norte" $
      leerComando "norte" `shouldBe` Just (Ir Norte)
      
    it "reconoce 'ir sur' como Ir Sur" $
      leerComando "ir sur" `shouldBe` Just (Ir Sur)
      
    it "reconoce el sinónimo 'coger' como Tomar" $
      leerComando "coger carnet" `shouldBe` Just (Tomar "carnet")
      
    it "reconoce 'inventario'" $
      leerComando "inventario" `shouldBe` Just Inventario
      
    it "rechaza comandos desconocidos" $
      leerComando "volar al infinito" `shouldBe` Nothing

  describe "Motor.Mundo (leerMundo) - V1 Sintaxis" $ do
    it "rechaza un mundo con sintaxis inválida (sin ':')" $ do
      let txt = "MUNDO: Test\nINICIO: a\nMETA: llegar a a\n---\nSALA: a\nDESC: algo\nSALIDA norte a"
      case leerMundo txt of
        Left errs -> errs `shouldSatisfy` (not . null)
        Right _   -> expectationFailure "Debería haber fallado por sintaxis"

  describe "Motor.Mundo (leerMundo) - V2 a V8 Semántica" $ do
    it "detecta salida a sala inexistente (V3)" $ do
      let txt = "MUNDO: Test\nINICIO: a\nMETA: llegar a a\n---\nSALA: a\nDESC: algo\nSALIDA: norte -> b"
      case leerMundo txt of
        Left errs -> show errs `shouldSatisfy` ("SalaInexistenteEnSalida" `isInfixOf`)
        Right _   -> expectationFailure "Debería fallar V3"

    it "detecta objeto en sala inexistente (V6)" $ do
      let txt = "MUNDO: Test\nINICIO: a\nMETA: llegar a a\n---\nOBJETO: llave\nDESC: llave\n---\nSALA: a\nDESC: algo\nOBJETO: fantasma"
      case leerMundo txt of
        Left errs -> show errs `shouldSatisfy` ("ObjetoEnSalaInexistente" `isInfixOf`)
        Right _   -> expectationFailure "Debería fallar V6"

  describe "Motor.Nucleo - Lógica de Juego" $ do
    it "permite moverse a una sala existente" $ do
      let (msgs, est') = ejecutar (Ir Norte) (estadoInicial mundoSimulado)
      estadoSalaActual est' `shouldBe` "b"

    it "bloquea el paso si falta el objeto requerido" $ do
      let salaC = Sala "c" "Sala C" [Salida Este "a" (Just "llave")] []
          mundoBloqueado = mundoSimulado { mundoSalas = M.insert "c" salaC (mundoSalas mundoSimulado) }
          est = (estadoInicial mundoBloqueado) { estadoSalaActual = "c" }
          (msgs, est') = ejecutar (Ir Este) est
      estadoSalaActual est' `shouldBe` "c" -- No se movió
      msgs `shouldSatisfy` (any ("bloqueada" `isInfixOf`))

    it "toma un objeto de la sala y lo pone en el inventario" $ do
      let (msgs, est') = ejecutar (Tomar "carnet") (estadoInicial mundoSimulado)
      estadoInventario est' `shouldBe` ["carnet"]

    it "suelta un objeto del inventario en la sala" $ do
      let est = (estadoInicial mundoSimulado) { estadoInventario = ["carnet"] }
          (msgs, est') = ejecutar (Soltar "carnet") est
      estadoInventario est' `shouldBe` []
      (salaObjetos (mundoSalas (estadoMundo est') M.! "a")) `shouldSatisfy` (elem "carnet")

  describe "Motor.Nucleo - Condiciones de Victoria y Turnos" $ do
    it "gana si se cumple la meta (LlegarASala)" $ do
      let est = (estadoInicial mundoSimulado) { estadoSalaActual = "b" }
      metaCumplida est `shouldBe` True

    it "no gana si no se ha llegado a la meta" $ do
      let est = (estadoInicial mundoSimulado) { estadoSalaActual = "a" }
      metaCumplida est `shouldBe` False

    it "gasta turnos al moverse" $ do
      let mundoTurnos = mundoSimulado { mundoTurnos = 5 }
          (_, est') = ejecutar (Ir Norte) (estadoInicial mundoTurnos)
      turnosRestantes est' `shouldBe` 4

    it "detecta cuando se acaban los turnos" $ do
      let mundoTurnos = mundoSimulado { mundoTurnos = 1 }
          (_, est') = ejecutar (Ir Norte) (estadoInicial mundoTurnos)
      sinTurnos est' `shouldBe` True
      
    it "no gasta turnos al mirar" $ do
      let mundoTurnos = mundoSimulado { mundoTurnos = 5 }
          (_, est') = ejecutar Mirar (estadoInicial mundoTurnos)
      turnosRestantes est' `shouldBe` 5