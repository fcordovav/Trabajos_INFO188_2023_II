module Main where

import System.Environment
import System.Random
import System.Process
import Data.List.Split (chunksOf)

data Celda = Caminable | Lava | Obstaculo | Tesoro | Personaje deriving (Eq)

instance Show Celda where
    show Caminable = " "
    show Lava = "$"
    show Obstaculo = "L"
    show Tesoro = "X"
    show Personaje = "@"

data Game = Game
    {
    tamMapa :: Int,
    posTesoro :: (Int, Int),
    posPersonaje :: (Int, Int),
    mapa :: [[Celda]],
    posLava :: [(Int,Int)]
    }

main :: IO ()
main = do
    args <- getArgs
    if length args /= 2
        then putStrLn "Debe ejecutar el codigo de la siguente forma\n./max <n> <s>\nn = Tamaño del mapa\ns = Semilla"
        else do
            let n = read (args !! 0) :: Int
                s = read (args !! 1) :: Int
            if n < 6
                then putStrLn "El valor de n debe ser mayor o igual a 6 para el correcto funcionamiento."
                else do
                    let gen = mkStdGen s
                        (x, gen') = randomR (0, n - 1) gen
                        (y, gen'') = randomR (0, n - 1) gen'
                        (x',gen''') = checkPosition n (x, gen'')
                        (y',_) = checkPosition n (y, gen''')

                    let game = generateGame n s (x, y) (x',y')

                    gameLoop game

gameLoop :: Game -> IO ()
gameLoop game
    | posPersonaje game == posTesoro game = do
      printGame game
      putStrLn "¡Has encontrado el tesoro! ¡Has ganado!"
    | elem (posPersonaje game) (posLava game) = do
        printGame game
        putStrLn "¡Caíste a la lava!¡GAME OVER!"
        return () 
    | otherwise = do
      printGame game
      putStrLn "Ingrese una opción (W/A/S/D) para moverse, 'R' para reiniciar el mapa y 'Q' para salir): "
      option <- getLine
      randomSeed <- getStdRandom random -- Genera un número aleatorio
      let game' = case option of
            "W" -> arriba game
            "w" -> arriba game
            "A" -> izquierda game
            "a" -> izquierda game
            "S" -> abajo game
            "s" -> abajo game
            "D" -> derecha game
            "d" -> derecha game
            "Q" -> game
            "q" -> game
            "R" -> generateGame (tamMapa game) (randomSeed) (posTesoro game) (posPersonaje game)
            "r" -> generateGame (tamMapa game) (randomSeed) (posTesoro game) (posPersonaje game)
            _   -> game
      if option /= "Q"
            then gameLoop game'
            else return ()

-- Función simple que mueve el personaje hacia arriba, verificando que sea un movimiento válido y que no se salga de los bordes
arriba :: Game -> Game
arriba game@Game{posPersonaje=(x,y), mapa=mapa} = 
    let newPos = (x, y-1)
    in if y > 0 && checkMov newPos mapa
        then actualizarMapa game newPos
        else game

-- Función simple que mueve el personaje hacia la izquierda, verificando que sea un movimiento válido y que no se salga de los bordes
izquierda :: Game -> Game
izquierda game@Game{posPersonaje=(x,y), mapa=mapa} = 
    let newPos = (x-1, y)
    in if x > 0 && checkMov newPos mapa
        then actualizarMapa game newPos
        else game

-- Función simple que mueve el personaje hacia abajo, verificando que sea un movimiento válido y que no se salga de los bordes
abajo :: Game -> Game
abajo game@Game{posPersonaje=(x,y), tamMapa=n, mapa=mapa} = 
    let newPos = (x, y+1)
    in if y < n-1 && checkMov newPos mapa
        then actualizarMapa game newPos
        else game

-- Función simple que mueve el personaje hacia la derecha, verificando que sea un movimiento válido y que no se salga de los bordes
derecha :: Game -> Game
derecha game@Game{posPersonaje=(x,y), tamMapa=n, mapa=mapa} = 
    let newPos = (x+1, y)
    in if x < n-1 && checkMov newPos mapa
        then actualizarMapa game newPos
        else game

-- Función que verifica que el movimiento sea válido, es decir, que no atraviese obstáculos. 
-- Si el siguente paso es lava, se toma como valido, ya que otra parte
-- del código se encarga de verificar si pisa lava, ahi muere y termina el juego
checkMov :: (Int, Int) -> [[Celda]] -> Bool
checkMov (x,y) mapa = case (mapa !! y) !! x of
    Caminable -> True
    Tesoro -> True
    Lava -> True
    _ -> False
 
-- Para actualizar la nueva posición del personaje 
actualizarMapa :: Game -> (Int, Int) -> Game
actualizarMapa game@Game{posPersonaje=oldPos, mapa=map} newPos@(x,y) =
    let mapaActualizado = borraObjetos oldPos map
        newMap = agregaObjetos newPos Personaje mapaActualizado
    in game {posPersonaje = newPos, mapa = newMap}

-- Para borrar la posicion antigua del personaje
borraObjetos :: (Int, Int) -> [[Celda]] -> [[Celda]]
borraObjetos (x, y) grid = 
    take y grid ++ [take x (grid !! y) ++ [Caminable] ++ drop (x+1) (grid !! y)] ++ drop (y+1) grid

generarMurallas :: Int -> Int -> [[Celda]] -> [[Celda]]
generarMurallas _ _ [] = []
generarMurallas n s (fila:filasRestantes) =
    let (anchura, s') = randomR (2, 6) (mkStdGen s)  -- define la anchura de los obstaculos, en este caso, pueden ser de ancho 2-3-4
        probabilidadGeneracion =20::Int  -- Probabilidad de generación de murallas (ajustar según sea necesario)
        (posicion, s'') = randomR (0, n - anchura) s'
        (generarMuralla, s''') = randomR (1::Int, 100) s''
        muralla = if generarMuralla <= probabilidadGeneracion 
            then replicate anchura Obstaculo 
            else if generarMuralla <= 2*probabilidadGeneracion
                then replicate anchura Lava
                else replicate anchura Caminable
        filaConMuralla = take posicion fila ++ muralla ++ drop (posicion + anchura) fila
    in filaConMuralla : generarMurallas n (fst (next s'')) filasRestantes


generateGame :: Int -> Int -> (Int, Int) -> (Int, Int) -> Game
generateGame n s (x, y) (x', y') =
    let gen = mkStdGen s
        filaCaminable = replicate n Caminable
        mapaCaminable = replicate n filaCaminable
        mapaConMurallas = generarMurallas n s mapaCaminable
        celdas = agregaObjetos (x, y) Tesoro mapaConMurallas
        celdas2 = agregaObjetos (x', y') Personaje celdas
        lavas = posicionesLava Lava celdas2
    in Game { tamMapa = n, posTesoro = (x, y), posPersonaje = (x', y'), mapa = celdas2, posLava =lavas }


-- Función para verificar si dos posiciones son distintas y generar una nueva posición si no lo son.
checkPosition :: Int -> (Int, StdGen) -> (Int, StdGen)
checkPosition n (pos, gen) = 
    let (pos', gen') = randomR (0, n - 1) gen
    in if pos' /= pos
        then (pos', gen')
        else checkPosition n (pos, gen')

-- Agrega el personaje o tesoro en las posiciones aleatorias
agregaObjetos :: (Int, Int) -> Celda -> [[Celda]] -> [[Celda]]
agregaObjetos (x, y) objeto grid = take y grid ++ [take x (grid !! y) ++ [objeto] ++ drop (x+1) (grid !! y)] ++ drop (y+1) grid

-- Busca las posiciones de las lavas y devuelve una lista con las coordenadas
posicionesLava :: Celda -> [[Celda]] -> [(Int,Int)]
posicionesLava objeto mapa = [(x, y) | (y, row) <- zip [0..] mapa, (x, celda) <- zip [0..] row, celda == objeto]

-- Función para convertir una posición (Int, Int) a una semilla para generar números aleatorios
posToSeed :: (Int, Int) -> Int
posToSeed (x, y) = mod (2654435761 * x + 2654435769 * y) 1000000007

-- Limpia la consola "clear"
limpiarConsola :: IO ()
limpiarConsola = do
    _ <- system "clear"  -- Para Ubuntu
    --_ <- system "cls"  -- Para Windows
    return ()

-- Imprime el tablero ordenado y bonito
printGame :: Game -> IO ()
printGame game = do
    limpiarConsola
    let n = tamMapa game
        border = "□" ++ (replicate n '-') ++ "□"
        gameMap = mapa game
        printRow row = putStrLn $ "|" ++ row ++ "|"
    putStrLn $ "Tamaño del mundo: " ++ show n ++ "x" ++ show n
    putStrLn $ "Tesoro en la posición: " ++ show (posTesoro game)
    putStrLn "Mapa:"
    putStrLn border
    mapM_ printRow (map (concatMap show) gameMap)
    putStrLn border