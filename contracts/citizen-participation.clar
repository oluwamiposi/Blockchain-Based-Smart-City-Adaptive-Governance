;; Citizen Participation Contract
;; Manages democratic engagement and voting

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u201))
(define-constant ERR_ALREADY_VOTED (err u202))
(define-constant ERR_VOTING_CLOSED (err u203))

;; Data structures
(define-map proposals
  { proposal-id: uint }
  {
    title: (string-ascii 200),
    description: (string-ascii 500),
    proposer: principal,
    start-block: uint,
    end-block: uint,
    yes-votes: uint,
    no-votes: uint,
    status: (string-ascii 20)
  }
)

(define-map votes
  { proposal-id: uint, voter: principal }
  { vote: bool, block-height: uint }
)

(define-map citizen-registry
  { citizen: principal }
  { registered: bool, registration-block: uint }
)

(define-data-var next-proposal-id uint u1)

;; Public functions
(define-public (register-citizen)
  (begin
    (map-set citizen-registry
      { citizen: tx-sender }
      { registered: true, registration-block: block-height }
    )
    (ok true)
  )
)

(define-public (create-proposal (title (string-ascii 200)) (description (string-ascii 500)) (voting-period uint))
  (let ((proposal-id (var-get next-proposal-id)))
    (asserts! (is-citizen tx-sender) ERR_UNAUTHORIZED)

    (map-set proposals
      { proposal-id: proposal-id }
      {
        title: title,
        description: description,
        proposer: tx-sender,
        start-block: block-height,
        end-block: (+ block-height voting-period),
        yes-votes: u0,
        no-votes: u0,
        status: "active"
      }
    )
    (var-set next-proposal-id (+ proposal-id u1))
    (ok proposal-id)
  )
)

(define-public (vote (proposal-id uint) (vote-choice bool))
  (let ((proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND)))
    (asserts! (is-citizen tx-sender) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? votes { proposal-id: proposal-id, voter: tx-sender })) ERR_ALREADY_VOTED)
    (asserts! (<= block-height (get end-block proposal)) ERR_VOTING_CLOSED)

    (map-set votes
      { proposal-id: proposal-id, voter: tx-sender }
      { vote: vote-choice, block-height: block-height }
    )

    (if vote-choice
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal { yes-votes: (+ (get yes-votes proposal) u1) })
      )
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal { no-votes: (+ (get no-votes proposal) u1) })
      )
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (is-citizen (citizen principal))
  (default-to false (get registered (map-get? citizen-registry { citizen: citizen })))
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes { proposal-id: proposal-id, voter: voter })
)
