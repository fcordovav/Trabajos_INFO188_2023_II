module Main where

import System.Environment
import System.Random
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
    mapa :: [[Celda]]
    }

main :: IO ()
main = do
    args <- getArgs
    let n = read (args !! 0) :: Int
        s = read (args !! 1) :: Int

    let game = generateGame n s

    gameLoop game

gameLoop :: Game -> IO ()
gameLoop game = do
    printGame game
    putStrLn "Ingrese una opción (W/A/S/D para moverse, Q para salir): "
    option <- getLine
    let game' = case option of
            "W" -> arriba game
            "A" -> izquierda game
            "S" -> abajo game
            "D" -> derecha game
            "Q" -> game
            _ -> game
    if option /= "Q"
        then gameLoop game'
        else return ()

arriba :: Game -> Game
arriba game@Game{posPersonaje=(x,y), mapa=mapa} = 
    let newPos = (x, y-1)
    in if y > 0 && checkMov newPos mapa
        then actualizarMapa game newPos
        else game

izquierda :: Game -> Game
izquierda game@Game{posPersonaje=(x,y), mapa=mapa} = 
    let newPos = (x-1, y)
    in if x > 0 && checkMov newPos mapa
        then actualizarMapa game newPos
        else game

abajo :: Game -> Game
abajo game@Game{posPersonaje=(x,y), tamMapa=n, mapa=mapa} = 
    let newPos = (x, y+1)
    in if y < n-1 && checkMov newPos mapa
        then actualizarMapa game newPos
        else game

derecha :: Game -> Game
derecha game@Game{posPersonaje=(x,y), tamMapa=n, mapa=mapa} = 
    let newPos = (x+1, y)
    in if x < n-1 && checkMov newPos mapa
        then actualizarMapa game newPos
        else game

-- Funcion que verifica que el movimiento sea válido, es decir, que no atraviese obstáculos o lava
-- ni que se salga de los bordes
checkMov :: (Int, Int) -> [[Celda]] -> Bool
checkMov (x,y) mapa = case (mapa !! y) !! x of
    Caminable -> True
    Tesoro -> True
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

-- Crea el tablero
generateGame :: Int -> Int -> Game
generateGame n s =
    let gen = mkStdGen s
        positions = [(i, j) | i <- [0 .. n - 1], j <- [0 .. n - 1]]
        celdaList = map (\pos -> getCelda (mkStdGen (s * (posToSeed pos))) pos) positions
        (x, gen') = randomR (0, n - 1) gen
        (y, gen'') = randomR (0, n - 1) gen'
        (x',gen''') = checkPosition n (x, gen'')
        (y',_) = checkPosition n (y, gen''')
        celdas = agregaObjetos (x,y) Tesoro (chunksOf n celdaList)
        celdas2 = agregaObjetos (x',y') Personaje celdas
    in Game {tamMapa = n, posTesoro = (x, y), posPersonaje = (x',y'), mapa = celdas2}

-- Función para verificar si dos posiciones son distintas y generar una nueva posición si no lo son.
checkPosition :: Int -> (Int, StdGen) -> (Int, StdGen)
checkPosition n (pos, gen) = 
    let (pos', gen') = randomR (0, n - 1) gen
    in if pos' /= pos
        then (pos', gen')
        else checkPosition n (pos, gen')

-- agrega el personaje o tesoro en las posiciones aleatorias
agregaObjetos :: (Int, Int) -> Celda -> [[Celda]] -> [[Celda]]
agregaObjetos (x, y) objeto grid = take y grid ++ [take x (grid !! y) ++ [objeto] ++ drop (x+1) (grid !! y)] ++ drop (y+1) grid

-- Para crear las celdas del mapa, HAY QUE CAMBIAR ESTO
getCelda :: StdGen -> (Int, Int) -> Celda
getCelda gen pos =
    let (r, _) = randomR (0 :: Int, 100) gen
        in if r < 5
            then Obstaculo
            else if r < 10
                then Lava
                else Caminable

-- Función para convertir una posición a una semilla para generar números aleatorios
posToSeed :: (Int, Int) -> Int
posToSeed (x, y) = mod (2654435761 * x + 2654435769 * y) 1000000007

printGame :: Game -> IO ()
printGame game = do
    putStrLn $ "Tamaño del mundo: " ++ show (tamMapa game)
    putStrLn $ "Tesoro en la posición: " ++ show (posTesoro game)
    putStrLn "Mapa:"
    mapM_ (putStrLn . concatMap show) (mapa game)


