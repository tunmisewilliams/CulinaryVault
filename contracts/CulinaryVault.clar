;; CulinaryVault: Traditional Recipe Preservation and Exchange Platform
;; Version: 1.0.0
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-RECIPE-NOT-FOUND (err u2))
(define-constant ERR-ALREADY-SHARED (err u3))
(define-constant ERR-INVALID-STATUS (err u4))
(define-constant ERR-INVALID-SERVINGS (err u5))
(define-constant ERR-INVALID-CUISINE-TYPE (err u6))
(define-constant ERR-INVALID-DIFFICULTY (err u7))
(define-constant ERR-INVALID-RECIPE-NAME (err u8))
(define-constant ERR-INVALID-INSTRUCTIONS (err u9))
(define-constant MIN-SERVINGS u1)
(define-data-var next-recipe-id uint u1)
(define-map recipe-collection
    uint
    {
        chef: principal,
        recipe-name: (string-utf8 50),
        instructions: (string-utf8 200),
        cuisine-type: (string-utf8 15),
        difficulty: (string-utf8 10),
        sharing-status: (string-utf8 15),
        serving-size: uint
    }
)
(define-private (validate-cuisine-type (cuisine-type (string-utf8 15)))
    (or 
        (is-eq cuisine-type u"Italian")
        (is-eq cuisine-type u"French")
        (is-eq cuisine-type u"Asian")
        (is-eq cuisine-type u"Mexican")
        (is-eq cuisine-type u"Mediterranean")
        (is-eq cuisine-type u"Traditional")
    )
)
(define-private (validate-difficulty (difficulty (string-utf8 10)))
    (or 
        (is-eq difficulty u"Beginner")
        (is-eq difficulty u"Easy")
        (is-eq difficulty u"Medium")
        (is-eq difficulty u"Advanced")
        (is-eq difficulty u"Expert")
    )
)
(define-private (validate-text-content (text (string-utf8 200)) (min-length uint) (max-length uint))
    (let 
        (
            (text-length (len text))
        )
        (and 
            (>= text-length min-length)
            (<= text-length max-length)
        )
    )
)
(define-public (share-recipe 
    (recipe-name (string-utf8 50))
    (instructions (string-utf8 200))
    (cuisine-type (string-utf8 15))
    (difficulty (string-utf8 10))
    (serving-size uint)
)
    (let
        (
            (recipe-id (var-get next-recipe-id))
        )
        (asserts! (validate-text-content recipe-name u3 u50) ERR-INVALID-RECIPE-NAME)
        (asserts! (validate-text-content instructions u10 u200) ERR-INVALID-INSTRUCTIONS)
        (asserts! (>= serving-size MIN-SERVINGS) ERR-INVALID-SERVINGS)
        (asserts! (validate-cuisine-type cuisine-type) ERR-INVALID-CUISINE-TYPE)
        (asserts! (validate-difficulty difficulty) ERR-INVALID-DIFFICULTY)
        
        (map-set recipe-collection recipe-id {
            chef: tx-sender,
            recipe-name: recipe-name,
            instructions: instructions,
            cuisine-type: cuisine-type,
            difficulty: difficulty,
            sharing-status: u"public",
            serving-size: serving-size
        })
        (var-set next-recipe-id (+ recipe-id u1))
        (ok recipe-id)
    )
)
(define-public (privatize-recipe (recipe-id uint))
    (let
        (
            (recipe (unwrap! (map-get? recipe-collection recipe-id) ERR-RECIPE-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get chef recipe)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get sharing-status recipe) u"public") ERR-INVALID-STATUS)
        (ok (map-set recipe-collection recipe-id (merge recipe { sharing-status: u"private" })))
    )
)
(define-read-only (get-recipe (recipe-id uint))
    (ok (map-get? recipe-collection recipe-id))
)
(define-read-only (get-chef (recipe-id uint))
    (ok (get chef (unwrap! (map-get? recipe-collection recipe-id) ERR-RECIPE-NOT-FOUND)))
)