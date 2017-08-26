module DropdownMenu
    exposing
        ( CommonFeatures
        , defaultCommonFeatures
        , Classes
        , defaultClasses
        , Config
        , Setters
        , OpenState
        , Msg
        , open
        , update
        , view
        )

{-| This module is candidate to packaging, and should be maintained as generic as possible
-}

import Char
import Html exposing (Html, div, span, text, ul, li)
import Html.Attributes exposing (class)
import Html.Events
import Json.Decode
import List.Extra
import Process
import Regex
import Task
import Time


-- Exposed (API) types


type alias CommonFeatures =
    { downArrow : Html Never
    , clearButton : Html Never
    , scrollIntoView : String -> Cmd Never
    , classes : Classes
    }


type alias Classes =
    { root : String
    , isOpen : String
    , isClosed : String
    , isDisabled : String

    -- selection box
    , selectBox : String
    , selection : String
    , placeholder : String
    , clearButton : String
    , downArrow : String

    -- menu
    , menu : String
    , menuOption : String
    , menuOptionSelected : String
    , menuOptionHighlighted : String
    }


type alias Config model item msg =
    { hasClearButton : Bool
    , itemToHtml : Bool -> Bool -> item -> Html Never
    , itemToId : item -> String
    , itemToLabel : item -> String
    , modelToItems : model -> List item
    , modelToMaybeOpenState : model -> Maybe OpenState
    , modelToMaybeSelection : model -> Maybe item
    , msgWrapper : Msg -> msg
    , placeholder : Html Never
    }


type alias Setters model item msg =
    { closeAllDropdowns : model -> model
    , openOnlyThisDropdown : OpenState -> model -> ( model, Cmd msg )
    , setCurrentSelection : Maybe item -> model -> ( model, Cmd msg )
    }


type OpenOrClosed
    = Closed
    | Open (Maybe OpenState)


type Outcome item
    = CloseAndSelect (Maybe item)
    | OpenWithState OpenState


type OpenState
    = OpenState PrivateOpenState



-- Internal types


type alias PrivateOpenState =
    { maybeHighlightId : Maybe String
    , searchCounter : Int
    , searchString : String
    }


type Key
    = Esc
    | Enter
    | Space
    | ArrowUp
    | ArrowDown
    | PageUp
    | PageDown
    | Home
    | End
    | Searchable Char


type Msg
    = NoOp
    | OnKey Key
    | OnBlur
    | OnClickCurrentSelection
    | OnClickItem String
    | OnMouseEnterItem String
    | OnClickClear
    | OnResetSearchString Int
    | OnTransitionEnd



-- Defaults


openModel : PrivateOpenState
openModel =
    { maybeHighlightId = Nothing
    , searchCounter = 0
    , searchString = ""
    }


open : OpenState
open =
    OpenState openModel


namespace s =
    "ElmDropdownMenu-" ++ s


defaultCommonFeatures : CommonFeatures
defaultCommonFeatures =
    { downArrow = text "▼"
    , clearButton = text "×"
    , scrollIntoView = always Cmd.none
    , classes = defaultClasses
    }


defaultClasses : Classes
defaultClasses =
    { root = namespace "root"
    , isOpen = namespace "isOpen"
    , isClosed = namespace "isClosed"
    , isDisabled = namespace "isDisabled"

    -- selection box
    , selectBox = namespace "selectBox"
    , selection = namespace "selection"
    , placeholder = namespace "placeholder"
    , clearButton = namespace "clearButton"
    , downArrow = namespace "downArrow"

    -- menu
    , menu = namespace "menu"
    , menuOption = namespace "menuOption"
    , menuOptionSelected = namespace "menuOptionSelected"
    , menuOptionHighlighted = namespace "menuOptionHighlighted"
    }



-- Update helpers


noCmd : outcome -> ( outcome, Cmd msg )
noCmd outcome =
    ( outcome, Cmd.none )


maybeFallback : Maybe a -> Maybe a -> Maybe a
maybeFallback replacement original =
    case original of
        Just _ ->
            original

        Nothing ->
            replacement


itemIdToDomId : String -> String
itemIdToDomId itemId =
    itemId
        |> Regex.replace Regex.All (Regex.regex "[^a-zA-Z0-9_-]") (\_ -> "_")
        |> namespace


itemToDomId : Config model item msg -> item -> String
itemToDomId config item =
    item
        |> config.itemToId
        |> itemIdToDomId


findItem : Config model item msg -> model -> Maybe String -> Maybe item
findItem config model maybeId =
    maybeId
        |> Maybe.andThen (\id -> List.Extra.find (\i -> config.itemToId i == id) (config.modelToItems model))


findNext : element -> List element -> Maybe element
findNext e items =
    case items of
        a :: b :: xs ->
            if a == e then
                Just b
            else
                findNext e (b :: xs)

        _ ->
            Nothing


maybeSelectionId : Config model item msg -> model -> Maybe String
maybeSelectionId config model =
    model |> config.modelToMaybeSelection |> Maybe.map config.itemToId


maybeOpenState : Config model item msg -> model -> Maybe PrivateOpenState
maybeOpenState config model =
    case config.modelToMaybeOpenState model of
        Just (OpenState openState) ->
            Just openState

        _ ->
            Nothing


type alias Picker =
    ( PrivateOpenState, List String ) -> Maybe String


pick : Config model item msg -> model -> Picker -> Maybe String
pick config model picker =
    case maybeOpenState config model of
        Nothing ->
            -- Closed. Open it with the current selection highlighted.
            maybeSelectionId config model

        Just openState ->
            model
                |> config.modelToItems
                |> List.map config.itemToId
                |> (,) openState
                |> picker


reversePicker : Picker -> Picker
reversePicker picker =
    Tuple.mapSecond List.reverse >> picker


pickerNext : Picker
pickerNext ( openState, ids ) =
    case openState.maybeHighlightId of
        Nothing ->
            List.head ids

        Just highlightId ->
            ids
                |> findNext highlightId
                |> maybeFallback (ids |> List.reverse |> List.head)


pickerSkip : Int -> Picker
pickerSkip skip ( openState, ids ) =
    case openState.maybeHighlightId of
        Nothing ->
            List.head ids

        Just highlightId ->
            ids
                |> List.Extra.dropWhile ((/=) highlightId)
                |> List.drop skip
                |> List.head
                |> maybeFallback (ids |> List.reverse |> List.head)


scrollToHighlight : CommonFeatures -> PrivateOpenState -> Cmd msg
scrollToHighlight commonFeatures openState =
    case openState.maybeHighlightId of
        Nothing ->
            Cmd.none

        Just highlightId ->
            highlightId
                |> itemIdToDomId
                |> commonFeatures.scrollIntoView
                |> Cmd.map never



-- Update partials


type alias PartialUpdate model item msg =
    CommonFeatures -> Config model item msg -> model -> ( Outcome item, Cmd Msg )


updateNoChange : PartialUpdate model item msg
updateNoChange commonFeatures config model =
    case config.modelToMaybeOpenState model of
        Nothing ->
            model |> config.modelToMaybeSelection |> CloseAndSelect |> noCmd

        Just openState ->
            OpenWithState openState |> noCmd


updateClose : PartialUpdate model item msg
updateClose commonFeatures config model =
    CloseAndSelect (config.modelToMaybeSelection model) |> noCmd


updateHighlight : Maybe String -> PartialUpdate model item msg
updateHighlight maybeHighlightId commonFeatures config model =
    let
        openState =
            { openModel
                | maybeHighlightId = maybeHighlightId
                , searchString = ""
            }

        cmd =
            scrollToHighlight commonFeatures openState
    in
        ( OpenWithState (OpenState openState), cmd )


updateSelect : Maybe String -> PartialUpdate model item msg
updateSelect maybeItemId commonFeatures config model =
    CloseAndSelect (findItem config model maybeItemId) |> noCmd


updateSearchStringTimeout : Char -> PartialUpdate model item msg
updateSearchStringTimeout searchChar commonFeatures config model =
    let
        oldOpenState =
            maybeOpenState config model
                |> Maybe.withDefault openModel

        searchCounter =
            oldOpenState.searchCounter + 1

        searchString =
            -- Manage backspace character
            if searchChar == '\x08' then
                String.dropRight 1 oldOpenState.searchString
            else
                oldOpenState.searchString ++ String.toLower (String.fromChar searchChar)

        matchesSearchString item =
            String.startsWith searchString (config.itemToLabel item |> String.toLower)

        maybeHighlightId =
            List.Extra.find matchesSearchString (config.modelToItems model)
                |> Maybe.map config.itemToId
                |> maybeFallback oldOpenState.maybeHighlightId

        openState =
            { oldOpenState
                | maybeHighlightId = maybeHighlightId
                , searchCounter = searchCounter
                , searchString = searchString
            }

        cmdTimeout =
            Process.sleep (1.0 * Time.second)
                |> Task.perform (\() -> OnResetSearchString searchCounter)

        cmdHighlight =
            scrollToHighlight commonFeatures openState

        cmd =
            Cmd.batch
                [ cmdHighlight
                , cmdTimeout
                ]
    in
        ( OpenWithState (OpenState openState), cmd )


updatePartial : Config model item msg -> model -> Msg -> PartialUpdate model item msg
updatePartial config model msg =
    let
        pickHighlight =
            pick config model >> updateHighlight
    in
        case msg of
            NoOp ->
                updateNoChange

            OnClickCurrentSelection ->
                case maybeOpenState config model of
                    Nothing ->
                        model |> config.modelToMaybeSelection |> Maybe.map config.itemToId |> updateHighlight

                    Just openState ->
                        updateClose

            OnClickItem itemId ->
                updateSelect (Just itemId)

            OnMouseEnterItem itemId ->
                case maybeOpenState config model of
                    Nothing ->
                        updateNoChange

                    Just openState ->
                        Just itemId |> updateHighlight

            OnClickClear ->
                updateSelect Nothing

            OnTransitionEnd ->
                case maybeOpenState config model of
                    Nothing ->
                        updateNoChange

                    Just openState ->
                        openState.maybeHighlightId |> updateHighlight

            OnResetSearchString searchCounter ->
                case maybeOpenState config model of
                    Nothing ->
                        updateNoChange

                    Just openState ->
                        if openState.searchCounter /= searchCounter then
                            updateNoChange
                        else
                            updateHighlight openState.maybeHighlightId

            OnBlur ->
                updateClose

            OnKey Esc ->
                updateClose

            OnKey Enter ->
                case maybeOpenState config model of
                    Nothing ->
                        maybeSelectionId config model |> updateHighlight

                    Just openState ->
                        updateSelect openState.maybeHighlightId

            OnKey Space ->
                maybeSelectionId config model |> updateHighlight

            OnKey ArrowUp ->
                pickHighlight (Tuple.mapSecond List.reverse >> pickerNext)

            OnKey ArrowDown ->
                pickHighlight pickerNext

            OnKey PageUp ->
                pickHighlight (Tuple.mapSecond List.reverse >> (pickerSkip 9))

            OnKey PageDown ->
                pickHighlight (pickerSkip 9)

            OnKey Home ->
                pickHighlight (Tuple.second >> List.head)

            OnKey End ->
                pickHighlight (Tuple.second >> List.reverse >> List.head)

            OnKey (Searchable char) ->
                updateSearchStringTimeout char



-- Update


update : CommonFeatures -> Config model item msg -> Setters model item msg -> Msg -> model -> ( model, Cmd msg )
update commonFeatures config setters msg model =
    let
        partial =
            updatePartial config model msg

        ( outcome, dropdownCmd ) =
            partial commonFeatures config model

        ( newParentModel, userCmd ) =
            case outcome of
                OpenWithState openState ->
                    setters.openOnlyThisDropdown openState model

                CloseAndSelect maybeItem ->
                    let
                        updateSelection =
                            if maybeItem /= config.modelToMaybeSelection model then
                                setters.setCurrentSelection maybeItem
                            else
                                noCmd
                    in
                        model
                            |> setters.closeAllDropdowns
                            |> updateSelection

        cmd =
            Cmd.batch
                [ dropdownCmd |> Cmd.map config.msgWrapper
                , userCmd
                ]
    in
        ( newParentModel, cmd )



-- Key decoder


keyDecoder : Config model item msg -> model -> Int -> Json.Decode.Decoder Key
keyDecoder config model keyCode =
    let
        -- This is necessary to ensure that the key is not consumed and can propagate to the parent
        pass =
            Json.Decode.fail ""

        key =
            Json.Decode.succeed
    in
        case keyCode of
            13 ->
                key Enter

            27 ->
                -- Consume Esc only if the Menu is open
                if maybeOpenState config model == Nothing then
                    pass
                else
                    key Esc

            32 ->
                key Space

            33 ->
                key PageUp

            34 ->
                key PageDown

            35 ->
                key End

            36 ->
                key Home

            38 ->
                key ArrowUp

            40 ->
                key ArrowDown

            _ ->
                let
                    char =
                        Char.fromCode keyCode

                    -- TODO should the user be able to search non-alphanum chars?
                    -- TODO add support for non-ascii alphas
                    isAlpha char =
                        (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z')
                in
                    -- Backspace is "searchable" because it can be used to modify the search string
                    if isAlpha char || Char.isDigit char || char == '\x08' then
                        key (Searchable char)
                    else
                        pass



-- View


htmlNeverToHtmlMsg : Html Never -> Html Msg
htmlNeverToHtmlMsg =
    Html.map (always NoOp)


viewItem : CommonFeatures -> Config model item msg -> model -> Maybe String -> item -> Html Msg
viewItem commonFeatures config model maybeHighlightId item =
    let
        isSelected =
            case maybeSelectionId config model of
                Just selectionId ->
                    config.itemToId item == selectionId

                Nothing ->
                    False

        isHighlighted =
            case maybeHighlightId of
                Just highlightId ->
                    config.itemToId item == highlightId

                Nothing ->
                    False

        classes =
            Html.Attributes.classList
                [ ( commonFeatures.classes.menuOption, True )
                , ( commonFeatures.classes.menuOptionSelected, isSelected )
                , ( commonFeatures.classes.menuOptionHighlighted, isHighlighted )
                ]
    in
        li
            [ classes
            , Html.Events.onClick <| OnClickItem <| config.itemToId item
            , Html.Events.on "mousemove" <| Json.Decode.succeed <| OnMouseEnterItem <| config.itemToId item
            , Html.Attributes.id <| itemToDomId config item
            ]
            [ config.itemToHtml isSelected isHighlighted item |> htmlNeverToHtmlMsg
            ]


viewSelection : CommonFeatures -> Config model item msg -> model -> Html Msg
viewSelection commonFeatures config model =
    let
        maybeSelId =
            maybeSelectionId config model

        currentSelection =
            case findItem config model maybeSelId of
                Nothing ->
                    div
                        [ class commonFeatures.classes.placeholder ]
                        [ config.placeholder ]

                Just item ->
                    div
                        [ class commonFeatures.classes.selection ]
                        [ config.itemToHtml False False item ]

        onClickNoBubble =
            Html.Events.onWithOptions "click" { stopPropagation = True, preventDefault = False } << Json.Decode.succeed

        clearIcon =
            if config.hasClearButton && maybeSelId /= Nothing then
                div
                    [ onClickNoBubble OnClickClear
                    , class commonFeatures.classes.clearButton
                    ]
                    [ commonFeatures.clearButton |> htmlNeverToHtmlMsg
                    ]
            else
                text ""
    in
        div
            [ class commonFeatures.classes.selectBox
            , Html.Events.onClick OnClickCurrentSelection
            ]
            [ currentSelection |> htmlNeverToHtmlMsg
            , clearIcon
            , div
                [ class commonFeatures.classes.downArrow ]
                [ commonFeatures.downArrow |> htmlNeverToHtmlMsg ]
            ]


view : CommonFeatures -> Config model item msg -> Bool -> model -> Html msg
view commonFeatures config isDisabled model =
    if isDisabled then
        viewDisabled commonFeatures config model
    else
        viewEnabled commonFeatures config model


viewDisabled : CommonFeatures -> Config model item msg -> model -> Html msg
viewDisabled commonFeatures config model =
    div
        [ class commonFeatures.classes.root
        , class commonFeatures.classes.isClosed
        , class commonFeatures.classes.isDisabled
        ]
        [ viewSelection commonFeatures config model
        ]
        |> Html.map (\msg -> config.msgWrapper NoOp)


viewEnabled : CommonFeatures -> Config model item msg -> model -> Html msg
viewEnabled commonFeatures config model =
    let
        maybeHighlightId =
            model
                |> maybeOpenState config
                |> Maybe.andThen .maybeHighlightId

        menuItems =
            model
                |> config.modelToItems
                |> List.map (viewItem commonFeatures config model maybeHighlightId)

        classOpenOrClosed =
            if maybeOpenState config model == Nothing then
                commonFeatures.classes.isClosed
            else
                commonFeatures.classes.isOpen

        keyMsgDecoder =
            Html.Events.keyCode
                |> Json.Decode.andThen (keyDecoder config model)
                |> Json.Decode.map OnKey
    in
        div
            [ class commonFeatures.classes.root
            , class classOpenOrClosed
            , Html.Attributes.tabindex 0
            , Html.Events.onBlur OnBlur
            , Html.Events.onWithOptions "keydown" { stopPropagation = True, preventDefault = True } keyMsgDecoder
            ]
            [ viewSelection commonFeatures config model
            , div
                [ Html.Attributes.style
                    [ ( "position", "relative" ) ]
                ]
                [ ul
                    [ class commonFeatures.classes.menu
                    , Html.Events.on "transitionend" (Json.Decode.succeed OnTransitionEnd)
                    , Html.Events.on "animationend" (Json.Decode.succeed OnTransitionEnd)
                    , Html.Attributes.style
                        [ ( "position", "absolute" ) ]
                    ]
                    menuItems
                ]
            ]
            |> Html.map config.msgWrapper
