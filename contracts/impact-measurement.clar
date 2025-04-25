;; Impact Measurement Contract
;; Records outcomes of funded initiatives

(define-data-var admin principal tx-sender)
(define-data-var impact-counter uint u0)

;; Data structure for impact records
(define-map impact-records
  { impact-id: uint }
  {
    loan-id: uint,
    borrower: principal,
    impact-category: (string-utf8 50),
    description: (string-utf8 200),
    metrics: (list 5 {
      name: (string-utf8 50),
      value: uint,
      unit: (string-utf8 20)
    }),
    verification-status: bool,
    timestamp: uint
  }
)

;; Map to track impact records by loan
(define-map loan-impacts
  { loan-id: uint }
  { impact-ids: (list 20 uint) }
)

;; Create a new impact record
(define-public (create-impact-record
                (loan-id uint)
                (borrower principal)
                (impact-category (string-utf8 50))
                (description (string-utf8 200))
                (metrics (list 5 {
                  name: (string-utf8 50),
                  value: uint,
                  unit: (string-utf8 20)
                })))
  (let ((impact-id (var-get impact-counter)))
    (begin
      ;; Verify the caller is either the borrower or admin
      (asserts! (or (is-eq tx-sender borrower) (is-eq tx-sender (var-get admin))) (err u403))

      ;; Create the impact record
      (map-set impact-records
        { impact-id: impact-id }
        {
          loan-id: loan-id,
          borrower: borrower,
          impact-category: impact-category,
          description: description,
          metrics: metrics,
          verification-status: false,
          timestamp: block-height
        }
      )

      ;; Update loan's impact record list
      (match (map-get? loan-impacts { loan-id: loan-id })
        existing-data (map-set loan-impacts
                        { loan-id: loan-id }
                        { impact-ids: (unwrap! (as-max-len? (append (get impact-ids existing-data) impact-id) u20) (err u5)) })
        (map-set loan-impacts
          { loan-id: loan-id }
          { impact-ids: (list impact-id) })
      )

      ;; Increment impact counter
      (var-set impact-counter (+ impact-id u1))

      (ok impact-id)
    )
  )
)

;; Verify an impact record
(define-public (verify-impact-record (impact-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Only admin can verify
    (match (map-get? impact-records { impact-id: impact-id })
      impact-data (ok (map-set impact-records
                      { impact-id: impact-id }
                      (merge impact-data { verification-status: true })))
      (err u404) ;; Impact record not found
    )
  )
)

;; Get impact record information
(define-read-only (get-impact-record (impact-id uint))
  (map-get? impact-records { impact-id: impact-id })
)

;; Get impact records by loan
(define-read-only (get-loan-impacts (loan-id uint))
  (map-get? loan-impacts { loan-id: loan-id })
)

;; Set a new admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
