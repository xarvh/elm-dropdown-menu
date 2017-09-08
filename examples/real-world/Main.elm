module Main exposing (..)

import Array
import Css
import Form
import Html exposing (..)
import List.Nonempty exposing (Nonempty)
import UI.DropdownMenu


templates : Nonempty Form.Template
templates =
    [ { id = "fruit"
      , name = "Fruit"
      , parameters =
            [ { id = "variety"
              , label = "Type"
              , options =
                    [ { id = "f-0", label = "Orange" }
                    , { id = "f-1", label = "Pear" }
                    , { id = "f-2", label = "Apple" }
                    , { id = "f-3", label = "Prune" }
                    , { id = "f-4", label = "Pineapple" }
                    , { id = "f-5", label = "Peach" }
                    , { id = "f-6", label = "Apricot" }
                    , { id = "f-7", label = "Grape" }
                    , { id = "f-8", label = "Mandarin" }
                    , { id = "f-9", label = "Banana" }
                    , { id = "f-10", label = "Melon" }
                    , { id = "f-11", label = "Watermelon" }
                    ]
                        |> toNonEmpty
              }
            ]
                |> Array.fromList
      }
    , { id = "pizza"
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
