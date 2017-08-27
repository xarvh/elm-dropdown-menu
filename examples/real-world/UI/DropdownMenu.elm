module UI.DropdownMenu exposing (..)

import DropdownMenu exposing (defaultCommonFeatures)
import DropdownMenuScroll
import Html exposing (Html)
import Css exposing (..)


-- Re-exports


view =
    DropdownMenu.view commonFeatures


update =
    DropdownMenu.update commonFeatures


type alias Config model item msg =
    DropdownMenu.Config model item msg


type alias Setters model item msg =
    DropdownMenu.Setters model item msg


type alias OpenState =
    DropdownMenu.OpenState


type alias Msg =
    DropdownMenu.Msg



-- Stuff common to all dropdowns in the app


commonFeatures : DropdownMenu.CommonFeatures
commonFeatures =
    { defaultCommonFeatures
        | scrollIntoView = DropdownMenuScroll.scrollToDomId
    }


itemToHtml : (item -> String) -> Bool -> Bool -> item -> Html msg
itemToHtml itemToLabel isSelected isHighlighted item =
    item
        |> itemToLabel
        |> Html.text



-- style


stylesheet =
    let
        rem =
            Css.rem

        css =
            defaultCommonFeatures.classes

        ease =
            property "transition-timing-function" "ease"

        duration =
            property "transition-duration" "100ms"

        cssSelect p1 p2 rules =
            class p1
                [ descendants
                    [ class
                        p2
                        rules
                    ]
                ]

        selectionGrow =
            [ flexGrow (num 1)
            , textOverflow ellipsis
            , overflow hidden
            , whiteSpace noWrap
            ]

        white =
            (hex "fff")

        lightGrey =
            (hex "f3f3f4")

        grey =
            (hex "b1b1b1")

        black =
            (hex "202027")

        standardInputBorder =
            border3 (px 1) solid (hex "e0e0e0")

        standardInputBorderOnHover =
            border3 (px 1) solid (hex "00cccf")
    in
        [ class css.root
            [ outline none
            , hover [ descendants [ class css.selectBox [ standardInputBorderOnHover ] ] ]
            , focus [ descendants [ class css.selectBox [ standardInputBorderOnHover ] ] ]
            ]
        , class css.isDisabled
            [ hover [ descendants [ class css.selectBox [ standardInputBorder ] ] ]
            , focus [ descendants [ class css.selectBox [ standardInputBorder ] ] ]
            , backgroundColor (hex "f3f3f4")
            ]
        , cssSelect
            css.isClosed
            css.menu
            [ property "transform" "translate(0, -50%) scale(1, 0) translate(0, 50%)"
            , property "transition" "transform"
            , duration
            , ease
            ]
        , cssSelect
            css.isOpen
            css.menu
            [ property "transform" "translate(0, -50%) scale(1, 1) translate(0, 50%)"
            , property "transition-properties" "transform"
            , duration
            , ease
            ]
        , cssSelect
            css.isClosed
            css.downArrow
            [ descendants
                [ selector "svg"
                    [ fill grey
                    , property "transition-properties" "fill, transform"
                    , duration
                    , ease
                    ]
                ]
            ]
        , cssSelect
            css.isOpen
            css.downArrow
            [ descendants
                [ selector "svg"
                    [ fill black
                    , property "transform" "rotate(180deg)"
                    , property "transition-properties" "fill, transform"
                    , duration
                    , ease
                    ]
                ]
            ]
        , class css.selectBox <|
            [ standardInputBorder
            , fontSize (px 13)
            , focus
                [ outline none
                ]
            , height (rem 2)
            , boxSizing borderBox
            , padding2 zero (rem 0.5)
            , displayFlex
            , alignItems (center)
            , cursor pointer
            ]
        , cssSelect
            css.isDisabled
            css.selectBox
            [ cursor auto
            ]
        , class css.selection
            selectionGrow
        , class css.placeholder <|
            color grey
                :: selectionGrow
        , class css.clearButton
            [ marginRight (rem 0.25)
            , fill grey
            , lineHeight zero
            , hover
                [ fill white ]
            ]
        , class css.menu
            [ backgroundColor white
            , listStyleType none
            , margin zero
            , width (pct 100)
            , boxShadow4 (px 0) (px 2) (px 4) (rgba 48 48 55 0.1)
            , padding zero
            , zIndex (int 1)
            , maxHeight (px 300)
            , overflowY auto
            ]
        , class css.menuOption
            [ padding (rem 0.5)
            , cursor pointer
            ]
        , class css.menuOptionSelected
            [ fontWeight bold
            ]
        , class css.menuOptionHighlighted
            [ backgroundColor lightGrey
            ]
        ]
