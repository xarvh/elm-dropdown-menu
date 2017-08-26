port module DropdownMenuScroll exposing (scrollToDomId)


port dropdownMenuScroll : String -> Cmd msg


scrollToDomId : String -> Cmd msg
scrollToDomId =
    dropdownMenuScroll
