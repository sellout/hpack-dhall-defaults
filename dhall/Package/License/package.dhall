{-| This has the same operations as hall.hpack.License, but it generates both
    the SPDX expression and a list of license files to include in the package.
-}
let H = (../../dependencies.dhall).hall

let License = H.hpack.License.Type

let id = ./id

let or = ./or

let ref = ./ref

let simple = ./simple

let `with` = ./with

let checkMyStandardLicense =
        assert
      :   or
            [ `with` (id "AGPL-3.0-only") (id "Universal-FOSS-exception-1.0")
            , simple (ref (None Text) "commercial")
            ]
        ≡ { license = Some
              ( License.Expression
                  "AGPL-3.0-only WITH Universal-FOSS-exception-1.0 OR LicenseRef-commercial"
              )
          , license-file =
            [ "LICENSE.AGPL-3.0-only"
            , "LICENSE.Universal-FOSS-exception-1.0"
            , "LICENSE.commercial"
            ]
          }

in  { Info = ./Info
    , additionRef = ./additionRef
    , and = ./and
    , finalize = ./finalize
    , id
    , noAssertion = ./noAssertion
    , none = ./none
    , or
    , orLater = ./orLater
    , ref
    , simple
    , `with`
    }
