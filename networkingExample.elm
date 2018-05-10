import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import WebSocket
import Time exposing(Time,second)
import Task


main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


-- MODEL

type alias Player =
  { name: String
  , position: List (Float)
  , health: Int
  , score: Int
  }

type alias Model =
  { time: Time
  , players: List (Player)
  , message: List (String)
  }


init : (Model, Cmd Msg)
init =
  let pls = [Player "Player 1" [0,1,2] 1000 0 ,Player "Player 2"  [-20,45.6,-73.2] 750 2,Player "Player 3" [34,2314,-2435] 500 12, Player "Frank" [6,66,-666] 12 6666] in
  (Model 0 pls ["Start!"],  Cmd.none)

-- UPDATE

type Msg
  = Send Time
  | NewMessage String


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case (msg,model) of
    (Send time2, {time, players, message}) ->
      (Model time2 players message, WebSocket.send "ws://echo.websocket.org" (toString time))
      --(Model time2 message, WebSocket.send "ws://echo.websocket.org" (String.append "Time: " (toString time2)))

    (NewMessage time2, {time,players,message})->
      (Model time players (getMessage model), Cmd.none)
      --(Model input (str :: messages), Cmd.none)

getMessage : Model -> List (String)
getMessage m = case m of
  {time, players, message} ->
    List.append [String.append "Time: " (toString time), "       ", " "] (getPlayers players)

getPlayers : List (Player) -> List(String)
getPlayers p = case p of
  [] -> [""]
  only :: [] -> [String.append only.name (": "), String.append "Position: " (toString only.position), String.append "Health: " (toString only.health), String.append "Score: " (toString only.score)]
  first :: rest -> List.append [String.append first.name (": "), String.append "Position: " (toString first.position), String.append "Health: " (toString first.health), String.append "Score: " (toString first.score), " "] (getPlayers rest)

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
  [WebSocket.listen "ws://echo.websocket.org" NewMessage, Time.every Time.millisecond Send]

-- VIEW

view : Model -> Html Msg
view model =
  div []
    [ div [] (List.map viewMessage model.message)
    --, button [onClick (Send 2)] [text "Send"]
    ]

--getTime:Float


viewMessage : String -> Html msg
viewMessage msg =
  if msg == " " then div [style [("color","white")]][text "space"]
  else div [] [ text msg ]