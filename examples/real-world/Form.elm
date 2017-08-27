module Form exposing (..)

import Array exposing (Array)
import Html exposing (..)
import Html.Events exposing (onInput)
import List.Extra
import List.Nonempty exposing (Nonempty(Nonempty))
import UI.DropdownMenu


-- types


type alias Id =
    String


type alias Template =
    { id : Id
    , name : String
    , parameters : Array Parameter
    }


type alias Parameter =
    { id : Id
    , label : String
    , options : Nonempty ParameterOption
    }


type alias ParameterOption =
    { id : Id
    , label : String
    }



-- model


type DropdownId
    = DropdownTemplates
    | DropdownParameter Int


type Focus
    = FocusNone
    | FocusDropdown DropdownId UI.DropdownMenu.OpenState
    | FocusInteger String


type alias Model =
    { availableTemplates : Nonempty Template
    , focus : Focus
    , selectedInteger : Int
    , selectedTemplate : Template
    , selectedParameterOptions : Array ParameterOption
    }


type Msg
    = OnDropdownTemplate UI.DropdownMenu.Msg
    | OnDropdownParameter Int UI.DropdownMenu.Msg
    | OnIntegerInput Int (Maybe String)



-- Dropdowns focus managers


closeAllDropdowns : Model -> Model
closeAllDropdowns model =
    { model | focus = FocusNone }


openDropdown : DropdownId -> UI.DropdownMenu.OpenState -> Model -> ( Model, Cmd Msg )
openDropdown dropdownId openState model =
    noCmd { model | focus = FocusDropdown dropdownId openState }


modelToMaybeOpenState : DropdownId -> Model -> Maybe UI.DropdownMenu.OpenState
modelToMaybeOpenState targetDropdownId model =
    case model.focus of
        FocusDropdown dropdownId dropdownModel ->
            if dropdownId == targetDropdownId then
                Just dropdownModel
            else
                Nothing

        _ ->
            Nothing



-- Templates dropdown


templatesDropdownConfig : UI.DropdownMenu.Config Model Template Msg
templatesDropdownConfig =
    let
        modelToItems model =
            model.availableTemplates
                |> List.Nonempty.toList
                |> List.sortBy .name
    in
        { hasClearButton = False
        , itemToHtml = UI.DropdownMenu.itemToHtml .name
        , itemToId = .id
        , itemToLabel = .name
        , modelToItems = modelToItems
        , modelToMaybeOpenState = modelToMaybeOpenState DropdownTemplates
        , modelToMaybeSelection = .selectedTemplate >> Just
        , msgWrapper = OnDropdownTemplate
        , placeholder = text ""
        }


selectTemplate : Maybe Template -> Model -> ( Model, Cmd msg )
selectTemplate maybeTemplate model =
    case maybeTemplate of
        Nothing ->
            noCmd model

        Just template ->
            noCmd
                { model
                    | selectedTemplate = template
                    , selectedParameterOptions = defaultParameterOptions template
                }


defaultParameterOptions : Template -> Array ParameterOption
defaultParameterOptions template =
    template.parameters
        |> Array.map (.options >> List.Nonempty.head)



-- Parameter dropdowns


parameterDropdownConfig : Int -> UI.DropdownMenu.Config Model ParameterOption Msg
parameterDropdownConfig parameterIndex =
    let
        modelToItems : Model -> List ParameterOption
        modelToItems model =
            model.selectedTemplate.parameters
                |> Array.get parameterIndex
                |> Maybe.map (.options >> List.Nonempty.toList)
                |> Maybe.withDefault []
    in
        { hasClearButton = False
        , itemToHtml = UI.DropdownMenu.itemToHtml .label
        , itemToId = .id
        , itemToLabel = .label
        , modelToItems = modelToItems
        , modelToMaybeSelection = .selectedParameterOptions >> Array.get parameterIndex
        , modelToMaybeOpenState = modelToMaybeOpenState (DropdownParameter parameterIndex)
        , msgWrapper = OnDropdownParameter parameterIndex
        , placeholder = text ""
        }


selectParameter : Int -> Maybe ParameterOption -> Model -> ( Model, Cmd msg )
selectParameter parameterIndex maybeParameterOption model =
    case maybeParameterOption of
        Nothing ->
            noCmd model

        Just parameterOption ->
            let
                selectedParameterOptions =
                    model.selectedParameterOptions
                        |> Array.set parameterIndex parameterOption
            in
                noCmd { model | selectedParameterOptions = selectedParameterOptions }



-- init


init : Nonempty Template -> Model
init availableTemplates =
    let
        selectedTemplate =
            List.Nonempty.head availableTemplates
    in
        { availableTemplates = availableTemplates
        , focus = FocusNone
        , selectedInteger = 1
        , selectedTemplate = selectedTemplate
        , selectedParameterOptions = defaultParameterOptions selectedTemplate
        }



-- Update


noCmd model =
    ( model, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnIntegerInput _ _ ->
            -- TODO
            noCmd model

        OnDropdownTemplate dropdownMsg ->
            UI.DropdownMenu.update
                templatesDropdownConfig
                { closeAllDropdowns = closeAllDropdowns
                , openOnlyThisDropdown = openDropdown DropdownTemplates
                , setCurrentSelection = selectTemplate
                }
                dropdownMsg
                model

        OnDropdownParameter parameterIndex dropdownMsg ->
            UI.DropdownMenu.update
                (parameterDropdownConfig parameterIndex)
                { closeAllDropdowns = closeAllDropdowns
                , openOnlyThisDropdown = openDropdown (DropdownParameter parameterIndex)
                , setCurrentSelection = selectParameter parameterIndex
                }
                dropdownMsg
                model



-- View


view : Model -> Html Msg
view model =
    div
        []
        [ div
            []
            [ h2
                []
                [ text "Templates dropdown" ]
            , UI.DropdownMenu.view templatesDropdownConfig False model
            ]
        , div
            []
            [ h2
                []
                [ text "Parameters dropdowns" ]
            , model.selectedTemplate.parameters
                |> Array.indexedMap (viewParameterDropdown model)
                |> Array.toList
                |> div []
            ]
        ]


viewParameterDropdown : Model -> Int -> Parameter -> Html Msg
viewParameterDropdown model parameterIndex parameter =
    div
        []
        [ h3
            []
            [ text <| "Parameter " ++ toString parameterIndex ++ ": " ++ parameter.label ]
        , UI.DropdownMenu.view (parameterDropdownConfig parameterIndex) False model
        ]
