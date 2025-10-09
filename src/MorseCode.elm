module MorseCode exposing (dotDuration, dashDuration, pauseDuration)
import Dict exposing (Dict)

dotDuration = 250

dashDuration = dotDuration * 3

pauseDuration = dotDuration

patternMap : Dict String String
patternMap =
    Dict.fromList
        [ (".-", "A")
        , ("-...", "B")
        , ("-.-.", "C")
        , ("-..", "D")
        , (".", "E")
        , ("..-.", "F")
        , ("--.", "G")
        , ("....", "H")
        , ("..", "I")
        , (".---", "J")
        , ("-.-", "K")
        , (".-..", "L")
        , ("--", "M")
        , ("-.", "N")
        , ("---", "O")
        , (".--.", "P")
        , ("--.-", "Q")
        , (".-.", "R")
        , ("...", "S")
        , ("-", "T")
        , ("..-", "U")
        , ("...-", "V")
        , (".--", "W")
        , ("-..-", "X")
        , ("-.--", "Y")
        , ("--..", "Z")
        , ("-----", "0")
        , (".----", "1")
        , ("..---", "2")
        , ("...--", "3")
        , ("....-", "4")
        , (".....", "5")
        , ("-....", "6")
        , ("--...", "7")
        , ("---..", "8")
        , ("----.", "9")
        ]


addSequence : String -> String -> String
addSequence sequence newSymbol =
    case newSymbol of
        "." -> sequence ++ newSymbol
        "-" -> sequence ++ newSymbol
        _ -> sequence

addDash : String -> String
addDash sequence =
    addSequence sequence "-"

addDot : String -> String
addDot sequence =
    addSequence sequence "."


resolveSequence : String -> Maybe String
resolveSequence sequence =
    Dict.get sequence patternMap
