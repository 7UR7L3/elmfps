port module Fps exposing (main, requestPointerLock)

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









type alias Model =
    { size : Window.Size
    , angle : Float
    , position : Vec3
    , direction : Vec3
    , pressedKeys : List Key
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
    ( { size = Window.Size 0 0
      , angle = 0
      , position = vec3 0 0.3 0
      , direction = vec3 0 0 -1
      , pressedKeys = []
      }
    , Task.perform Resize Window.size
    )


type Action
    = Resize Window.Size
    | Animate Time
    | KeyboardMsg Keyboard.Extra.Msg
    | Click Mouse.Position
    | MouseMove (Float, Float)



subscriptions : Model -> Sub Action
subscriptions _ =
    Sub.batch
        [ AnimationFrame.diffs Animate
        --, Window.resizes Resize -- don't capture this if you want to zoom in lol
        , Sub.map KeyboardMsg Keyboard.Extra.subscriptions
        , Mouse.clicks Click
        , mouseMove MouseMove
        ]


-- thanks https://github.com/evancz/first-person-elm
-- thanks https://guide.elm-lang.org/interop/javascript.html
-- thanks https://gist.github.com/groteck/e4cc180ac182436f31f1d709466df768
-- thanks https://developer.mozilla.org/en-US/docs/Web/API/Element/requestPointerLock
port requestPointerLock : () -> Cmd msg
port mouseMove : ((Float, Float) -> msg) -> Sub msg


update : Action -> Model -> ( Model, Cmd Action )
update action model =
    case action of
        Resize size ->
            { model | size = size } ! []

        Animate elapsed ->
            let dir = Keyboard.Extra.wasdDirection model.pressedKeys in
            let a = ( directionToAngle dir ) - ( atan2 (getX model.direction) (getZ model.direction) ) + pi in
            { model | angle = model.angle + a / 50,
                      position =
                        if dir == NoDirection then model.position
                        else vec3 ((getX model.position) + (sin a)/75) (getY model.position) ((getZ model.position) - (cos a)/75) } ! []

        KeyboardMsg keyMsg -> let keys = Keyboard.Extra.update keyMsg model.pressedKeys in
            { model | pressedKeys = keys } ! []

        Click position ->
            ( model, requestPointerLock () )

        MouseMove ( dx, dy ) ->
            let pitched = transform ( makeRotate (-dx/1000) (vec3 0 1 0) ) model.direction in
            let acrossvec = ( atan2 (getX model.direction) (getZ model.direction) ) - pi / 2 in
            let yawed = transform ( makeRotate (-dy/1000) (vec3 (sin acrossvec) 0 (cos acrossvec)) ) pitched in
            { model | direction = yawed } ! []

-- View

view : Model -> Html Action
view { size, angle, position, direction, pressedKeys } =
    WebGL.toHtml
        [ width size.width
        , height size.height
        , style [ ( "display", "block" ) ]
        ]
        [
            --WebGL.entity vertexShader fragmentShader copter (uniforms size (angle / 10)),
            --WebGL.entity vertexShader fragmentShader blade (uniforms size (angle / 10 - angle)),
            --WebGL.entity vertexShader fragmentShader blade (uniforms size 20),
            --WebGL.entity vertexShader fragmentShader (WebGL.triangles ( ptToCube (vec3 10 0 10) 4 (vec3 0.2 0.2 0.2)) ) (uniforms size (angle/2) position),
            
            --WebGL.entity vertexShader fragmentShader (WebGL.triangles map) (uniforms size (pi/2) position direction)
            WebGL.entityWith [ Blend.add Blend.srcAlpha Blend.oneMinusSrcAlpha, DepthTest.always { write = True, near = 0, far = 1 } ]
                vertexShader fragmentShader (WebGL.triangles map) (uniforms size (pi/2) position direction)
        ]







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
      gl_FragColor = vec4(vcolor, 0.25);
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







dotMap =
    [
        vec3 0 0 0,
        vec3 0 1 0,
        vec3 0 2 0,
        vec3 0 3 0,
        vec3 1 0 0,
        vec3 1 1 0,
        vec3 1 2 0,
        vec3 1 3 0,
        vec3 2 0 0,
        vec3 2 1 0,
        vec3 2 2 0,
        vec3 2 3 0,
        vec3 1 3 1,
        vec3 2 2 1,
        vec3 2 3 1,
        vec3 2 3 2
    ]

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
                    ptToCube e 1.5 (vec3 0.2 0.5 0.5) )
                ( List.map ( scale 4 ) dotMap )