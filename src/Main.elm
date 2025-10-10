port module Main exposing (main)

import Browser
import Process
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick, onMouseDown, onMouseUp)
import Html.Attributes exposing (id, class, style)
import Json.Encode
import Time exposing (Posix, posixToMillis)
import Task

import MorseCode exposing (dotDuration, dashDuration, pauseDuration)

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
    , lastActivity: Maybe Time.Posix
    }


minMax : List Int -> Maybe (Int, Int)
minMax list =
    let
        min = List.minimum list
        max = List.maximum list
    in
    case ( min, max ) of
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
                List.map (\ts -> ((toFloat (ts-min)) / (toFloat (max-min)))) eventsInt


    
init : () -> ( Model, Cmd Msg )
init _ =
    ( {
      events = []
      , playingMorse = False
      , playingTone = False
      , lastActivity = Nothing
    }, Cmd.none )

-- UPDATE
type Msg
    = MorseKeyDown
    | MorseKeyUp
    | RecordEvent MorseEvent Time.Posix
    | TimeoutFired Time.Posix
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

        RecordEvent morseEvent timestamp ->
            let
                newEvent = TimedMorseEvent morseEvent timestamp
                newEvents = List.append model.events [newEvent]
                command =
                    case morseEvent of
                        KeyDown ->
                            Cmd.none
                        KeyUp ->
                            -- When the user releases the key, start counting
                            Process.sleep 3000 |>
                                Task.perform (\_ -> TimeoutFired timestamp)       
            in
            ( { model |  events = newEvents, lastActivity = Just timestamp }
            , command
            )

        TimeoutFired timestamp ->
            -- Check if this timeout is the one we care about.
            if model.lastActivity == Just timestamp then
                -- It is! No key presses for a few seconds, so check the pattern
                -- from model.events
                init ()  -- for now, reset

            else
                -- A newer key press occurred. Ignore this stale timeout.
                ( model, Cmd.none )

                
            
        Reset ->
            init ()

-- VIEW
view : Model -> Html Msg
view model =
    div [ class "page" ]
        [ button [ id "key", onMouseDown MorseKeyDown, onMouseUp MorseKeyUp ]
            [ text (if model.playingTone then "Beep" else "") ]
        , viewMorseTimeline (rescaledTimeline model.events)
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
    div [ id "timeline" ] divs



-- MAIN
main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }
