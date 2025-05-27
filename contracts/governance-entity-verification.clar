;; Governance Entity Verification Contract
;; Validates city management systems and entities

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ENTITY_EXISTS (err u101))
(define-constant ERR_ENTITY_NOT_FOUND (err u102))

;; Data structures
(define-map verified-entities
  { entity-id: uint }
  {
    name: (string-ascii 100),
    entity-type: (string-ascii 50),
    verification-date: uint,
    status: (string-ascii 20),
    verifier: principal
  }
)

(define-data-var next-entity-id uint u1)

;; Public functions
(define-public (verify-entity (name (string-ascii 100)) (entity-type (string-ascii 50)))
  (let ((entity-id (var-get next-entity-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? verified-entities { entity-id: entity-id })) ERR_ENTITY_EXISTS)

    (map-set verified-entities
      { entity-id: entity-id }
      {
        name: name,
        entity-type: entity-type,
        verification-date: block-height,
        status: "verified",
        verifier: tx-sender
      }
    )
    (var-set next-entity-id (+ entity-id u1))
    (ok entity-id)
  )
)

(define-public (revoke-verification (entity-id uint))
  (let ((entity (unwrap! (map-get? verified-entities { entity-id: entity-id }) ERR_ENTITY_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set verified-entities
      { entity-id: entity-id }
      (merge entity { status: "revoked" })
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-entity (entity-id uint))
  (map-get? verified-entities { entity-id: entity-id })
)

(define-read-only (is-verified (entity-id uint))
  (match (map-get? verified-entities { entity-id: entity-id })
    entity (is-eq (get status entity) "verified")
    false
  )
)
