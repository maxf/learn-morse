port module Main exposing (main)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick, onMouseDown, onMouseUp)
import Html.Attributes exposing (id, class, style)
import Json.Encode
import Time exposing (Posix, posixToMillis)
import Task

-- PORTS
port startTone : (() -> Cmd msg)
port stopTone : (() -> Cmd msg)

-- MODEL

type alias Timings = List Float

type MorseEvent
    = KeyDown
    | KeyUp

type alias TimedMorseEvent =
    { event : MorseEvent
    , timestamp: Time.Posix
    }

type alias Model =
    { events : List TimedMorseEvent
    , playingMorse : Bool
    , playingTone: Bool
    }


minMax : List Int -> Maybe (Int, Int)
minMax list =
    let
        max = List.maximum list
        min = List.minimum list
    in
    case ( max, min ) of
        ( Just a, Just b ) -> Just ( a, b )
        _ -> Nothing


rescaledTimeline : List TimedMorseEvent -> Timings
rescaledTimeline events =
    let
        eventsInt = List.map (\e -> posixToMillis e.timestamp) events
    in
        case minMax eventsInt of
            Nothing -> []
            Just (min, max) ->
                List.map (\ts -> ((toFloat (ts - min)) / (toFloat (max-min)))) eventsInt


    
init : () -> ( Model, Cmd Msg )
init _ =
    ( {
      events = []
      , playingMorse = False
      , playingTone = False
    }, Cmd.none )

-- UPDATE
type Msg
    = MorseKeyDown
    | MorseKeyUp
    | RecordEvent MorseEvent Time.Posix
    | Reset

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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

        Reset ->
            init ()


-- VIEW
view : Model -> Html Msg
view model =
    div [ class "page" ]
        [ button [ id "key", onMouseDown MorseKeyDown, onMouseUp MorseKeyUp ]
            [ text (if model.playingTone then "Beep" else "") ]
        , viewMorseTimeline (rescaledTimeline model.events)
        , button [ id "reset", onClick Reset ] [ text "Reset" ]
        ]

viewEventSegment : Float -> Html Msg
viewEventSegment x =
    div
        [ class "segment"
        , style "width" (((x * 100) |> String.fromFloat) ++ "%")
        ]
        []

viewMorseTimeline : Timings -> Html Msg
viewMorseTimeline events =
    let
        tail = List.drop 1 events
        divs = List.map2 (\prev curr -> viewEventSegment (curr - prev)) events tail
    in
    div [ id "timeline" ] (List.reverse divs)



-- MAIN
main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }
