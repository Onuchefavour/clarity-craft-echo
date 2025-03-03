;; CraftEcho - DIY Tutorial Sharing Platform

;; Constants
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-UNAUTHORIZED (err u401))
(define-constant ERR-INVALID-PARAMS (err u400))
(define-constant ERR-ALREADY-EXISTS (err u409))

;; Data Variables  
(define-data-var next-tutorial-id uint u0)
(define-data-var next-category-id uint u0)
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
        edited-at: (optional uint),
        is-deleted: bool
    }
)

(define-map tutorial-history
    {tutorial-id: uint, version: uint}
    {
        title: (string-utf8 100),
        description: (string-utf8 1000),
        materials: (string-utf8 500),
        edited-at: uint
    }
)

;; [Previous maps remain unchanged]

;; Helper Functions
(define-private (create-event-payload
    (event-type (string-utf8 20))
    (id uint)
    (additional-data (optional (string-utf8 200))))
    (concat 
        (concat 
            (concat "{\"type\":\"" event-type)
            (concat "\",\"id\":" (to-ascii id)))
        (concat 
            (match additional-data
                data (concat ",\"data\":\"" (concat data "\""))
                "")
            "}")
    )
)

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

;; Public Functions
(define-public (edit-tutorial
    (tutorial-id uint)
    (title (string-utf8 100))
    (description (string-utf8 1000))
    (materials (string-utf8 500)))
    (let (
        (tutorial (unwrap! (map-get? tutorials tutorial-id) ERR-NOT-FOUND))
        (current-version (default-to u0 (get edited-at tutorial)))
        )
        
        ;; Authorization check
        (asserts! (is-eq tx-sender (get creator tutorial)) ERR-UNAUTHORIZED)
        (asserts! (not (get is-deleted tutorial)) ERR-NOT-FOUND)
        
        ;; Save current version to history
        (map-set tutorial-history 
            {tutorial-id: tutorial-id, version: current-version}
            {
                title: (get title tutorial),
                description: (get description tutorial),
                materials: (get materials tutorial),
                edited-at: current-version
            })
        
        ;; Update tutorial
        (map-set tutorials tutorial-id
            (merge tutorial {
                title: title,
                description: description,
                materials: materials,
                edited-at: (some block-height)
            }))
        
        (emit-event "tutorial_edited" 
            (create-event-payload "edit" tutorial-id none))
        
        (ok true)
    ))

(define-public (delete-tutorial (tutorial-id uint))
    (let ((tutorial (unwrap! (map-get? tutorials tutorial-id) ERR-NOT-FOUND)))
        (asserts! (is-eq tx-sender (get creator tutorial)) ERR-UNAUTHORIZED)
        (asserts! (not (get is-deleted tutorial)) ERR-NOT-FOUND)
        
        (map-set tutorials tutorial-id
            (merge tutorial {is-deleted: true}))
        
        (emit-event "tutorial_deleted" 
            (create-event-payload "delete" tutorial-id none))
        
        (ok true)
    ))

;; [Previous functions remain unchanged]
