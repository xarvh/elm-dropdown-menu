module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class)
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


mainMenuConfig =
    let
        items =
            [ MenuTicked
            , MenuNumbers
            ]

        itemToLabel item =
            case item of
                MenuTicked ->
                    "Vegetables (selected veggie will have a checkmark)"

                MenuNumbers ->
                    "Numbers"

                _ ->
                    ""
    in
        { hasClearButton = True
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


vegetables =
    [ "Jalapeño"
    , "Corn salad"
    , "Green beans"
    , "Bok choy"
    , "Squash"
    , "Maize"
    , "Onion"
    , "Paprika"
    , "Arugula"
    , "Horseradish"
    , "Frisee"
    , "Turnip"
    , "Basil"
    , "Rosemary"
    , "Okra"
    , "Rhubarb"
    , "Sage"
    , "Turnip"
    , "Split peas"
    , "Kohlrabi"
    , "Daikon"
    , "Runner beans"
    , "Spinach"
    , "Jicama"
    , "Ginger"
    , "Endive"
    , "Chives"
    , "Kale"
    , "Soy beans"
    , "Fennel"
    , "Thyme"
    , "Courgette"
    , "Chard"
    , "Chickpeas"
    , "Nettles"
    , "Taro"
    , "Carrots"
    , "Wasabi"
    , "Skirret"
    , "Garlic"
    , "Rutabaga"
    , "Collard greens"
    , "Lettuce"
    , "Mung beans"
    , "Dill"
    , "Black-eyed peas"
    , "Tomato"
    , "Radicchio"
    , "Oregano"
    , "Pumpkin"
    , "Caraway"
    , "Calabrese"
    , "Mustard greens"
    , "Marjoram"
    , "Asparagus"
    , "White radish"
    , "Leek"
    , "Sweet potato"
    , "Celeriac"
    , "Peas"
    , "Potato"
    , "Artichoke"
    , "Pinto beans"
    , "Navy beans"
    , "Parsley"
    , "Anise"
    , "Lavender"
    , "Sunchokes"
    , "Borlotti bean"
    , "Beetroot"
    , "Cabbage"
    , "Shallot"
    , "Tat soi"
    , "Broccoli"
    , "Lemon Grass"
    , "Lima beans"
    , "Delicata"
    , "Fennel"
    , "Parsley"
    , "Cayenne pepper"
    , "Zucchini"
    , "Coriander"
    , "Parsnip"
    , "Celery"
    , "Lentils"
    , "Cauliflower"
    , "Habanero"
    , "Chamomile"
    , "Black beans"
    , "Tabasco pepper"
    , "Kidney beans"
    , "Carrot"
    , "Watercress"
    , "Cucumber"
    , "Water chestnut"
    ]


tickedMenuConfig =
    let
        tick isSelected =
            if isSelected then
                "✔"
            else
                ""

        itemToHtml isSelected isHighlighted item =
            span
                []
                [ span
                    [ class "tickContainer" ]
                    [ isSelected |> tick |> text ]
                , span
                    []
                    [ text item ]
                ]

        modelToMaybeSelection model =
            case model.maybeSelectedMenu of
                Just (SelectedMenuTicked maybeTickedOption) ->
                    maybeTickedOption

                _ ->
                    Nothing
    in
        { hasClearButton = False
        , itemToHtml = itemToHtml
        , itemToId = identity
        , itemToLabel = identity
        , modelToItems = always (List.sort vegetables)
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
        { hasClearButton = True
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
            dropdownUpdate mainMenuConfig
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


view : Model -> Html Msg
view model =
    div
        []
        [ DropdownMenu.view commonFeatures mainMenuConfig False model
        , hr [] []
        , case model.maybeSelectedMenu of
            Nothing ->
                text ""

            Just (SelectedMenuTicked maybeTicked) ->
                div
                    []
                    [ maybeTicked
                        |> Maybe.map (\t -> "Ticked menu selection is: " ++ t)
                        |> Maybe.withDefault ""
                        |> text
                    , DropdownMenu.view commonFeatures tickedMenuConfig False model
                    ]

            Just (SelectedMenuNumbers maybeN) ->
                div
                    []
                    [ maybeN
                        |> Maybe.map (\n -> "The number you have selected is: " ++ toString n)
                        |> Maybe.withDefault ""
                        |> text
                    , DropdownMenu.view commonFeatures numbersMenuConfig False model
                    ]
        ]


main =
    Html.program
        { init = noCmd init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }
