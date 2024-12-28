;; CraftEcho - DIY Tutorial Sharing Platform

;; Constants
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-UNAUTHORIZED (err u401))
(define-constant ERR-INVALID-PARAMS (err u400))

;; Data Variables
(define-data-var next-tutorial-id uint u0)

;; Data Maps
(define-map tutorials
    uint 
    {
        creator: principal,
        title: (string-utf8 100),
        description: (string-utf8 1000),
        materials: (string-utf8 500),
        likes: uint,
        tips-received: uint
    }
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

(define-public (create-tutorial (title (string-utf8 100)) (description (string-utf8 1000)) (materials (string-utf8 500)))
    (let
        (
            (tutorial-id (var-get next-tutorial-id))
            (user-stat (default-to {tutorials-created: u0, total-likes-received: u0, total-tips-received: u0, reputation-score: u0} 
                (map-get? user-stats tx-sender)))
        )
        
        ;; Store tutorial
        (map-set tutorials tutorial-id {
            creator: tx-sender,
            title: title,
            description: description,
            materials: materials,
            likes: u0,
            tips-received: u0
        })
        
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

(define-read-only (get-user-stats (user principal))
    (ok (map-get? user-stats user))
)