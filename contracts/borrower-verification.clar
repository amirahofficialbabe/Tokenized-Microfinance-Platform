;; Borrower Verification Contract
;; Manages recipient identities and verification

(define-data-var admin principal tx-sender)

;; Data structure for borrowers
(define-map borrowers
  { borrower-id: principal }
  {
    name: (string-utf8 100),
    verification-status: bool,
    credit-score: uint,
    total-borrowed: uint,
    repayment-history: uint,
    location: (string-utf8 100)
  }
)

;; Public function to register a new borrower
(define-public (register-borrower (name (string-utf8 100)) (location (string-utf8 100)))
  (let ((borrower-principal tx-sender))
    (if (is-none (map-get? borrowers { borrower-id: borrower-principal }))
        (ok (map-set borrowers
          { borrower-id: borrower-principal }
          {
            name: name,
            verification-status: false,
            credit-score: u0,
            total-borrowed: u0,
            repayment-history: u0,
            location: location
          }))
        (err u1) ;; Borrower already exists
    )
  )
)

;; Admin function to verify a borrower
(define-public (verify-borrower (borrower-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Only admin can verify
    (match (map-get? borrowers { borrower-id: borrower-id })
      borrower-data (ok (map-set borrowers
                      { borrower-id: borrower-id }
                      (merge borrower-data { verification-status: true })))
      (err u404) ;; Borrower not found
    )
  )
)

;; Update borrower's credit score
(define-public (update-credit-score (borrower-id principal) (score uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Only admin can update
    (match (map-get? borrowers { borrower-id: borrower-id })
      borrower-data (ok (map-set borrowers
                      { borrower-id: borrower-id }
                      (merge borrower-data { credit-score: score })))
      (err u404) ;; Borrower not found
    )
  )
)

;; Update borrower's total borrowed amount
(define-public (update-borrowed-amount (borrower-id principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Only admin can update
    (match (map-get? borrowers { borrower-id: borrower-id })
      borrower-data (ok (map-set borrowers
                      { borrower-id: borrower-id }
                      (merge borrower-data { total-borrowed: (+ (get total-borrowed borrower-data) amount) })))
      (err u404) ;; Borrower not found
    )
  )
)

;; Update borrower's repayment history
(define-public (update-repayment-history (borrower-id principal) (value uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Only admin can update
    (match (map-get? borrowers { borrower-id: borrower-id })
      borrower-data (ok (map-set borrowers
                      { borrower-id: borrower-id }
                      (merge borrower-data { repayment-history: value })))
      (err u404) ;; Borrower not found
    )
  )
)

;; Check if a borrower is verified
(define-read-only (is-verified-borrower (borrower-id principal))
  (match (map-get? borrowers { borrower-id: borrower-id })
    borrower-data (get verification-status borrower-data)
    false
  )
)

;; Get borrower information
(define-read-only (get-borrower-info (borrower-id principal))
  (map-get? borrowers { borrower-id: borrower-id })
)

;; Set a new admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
