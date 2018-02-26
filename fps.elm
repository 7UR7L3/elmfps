module Fps exposing (main)

import WebGL exposing (Mesh, Shader)
import Math.Vector3 exposing (Vec3, vec3, add, scale, normalize, length, dot, getX, getY, getZ)
import Math.Matrix4 exposing (Mat4, makeRotate, mul, makeLookAt, makePerspective, inverseOrthonormal, transpose)
import AnimationFrame
import Window
import Html.Attributes exposing (width, height, style)
import Html exposing (Html)
import Time exposing (Time)
import Task


type Action
    = Resize Window.Size
    | Animate Time


type alias Model =
    { size : Window.Size
    , angle : Float
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
      }
    , Task.perform Resize Window.size
    )

subscriptions : Model -> Sub Action
subscriptions _ =
    Sub.batch
        [ AnimationFrame.diffs Animate
        --, Window.resizes Resize -- don't capture this if you want to zoom in lol
        ]

update : Action -> Model -> ( Model, Cmd Action )
update action model =
    case action of
        Resize size ->
            { model | size = size } ! []

        Animate elapsed ->
            { model | angle = model.angle + elapsed / 200 } ! []

-- View

view : Model -> Html Action
view { size, angle } =
    WebGL.toHtml
        [ width size.width
        , height size.height
        , style [ ( "display", "block" ) ]
        ]
        [
            --WebGL.entity vertexShader fragmentShader copter (uniforms size (angle / 10)),
            --WebGL.entity vertexShader fragmentShader blade (uniforms size (angle / 10 - angle)),
            --WebGL.entity vertexShader fragmentShader blade (uniforms size 20),
            WebGL.entity vertexShader fragmentShader (WebGL.triangles ( ptToCube (vec3 10 0 10) 4 (vec3 0.2 0.2 0.2)) ) (uniforms size (angle/2)),
            WebGL.entity vertexShader fragmentShader (WebGL.triangles map) (uniforms size 20)
        ]







uniforms : Window.Size -> Float -> Uniform
uniforms { width, height } angle =
    { rotation = makeRotate angle (vec3 -1 0 0)
    , perspective = makePerspective 45 (toFloat width / toFloat height) 0.01 100
    , camera = makeLookAt (vec3 0 0 5) (vec3 0 0 0) (vec3 0 1 0)
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
      gl_FragColor = vec4(vcolor, 1.0);
  }
|]










blade : Mesh Vertex
blade =
    WebGL.triangles
        [ ( Vertex (vec3 -10 10 -10) (vec3 0 0 0)
          , Vertex (vec3 10 10 -10) (vec3 0 0 0)
          , Vertex (vec3 -10 -10 -10) (vec3 0 0 0)
          )
        , ( Vertex (vec3 10 10 -10) (vec3 0 0 0)
          , Vertex (vec3 -10 -10 -10) (vec3 0 0 0)
          , Vertex (vec3 10 -10 -10) (vec3 1.6039 0.6039 0.6118)
          )
        ]



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
                    ptToCube e 3 (vec3 0.2 0.5 0.5) )
                ( List.map ( scale 8 ) dotMap )


copter : Mesh Vertex
copter =
    WebGL.triangles
        [ ( Vertex (vec3 0.0 -2.6333 13.0) (vec3 0.7451 0.7098 0.7098)
          , Vertex (vec3 0.0 1.8667 7.0) (vec3 0.7725 0.7647 0.7647)
          , Vertex (vec3 1.7 1.8667 7.0) (vec3 0.7804 0.7647 0.7647)
          )
        , ( Vertex (vec3 0.0 -2.6333 13.0) (vec3 0.7451 0.7098 0.7098)
          , Vertex (vec3 1.7 1.8667 7.0) (vec3 0.7608 0.7647 0.7647)
          , Vertex (vec3 2.0 -2.6333 13.0) (vec3 0.702 0.6392 0.6588)
          )
        , ( Vertex (vec3 2.0 -2.6333 13.0) (vec3 0.7451 0.7098 0.7098)
          , Vertex (vec3 1.7 1.8667 7.0) (vec3 0.749 0.7647 0.7647)
          , Vertex (vec3 4.0 -3.1333 9.0) (vec3 0.7725 0.7216 0.7216)
          )
        , ( Vertex (vec3 4.0 -3.1333 9.0) (vec3 0.7765 0.7216 0.7216)
          , Vertex (vec3 1.7 1.8667 7.0) (vec3 0.7725 0.7647 0.7647)
          , Vertex (vec3 5.0 -3.6333 4.0) (vec3 0.7843 0.7216 0.7216)
          )
        , ( Vertex (vec3 5.0 -3.6333 4.0) (vec3 0.7725 0.7216 0.7216)
          , Vertex (vec3 1.7 1.8667 7.0) (vec3 0.7686 0.7647 0.7647)
          , Vertex (vec3 3.0 3.3667 1.0) (vec3 0.7529 0.7647 0.7647)
          )
        , ( Vertex (vec3 5.0 -3.6333 4.0) (vec3 0.7804 0.7216 0.7216)
          , Vertex (vec3 4.0 -2.1333 -4.0) (vec3 0.7843 0.7216 0.7216)
          , Vertex (vec3 3.0 3.3667 1.0) (vec3 0.7686 0.7647 0.7647)
          )
        , ( Vertex (vec3 4.0 -2.1333 -4.0) (vec3 0.7686 0.7216 0.7216)
          , Vertex (vec3 2.0 2.8667 -4.0) (vec3 0.7765 0.7647 0.7647)
          , Vertex (vec3 3.0 3.3667 1.0) (vec3 0.7451 0.7647 0.7647)
          )
        , ( Vertex (vec3 4.0 -2.1333 -4.0) (vec3 0.7765 0.7216 0.7216)
          , Vertex (vec3 3.0 -1.1333 -6.0) (vec3 0.7804 0.7216 0.7216)
          , Vertex (vec3 2.0 2.8667 -4.0) (vec3 0.749 0.7647 0.7647)
          )
        , ( Vertex (vec3 3.0 -1.1333 -6.0) (vec3 0.7765 0.7216 0.7216)
          , Vertex (vec3 0.0 2.3667 -5.0) (vec3 0.7765 0.7647 0.7647)
          , Vertex (vec3 2.0 2.8667 -4.0) (vec3 0.7647 0.7647 0.7647)
          )
        , ( Vertex (vec3 3.0 -1.1333 -6.0) (vec3 0.7686 0.7216 0.7216)
          , Vertex (vec3 2.0 0.3667 -9.0) (vec3 0.7529 0.7216 0.7216)
          , Vertex (vec3 0.0 2.3667 -5.0) (vec3 0.7608 0.7647 0.7647)
          )
        , ( Vertex (vec3 2.0 0.3667 -9.0) (vec3 0.7843 0.7216 0.7216)
          , Vertex (vec3 0.0 1.8667 -9.0) (vec3 0.7686 0.7647 0.7647)
          , Vertex (vec3 0.0 2.3667 -5.0) (vec3 0.7529 0.7647 0.7647)
          )
        , ( Vertex (vec3 2.0 0.3667 -9.0) (vec3 0.7686 0.7216 0.7216)
          , Vertex (vec3 0.0 2.8667 -22.0) (vec3 0.7569 0.7647 0.7647)
          , Vertex (vec3 0.0 1.8667 -9.0) (vec3 0.7569 0.7647 0.7647)
          )
        , ( Vertex (vec3 2.0 0.3667 -9.0) (vec3 0.7843 0.7216 0.7216)
          , Vertex (vec3 1.0 2.5667 -23.0) (vec3 0.7686 0.7647 0.7647)
          , Vertex (vec3 0.0 2.8667 -22.0) (vec3 0.7725 0.7647 0.7647)
          )
        , ( Vertex (vec3 1.0 2.5667 -23.0) (vec3 0.7451 0.7647 0.7647)
          , Vertex (vec3 1.0 2.8667 -27.0) (vec3 0.6706 0.6588 0.6392)
          , Vertex (vec3 0.0 2.8667 -22.0) (vec3 0.7765 0.7647 0.7647)
          )
        , ( Vertex (vec3 1.7 1.8667 7.0) (vec3 0.8275 0.8157 0.8157)
          , Vertex (vec3 0.0 3.8667 0.7) (vec3 0.9098 0.8157 0.8157)
          , Vertex (vec3 0.0 1.8667 7.0) (vec3 0.8196 0.8157 0.8157)
          )
        , ( Vertex (vec3 1.7 1.8667 7.0) (vec3 0.8235 0.8157 0.8157)
          , Vertex (vec3 1.0 3.8667 0.7) (vec3 0.8353 0.8157 0.8157)
          , Vertex (vec3 0.0 3.8667 0.7) (vec3 0.8275 0.8157 0.8157)
          )
        , ( Vertex (vec3 1.7 1.8667 7.0) (vec3 0.8196 0.8157 0.8157)
          , Vertex (vec3 3.0 3.3667 1.0) (vec3 0.8157 0.8157 0.8157)
          , Vertex (vec3 1.0 3.8667 0.7) (vec3 0.8157 0.8157 0.8157)
          )
        , ( Vertex (vec3 3.0 3.3667 1.0) (vec3 0.8118 0.8157 0.8157)
          , Vertex (vec3 2.0 2.8667 -4.0) (vec3 0.8078 0.8157 0.8157)
          , Vertex (vec3 1.0 3.8667 0.7) (vec3 0.8157 0.8157 0.8157)
          )
        , ( Vertex (vec3 2.0 2.8667 -4.0) (vec3 0.8078 0.8157 0.8157)
          , Vertex (vec3 0.0 3.8667 -2.0) (vec3 0.8235 0.8157 0.8157)
          , Vertex (vec3 1.0 3.8667 0.7) (vec3 0.8353 0.8157 0.8157)
          )
        , ( Vertex (vec3 2.0 2.8667 -4.0) (vec3 0.8314 0.8157 0.8157)
          , Vertex (vec3 0.0 2.3667 -5.0) (vec3 0.8275 0.8157 0.8157)
          , Vertex (vec3 0.0 3.8667 -2.0) (vec3 0.8235 0.8157 0.8157)
          )
        , ( Vertex (vec3 1.0 3.8667 0.7) (vec3 0.5294 0.5255 0.5137)
          , Vertex (vec3 0.7 4.8667 0.6) (vec3 0.5255 0.5255 0.5137)
          , Vertex (vec3 0.0 3.8667 0.7) (vec3 0.5216 0.5255 0.5137)
          )
        , ( Vertex (vec3 0.7 4.8667 0.6) (vec3 0.5176 0.5255 0.5137)
          , Vertex (vec3 0.0 4.8667 0.6) (vec3 0.5255 0.5255 0.5137)
          , Vertex (vec3 0.0 3.8667 0.7) (vec3 0.5137 0.5255 0.5137)
          )
        , ( Vertex (vec3 1.0 3.8667 0.7) (vec3 0.5373 0.5255 0.5137)
          , Vertex (vec3 0.7 4.8667 0.6) (vec3 0.5412 0.5255 0.5137)
          , Vertex (vec3 0.0 4.8667 -1.0) (vec3 0.5255 0.5255 0.5137)
          )
        , ( Vertex (vec3 0.0 4.8667 -1.0) (vec3 0.5255 0.5255 0.5137)
          , Vertex (vec3 0.0 3.8667 -2.0) (vec3 0.5255 0.5255 0.5137)
          , Vertex (vec3 1.0 3.8667 0.7) (vec3 0.5294 0.5255 0.5137)
          )
        , ( Vertex (vec3 0.7 4.8667 0.6) (vec3 0.5412 0.4431 0.4314)
          , Vertex (vec3 0.0 4.8667 -1.0) (vec3 0.5216 0.4431 0.4314)
          , Vertex (vec3 0.0 4.8667 0.6) (vec3 0.5216 0.4431 0.4314)
          )
        , ( Vertex (vec3 0.0 -2.6333 13.0) (vec3 0.6549 0.6588 0.6392)
          , Vertex (vec3 2.0 -4.6333 11.0) (vec3 0.4941 0.5137 0.4431)
          , Vertex (vec3 0.0 -4.6333 11.0) (vec3 0.5059 0.5137 0.4431)
          )
        , ( Vertex (vec3 0.0 -2.6333 13.0) (vec3 0.6627 0.6588 0.6392)
          , Vertex (vec3 2.0 -2.6333 13.0) (vec3 0.6588 0.6588 0.6392)
          , Vertex (vec3 2.0 -4.6333 11.0) (vec3 0.5137 0.5137 0.4431)
          )
        , ( Vertex (vec3 2.0 -4.6333 11.0) (vec3 0.4941 0.5137 0.4431)
          , Vertex (vec3 2.0 -2.6333 13.0) (vec3 0.6627 0.6588 0.6392)
          , Vertex (vec3 4.0 -3.1333 9.0) (vec3 0.6745 0.6588 0.6392)
          )
        , ( Vertex (vec3 4.0 -3.1333 9.0) (vec3 0.6745 0.6588 0.6392)
          , Vertex (vec3 4.0 -4.8333 -1.0) (vec3 0.5176 0.5137 0.4431)
          , Vertex (vec3 2.0 -4.6333 11.0) (vec3 0.5294 0.5137 0.4431)
          )
        , ( Vertex (vec3 4.0 -3.1333 9.0) (vec3 0.6667 0.6588 0.6392)
          , Vertex (vec3 5.0 -3.6333 4.0) (vec3 0.5176 0.5137 0.4431)
          , Vertex (vec3 4.0 -4.8333 -1.0) (vec3 0.5294 0.5137 0.4431)
          )
        , ( Vertex (vec3 5.0 -3.6333 4.0) (vec3 0.4941 0.5137 0.4431)
          , Vertex (vec3 4.0 -2.1333 -4.0) (vec3 0.6706 0.6588 0.6392)
          , Vertex (vec3 4.0 -4.8333 -1.0) (vec3 0.5216 0.5137 0.4431)
          )
        , ( Vertex (vec3 4.0 -4.8333 -1.0) (vec3 0.5098 0.5137 0.4431)
          , Vertex (vec3 4.0 -2.1333 -4.0) (vec3 0.5176 0.5137 0.4431)
          , Vertex (vec3 2.0 -2.1333 -6.0) (vec3 0.5137 0.5137 0.4431)
          )
        , ( Vertex (vec3 4.0 -2.1333 -4.0) (vec3 0.5098 0.5137 0.4431)
          , Vertex (vec3 3.0 -1.1333 -6.0) (vec3 0.6549 0.6588 0.6392)
          , Vertex (vec3 2.0 -2.1333 -6.0) (vec3 0.5216 0.5137 0.4431)
          )
        , ( Vertex (vec3 3.0 -1.1333 -6.0) (vec3 0.6588 0.6588 0.6392)
          , Vertex (vec3 2.0 -2.1333 -6.0) (vec3 0.502 0.5137 0.4431)
          , Vertex (vec3 2.0 0.3667 -9.0) (vec3 0.651 0.6588 0.6392)
          )
        , ( Vertex (vec3 2.0 0.3667 -9.0) (vec3 0.6549 0.6588 0.6392)
          , Vertex (vec3 2.0 -2.1333 -6.0) (vec3 0.4902 0.5137 0.4431)
          , Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.4863 0.5137 0.4431)
          )
        , ( Vertex (vec3 2.0 0.3667 -9.0) (vec3 0.6549 0.6588 0.6392)
          , Vertex (vec3 1.0 2.5667 -23.0) (vec3 0.651 0.6588 0.6392)
          , Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.498 0.5137 0.4431)
          )
        , ( Vertex (vec3 1.0 2.5667 -23.0) (vec3 0.6549 0.6588 0.6392)
          , Vertex (vec3 1.0 2.8667 -27.0) (vec3 0.6667 0.6588 0.6392)
          , Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.498 0.5137 0.4431)
          )
        , ( Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.4902 0.5137 0.4431)
          , Vertex (vec3 0.0 2.8667 -27.0) (vec3 0.651 0.6588 0.6392)
          , Vertex (vec3 1.0 2.8667 -27.0) (vec3 0.6588 0.6588 0.6392)
          )
        , ( Vertex (vec3 0.0 2.8667 -22.0) (vec3 0.7569 0.7647 0.7647)
          , Vertex (vec3 1.0 2.8667 -27.0) (vec3 0.6706 0.6588 0.6392)
          , Vertex (vec3 0.0 2.8667 -27.0) (vec3 0.7451 0.7216 0.7216)
          )
        , ( Vertex (vec3 0.0 -4.8333 -1.0) (vec3 0.3451 0.349 0.3725)
          , Vertex (vec3 2.0 -4.6333 11.0) (vec3 0.498 0.5137 0.4431)
          , Vertex (vec3 0.0 -4.6333 11.0) (vec3 0.4902 0.5137 0.4431)
          )
        , ( Vertex (vec3 0.0 -4.8333 -1.0) (vec3 0.3569 0.349 0.3725)
          , Vertex (vec3 2.0 -4.6333 11.0) (vec3 0.502 0.5137 0.4431)
          , Vertex (vec3 4.0 -4.8333 -1.0) (vec3 0.4902 0.5137 0.4431)
          )
        , ( Vertex (vec3 0.0 -4.8333 -1.0) (vec3 0.3569 0.349 0.3725)
          , Vertex (vec3 4.0 -4.8333 -1.0) (vec3 0.498 0.5137 0.4431)
          , Vertex (vec3 2.0 -2.1333 -6.0) (vec3 0.502 0.5137 0.4431)
          )
        , ( Vertex (vec3 0.0 -4.8333 -1.0) (vec3 0.349 0.349 0.3725)
          , Vertex (vec3 2.0 -2.1333 -6.0) (vec3 0.502 0.5137 0.4431)
          , Vertex (vec3 0.0 -1.1333 -8.0) (vec3 0.4824 0.5137 0.4431)
          )
        , ( Vertex (vec3 2.0 -2.1333 -6.0) (vec3 0.5059 0.5137 0.4431)
          , Vertex (vec3 0.0 -1.1333 -8.0) (vec3 0.502 0.5137 0.4431)
          , Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.498 0.5137 0.4431)
          )
        , ( Vertex (vec3 5.0 -3.6333 4.0) (vec3 0.7294 0.7373 0.7529)
          , Vertex (vec3 8.0 -3.6333 2.0) (vec3 0.6588 0.6588 0.6392)
          , Vertex (vec3 8.0 -2.1333 -2.0) (vec3 0.6627 0.6588 0.6392)
          )
        , ( Vertex (vec3 8.0 -2.1333 -2.0) (vec3 0.6549 0.6588 0.6392)
          , Vertex (vec3 5.0 -3.6333 4.0) (vec3 0.7294 0.7373 0.7529)
          , Vertex (vec3 4.0 -2.1333 -4.0) (vec3 0.7412 0.7373 0.7529)
          )
        , ( Vertex (vec3 8.0 -3.6333 2.0) (vec3 0.8275 0.8157 0.8157)
          , Vertex (vec3 8.0 -2.8333 -2.0) (vec3 0.8235 0.8157 0.8157)
          , Vertex (vec3 8.0 -2.1333 -2.0) (vec3 0.8353 0.8157 0.8157)
          )
        , ( Vertex (vec3 8.0 -2.1333 -2.0) (vec3 0.8314 0.8157 0.8157)
          , Vertex (vec3 8.0 -2.8333 -2.0) (vec3 0.8392 0.8157 0.8157)
          , Vertex (vec3 4.0 -2.1333 -4.0) (vec3 0.502 0.5137 0.4431)
          )
        , ( Vertex (vec3 4.0 -2.1333 -4.0) (vec3 0.4902 0.5137 0.4431)
          , Vertex (vec3 8.0 -2.8333 -2.0) (vec3 0.8275 0.8157 0.8157)
          , Vertex (vec3 3.0 -3.1333 -3.0) (vec3 0.498 0.5137 0.4431)
          )
        , ( Vertex (vec3 3.0 -3.1333 -3.0) (vec3 0.498 0.5137 0.4431)
          , Vertex (vec3 8.0 -3.6333 2.0) (vec3 0.549 0.5608 0.5451)
          , Vertex (vec3 8.0 -2.8333 -2.0) (vec3 0.498 0.5137 0.4431)
          )
        , ( Vertex (vec3 8.0 -3.6333 2.0) (vec3 0.5529 0.5608 0.5451)
          , Vertex (vec3 5.0 -3.6333 4.0) (vec3 0.4902 0.5137 0.4431)
          , Vertex (vec3 3.0 -3.1333 -3.0) (vec3 0.498 0.5137 0.4431)
          )
        , ( Vertex (vec3 1.0 2.5667 -23.0) (vec3 0.7569 0.7647 0.7647)
          , Vertex (vec3 4.0 2.8667 -26.0) (vec3 0.7647 0.7647 0.7647)
          , Vertex (vec3 1.0 2.8667 -27.0) (vec3 0.6706 0.6588 0.6392)
          )
        , ( Vertex (vec3 4.0 2.8667 -26.0) (vec3 0.7608 0.7647 0.7647)
          , Vertex (vec3 1.0 2.8667 -27.0) (vec3 0.6627 0.6588 0.6392)
          , Vertex (vec3 3.0 2.8667 -28.0) (vec3 0.6588 0.6588 0.6392)
          )
        , ( Vertex (vec3 1.0 2.8667 -27.0) (vec3 0.6667 0.6588 0.6392)
          , Vertex (vec3 3.0 2.8667 -28.0) (vec3 0.5569 0.5608 0.5451)
          , Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.498 0.5137 0.4431)
          )
        , ( Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.4902 0.5137 0.4431)
          , Vertex (vec3 3.0 2.8667 -28.0) (vec3 0.549 0.5608 0.5451)
          , Vertex (vec3 3.0 2.1667 -28.0) (vec3 0.5569 0.5608 0.5451)
          )
        , ( Vertex (vec3 4.0 2.8667 -26.0) (vec3 0.7569 0.7647 0.7647)
          , Vertex (vec3 3.0 2.8667 -28.0) (vec3 0.6588 0.6588 0.6392)
          , Vertex (vec3 3.0 2.1667 -28.0) (vec3 0.8314 0.8157 0.8157)
          )
        , ( Vertex (vec3 1.0 2.5667 -23.0) (vec3 0.5608 0.5608 0.5451)
          , Vertex (vec3 4.0 2.8667 -26.0) (vec3 0.502 0.5137 0.4431)
          , Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.4902 0.5137 0.4431)
          )
        , ( Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.498 0.5137 0.4431)
          , Vertex (vec3 4.0 2.8667 -26.0) (vec3 0.4941 0.5137 0.4431)
          , Vertex (vec3 3.0 2.1667 -28.0) (vec3 0.5529 0.5608 0.5451)
          )
        , ( Vertex (vec3 0.0 2.8667 -22.0) (vec3 0.7333 0.7373 0.7529)
          , Vertex (vec3 0.0 6.8667 -26.0) (vec3 0.8314 0.8157 0.8157)
          , Vertex (vec3 0.35 7.1667 -28.0) (vec3 0.7176 0.7137 0.7098)
          )
        , ( Vertex (vec3 0.35 7.1667 -28.0) (vec3 0.7176 0.7137 0.7098)
          , Vertex (vec3 0.0 2.8667 -22.0) (vec3 0.7333 0.7373 0.7529)
          , Vertex (vec3 0.5 2.8667 -27.0) (vec3 0.7098 0.7137 0.7098)
          )
        , ( Vertex (vec3 0.35 7.1667 -28.0) (vec3 0.7098 0.7137 0.7098)
          , Vertex (vec3 0.5 2.8667 -27.0) (vec3 0.7216 0.7137 0.7098)
          , Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.498 0.5137 0.4431)
          )
        , ( Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.4902 0.5137 0.4431)
          , Vertex (vec3 0.35 7.1667 -28.0) (vec3 0.7176 0.7137 0.7098)
          , Vertex (vec3 0.0 7.2667 -28.2) (vec3 0.5569 0.5608 0.5451)
          )
        , ( Vertex (vec3 0.0 7.2667 -28.2) (vec3 0.8314 0.8157 0.8157)
          , Vertex (vec3 0.0 6.8667 -26.0) (vec3 0.8392 0.8157 0.8157)
          , Vertex (vec3 0.35 7.1667 -28.0) (vec3 0.7176 0.7137 0.7098)
          )
        , ( Vertex (vec3 4.2 -5.4333 9.5) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.0 -5.8333 9.5) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 3.8 -5.4333 9.5) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 4.2 -5.4333 9.5) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.0 -5.8333 9.5) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 4.2 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 4.0 -5.8333 9.5) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 4.0 -7.3333 6.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 4.2 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 3.8 -5.4333 9.5) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 4.0 -5.8333 9.5) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 3.8 -6.9333 6.0) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 4.0 -5.8333 9.5) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 4.0 -7.3333 6.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 3.8 -6.9333 6.0) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 4.2 -5.4333 9.5) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 3.8 -5.4333 9.5) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 4.2 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 4.2 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 3.8 -6.9333 6.0) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 3.8 -5.4333 9.5) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 4.2 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.0 -7.3333 6.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 3.8 -6.9333 6.0) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 4.2 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.0 -7.3333 6.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 2.2 -2.9333 4.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 2.2 -2.9333 4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 2.0 -3.3333 4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.0 -7.3333 6.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 3.8 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.0 -7.3333 6.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 1.8 -2.9333 4.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 1.8 -2.9333 4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 2.0 -3.3333 4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.0 -7.3333 6.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 4.2 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 2.2 -2.9333 4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 3.8 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 1.8 -2.9333 4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 2.2 -2.9333 4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 3.8 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 4.2 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.0 -7.3333 6.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 4.2 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 4.2 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.0 -7.3333 6.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          )
        , ( Vertex (vec3 3.8 -6.9333 6.0) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 4.0 -7.3333 6.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 3.8 -5.9333 -4.0) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 3.8 -5.9333 -4.0) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 4.0 -7.3333 6.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          )
        , ( Vertex (vec3 4.2 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.2 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.0 -7.3333 6.0) (vec3 0.6706 0.6706 0.6824)
          )
        , ( Vertex (vec3 4.0 -7.3333 6.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 4.2 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 4.2 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 3.8 -5.9333 -4.0) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 4.2 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 2.2 -1.9333 -3.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.0 -6.3333 -4.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 2.2 -1.9333 -3.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 2.0 -2.3333 -3.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          )
        , ( Vertex (vec3 3.8 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 1.8 -1.9333 -3.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.0 -6.3333 -4.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 1.8 -1.9333 -3.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 2.0 -2.3333 -3.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.0 -6.3333 -4.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 4.2 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 3.8 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 2.2 -1.9333 -3.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 2.2 -1.9333 -3.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 1.8 -1.9333 -3.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 3.8 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 4.2 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.2 -3.9333 -7.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          )
        , ( Vertex (vec3 4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 4.0 -4.3333 -7.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 4.2 -3.9333 -7.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 3.8 -5.9333 -4.0) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 3.8 -3.9333 -7.0) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          )
        , ( Vertex (vec3 4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 4.0 -4.3333 -7.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 3.8 -3.9333 -7.0) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 4.2 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.2 -3.9333 -7.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          )
        , ( Vertex (vec3 4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 4.0 -4.3333 -7.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 4.2 -3.9333 -7.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 4.2 -3.9333 -7.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 4.0 -4.3333 -7.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 3.8 -3.9333 -7.0) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 0.0 -2.6333 13.0) (vec3 0.7451 0.7098 0.7098)
          , Vertex (vec3 0.0 1.8667 7.0) (vec3 0.7725 0.7647 0.7647)
          , Vertex (vec3 -1.7 1.8667 7.0) (vec3 0.7804 0.7647 0.7647)
          )
        , ( Vertex (vec3 0.0 -2.6333 13.0) (vec3 0.7451 0.7098 0.7098)
          , Vertex (vec3 -1.7 1.8667 7.0) (vec3 0.7608 0.7647 0.7647)
          , Vertex (vec3 -2.0 -2.6333 13.0) (vec3 0.702 0.6392 0.6588)
          )
        , ( Vertex (vec3 -2.0 -2.6333 13.0) (vec3 0.7451 0.7098 0.7098)
          , Vertex (vec3 -1.7 1.8667 7.0) (vec3 0.749 0.7647 0.7647)
          , Vertex (vec3 -4.0 -3.1333 9.0) (vec3 0.7725 0.7216 0.7216)
          )
        , ( Vertex (vec3 -4.0 -3.1333 9.0) (vec3 0.7765 0.7216 0.7216)
          , Vertex (vec3 -1.7 1.8667 7.0) (vec3 0.7725 0.7647 0.7647)
          , Vertex (vec3 -5.0 -3.6333 4.0) (vec3 0.7843 0.7216 0.7216)
          )
        , ( Vertex (vec3 -5.0 -3.6333 4.0) (vec3 0.7725 0.7216 0.7216)
          , Vertex (vec3 -1.7 1.8667 7.0) (vec3 0.7686 0.7647 0.7647)
          , Vertex (vec3 -3.0 3.3667 1.0) (vec3 0.7529 0.7647 0.7647)
          )
        , ( Vertex (vec3 -5.0 -3.6333 4.0) (vec3 0.7804 0.7216 0.7216)
          , Vertex (vec3 -4.0 -2.1333 -4.0) (vec3 0.7843 0.7216 0.7216)
          , Vertex (vec3 -3.0 3.3667 1.0) (vec3 0.7686 0.7647 0.7647)
          )
        , ( Vertex (vec3 -4.0 -2.1333 -4.0) (vec3 0.7686 0.7216 0.7216)
          , Vertex (vec3 -2.0 2.8667 -4.0) (vec3 0.7765 0.7647 0.7647)
          , Vertex (vec3 -3.0 3.3667 1.0) (vec3 0.7451 0.7647 0.7647)
          )
        , ( Vertex (vec3 -4.0 -2.1333 -4.0) (vec3 0.7765 0.7216 0.7216)
          , Vertex (vec3 -3.0 -1.1333 -6.0) (vec3 0.7804 0.7216 0.7216)
          , Vertex (vec3 -2.0 2.8667 -4.0) (vec3 0.749 0.7647 0.7647)
          )
        , ( Vertex (vec3 -3.0 -1.1333 -6.0) (vec3 0.7765 0.7216 0.7216)
          , Vertex (vec3 0.0 2.3667 -5.0) (vec3 0.7765 0.7647 0.7647)
          , Vertex (vec3 -2.0 2.8667 -4.0) (vec3 0.7647 0.7647 0.7647)
          )
        , ( Vertex (vec3 -3.0 -1.1333 -6.0) (vec3 0.7686 0.7216 0.7216)
          , Vertex (vec3 -2.0 0.3667 -9.0) (vec3 0.7529 0.7216 0.7216)
          , Vertex (vec3 0.0 2.3667 -5.0) (vec3 0.7608 0.7647 0.7647)
          )
        , ( Vertex (vec3 -2.0 0.3667 -9.0) (vec3 0.7843 0.7216 0.7216)
          , Vertex (vec3 0.0 1.8667 -9.0) (vec3 0.7686 0.7647 0.7647)
          , Vertex (vec3 0.0 2.3667 -5.0) (vec3 0.7529 0.7647 0.7647)
          )
        , ( Vertex (vec3 -2.0 0.3667 -9.0) (vec3 0.7686 0.7216 0.7216)
          , Vertex (vec3 0.0 2.8667 -22.0) (vec3 0.7569 0.7647 0.7647)
          , Vertex (vec3 0.0 1.8667 -9.0) (vec3 0.7569 0.7647 0.7647)
          )
        , ( Vertex (vec3 -2.0 0.3667 -9.0) (vec3 0.7843 0.7216 0.7216)
          , Vertex (vec3 -1.0 2.5667 -23.0) (vec3 0.7686 0.7647 0.7647)
          , Vertex (vec3 0.0 2.8667 -22.0) (vec3 0.7725 0.7647 0.7647)
          )
        , ( Vertex (vec3 -1.0 2.5667 -23.0) (vec3 0.7451 0.7647 0.7647)
          , Vertex (vec3 -1.0 2.8667 -27.0) (vec3 0.6706 0.6588 0.6392)
          , Vertex (vec3 0.0 2.8667 -22.0) (vec3 0.7765 0.7647 0.7647)
          )
        , ( Vertex (vec3 -1.7 1.8667 7.0) (vec3 0.8275 0.8157 0.8157)
          , Vertex (vec3 0.0 3.8667 0.7) (vec3 0.9098 0.8157 0.8157)
          , Vertex (vec3 0.0 1.8667 7.0) (vec3 0.8196 0.8157 0.8157)
          )
        , ( Vertex (vec3 -1.7 1.8667 7.0) (vec3 0.8235 0.8157 0.8157)
          , Vertex (vec3 -1.0 3.8667 0.7) (vec3 0.8353 0.8157 0.8157)
          , Vertex (vec3 0.0 3.8667 0.7) (vec3 0.8275 0.8157 0.8157)
          )
        , ( Vertex (vec3 -1.7 1.8667 7.0) (vec3 0.8196 0.8157 0.8157)
          , Vertex (vec3 -3.0 3.3667 1.0) (vec3 0.8157 0.8157 0.8157)
          , Vertex (vec3 -1.0 3.8667 0.7) (vec3 0.8157 0.8157 0.8157)
          )
        , ( Vertex (vec3 -3.0 3.3667 1.0) (vec3 0.8118 0.8157 0.8157)
          , Vertex (vec3 -2.0 2.8667 -4.0) (vec3 0.8078 0.8157 0.8157)
          , Vertex (vec3 -1.0 3.8667 0.7) (vec3 0.8157 0.8157 0.8157)
          )
        , ( Vertex (vec3 -2.0 2.8667 -4.0) (vec3 0.8078 0.8157 0.8157)
          , Vertex (vec3 0.0 3.8667 -2.0) (vec3 0.8235 0.8157 0.8157)
          , Vertex (vec3 -1.0 3.8667 0.7) (vec3 0.8353 0.8157 0.8157)
          )
        , ( Vertex (vec3 -2.0 2.8667 -4.0) (vec3 0.8314 0.8157 0.8157)
          , Vertex (vec3 0.0 2.3667 -5.0) (vec3 0.8275 0.8157 0.8157)
          , Vertex (vec3 0.0 3.8667 -2.0) (vec3 0.8235 0.8157 0.8157)
          )
        , ( Vertex (vec3 -1.0 3.8667 0.7) (vec3 0.5294 0.5255 0.5137)
          , Vertex (vec3 -0.7 4.8667 0.6) (vec3 0.5255 0.5255 0.5137)
          , Vertex (vec3 0.0 3.8667 0.7) (vec3 0.5216 0.5255 0.5137)
          )
        , ( Vertex (vec3 -0.7 4.8667 0.6) (vec3 0.5176 0.5255 0.5137)
          , Vertex (vec3 0.0 4.8667 0.6) (vec3 0.5255 0.5255 0.5137)
          , Vertex (vec3 0.0 3.8667 0.7) (vec3 0.5137 0.5255 0.5137)
          )
        , ( Vertex (vec3 -1.0 3.8667 0.7) (vec3 0.5373 0.5255 0.5137)
          , Vertex (vec3 -0.7 4.8667 0.6) (vec3 0.5412 0.5255 0.5137)
          , Vertex (vec3 0.0 4.8667 -1.0) (vec3 0.5255 0.5255 0.5137)
          )
        , ( Vertex (vec3 0.0 4.8667 -1.0) (vec3 0.5255 0.5255 0.5137)
          , Vertex (vec3 0.0 3.8667 -2.0) (vec3 0.5255 0.5255 0.5137)
          , Vertex (vec3 -1.0 3.8667 0.7) (vec3 0.5294 0.5255 0.5137)
          )
        , ( Vertex (vec3 -0.7 4.8667 0.6) (vec3 0.5412 0.4431 0.4314)
          , Vertex (vec3 0.0 4.8667 -1.0) (vec3 0.5216 0.4431 0.4314)
          , Vertex (vec3 0.0 4.8667 0.6) (vec3 0.5216 0.4431 0.4314)
          )
        , ( Vertex (vec3 0.0 -2.6333 13.0) (vec3 0.6549 0.6588 0.6392)
          , Vertex (vec3 -2.0 -4.6333 11.0) (vec3 0.4941 0.5137 0.4431)
          , Vertex (vec3 0.0 -4.6333 11.0) (vec3 0.5059 0.5137 0.4431)
          )
        , ( Vertex (vec3 0.0 -2.6333 13.0) (vec3 0.6627 0.6588 0.6392)
          , Vertex (vec3 -2.0 -2.6333 13.0) (vec3 0.6588 0.6588 0.6392)
          , Vertex (vec3 -2.0 -4.6333 11.0) (vec3 0.5137 0.5137 0.4431)
          )
        , ( Vertex (vec3 -2.0 -4.6333 11.0) (vec3 0.4941 0.5137 0.4431)
          , Vertex (vec3 -2.0 -2.6333 13.0) (vec3 0.6627 0.6588 0.6392)
          , Vertex (vec3 -4.0 -3.1333 9.0) (vec3 0.6745 0.6588 0.6392)
          )
        , ( Vertex (vec3 -4.0 -3.1333 9.0) (vec3 0.6745 0.6588 0.6392)
          , Vertex (vec3 -4.0 -4.8333 -1.0) (vec3 0.5176 0.5137 0.4431)
          , Vertex (vec3 -2.0 -4.6333 11.0) (vec3 0.5294 0.5137 0.4431)
          )
        , ( Vertex (vec3 -4.0 -3.1333 9.0) (vec3 0.6667 0.6588 0.6392)
          , Vertex (vec3 -5.0 -3.6333 4.0) (vec3 0.5176 0.5137 0.4431)
          , Vertex (vec3 -4.0 -4.8333 -1.0) (vec3 0.5294 0.5137 0.4431)
          )
        , ( Vertex (vec3 -5.0 -3.6333 4.0) (vec3 0.4941 0.5137 0.4431)
          , Vertex (vec3 -4.0 -2.1333 -4.0) (vec3 0.6706 0.6588 0.6392)
          , Vertex (vec3 -4.0 -4.8333 -1.0) (vec3 0.5216 0.5137 0.4431)
          )
        , ( Vertex (vec3 -4.0 -4.8333 -1.0) (vec3 0.5098 0.5137 0.4431)
          , Vertex (vec3 -4.0 -2.1333 -4.0) (vec3 0.5176 0.5137 0.4431)
          , Vertex (vec3 -2.0 -2.1333 -6.0) (vec3 0.5137 0.5137 0.4431)
          )
        , ( Vertex (vec3 -4.0 -2.1333 -4.0) (vec3 0.5098 0.5137 0.4431)
          , Vertex (vec3 -3.0 -1.1333 -6.0) (vec3 0.6549 0.6588 0.6392)
          , Vertex (vec3 -2.0 -2.1333 -6.0) (vec3 0.5216 0.5137 0.4431)
          )
        , ( Vertex (vec3 -3.0 -1.1333 -6.0) (vec3 0.6588 0.6588 0.6392)
          , Vertex (vec3 -2.0 -2.1333 -6.0) (vec3 0.502 0.5137 0.4431)
          , Vertex (vec3 -2.0 0.3667 -9.0) (vec3 0.651 0.6588 0.6392)
          )
        , ( Vertex (vec3 -2.0 0.3667 -9.0) (vec3 0.6549 0.6588 0.6392)
          , Vertex (vec3 -2.0 -2.1333 -6.0) (vec3 0.4902 0.5137 0.4431)
          , Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.4863 0.5137 0.4431)
          )
        , ( Vertex (vec3 -2.0 0.3667 -9.0) (vec3 0.6549 0.6588 0.6392)
          , Vertex (vec3 -1.0 2.5667 -23.0) (vec3 0.651 0.6588 0.6392)
          , Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.498 0.5137 0.4431)
          )
        , ( Vertex (vec3 -1.0 2.5667 -23.0) (vec3 0.6549 0.6588 0.6392)
          , Vertex (vec3 -1.0 2.8667 -27.0) (vec3 0.6667 0.6588 0.6392)
          , Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.498 0.5137 0.4431)
          )
        , ( Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.4902 0.5137 0.4431)
          , Vertex (vec3 0.0 2.8667 -27.0) (vec3 0.651 0.6588 0.6392)
          , Vertex (vec3 -1.0 2.8667 -27.0) (vec3 0.6588 0.6588 0.6392)
          )
        , ( Vertex (vec3 0.0 2.8667 -22.0) (vec3 0.7569 0.7647 0.7647)
          , Vertex (vec3 -1.0 2.8667 -27.0) (vec3 0.6706 0.6588 0.6392)
          , Vertex (vec3 0.0 2.8667 -27.0) (vec3 0.7451 0.7216 0.7216)
          )
        , ( Vertex (vec3 0.0 -4.8333 -1.0) (vec3 0.3451 0.349 0.3725)
          , Vertex (vec3 -2.0 -4.6333 11.0) (vec3 0.498 0.5137 0.4431)
          , Vertex (vec3 0.0 -4.6333 11.0) (vec3 0.4902 0.5137 0.4431)
          )
        , ( Vertex (vec3 0.0 -4.8333 -1.0) (vec3 0.3569 0.349 0.3725)
          , Vertex (vec3 -2.0 -4.6333 11.0) (vec3 0.502 0.5137 0.4431)
          , Vertex (vec3 -4.0 -4.8333 -1.0) (vec3 0.4902 0.5137 0.4431)
          )
        , ( Vertex (vec3 0.0 -4.8333 -1.0) (vec3 0.3569 0.349 0.3725)
          , Vertex (vec3 -4.0 -4.8333 -1.0) (vec3 0.498 0.5137 0.4431)
          , Vertex (vec3 -2.0 -2.1333 -6.0) (vec3 0.502 0.5137 0.4431)
          )
        , ( Vertex (vec3 0.0 -4.8333 -1.0) (vec3 0.349 0.349 0.3725)
          , Vertex (vec3 -2.0 -2.1333 -6.0) (vec3 0.502 0.5137 0.4431)
          , Vertex (vec3 0.0 -1.1333 -8.0) (vec3 0.4824 0.5137 0.4431)
          )
        , ( Vertex (vec3 -2.0 -2.1333 -6.0) (vec3 0.5059 0.5137 0.4431)
          , Vertex (vec3 0.0 -1.1333 -8.0) (vec3 0.502 0.5137 0.4431)
          , Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.498 0.5137 0.4431)
          )
        , ( Vertex (vec3 -5.0 -3.6333 4.0) (vec3 0.7294 0.7373 0.7529)
          , Vertex (vec3 -8.0 -3.6333 2.0) (vec3 0.6588 0.6588 0.6392)
          , Vertex (vec3 -8.0 -2.1333 -2.0) (vec3 0.6627 0.6588 0.6392)
          )
        , ( Vertex (vec3 -8.0 -2.1333 -2.0) (vec3 0.6549 0.6588 0.6392)
          , Vertex (vec3 -5.0 -3.6333 4.0) (vec3 0.7294 0.7373 0.7529)
          , Vertex (vec3 -4.0 -2.1333 -4.0) (vec3 0.7412 0.7373 0.7529)
          )
        , ( Vertex (vec3 -8.0 -3.6333 2.0) (vec3 0.8275 0.8157 0.8157)
          , Vertex (vec3 -8.0 -2.8333 -2.0) (vec3 0.8235 0.8157 0.8157)
          , Vertex (vec3 -8.0 -2.1333 -2.0) (vec3 0.8353 0.8157 0.8157)
          )
        , ( Vertex (vec3 -8.0 -2.1333 -2.0) (vec3 0.8314 0.8157 0.8157)
          , Vertex (vec3 -8.0 -2.8333 -2.0) (vec3 0.8392 0.8157 0.8157)
          , Vertex (vec3 -4.0 -2.1333 -4.0) (vec3 0.502 0.5137 0.4431)
          )
        , ( Vertex (vec3 -4.0 -2.1333 -4.0) (vec3 0.4902 0.5137 0.4431)
          , Vertex (vec3 -8.0 -2.8333 -2.0) (vec3 0.8275 0.8157 0.8157)
          , Vertex (vec3 -3.0 -3.1333 -3.0) (vec3 0.498 0.5137 0.4431)
          )
        , ( Vertex (vec3 -3.0 -3.1333 -3.0) (vec3 0.498 0.5137 0.4431)
          , Vertex (vec3 -8.0 -3.6333 2.0) (vec3 0.549 0.5608 0.5451)
          , Vertex (vec3 -8.0 -2.8333 -2.0) (vec3 0.498 0.5137 0.4431)
          )
        , ( Vertex (vec3 -8.0 -3.6333 2.0) (vec3 0.5529 0.5608 0.5451)
          , Vertex (vec3 -5.0 -3.6333 4.0) (vec3 0.4902 0.5137 0.4431)
          , Vertex (vec3 -3.0 -3.1333 -3.0) (vec3 0.498 0.5137 0.4431)
          )
        , ( Vertex (vec3 -1.0 2.5667 -23.0) (vec3 0.7569 0.7647 0.7647)
          , Vertex (vec3 -4.0 2.8667 -26.0) (vec3 0.7647 0.7647 0.7647)
          , Vertex (vec3 -1.0 2.8667 -27.0) (vec3 0.6706 0.6588 0.6392)
          )
        , ( Vertex (vec3 -4.0 2.8667 -26.0) (vec3 0.7608 0.7647 0.7647)
          , Vertex (vec3 -1.0 2.8667 -27.0) (vec3 0.6627 0.6588 0.6392)
          , Vertex (vec3 -3.0 2.8667 -28.0) (vec3 0.6588 0.6588 0.6392)
          )
        , ( Vertex (vec3 -1.0 2.8667 -27.0) (vec3 0.6667 0.6588 0.6392)
          , Vertex (vec3 -3.0 2.8667 -28.0) (vec3 0.5569 0.5608 0.5451)
          , Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.498 0.5137 0.4431)
          )
        , ( Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.4902 0.5137 0.4431)
          , Vertex (vec3 -3.0 2.8667 -28.0) (vec3 0.549 0.5608 0.5451)
          , Vertex (vec3 -3.0 2.1667 -28.0) (vec3 0.5569 0.5608 0.5451)
          )
        , ( Vertex (vec3 -4.0 2.8667 -26.0) (vec3 0.7569 0.7647 0.7647)
          , Vertex (vec3 -3.0 2.8667 -28.0) (vec3 0.6588 0.6588 0.6392)
          , Vertex (vec3 -3.0 2.1667 -28.0) (vec3 0.8314 0.8157 0.8157)
          )
        , ( Vertex (vec3 -1.0 2.5667 -23.0) (vec3 0.5608 0.5608 0.5451)
          , Vertex (vec3 -4.0 2.8667 -26.0) (vec3 0.502 0.5137 0.4431)
          , Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.4902 0.5137 0.4431)
          )
        , ( Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.498 0.5137 0.4431)
          , Vertex (vec3 -4.0 2.8667 -26.0) (vec3 0.4941 0.5137 0.4431)
          , Vertex (vec3 -3.0 2.1667 -28.0) (vec3 0.5529 0.5608 0.5451)
          )
        , ( Vertex (vec3 0.0 2.8667 -22.0) (vec3 0.7333 0.7373 0.7529)
          , Vertex (vec3 0.0 6.8667 -26.0) (vec3 0.8314 0.8157 0.8157)
          , Vertex (vec3 -0.35 7.1667 -28.0) (vec3 0.7176 0.7137 0.7098)
          )
        , ( Vertex (vec3 -0.35 7.1667 -28.0) (vec3 0.7176 0.7137 0.7098)
          , Vertex (vec3 0.0 2.8667 -22.0) (vec3 0.7333 0.7373 0.7529)
          , Vertex (vec3 -0.5 2.8667 -27.0) (vec3 0.7098 0.7137 0.7098)
          )
        , ( Vertex (vec3 -0.35 7.1667 -28.0) (vec3 0.7098 0.7137 0.7098)
          , Vertex (vec3 -0.5 2.8667 -27.0) (vec3 0.7216 0.7137 0.7098)
          , Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.498 0.5137 0.4431)
          )
        , ( Vertex (vec3 0.0 1.8667 -27.0) (vec3 0.4902 0.5137 0.4431)
          , Vertex (vec3 -0.35 7.1667 -28.0) (vec3 0.7176 0.7137 0.7098)
          , Vertex (vec3 0.0 7.2667 -28.2) (vec3 0.5569 0.5608 0.5451)
          )
        , ( Vertex (vec3 0.0 7.2667 -28.2) (vec3 0.8314 0.8157 0.8157)
          , Vertex (vec3 0.0 6.8667 -26.0) (vec3 0.8392 0.8157 0.8157)
          , Vertex (vec3 -0.35 7.1667 -28.0) (vec3 0.7176 0.7137 0.7098)
          )
        , ( Vertex (vec3 -4.2 -5.4333 9.5) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.0 -5.8333 9.5) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -3.8 -5.4333 9.5) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 -4.2 -5.4333 9.5) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.0 -5.8333 9.5) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -4.2 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 -4.0 -5.8333 9.5) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -4.0 -7.3333 6.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -4.2 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 -3.8 -5.4333 9.5) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 -4.0 -5.8333 9.5) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -3.8 -6.9333 6.0) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 -4.0 -5.8333 9.5) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -4.0 -7.3333 6.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -3.8 -6.9333 6.0) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 -4.2 -5.4333 9.5) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -3.8 -5.4333 9.5) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 -4.2 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 -4.2 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -3.8 -6.9333 6.0) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 -3.8 -5.4333 9.5) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 -4.2 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.0 -7.3333 6.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -3.8 -6.9333 6.0) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 -4.2 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.0 -7.3333 6.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -2.2 -2.9333 4.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 -2.2 -2.9333 4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -2.0 -3.3333 4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.0 -7.3333 6.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 -3.8 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.0 -7.3333 6.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -1.8 -2.9333 4.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 -1.8 -2.9333 4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -2.0 -3.3333 4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.0 -7.3333 6.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 -4.2 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -2.2 -2.9333 4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -3.8 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 -1.8 -2.9333 4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -2.2 -2.9333 4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -3.8 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 -4.2 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.0 -7.3333 6.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -4.2 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 -4.2 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.0 -7.3333 6.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          )
        , ( Vertex (vec3 -3.8 -6.9333 6.0) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 -4.0 -7.3333 6.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -3.8 -5.9333 -4.0) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 -3.8 -5.9333 -4.0) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 -4.0 -7.3333 6.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          )
        , ( Vertex (vec3 -4.2 -6.9333 6.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.2 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.0 -7.3333 6.0) (vec3 0.6706 0.6706 0.6824)
          )
        , ( Vertex (vec3 -4.0 -7.3333 6.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -4.2 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 -4.2 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -3.8 -5.9333 -4.0) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 -4.2 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -2.2 -1.9333 -3.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.0 -6.3333 -4.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 -2.2 -1.9333 -3.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -2.0 -2.3333 -3.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          )
        , ( Vertex (vec3 -3.8 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -1.8 -1.9333 -3.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.0 -6.3333 -4.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 -1.8 -1.9333 -3.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -2.0 -2.3333 -3.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.0 -6.3333 -4.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 -4.2 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -3.8 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -2.2 -1.9333 -3.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 -2.2 -1.9333 -3.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -1.8 -1.9333 -3.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -3.8 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 -4.2 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.2 -3.9333 -7.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          )
        , ( Vertex (vec3 -4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -4.0 -4.3333 -7.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -4.2 -3.9333 -7.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 -3.8 -5.9333 -4.0) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 -3.8 -3.9333 -7.0) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 -4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          )
        , ( Vertex (vec3 -4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -4.0 -4.3333 -7.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -3.8 -3.9333 -7.0) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 -4.2 -5.9333 -4.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.2 -3.9333 -7.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          )
        , ( Vertex (vec3 -4.0 -6.3333 -4.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -4.0 -4.3333 -7.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -4.2 -3.9333 -7.0) (vec3 0.8471 0.8588 0.8471)
          )
        , ( Vertex (vec3 -4.2 -3.9333 -7.0) (vec3 0.8471 0.8588 0.8471)
          , Vertex (vec3 -4.0 -4.3333 -7.0) (vec3 0.6706 0.6706 0.6824)
          , Vertex (vec3 -3.8 -3.9333 -7.0) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 0.2 4.0 -0.2) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 0.2 9.0 -0.2) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 0.2 9.0 0.2) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 0.2 4.0 -0.2) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 0.2 4.0 0.2) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 0.2 9.0 0.2) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 -0.2 4.0 0.2) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 -0.2 9.0 0.2) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 0.2 9.0 0.2) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 -0.2 4.0 0.2) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 0.2 4.0 0.2) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 0.2 9.0 0.2) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 -0.2 4.0 0.2) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 -0.2 9.0 0.2) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 -0.2 9.0 -0.2) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 -0.2 4.0 0.2) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 -0.2 4.0 -0.2) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 -0.2 9.0 -0.2) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 0.2 4.0 -0.2) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 0.2 9.0 -0.2) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 -0.2 9.0 -0.2) (vec3 0.7922 0.7922 0.7922)
          )
        , ( Vertex (vec3 0.2 4.0 -0.2) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 -0.2 4.0 -0.2) (vec3 0.7922 0.7922 0.7922)
          , Vertex (vec3 -0.2 9.0 -0.2) (vec3 0.7922 0.7922 0.7922)
          )
        ]