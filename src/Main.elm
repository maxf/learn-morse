port module Main exposing (main)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick, onMouseDown, onMouseUp)
import Html.Attributes exposing (id)
import Json.Encode
import Time exposing (Posix)
import Task

-- PORTS
port playMorse : String -> Cmd msg
port morseComplete : (() -> msg) -> Sub msg

port startTone : (() -> Cmd msg)
port stopTone : (() -> Cmd msg)

-- MODEL

type MorseEvent
    = KeyDown
    | KeyUp

type alias TimedMorseEvent =
    { event : MorseEvent
    , timeStamp: Time.Posix
    }

type alias Model =
    { text : String
    , events : List TimedMorseEvent
    , playingMorse : Bool
    , playingTone: Bool
    }

init : () -> ( Model, Cmd Msg )
init _ =
    ( {
      text = "init text"
      , events = []
      , playingMorse = False
      , playingTone = False
    }, Cmd.none )

-- UPDATE
type Msg
    = PlayMorse
    | MorseComplete
    | MorseKeyDown
    | MorseKeyUp
    | RecordEvent MorseEvent Time.Posix

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PlayMorse ->
            ( { model | playingMorse = True }
            , playMorse (stringToMorse model.text)
            )
            
        MorseComplete ->
            ( { model | playingMorse = False }, Cmd.none )

        MorseKeyDown ->
            ( { model | playingTone = True }
            , Cmd.batch
                [ Time.now |> Task.perform (RecordEvent KeyDown)
                , startTone ()
                ]
            )

        MorseKeyUp ->
            ( { model | playingTone = False }
            , Cmd.batch
                [ Time.now |> Task.perform (RecordEvent KeyUp)
                , stopTone ()
                ]
            )

        RecordEvent morseEvent timeStamp ->
            let
                newEvent = TimedMorseEvent morseEvent timeStamp
                newEvents = List.append [newEvent] model.events
            in
            ( { model |  events = newEvents }, Cmd.none )


stringToMorse : String -> String
stringToMorse s =
    let
        characters = String.split "" s
    in
    String.join " " (List.map characterToMorse characters)

-- Convert a single character to Morse code
characterToMorse : String -> String
characterToMorse char =
    case String.toUpper char of
        -- Numbers
        "0" -> "-----"
        "1" -> ".----"
        "2" -> "..---"
        "3" -> "...--"
        "4" -> "....-"
        "5" -> "....."
        "6" -> "-...."
        "7" -> "--..."
        "8" -> "---.."
        "9" -> "----."
        
        -- Letters (uppercase)
        "A" -> ".-"
        "B" -> "-..."
        "C" -> "-.-."
        "D" -> "-.."
        "E" -> "."
        "F" -> "..-."
        "G" -> "--."
        "H" -> "...."
        "I" -> ".."
        "J" -> ".---"
        "K" -> "-.-"
        "L" -> ".-.."
        "M" -> "--"
        "N" -> "-."
        "O" -> "---"
        "P" -> ".--."
        "Q" -> "--.-"
        "R" -> ".-."
        "S" -> "..."
        "T" -> "-"
        "U" -> "..-"
        "V" -> "...-"
        "W" -> ".--"
        "X" -> "-..-"
        "Y" -> "-.--"
        "Z" -> "--.."
        
        -- Punctuation
        "." -> ".-.-.-"
        "," -> "--..--"
        "?" -> "..--.."
        "'" -> ".----."
        "!" -> "-.-.--"
        "/" -> "-..-."
        "(" -> "-.--."
        ")" -> "-.--.-"
        "&" -> ".-..."
        ":" -> "---..."
        ";" -> "-.-.-."
        "=" -> "-...-"
        "+" -> ".-.-."
        "-" -> "-....-"
        "_" -> "..--.-"
        "\"" -> ".-..-."
        "$" -> "...-..-"
        "@" -> ".--.-."
        
        -- Default for unknown characters
        _ -> ""

-- VIEW
view : Model -> Html Msg
view model =
    div []
        [ div [] [ text model.text ]
        , button [ onClick PlayMorse ]
            [ text 
                (if model.playingMorse then
                    "Playing..." 
                 else 
                    "Play Morse"
                )
            ]
        , button [ id "key", onMouseDown MorseKeyDown, onMouseUp MorseKeyUp ]
            [ text
                (if model.playingTone then
                    "Beep"
                 else
                    ""
                )
            ]
        ]

-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions _ =
    morseComplete (\_ -> MorseComplete)

-- MAIN
main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
