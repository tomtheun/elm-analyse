module Analyser.Files.FileContent exposing (FileContent, RefeshedAST, asRawFile)

import Elm.Parser as Parser
import Elm.RawFile exposing (RawFile)
import Elm.Json.Decode as Elm
import Maybe.Extra as Maybe
import Json.Decode
import Result.Extra as Result


type alias RefeshedAST =
    Bool


type alias FileContent =
    { path : String
    , success : Bool
    , sha1 : Maybe String
    , content : Maybe String
    , ast : Maybe String
    , formatted : Bool
    }


asRawFile : FileContent -> ( Result String RawFile, RefeshedAST )
asRawFile fileContent =
    fileContent.ast
        |> Maybe.andThen (Json.Decode.decodeString Elm.decode >> Result.toMaybe)
        |> Maybe.map (\x -> ( Ok x, False ))
        |> Maybe.orElseLazy (\() -> Just ( loadedFileFromContent fileContent, True ))
        |> Maybe.withDefault ( Err "Internal problem in the file loader. Please report an issue.", False )


loadedFileFromContent : FileContent -> Result String RawFile
loadedFileFromContent fileContent =
    case fileContent.content of
        Just content ->
            (Parser.parse content
                |> Result.map Ok
                |> Result.mapError (List.head >> Maybe.withDefault "" >> Err)
                |> Result.merge
            )

        Nothing ->
            Err "No file content"
