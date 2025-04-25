;; Lender Verification Contract
;; Validates legitimate funding sources and manages lender information

(define-data-var admin principal tx-sender)

;; Data structure for lenders
(define-map lenders
  { lender-id: principal }
  {
    name: (string-utf8 100),
    verification-status: bool,
    funding-source: (string-utf8 100),
    total-funded: uint,
    reputation-score: uint
  }
)

;; Public function to register a new lender
(define-public (register-lender (name (string-utf8 100)) (funding-source (string-utf8 100)))
  (let ((lender-principal tx-sender))
    (if (is-none (map-get? lenders { lender-id: lender-principal }))
        (ok (map-set lenders
          { lender-id: lender-principal }
          {
            name: name,
            verification-status: false,
            funding-source: funding-source,
            total-funded: u0,
            reputation-score: u0
          }))
        (err u1) ;; Lender already exists
    )
  )
)

;; Admin function to verify a lender
(define-public (verify-lender (lender-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Only admin can verify
    (match (map-get? lenders { lender-id: lender-id })
      lender-data (ok (map-set lenders
                      { lender-id: lender-id }
                      (merge lender-data { verification-status: true })))
      (err u404) ;; Lender not found
    )
  )
)

;; Update lender's total funded amount
(define-public (update-funded-amount (lender-id principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Only admin can update
    (match (map-get? lenders { lender-id: lender-id })
      lender-data (ok (map-set lenders
                      { lender-id: lender-id }
                      (merge lender-data { total-funded: (+ (get total-funded lender-data) amount) })))
      (err u404) ;; Lender not found
    )
  )
)

;; Check if a lender is verified
(define-read-only (is-verified-lender (lender-id principal))
  (match (map-get? lenders { lender-id: lender-id })
    lender-data (get verification-status lender-data)
    false
  )
)

;; Get lender information
(define-read-only (get-lender-info (lender-id principal))
  (map-get? lenders { lender-id: lender-id })
)

;; Set a new admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
