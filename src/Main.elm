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
    , similarity : Float
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

red : Timings
red = [ 0.0, 0.05
      , 0.10, 0.25
      , 0.30, 0.35
      , 0.475, 0.525
      , 0.65, 0.80
      , 0.85, 0.90
      , 0.95, 1.0
      ]

calculateMatchingTime : Timings -> Timings -> Float
calculateMatchingTime timings1 timings2 =
    let
        -- Convert timings to intervals with state (True = key down, False = key up)
        toIntervals : Timings -> List (Float, Float, Bool)
        toIntervals timings =
            case timings of
                [] -> []
                _ -> 
                    List.map2 
                        (\start end -> (start, end, modBy 2 (List.length (List.filter (\t -> t <= start) timings)) == 0))
                        timings
                        (List.drop 1 timings ++ [1.0])
        
        -- Get all intervals from both timings
        intervals1 = toIntervals timings1
        intervals2 = toIntervals timings2
        
        -- Find overlapping intervals with matching states
        findOverlaps : List (Float, Float, Bool) -> List (Float, Float, Bool) -> Float
        findOverlaps ints1 ints2 =
            List.foldl 
                (\(start1, end1, state1) acc ->
                    acc + List.foldl 
                        (\(start2, end2, state2) innerAcc ->
                            if state1 == state2 then
                                let
                                    overlapStart = max start1 start2
                                    overlapEnd = min end1 end2
                                    overlap = max 0 (overlapEnd - overlapStart)
                                in
                                    innerAcc + overlap
                            else
                                innerAcc
                        ) 0 ints2
                ) 0 ints1
    in
        findOverlaps intervals1 intervals2


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
      , similarity = 0.0
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
                newEvents = List.append model.events [newEvent]
                score = calculateMatchingTime (rescaledTimeline newEvents) red
            in
            ( { model |  events = newEvents
              , similarity = score}, Cmd.none )

        Reset ->
            init ()

-- VIEW
view : Model -> Html Msg
view model =
    div [ class "page" ]
        [ button [ id "key", onMouseDown MorseKeyDown, onMouseUp MorseKeyUp ]
            [ text (if model.playingTone then "Beep" else "") ]
        , viewMorseTimeline (rescaledTimeline model.events)
        , viewMorseTimeline red
        , div [] [ model.similarity |> String.fromFloat |> text  ]
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
