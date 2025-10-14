port module Main exposing (main)

import Browser
import Process
import Dict exposing (Dict)
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick, onMouseDown, onMouseUp)
import Html.Attributes exposing (id, class, style)
import Json.Decode
import Json.Encode
import Time exposing (Posix, posixToMillis)
import Task

dotDuration = 250

dashDuration = dotDuration * 3

pauseDuration = dotDuration

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
    , playingTone : Bool
    , lastActivity : Maybe Time.Posix
    , interpretedWord : Maybe String
    , introModalSeen : Bool 
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
      , playingTone = False
      , lastActivity = Nothing
      , interpretedWord = Nothing
      , introModalSeen = False
    }, Cmd.none )

-- UPDATE
type Msg
    = MorseKeyDown
    | MorseKeyUp
    | RecordEvent MorseEvent Time.Posix
    | TimeoutFired Time.Posix
    | Reset
    | UserClosedIntroModal

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UserClosedIntroModal ->
            ( { model | introModalSeen = True }, Cmd.none)
                
        MorseKeyDown ->
            ( { model | playingTone = True }
            , Cmd.batch
                [ startTone ()
                , Task.perform (RecordEvent KeyDown) Time.now
                ]
            )

        MorseKeyUp ->
            ( { model | playingTone = False }
            , Cmd.batch
                [ stopTone ()
                , Task.perform (RecordEvent KeyUp) Time.now
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
                            Task.perform
                                (\_ -> TimeoutFired timestamp)
                                (Process.sleep 3000)       
            in
            ( { model |  events = newEvents, lastActivity = Just timestamp }
            , command
            )

        TimeoutFired timestamp ->
            -- Check if this timeout is the one we care about.
            if model.lastActivity == Just timestamp then
                -- It is! No key presses for a few seconds, so check the pattern
                -- from model.events
                -- init ()  -- for now, reset
                ({ model | interpretedWord = interpretTimeline model.events, events = [], lastActivity = Nothing }
                , Cmd.none
                ) 

            else
                -- A newer key press occurred. Ignore this stale timeout.
                ( model, Cmd.none )
        
        Reset ->
            init ()

timelineToDuration : List TimedMorseEvent -> List Int 
timelineToDuration timeline =
    List.map2 (\a b -> posixToMillis b.timestamp - posixToMillis a.timestamp) timeline (List.drop 1 timeline)

        
interpretTimeline : List TimedMorseEvent -> Maybe String
interpretTimeline timeline =
    let
        durations : List Int
        durations = timelineToDuration timeline
        morse : String
        morse = durationsToMorse durations
    in
        morseToMaybeText morse
    

durationsToMorse : List Int -> String
durationsToMorse durations =
    -- [123, 383, 430, 300, 602, 100] -> ".- -"
    let
        transform : Int -> Int -> String
        transform index duration =
            if remainderBy 2 index == 0 then -- this is a tone
                if duration <= dotDuration then
                    "."
                else
                    "-"
            else -- this is a pause
                if duration > pauseDuration then
                    " "
            else
                ""
    in
    List.indexedMap transform durations |> String.concat


morseToMaybeText : String -> Maybe String
morseToMaybeText morseString =
    let
        -- 1. Split the string into codes. `String.words` correctly
        -- handles any amount of whitespace between codes, satisfying
        -- the "collapse whitespace" requirement.
        morseCodes : List String
        morseCodes =
            String.words morseString

        -- 2. Attempt to translate each code.
        maybeLetters : List (Maybe String)
        maybeLetters =
            List.map (\code -> Dict.get code morseMap) morseCodes

        -- 3. Convert the list of potential failures into a single
        -- potential failure. This results in Nothing if any code
        -- was invalid.
        allOrNothing : Maybe (List String)
        allOrNothing =
            List.foldr (Maybe.map2 (::)) (Just []) maybeLetters
    in
    -- 4. If we have a successful list of letters, join them.
    -- The result remains wrapped in a `Maybe`.
    Maybe.map String.concat allOrNothing                   

morseMap : Dict String String
morseMap =
    Dict.fromList
        -- Letters (A-Z)
        [ ( ".-", "A" ), ( "-...", "B" ), ( "-.-.", "C" ), ( "-..", "D" ), ( ".", "E" ), ( "..-.", "F" ), ( "--.", "G" ), ( "....", "H" ), ( "..", "I" ), ( ".---", "J" ), ( "-.-", "K" ), ( ".-..", "L" ), ( "--", "M" ), ( "-.", "N" ), ( "---", "O" ), ( ".--.", "P" ), ( "--.-", "Q" ), ( ".-.", "R" ), ( "...", "S" ), ( "-", "T" ), ( "..-", "U" ), ( "...-", "V" ), ( ".--", "W" ), ( "-..-", "X" ), ( "-.--", "Y" ), ( "--..", "Z" )

        -- Digits (0-9)
        , ( "-----", "0" ), ( ".----", "1" ), ( "..---", "2" ), ( "...--", "3" ), ( "....-", "4" ), ( ".....", "5" ), ( "-....", "6" ), ( "--...", "7" ), ( "---..", "8" ), ( "----.", "9" )

        -- Punctuation
        , ( ".-.-.-", "." ), ( "--..--", "," ), ( "..--..", "?" ), ( ".----.", "'" ), ( "-.-.--", "!" ), ( "-..-.", "/" ), ( "-.--.", "(" ), ( "-.--.-", ")" ), ( ".-...", "&" ), ( "---...", ":" ), ( "-.-.-.", ";" ), ( "-...-", "=" ), ( ".-.-.", "+" ), ( "-....-", "-" ), ( "..--.-", "_" ), ( ".-..-.", "\"" ), ( "...-..-", "$" ), ( ".--.-.", "@" )
        ]
        


        
-- VIEW
view : Model -> Html Msg
view model =
    div [ class "page" ]
        (if model.introModalSeen then
        [ button 
            [ id "key"
            , class (if model.playingTone then "keydown" else "")
            , onMouseDown MorseKeyDown
            , onMouseUp MorseKeyUp
            , Html.Events.preventDefaultOn "touchstart" (Json.Decode.succeed (MorseKeyDown, True))
            , Html.Events.preventDefaultOn "touchend" (Json.Decode.succeed (MorseKeyUp, True))
            ]
            [ text "" ]
        , viewMorseTimeline (rescaledTimeline model.events)
        , div [] [ model.interpretedWord |> Maybe.withDefault "~" |> text ]
        ] else
        [ button [ id "start-button", onClick UserClosedIntroModal ] [ text "Start "] ])

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
