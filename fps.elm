port module Fps exposing (main, requestPointerLock)

import WebSocket
import Time exposing(Time, second)
import WebGL exposing (Mesh, Shader)
import WebGL.Settings.Blend as Blend
import WebGL.Settings.DepthTest as DepthTest
import Math.Vector3 exposing (Vec3, vec3, add, scale, normalize, length, dot, getX, getY, getZ)
import Math.Matrix4 exposing (Mat4, transform, makeRotate, mul, makeLookAt, makePerspective, inverseOrthonormal, transpose)
import AnimationFrame
import Window
import Html.Attributes exposing (width, height, style)
import Html exposing (Html)
import Time exposing (Time)
import Task
import Keyboard.Extra exposing (Key(..), Direction(..))
import Mouse

--Imported from networking
type alias Player =
  { number: Int
  , name: String
  , position: List(Float)
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
    String.append (String.append (pToString p 0) "\n") (psToString rest)

--Model imported from networking
--type alias Model =
--  { time: String
--  , which: Int
--  , players: List (Player)
--  , message: List (String)
--  }

--Update model
type alias Model =
    { which: Int
    , players: List (Player)
    , message: List (String)
    , size : Window.Size
    , angle : Float
    , position : Vec3
    , direction : Vec3
    , pressedKeys : List Key
    , connected : Bool
    }








main : Program Never Model Action
main =
    Html.program
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }

init : ( Model, Cmd Action )
init =
    ( { which = 0
      , players = [Player 0 "Player 1" [0,0.15,0] 1000 0]
      --Rest of example players ,Player 1 "Player 2"  [-20,45.6,-73.2] 750 2,Player 2 "Player 3" [34,2314,-2435] 500 12, Player 3 "Frank" [6,66,-666] 12 6666]
      , message = ["Start!"]
      , size = Window.Size 0 0
      , angle = 0
      , position = vec3 0 0.15 0
      , direction = vec3 0 0 -1
      , pressedKeys = []
      , connected = False
      }
    , Task.perform Resize Window.size
    )


type Action
    = Resize Window.Size
    | Animate Time
    | KeyboardMsg Keyboard.Extra.Msg
    | Click Mouse.Position
    | MouseMove (Float, Float)
    | Send Time
    | NewMessage String



subscriptions : Model -> Sub Action
subscriptions _ =
    Sub.batch
        [ AnimationFrame.diffs Animate
        --, Window.resizes Resize -- don't capture this if you want to zoom in lol
        , Sub.map KeyboardMsg Keyboard.Extra.subscriptions
        , Mouse.clicks Click
        , mouseMove MouseMove
        --Updated from networking
        , WebSocket.listen "ws://localhost:3000" NewMessage
        , Time.every Time.second Send
        ]


-- thanks https://github.com/evancz/first-person-elm
-- thanks https://guide.elm-lang.org/interop/javascript.html
-- thanks https://gist.github.com/groteck/e4cc180ac182436f31f1d709466df768
-- thanks https://developer.mozilla.org/en-US/docs/Web/API/Element/requestPointerLock
port requestPointerLock : () -> Cmd msg
port mouseMove : ((Float, Float) -> msg) -> Sub msg


update : Action -> Model -> ( Model, Cmd Action )
update action model =
    --let throw3 = Debug.log "test2" "test2" in
    case action of
        NewMessage mesg -> case model of
            { which, players, message, size, angle, position, direction, pressedKeys, connected } ->
              let throw = Debug.log "message" mesg in
              let ap = (updatePlayers players (String.split "?" mesg)) in
              let ps = getPlayers players in
              let plsprint = String.concat ps in
              --let throw = Debug.log "Whjatever" plsprint in
              case String.uncons mesg of
                Just (first, rest) -> if first == '+' then let whichh = Result.withDefault 0 (String.toInt rest) in
                  let throw = Debug.log "Whichh" (psToString ap) in
                  (Model whichh (List.append players [Player whichh "Player 1" [0,0.15,0] 1000 0]) (getMessage2 model (String.split "?" mesg)) size angle position direction pressedKeys True, Cmd.none)
                  else
                  --let throw = Debug.log "Fail" "Fail" in
                    let throw = Debug.log "Before before" (psToString ap) in
                    (Model which ap (getMessage2 model (String.split "?" mesg)) size angle position direction pressedKeys connected, Cmd.none)

                _ ->
                  --let throw = Debug.log "Fail2" "Fail2" in
                  (Model which ap (getMessage2 model (String.split "?" mesg)) size angle position direction pressedKeys connected, Cmd.none)
            --_ -> (model,Cmd.none)S

        Resize size ->
            { model | size = size } ! []

        Animate elapsed ->
          --let throw = Debug.log "Conneced" model.connected in
          if model.connected then
            let dir = Keyboard.Extra.wasdDirection model.pressedKeys in
            let a = ( directionToAngle dir ) - ( atan2 (getX model.direction) (getZ model.direction) ) + pi in
            let m = {model | angle = model.angle + a / 50,
                      position =
                        let movSpeed = if List.member Shift model.pressedKeys then 2 else 1 in
                        if dir == NoDirection then model.position
                        else vec3 ((getX model.position) + (sin a)*movSpeed/75) (getY model.position) ((getZ model.position) - (cos a)*movSpeed/75)} in
            --Updated from networking
            let plsprint2 = psToString model.players in
            let throw2 = Debug.log "before" plsprint2 in
            let p = updatePPos model.which m.position model.players in
            let plsprint = psToString p in
            let throw2 = Debug.log "after" plsprint in
            let tosend = pToString p m.which in
            let throw2 = Debug.log "tosend" tosend in
            ({m | players = p}, WebSocket.send "ws://localhost:3000" tosend)
          else (model, Cmd.none)

        KeyboardMsg keyMsg -> let keys = Keyboard.Extra.update keyMsg model.pressedKeys in
            { model | pressedKeys = keys } ! []

        Click position ->
            ( model, requestPointerLock () )

        MouseMove ( dx, dy ) ->
            let pitched = transform ( makeRotate (-dx/1000) (vec3 0 1 0) ) model.direction in
            let acrossvec = ( atan2 (getX model.direction) (getZ model.direction) ) - pi / 2 in
            let yawed = transform ( makeRotate (-dy/1000) (vec3 (sin acrossvec) 0 (cos acrossvec)) ) pitched in
            { model | direction = yawed } ! []
        _ -> (model, Cmd.none)

--Helperfunction for networking stuff
updatePPos: Int -> Vec3 -> List(Player) -> List(Player)
updatePPos i p ps = case ps of
    [] -> []
    ({number, name, position, health, score}) :: rest -> if i == 0 then 
      --let print = Debug.log "Got to player" p in
      (Player number name [(getX p),(getY p),(getZ p)] health score) :: rest else (Player number name position health score) :: (updatePPos (i-1) p rest)
-- View

view : Model -> Html Action
--view { size, angle, position, direction, pressedKeys } =
view { which, players, message, size, angle, position, direction, pressedKeys, connected } =
    WebGL.toHtml
        [ width size.width
        , height size.height
        , style [ ( "display", "block" ) ]
        ]
        --[
            --WebGL.entity vertexShader fragmentShader copter (uniforms size (angle / 10)),
            --WebGL.entity vertexShader fragmentShader blade (uniforms size (angle / 10 - angle)),
            --WebGL.entity vertexShader fragmentShader blade (uniforms size 20),
            --WebGL.entity vertexShader fragmentShader (WebGL.triangles ( ptToCube (vec3 10 0 10) 4 (vec3 0.2 0.2 0.2)) ) (uniforms size (angle/2) position),
            
            --WebGL.entity vertexShader fragmentShader (WebGL.triangles map) (uniforms size (pi/2) position direction)
        (
        WebGL.entityWith [ Blend.add Blend.srcAlpha Blend.oneMinusSrcAlpha, DepthTest.always { write = True, near = 0, far = 1 } ]
          vertexShader fragmentShader (WebGL.triangles map) (uniforms size (pi/2) position direction)
        ::
          List.map (\p ->
            let pos = case p.position of
              a::b::c::rest -> vec3 (a*10) (-10*c) (b*10)
              _ -> Debug.log "ohno" ( vec3 0 0 0 )
            in
              WebGL.entityWith [ Blend.add Blend.srcAlpha Blend.oneMinusSrcAlpha, DepthTest.always { write = True, near = 0, far = 1 } ]
                vertexShader fragmentShader (WebGL.triangles ( ptToCube pos 2.5 (vec3 0.5 0.5 0.5) )) (uniforms size (pi/2) position direction)
            ) players
        --]
        )







uniforms : Window.Size -> Float -> Vec3 -> Vec3 -> Uniform
uniforms { width, height } angle position direction =
    { rotation = makeRotate angle (vec3 -1 0 0)
    , perspective = makePerspective 45 (toFloat width / toFloat height) 0.01 100
    , camera = makeLookAt position (add position direction) (vec3 0 1 0)
    }








type alias Vertex =
    { position : Vec3
    , color : Vec3
    }


type alias Uniform =
    { rotation : Mat4
    , perspective : Mat4
    , camera : Mat4
    }


type alias Varying =
    { vcolor : Vec3
    }









vertexShader : Shader Vertex Uniform Varying
vertexShader =
    [glsl|
  attribute vec3 position;
  attribute vec3 color;
  uniform mat4 perspective;
  uniform mat4 camera;
  uniform mat4 rotation;
  varying vec3 vcolor;
  void main () {
      gl_Position = perspective * camera * rotation * vec4((0.05 * position) , 1.0);
      vcolor = color;
  }
|]


fragmentShader : Shader {} Uniform Varying
fragmentShader =
    [glsl|
  precision mediump float;
  varying vec3 vcolor;
  void main () {
      gl_FragColor = vec4(vcolor, 0.2);
  }
|]










directionToAngle : Direction -> Float
directionToAngle direction =
    case direction of
        North ->
            0
        NorthEast ->
            pi * 0.25
        East ->
            pi * 0.5
        SouthEast ->
            pi * 0.75
        South ->
            pi * 1
        SouthWest ->
            pi * 1.25
        West ->
            pi * 1.5
        NorthWest ->
            pi * 1.75
        NoDirection ->
            0







--dotMap =
--    [
--        vec3 0 0 0,
--        vec3 0 1 0,
--        vec3 0 2 0,
--        vec3 0 3 0,
--        vec3 1 0 0,
--        vec3 1 1 0,
--        vec3 1 2 0,
--        vec3 1 3 0,
--        vec3 2 0 0,
--        vec3 2 1 0,
--        vec3 2 2 0,
--        vec3 2 3 0,
--        vec3 1 3 1,
--        vec3 2 2 1,
--        vec3 2 3 1,
--        vec3 2 3 2
--    ]

base = \n m -> List.concatMap ( \em -> List.map ( \en -> vec3 ( toFloat en ) ( toFloat em ) -1 ) ( List.range 1 n ) ) ( List.range 1 m )

dotMap = [ vec3 1 1 0, vec3 7 1 0, vec3 1 23 0, vec3 7 23 0,
           vec3 4 12 0, vec3 3 12 0, vec3 5 12 0, vec3 4 13 0, vec3 4 11 0, vec3 4 12 1 ] ++ ( base 7 23 )

ptToCube p s col =
    let fll = vec3 ( (getX p) - s ) ( (getY p) - s ) ( (getZ p) - s ) in
    let flr = vec3 ( (getX p) + s ) ( (getY p) - s ) ( (getZ p) - s ) in
    let ful = vec3 ( (getX p) - s ) ( (getY p) + s ) ( (getZ p) - s ) in
    let fur = vec3 ( (getX p) + s ) ( (getY p) + s ) ( (getZ p) - s ) in
    let bll = vec3 ( (getX p) - s ) ( (getY p) - s ) ( (getZ p) + s ) in
    let blr = vec3 ( (getX p) + s ) ( (getY p) - s ) ( (getZ p) + s ) in
    let bul = vec3 ( (getX p) - s ) ( (getY p) + s ) ( (getZ p) + s ) in
    let bur = vec3 ( (getX p) + s ) ( (getY p) + s ) ( (getZ p) + s ) in
    [   
        ( Vertex ful col, Vertex fur col, Vertex flr col ), -- front
        ( Vertex ful col, Vertex flr col, Vertex fll col ),

        ( Vertex bul col, Vertex bur col, Vertex blr col ), -- back
        ( Vertex bul col, Vertex blr col, Vertex bll col ),

        ( Vertex bul col, Vertex ful col, Vertex fll col ), -- left
        ( Vertex bul col, Vertex fll col, Vertex bll col ),

        ( Vertex bur col, Vertex fur col, Vertex flr col ), -- right
        ( Vertex bur col, Vertex flr col, Vertex blr col ),

        ( Vertex bul col, Vertex bur col, Vertex fur col ), -- top
        ( Vertex bul col, Vertex fur col, Vertex ful col ),

        ( Vertex bll col, Vertex blr col, Vertex flr col ), -- bottom
        ( Vertex bll col, Vertex flr col, Vertex fll col )
    ]

map = List.concatMap
                ( \e ->
                    ptToCube e 2.5 (vec3 0.2 0.5 0.5) )
                ( List.map ( scale 6 ) dotMap )
getMessage2 : Model -> List (String) -> List (String)
getMessage2 m s = case (m, s) of
  (_, []) -> getMessage m
  ({ which, players, message, size, angle, position, direction, pressedKeys, connected },_) -> getMessage (Model which (getMessageH players s) message size angle position direction pressedKeys connected)
      
updatePlayers: List(Player) -> List(String) -> List(Player)
updatePlayers p s = case s of
  first :: rest -> let l = String.split ";" first in
    case l of
      a :: (b :: (c :: (d :: (e::[])))) ->
        let throw2 = Debug.log "correct" (String.split "," (String.slice 1 ((String.length c)-1) c)) in --(List.map (Result.withDefault 0 << String.toFloat) (String.split (String.slice 1 ((String.length c)-1) c) "," )) in
        (Player (Result.withDefault 0 (String.toInt a)) b (List.map (Result.withDefault 0 << String.toFloat) (String.split "," (String.slice 1 ((String.length c)-1) c))) (Result.withDefault 0 <| String.toInt d) (Result.withDefault 0 <| String.toInt e)) :: (updatePlayers p rest) 
      _ -> []
        --let throw2 = Debug.log "incorrect" first in p
  _ ->[]


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
  { which, players, message, size, angle, position, direction, pressedKeys } ->
    List.append [String.append "Player " (toString which), " "] (getPlayers players)

getPlayers : List (Player) -> List(String)
getPlayers p = case p of
  [] -> [""]
  only :: [] -> [String.append only.name (": "), String.append "Position: " (toString only.position), String.append "Health: " (toString only.health), String.append "Score: " (toString only.score)]
  first :: rest -> List.append [String.append first.name (": "), String.append "Position: " (toString first.position), String.append "Health: " (toString first.health), String.append "Score: " (toString first.score), " "] (getPlayers rest)

-- SUBSCRIPTIONS

--subscriptions : Model -> Sub Msg
--subscriptions model =
--  Sub.batch
--  [WebSocket.listen "ws://localhost:3000" NewMessage, Time.every Time.second Send]

---- VIEW

--view : Model -> Html Msg
--view model =
--  div []
--    [ div [] (List.map viewMessage model.message)
--    --, button [onClick (Send 2)] [text "Send"]
--    ]

--getTime:Float


--viewMessage : String -> Html msg
--viewMessage msg =
--  if msg == " " then div [style [("color","white")]][text "space"]
--  else div [] [ text msg ]