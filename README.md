elm-dropdown-menu
=================

This is the dropdown menu we use in production at [Stax](http://stax.io).

You can see the dropdown menu in action [here]().

The package works really well for our specific use case, but looks a bit
jerky when it comes to dropdowns that have both an menu opening/closing
transition and allow the menu to vertically scroll.


The issue
=========

The update function needs to control the menu vertical scrolling, and
calculating the correct scrolling position requires knowing
the DOM geometry of the menu and its children; normally this can
be done via DOM traversal (as done in [elm-selecize](http://package.elm-lang.org/packages/kirchner/elm-selectize/latest)).

However, using a menu opening/closing transition will (depending on the
specific transition chosen) cause the geometry to change over time,
usually without triggering any DOM event that could be used to get updated
geometry information.

The ideal solution would allow an accurate and smooth scrolling during
any arbitrary transition or animation, but an ideal solution might not be
practical.


Usage
=====

```elm
import DropdownMenu
import Html


type Msg
    = FruitDropdownMsg DropdownMenu.Msg


type alias Fruit =
    { id : String
    , name : String
    }


type alias Model =
    { fruits : List Fruit
    , maybeFruitDropdown : Maybe DropdownMenu.OpenState
    , maybeSelectedFruit : Maybe Fruit
    }


fruitDropdownConfig =
    { hasClearButton = False
    , itemToHtml = \isSelected isHighlighted fruit -> Html.text fruit.name
    , itemToId = .id
    , itemToLabel = .name
    , modelToItems = .fruitList
    , modelToMaybeOpenState = .maybeFruitDropdown
    , modelToMaybeSelection = .maybeSelectedFruit
    , msgWrapper = FruitDropdownMsg
    , placeholder = Html.text "Select your favourite fruit"
    }


update msg model =
    case msg of
        FruitDropdownMsg nestedMsg ->
            DropdownMenu.update
                DropdownMenu.defaultCommonFeatures
                { closeAllDropdowns = \model -> { model | maybeFruitDropdown = Nothing }
                , openOnlyThisDropdown = \openState model -> ( { model | maybeFruitDropdown = Just openState }, Cmd.none )
                , setCurrentSelection = \maybeFruit model -> ( { model | maybeSelectedFruit = maybeFruit }, Cmd.none )
                }
                fruitDropdownConfig
                nestedMsg
                model


view model =
    DropdownMenu.viewEnabled DropdownMenu.defaultCommonFeatures fruitDropdownConfig model
```
