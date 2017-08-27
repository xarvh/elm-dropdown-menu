module Main exposing (..)

import Array
import Css
import Form
import Html exposing (..)
import List.Nonempty exposing (Nonempty)
import UI.DropdownMenu


templates : Nonempty Form.Template
templates =
    [ { id = "pizza"
      , name = "Pizza"
      , parameters =
            [ { id = "hasTomato"
              , label = "Tomato?"
              , options =
                    [ { id = "hasTomato-0", label = "Yes" }
                    , { id = "hasTomato-1", label = "No. THAT'S NO PIZZA." }
                    , { id = "hasTomato-2", label = "Fresh" }
                    ]
                        |> toNonEmpty
              }
            , { id = "mozzarella"
              , label = "Mozzarella?"
              , options =
                    [ { id = "mozzarella-0", label = "Yes" }
                    , { id = "mozzarella-1", label = "No" }
                    , { id = "mozzarella-2", label = "Bufala" }
                    ]
                        |> toNonEmpty
              }
            ]
                |> Array.fromList
      }
    , { id = "fruit"
      , name = "Fruit"
      , parameters =
            [ { id = "variety"
              , label = "Type"
              , options =
                    [ { id = "f-0", label = "Orange" }
                    , { id = "f-1", label = "Pear" }
                    , { id = "f-2", label = "Peach" }
                    ]
                        |> toNonEmpty
              }
            ]
                |> Array.fromList
      }
    ]
        |> toNonEmpty


toNonEmpty : List a -> Nonempty a
toNonEmpty list =
    case List.Nonempty.fromList list of
        Nothing ->
            Debug.crash "empty!"

        Just nonempty ->
            nonempty


view model =
    div
        []
        [ node "style"
            []
            [ UI.DropdownMenu.stylesheet
                |> Css.stylesheet
                |> List.singleton
                |> Css.compile
                |> .css
                |> text
            ]
        , Form.view model
        ]


main =
    Html.program
        { init = ( Form.init templates, Cmd.none )
        , update = Form.update
        , view = view
        , subscriptions = always Sub.none
        }
