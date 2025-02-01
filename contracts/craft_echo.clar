;; CraftEcho - DIY Tutorial Sharing Platform

;; Constants
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-UNAUTHORIZED (err u401))
(define-constant ERR-INVALID-PARAMS (err u400))

;; Data Variables  
(define-data-var next-tutorial-id uint u0)
(define-data-var next-category-id uint u0)

;; Data Maps
(define-map tutorials
    uint 
    {
        creator: principal,
        title: (string-utf8 100),
        description: (string-utf8 1000),
        materials: (string-utf8 500),
        category-id: uint,
        tags: (list 5 (string-utf8 20)),
        likes: uint,
        tips-received: uint
    }
)

(define-map categories
    uint
    {
        name: (string-utf8 50),
        description: (string-utf8 200)
    }
)

(define-map category-tutorials
    uint
    (list 100 uint)
)

(define-map user-stats
    principal
    {
        tutorials-created: uint,
        total-likes-received: uint,
        total-tips-received: uint,
        reputation-score: uint
    }
)

(define-map tutorial-likes
    {tutorial-id: uint, user: principal}
    bool
)

;; Public Functions

(define-public (create-category (name (string-utf8 50)) (description (string-utf8 200)))
    (let
        ((category-id (var-get next-category-id)))
        
        (map-set categories category-id {
            name: name,
            description: description
        })
        
        (var-set next-category-id (+ category-id u1))
        (ok category-id)
    )
)

(define-public (create-tutorial (title (string-utf8 100)) (description (string-utf8 1000)) 
                              (materials (string-utf8 500)) (category-id uint) (tags (list 5 (string-utf8 20))))
    (let
        (
            (tutorial-id (var-get next-tutorial-id))
            (user-stat (default-to {tutorials-created: u0, total-likes-received: u0, total-tips-received: u0, reputation-score: u0} 
                (map-get? user-stats tx-sender)))
            (category (unwrap! (map-get? categories category-id) ERR-NOT-FOUND))
        )
        
        ;; Store tutorial
        (map-set tutorials tutorial-id {
            creator: tx-sender,
            title: title,
            description: description,
            materials: materials,
            category-id: category-id,
            tags: tags,
            likes: u0,
            tips-received: u0
        })
        
        ;; Update category tutorials list
        (map-set category-tutorials category-id
            (unwrap! (as-max-len? 
                (append (default-to (list) (map-get? category-tutorials category-id)) tutorial-id)
                u100)
                ERR-INVALID-PARAMS))
        
        ;; Update user stats
        (map-set user-stats tx-sender 
            (merge user-stat {tutorials-created: (+ (get tutorials-created user-stat) u1)}))
        
        ;; Increment tutorial ID
        (var-set next-tutorial-id (+ tutorial-id u1))
        
        (ok tutorial-id)
    )
)

(define-public (like-tutorial (tutorial-id uint))
    (let
        (
            (tutorial (unwrap! (map-get? tutorials tutorial-id) ERR-NOT-FOUND))
            (like-key {tutorial-id: tutorial-id, user: tx-sender})
            (existing-like (default-to false (map-get? tutorial-likes like-key)))
        )
        
        (asserts! (not existing-like) ERR-INVALID-PARAMS)
        
        ;; Update tutorial likes
        (map-set tutorials tutorial-id 
            (merge tutorial {likes: (+ (get likes tutorial) u1)}))
            
        ;; Update creator stats    
        (map-set user-stats (get creator tutorial)
            (merge (default-to 
                {tutorials-created: u0, total-likes-received: u0, total-tips-received: u0, reputation-score: u0}
                (map-get? user-stats (get creator tutorial)))
                {total-likes-received: (+ (get total-likes-received 
                    (default-to {tutorials-created: u0, total-likes-received: u0, total-tips-received: u0, reputation-score: u0}
                    (map-get? user-stats (get creator tutorial)))) u1)}
            ))
            
        ;; Record like
        (map-set tutorial-likes like-key true)
        
        (ok true)
    )
)

(define-public (tip-creator (tutorial-id uint) (amount uint))
    (let
        (
            (tutorial (unwrap! (map-get? tutorials tutorial-id) ERR-NOT-FOUND))
        )
        
        ;; Transfer STX
        (try! (stx-transfer? amount tx-sender (get creator tutorial)))
        
        ;; Update tutorial stats
        (map-set tutorials tutorial-id 
            (merge tutorial {tips-received: (+ (get tips-received tutorial) amount)}))
            
        ;; Update creator stats
        (map-set user-stats (get creator tutorial)
            (merge (default-to 
                {tutorials-created: u0, total-likes-received: u0, total-tips-received: u0, reputation-score: u0}
                (map-get? user-stats (get creator tutorial)))
                {total-tips-received: (+ (get total-tips-received 
                    (default-to {tutorials-created: u0, total-likes-received: u0, total-tips-received: u0, reputation-score: u0}
                    (map-get? user-stats (get creator tutorial)))) amount)}
            ))
        
        (ok true)
    )
)

;; Read-only Functions

(define-read-only (get-tutorial (tutorial-id uint))
    (ok (map-get? tutorials tutorial-id))
)

(define-read-only (get-category (category-id uint))
    (ok (map-get? categories category-id))
)

(define-read-only (get-category-tutorials (category-id uint))
    (ok (map-get? category-tutorials category-id))
)

(define-read-only (get-user-stats (user principal))
    (ok (map-get? user-stats user))
)

(define-read-only (search-tutorials-by-tag (search-tag (string-utf8 20)))
    (let
        ((tutorial-count (var-get next-tutorial-id)))
        (filter search-tutorials-by-tag-helper (list tutorial-count))
    )
)

(define-private (search-tutorials-by-tag-helper (tutorial-id uint))
    (let
        ((tutorial (unwrap! (map-get? tutorials tutorial-id) false)))
        (index-of? (get tags tutorial) search-tag)
    )
)
