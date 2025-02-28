;; CraftEcho - DIY Tutorial Sharing Platform

;; Constants
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-UNAUTHORIZED (err u401))
(define-constant ERR-INVALID-PARAMS (err u400))
(define-constant ERR-ALREADY-EXISTS (err u409))

;; Data Variables  
(define-data-var next-tutorial-id uint u0)
(define-data-var next-category-id uint u0)

;; Events
(define-data-var last-event-id uint u0)

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
        tips-received: uint,
        created-at: uint,
        edited-at: (optional uint)
    }
)

(define-map categories
    uint
    {
        name: (string-utf8 50),
        description: (string-utf8 200),
        tutorial-count: uint
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

;; Private Functions
(define-private (validate-tutorial 
    (title (string-utf8 100)) 
    (description (string-utf8 1000))
    (category-id uint))
    (begin
        (asserts! (> (len title) u0) ERR-INVALID-PARAMS)
        (asserts! (> (len description) u0) ERR-INVALID-PARAMS)
        (asserts! (is-some (map-get? categories category-id)) ERR-NOT-FOUND)
        true
    ))

(define-private (emit-event (event-type (string-utf8 20)) (payload (string-utf8 500)))
    (let ((event-id (var-get last-event-id)))
        (print {event-id: event-id, type: event-type, payload: payload})
        (var-set last-event-id (+ event-id u1))
    ))

;; Public Functions
(define-public (create-category (name (string-utf8 50)) (description (string-utf8 200)))
    (let
        ((category-id (var-get next-category-id)))
        
        (asserts! (> (len name) u0) ERR-INVALID-PARAMS)
        
        (map-set categories category-id {
            name: name,
            description: description,
            tutorial-count: u0
        })
        
        (var-set next-category-id (+ category-id u1))
        (emit-event "category_created" (concat (concat "{\"id\":" (to-ascii category-id)) "}"))
        (ok category-id)
    ))

(define-public (create-tutorial 
    (title (string-utf8 100)) 
    (description (string-utf8 1000)) 
    (materials (string-utf8 500)) 
    (category-id uint) 
    (tags (list 5 (string-utf8 20))))
    (let
        (
            (tutorial-id (var-get next-tutorial-id))
            (user-stat (default-to 
                {tutorials-created: u0, total-likes-received: u0, total-tips-received: u0, reputation-score: u0} 
                (map-get? user-stats tx-sender)))
            (category (unwrap! (map-get? categories category-id) ERR-NOT-FOUND))
        )
        
        (try! (validate-tutorial title description category-id))
        
        ;; Store tutorial
        (map-set tutorials tutorial-id {
            creator: tx-sender,
            title: title,
            description: description,
            materials: materials,
            category-id: category-id,
            tags: tags,
            likes: u0,
            tips-received: u0,
            created-at: block-height,
            edited-at: none
        })
        
        ;; Update category
        (map-set categories category-id 
            (merge category {tutorial-count: (+ (get tutorial-count category) u1)}))
        
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
        
        (emit-event "tutorial_created" 
            (concat (concat "{\"id\":" (to-ascii tutorial-id)) "}"))
        
        (ok tutorial-id)
    ))

[... rest of the contract remains the same with added event emissions ...]
