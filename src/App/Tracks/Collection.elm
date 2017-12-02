module Tracks.Collection exposing (..)

import List.Extra as List
import Playlists.Types exposing (Playlist)
import Tracks.Collection.Internal exposing (buildf, identify, arrange, harvest, expose)
import Tracks.Collection.Responses exposing (..)
import Tracks.Types exposing (..)
import Types as TopLevel


-- 💧


makeParcel : Model -> Parcel
makeParcel model =
    (,) model model.collection



-- 🔥 / Rex


reidentify : Parcel -> Parcel
reidentify =
    identify >> arrange >> harvest >> expose


rearrange : Parcel -> Parcel
rearrange =
    arrange >> harvest >> expose


reharvest : Parcel -> Parcel
reharvest =
    harvest >> expose


reexpose : Parcel -> Parcel
reexpose =
    expose


recalibrate : Parcel -> Parcel
recalibrate parcel =
    Tuple.mapFirst (\model -> { model | exposedStep = 1 }) parcel


remap : (List IdentifiedTrack -> List IdentifiedTrack) -> Parcel -> Parcel
remap mapFn ( model, collection ) =
    (,)
        model
        { collection
            | identified = mapFn collection.identified
            , arranged = mapFn collection.arranged
            , harvested = mapFn collection.harvested
            , exposed = mapFn collection.exposed
        }



--🔥 / Rex, specialized.


redoBasedOnPlaylist : Maybe Playlist -> Parcel -> Parcel
redoBasedOnPlaylist maybePreviouslySelectedPlaylist parcel =
    let
        -- TODO
        prev =
            maybePreviouslySelectedPlaylist
                |> Maybe.map (.autoGenerated >> not)
                |> Maybe.withDefault False

        next =
            parcel
                |> Tuple.mapFirst .selectedPlaylist
                |> Tuple.first
                |> Maybe.map (.autoGenerated >> not)
                |> Maybe.withDefault False
    in
        if prev || next then
            rearrange parcel
        else
            reharvest parcel



-- 🔥 / Add or remove


add : List Track -> Parcel -> Parcel
add tracks ( model, collection ) =
    tracks
        |> (++) collection.untouched
        |> buildf ( model, collection )


removeBySourceId : SourceId -> Parcel -> Parcel
removeBySourceId sourceId ( model, collection ) =
    collection.untouched
        |> List.filter (.sourceId >> (/=) sourceId)
        |> buildf ( model, collection )


removeByPath : SourceId -> List String -> Parcel -> Parcel
removeByPath sourceId paths ( model, collection ) =
    collection.untouched
        |> List.filterNot
            (\t ->
                if t.sourceId == sourceId then
                    List.member t.path paths
                else
                    False
            )
        |> buildf ( model, collection )


partial : Int
partial =
    Tracks.Collection.Internal.partial



-- 🌱 / Responses


set : Parcel -> ( Model, Cmd TopLevel.Msg )
set ( model, newCollection ) =
    ( { model | collection = newCollection }
      --
      -- Consequences
      --
    , Cmd.batch
        [ harvestingConsequences model.collection newCollection model
        , globalConsequences model.collection newCollection model
        ]
    )
