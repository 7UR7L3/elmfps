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
  { number: Int
  , name: String
  , position: List (Float)
  , health: Int
  , score: Int
  }

pToString : List(Player) -> Int -> String
pToString p i = case p of
  first :: rest -> 
    if i == 0 then case first of
      {number, name, position, health, score} ->
        String.append (String.append (String.append (String.append (String.append (String.append (String.append (String.append (toString number) ";") name) ";") (toString position)) ";") (toString health)) ";") (toString score)
    else
      pToString rest (i-1)
  _ -> "fail"

psToString: List(Player) -> String
psToString p = case p of
  [] -> ""
  first :: rest ->
    String.append (pToString p 0) (psToString rest)

type alias Model =
  { time: String
  , which: Int
  , players: List (Player)
  , message: List (String)
  }


init : (Model, Cmd Msg)
init =
  let pls = [Player 0 "Player 1" [0,1,2] 1000 0 ,Player 1 "Player 2"  [-20,45.6,-73.2] 750 2,Player 2 "Player 3" [34,2314,-2435] 500 12, Player 3 "Frank" [6,66,-666] 12 6666] in
  (Model "0" 1 pls ["Start!"],  Cmd.none)

-- UPDATE

type Msg
  = Send Time
  | NewMessage String


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case (msg,model) of
    (Send time2, {time, which, players, message}) ->
      (Model (toString time2) which players message, WebSocket.send "ws://localhost:3000" (pToString players which))
      --(Model time2 message, WebSocket.send "ws://echo.websocket.org" (String.append "Time: " (toString time2)))

    (NewMessage mesg, {time,which, players,message})->
      let ap = (getMessageH players (String.split "?" mesg)) in
      let pls = Debug.log "pls" 1 in
      let throw = Debug.log "Altered Players" ap in
      (Model time which ap (getMessage2 model (String.split "?" mesg)), Cmd.none)
      --(Model time which players (getMessage2 model [mesg]), Cmd.none)
      --(Model input (str :: messages), Cmd.none)

getMessage2 : Model -> List (String) -> List (String)
getMessage2 m s = case (m, s) of
  (_, []) -> getMessage m
  ({time, which, players, message},_) -> getMessage (Model time which (getMessageH players s) message)
      

getMessageH : List(Player) -> List(String) -> List(Player)
getMessageH p s = case (p, s) of
  (_,[]) -> p
  (firstp :: restp, "" :: rests) -> firstp :: (getMessageH restp rests)
  ([], firsts :: rests) ->
    if firsts == "" then getMessageH [] rests else
    if firsts == "something" then p else
    let l = String.split ";" firsts in
    case l of
      a :: (b :: (c :: (d :: (e::[])))) ->
        (Player (Result.withDefault 0 (String.toInt a)) b (List.map (Result.withDefault 0 << String.toFloat) (String.split (String.slice 1 (String.length c) c) "," )) (Result.withDefault 0 <| String.toInt d) (Result.withDefault 0 <| String.toInt e)) :: (getMessageH [] rests) 
      _ -> []
  (_ :: restp, firsts :: rests) ->
    if firsts == "something" then p else
    let l = String.split ";" firsts in
    --case l of
    --  a :: (b :: (c :: (d :: (e :: [])))) ->
    --    (Player -1 d [-0.1] -1 -1) :: (getMessageH restp rests)
    --  _ -> (Player -1 "fail" [-0.1] -1 -1) :: (getMessageH restp rests)
    case l of
      a :: (b :: (c :: (d :: (e::[])))) ->
        --(Player (Result.withDefault 0 (String.toInt a)) (String.join "||" (String.split "," (String.slice 1 ((String.length c)-1) c) )) (List.map (Result.withDefault 0 << String.toFloat) (String.split "," (String.slice 1 ((String.length c)-1) c) )) (Result.withDefault 0 <| String.toInt d) (Result.withDefault 0 <| String.toInt e)) :: (getMessageH restp rests) 
        (Player (Result.withDefault 0 (String.toInt a)) b (List.map (Result.withDefault 0 << String.toFloat) (String.split "," (String.slice 1 ((String.length c)-1) c) )) (Result.withDefault 0 <| String.toInt d) (Result.withDefault 0 <| String.toInt e)) :: (getMessageH restp rests) 
      _ -> []


getMessage : Model -> List (String)
getMessage m = case m of
  {time, which, players, message} ->
    List.append [String.append "Player " (toString which), String.append "Time: " time, "       ", " "] (getPlayers players)

getPlayers : List (Player) -> List(String)
getPlayers p = case p of
  [] -> [""]
  only :: [] -> [String.append only.name (": "), String.append "Position: " (toString only.position), String.append "Health: " (toString only.health), String.append "Score: " (toString only.score)]
  first :: rest -> List.append [String.append first.name (": "), String.append "Position: " (toString first.position), String.append "Health: " (toString first.health), String.append "Score: " (toString first.score), " "] (getPlayers rest)

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
  [WebSocket.listen "ws://localhost:3000" NewMessage, Time.every Time.second Send]

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