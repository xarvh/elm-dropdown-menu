module Main exposing (..)

import Css exposing (..)
import DropdownMenu
import Html exposing (Html, div)


-- Types


type Msg
    = FruitDropdownMsg DropdownMenu.Msg


type alias Fruit =
    { id : String
    , name : String
    }


type alias Model =
    { availableFruits : List Fruit

    -- This is the dropdown menu "Model"
    -- It is needed only when the menu is open
    , maybeFruitDropdown : Maybe DropdownMenu.OpenState

    -- This is what the dropdown should modify
    , maybeSelectedFruit : Maybe Fruit
    }



-- Fruit DropdownMenu


fruitDropdownConfig : DropdownMenu.Config Model Fruit Msg
fruitDropdownConfig =
    DropdownMenu.simpleConfig
        { itemToLabel = .name
        , modelToItems = .availableFruits
        , modelToMaybeOpenState = .maybeFruitDropdown
        , modelToMaybeSelection = .maybeSelectedFruit
        , msgWrapper = FruitDropdownMsg
        , placeholder = "What fruit do you want?"
        }



-- Init


init : Model
init =
    { availableFruits =
        [ { id = "1", name = "Kiwi" }
        , { id = "2", name = "Mango" }
        , { id = "3", name = "Papaya" }
        , { id = "4", name = "Grape" }
        , { id = "5", name = "Pineapple" }
        , { id = "6", name = "Watermelon" }
        ]
    , maybeFruitDropdown = Nothing
    , maybeSelectedFruit = Nothing
    }



-- Update


noCmd : Model -> ( Model, Cmd msg )
noCmd model =
    ( model, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FruitDropdownMsg nestedMsg ->
            DropdownMenu.update
                DropdownMenu.defaultCommonFeatures
                fruitDropdownConfig
                { closeAllDropdowns = \model -> { model | maybeFruitDropdown = Nothing }
                , openOnlyThisDropdown = \openState model -> noCmd { model | maybeFruitDropdown = Just openState }
                , setCurrentSelection = \maybeFruit model -> noCmd { model | maybeSelectedFruit = maybeFruit }
                }
                nestedMsg
                model



-- View


stylesheet =
    let
        cf =
            DropdownMenu.defaultCommonFeatures

        classNames =
            cf.classes

        white =
            (hex "fff")

        lightGrey =
            (hex "f3f3f4")

        grey =
            (hex "b1b1b1")
    in
        [ class classNames.root
            [ width (px 300)
            ]
        , class classNames.selectBox
            [ displayFlex
            , alignItems (center)
            , padding (px 8)
            , cursor pointer
            ]
        , class classNames.placeholder
            [ color grey
            ]
        , selector ("." ++ classNames.isClosed ++ " ." ++ classNames.menu)
            [ display none
            ]
        , class classNames.menu
            [ backgroundColor white
            , listStyleType none
            , margin zero
            , width (pct 100)
            , boxShadow4 (px 0) (px 2) (px 4) (rgba 48 48 55 0.1)
            , padding zero
            , zIndex (int 1)
            ]
        , class classNames.menuOption
            [ padding (px 8)
            , cursor pointer
            ]
        , class classNames.menuOptionSelected
            [ fontWeight bold
            ]
        , class classNames.menuOptionHighlighted
            [ backgroundColor lightGrey
            ]
        ]


view : Model -> Html Msg
view model =
    let
        par content =
            Html.p [] [ Html.text content ]
    in
        div
            []
            [ par "Pressing the P key will move the highlight to Papaya."
            , par "Pressing the P key and then quickly the I key will move the highlight to Pineapple."
            , par "Up, Down, Page Up, Page Down, Home and End keys are also supported."
            , Html.hr [] []
            , case model.maybeSelectedFruit of
                Nothing ->
                    Html.text ""

                Just selectedFruit ->
                    par <| "You have selected a " ++ selectedFruit.name
            , DropdownMenu.view DropdownMenu.defaultCommonFeatures fruitDropdownConfig False model
            , Html.node "style"
                []
                [ stylesheet
                    |> Css.stylesheet
                    |> List.singleton
                    |> Css.compile
                    |> .css
                    |> Html.text
                ]
            ]



-- Program


main =
    Html.program
        { init = noCmd init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }
