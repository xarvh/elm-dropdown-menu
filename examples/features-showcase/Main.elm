module Main exposing (..)

import Css
import Html exposing (..)
import DropdownMenu exposing (defaultCommonFeatures, OpenState)
import DropdownMenuScroll


-- types


type MenuId
    = MenuMain
    | MenuTicked
    | MenuNumbers


type Focus
    = FocusNone
    | FocusDropdownMenu MenuId DropdownMenu.OpenState


type SelectedMenu
    = SelectedMenuTicked (Maybe String)
    | SelectedMenuNumbers (Maybe Int)


type alias Model =
    { focus : Focus
    , maybeSelectedMenu : Maybe SelectedMenu
    }


type Msg
    = DropdownMenuMsg MenuId DropdownMenu.Msg



-- Init


init : Model
init =
    { focus = FocusNone
    , maybeSelectedMenu = Nothing
    }



-- Common dropdown menu stuff


commonFeatures : DropdownMenu.CommonFeatures
commonFeatures =
    { defaultCommonFeatures | scrollIntoView = DropdownMenuScroll.scrollToDomId }


dropdownView =
    DropdownMenu.view commonFeatures


dropdownUpdate =
    DropdownMenu.update commonFeatures


maybeOpenState : MenuId -> Model -> Maybe OpenState
maybeOpenState id model =
    case model.focus of
        FocusNone ->
            Nothing

        FocusDropdownMenu menuId openState ->
            if menuId == id then
                Just openState
            else
                Nothing


closeAllDropdowns : Model -> Model
closeAllDropdowns model =
    { model | focus = FocusNone }


openDropdown : MenuId -> OpenState -> Model -> ( Model, Cmd msg )
openDropdown id openState model =
    noCmd { model | focus = FocusDropdownMenu id openState }



-- Main dropdown


selectionToMenuId : SelectedMenu -> MenuId
selectionToMenuId selection =
    case selection of
        SelectedMenuTicked _ ->
            MenuTicked

        SelectedMenuNumbers _ ->
            MenuNumbers


mainConfig =
    let
        items =
            [ MenuTicked
            , MenuNumbers
            ]

        itemToLabel item =
            case item of
                MenuTicked ->
                    "MenuTicked"

                MenuNumbers ->
                    "MenuNumbers"

                _ ->
                    ""
    in
        { hasClearButton = False
        , itemToHtml = DropdownMenu.itemToHtml itemToLabel
        , itemToId = itemToLabel
        , itemToLabel = itemToLabel
        , modelToItems = always items
        , modelToMaybeOpenState = maybeOpenState MenuMain
        , modelToMaybeSelection = .maybeSelectedMenu >> Maybe.map selectionToMenuId
        , msgWrapper = DropdownMenuMsg MenuMain
        , placeholder = text "Which dropdown do you want?"
        }



-- Ticked menu


tickedMenuConfig =
    let
        items =
            [ "a", "b", "c", "d" ]

        modelToMaybeSelection model =
            case model.maybeSelectedMenu of
                Just (SelectedMenuTicked maybeTickedOption) ->
                    maybeTickedOption

                _ ->
                    Nothing
    in
        { hasClearButton = False
        , itemToHtml = DropdownMenu.itemToHtml identity
        , itemToId = identity
        , itemToLabel = identity
        , modelToItems = always items
        , modelToMaybeOpenState = maybeOpenState MenuTicked
        , modelToMaybeSelection = modelToMaybeSelection
        , msgWrapper = DropdownMenuMsg MenuTicked
        , placeholder = text "Select  a letter"
        }



-- Numbers menu


numbersMenuConfig =
    let
        items =
            [ 1, 2, 5, 7 ]

        modelToMaybeSelection model =
            case model.maybeSelectedMenu of
                Just (SelectedMenuNumbers maybeNumber) ->
                    maybeNumber

                _ ->
                    Nothing
    in
        { hasClearButton = False
        , itemToHtml = DropdownMenu.itemToHtml toString
        , itemToId = toString
        , itemToLabel = toString
        , modelToItems = always items
        , modelToMaybeOpenState = maybeOpenState MenuNumbers
        , modelToMaybeSelection = modelToMaybeSelection
        , msgWrapper = DropdownMenuMsg MenuNumbers
        , placeholder = text "Select a number"
        }



-- Update


noCmd model =
    ( model, Cmd.none )


selectMenu : Maybe MenuId -> Model -> ( Model, Cmd msg )
selectMenu maybeMenu model =
    noCmd <|
        case ( maybeMenu, model.maybeSelectedMenu ) of
            ( Just MenuTicked, Just (SelectedMenuTicked _) ) ->
                model

            ( Just MenuTicked, _ ) ->
                { model | maybeSelectedMenu = Just <| SelectedMenuTicked Nothing }

            ( Just MenuNumbers, Just (SelectedMenuNumbers _) ) ->
                model

            ( Just MenuNumbers, _ ) ->
                { model | maybeSelectedMenu = Just <| SelectedMenuNumbers Nothing }

            _ ->
                { model | maybeSelectedMenu = Nothing }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.maybeSelectedMenu ) of
        ( DropdownMenuMsg MenuMain nestedMsg, _ ) ->
            dropdownUpdate mainConfig
                { closeAllDropdowns = closeAllDropdowns
                , openOnlyThisDropdown = openDropdown MenuMain
                , setCurrentSelection = selectMenu
                }
                nestedMsg
                model

        ( DropdownMenuMsg MenuTicked nestedMsg, Just (SelectedMenuTicked tickedOption) ) ->
            dropdownUpdate tickedMenuConfig
                { closeAllDropdowns = closeAllDropdowns
                , openOnlyThisDropdown = openDropdown MenuTicked
                , setCurrentSelection = \maybeItem model -> noCmd { model | maybeSelectedMenu = Just <| SelectedMenuTicked maybeItem }
                }
                nestedMsg
                model

        ( DropdownMenuMsg MenuNumbers nestedMsg, Just (SelectedMenuNumbers n) ) ->
            dropdownUpdate numbersMenuConfig
                { closeAllDropdowns = closeAllDropdowns
                , openOnlyThisDropdown = openDropdown MenuNumbers
                , setCurrentSelection = \maybeItem model -> noCmd { model | maybeSelectedMenu = Just <| SelectedMenuNumbers maybeItem }
                }
                nestedMsg
                model

        _ ->
            noCmd model



-- View


view model =
    div
        []
        []


main =
    Html.program
        { init = noCmd init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }
