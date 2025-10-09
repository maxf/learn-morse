
/*
```elm
import Browser
import Process
import Task
import Time

main =
    Browser.sandbox { init = init, update = update, view = ... }

-- MODEL
type alias Model =
    { lastActivity : Maybe Time.Posix }

init : Model
init =
    { lastActivity = Nothing }

-- UPDATE
type Msg
    = KeyPressed
    | HandleActivity Time.Posix -- Receives current time
    | TimeoutFired Time.Posix   -- Message from the timeout

update : Msg -> Model -> Model
update msg model =
    case msg of
        KeyPressed ->
            -- Get the current time to handle the activity.
            ( model, Time.now HandleActivity )

        HandleActivity now ->
            -- 1. Store the new timestamp.
            -- 2. Create a new timeout tagged with this timestamp.
            let
                newModel =
                    { model | lastActivity = Just now }

                timeoutCmd =
                    Process.sleep 10000 -- 10 seconds
                        |> Task.perform (\_ -> TimeoutFired now)
            in
            ( newModel, timeoutCmd )

        TimeoutFired timestamp ->
            -- Check if this timeout is the one we care about.
            if model.lastActivity == Just timestamp then
                -- It is! No key presses for 10 seconds.
                -- Perform your action here.
                ( model, Cmd.none )

            else
                -- A newer key press occurred. Ignore this stale timeout.
                ( model, Cmd.none )
