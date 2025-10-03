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
    = MorseComplete
    | MorseKeyDown
    | MorseKeyUp
    | RecordEvent MorseEvent Time.Posix

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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


-- VIEW
view : Model -> Html Msg
view model =
    div []
        [ div [] [ text model.text ]
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
