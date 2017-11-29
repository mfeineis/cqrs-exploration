port module Domain exposing (main)


import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Task


port toElm : (Value -> msg) -> Sub msg
port fromElm : Value -> Cmd msg


main : Program Never Model Msg
main =
    Platform.program
        { init = init ()
        , subscriptions = subscriptions
        , update = update
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ toElm Interop
        ]


decodeEnvelope : Decoder Envelope
decodeEnvelope =
    Decode.map Envelope
        (Decode.field "type" Decode.string)



init : () -> ( Model, Cmd Msg )
init flags =
    ( {}, Cmd.none )


type alias Model =
    {}


type Msg
    = Ack
    | Interop Value


type alias Envelope =
    { type_ : String
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Ack ->
            ( model, fromElm makeAck )

        Interop value ->
            handleInterop model value


msgToCmd : Msg -> Cmd Msg
msgToCmd msg =
    Task.succeed msg
        |> Task.perform identity


handleInterop : Model -> Value -> ( Model, Cmd Msg )
handleInterop model value =
    case Decode.decodeValue decodeEnvelope value of
        Err message ->
            ( model, fromElm (makeDecodeError message))

        Ok { type_ } ->
            case type_ of
                "PRODUCE" ->
                    ( model, Cmd.batch [ fromElm makeEmit, msgToCmd Ack ])

                _ ->
                    ( model, fromElm (makeUnknownError type_))


makeAck : Value
makeAck =
    Encode.object
        [ ( "type", Encode.string "ACK" )
        ]


makeEmit : Value
makeEmit =
    Encode.object
        [ ( "type", Encode.string "EMIT" )
        ]


makeUnknownError : String -> Value
makeUnknownError type_ =
    Encode.object
        [ ( "type", Encode.string "UNKNOWN_ERROR" )
        ]


makeDecodeError : String -> Value
makeDecodeError message =
    Encode.object
        [ ( "type", Encode.string "DECODE_ERROR" )
        ]
