;; A simple SIP-010-like fungible token implementation for uocoin.
;; This contract defines a fixed-supply fungible token that can be
;; minted by the contract deployer and transferred between principals.

;; --------------------
;; Constants & Errors
;; --------------------

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-INSUFFICIENT-ALLOWANCE (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))

;; IMPORTANT: update this constant to the principal that should be allowed
;; to mint new uocoin tokens before deploying the contract on a live network.
(define-constant CONTRACT-OWNER 'ST000000000000000000002AMW42H)

;; Token metadata
(define-constant TOKEN-NAME "uocoin")
(define-constant TOKEN-SYMBOL "UOC")
(define-constant TOKEN-DECIMALS u6)

;; --------------------
;; Data Maps & Vars
;; --------------------

;; balances: principal -> uint balance
(define-map balances
  { owner: principal }
  { balance: uint })

;; allowances: (owner, spender) -> uint allowance
(define-map allowances
  { owner: principal, spender: principal }
  { amount: uint })

;; total-supply of the token
(define-data-var total-supply uint u0)

;; --------------------
;; Internal helpers
;; --------------------

(define-private (is-owner (who principal))
  (is-eq who CONTRACT-OWNER))

(define-private (get-balance-or-zero (who principal))
  (default-to u0 (get balance (map-get? balances { owner: who }))))

;; --------------------
;; SIP-010 Interface (subset)
;; --------------------

(define-read-only (get-name)
  (ok TOKEN-NAME))

(define-read-only (get-symbol)
  (ok TOKEN-SYMBOL))

(define-read-only (get-decimals)
  (ok TOKEN-DECIMALS))

(define-read-only (get-total-supply)
  (ok (var-get total-supply)))

(define-read-only (get-balance (who principal))
  (ok (get-balance-or-zero who)))

(define-read-only (get-allowance (owner principal) (spender principal))
  (ok (default-to u0 (get amount (map-get? allowances { owner: owner, spender: spender })))))

;; --------------------
;; Public functions
;; --------------------

;; Mint new tokens to a recipient. Only the contract owner may call this.
(define-public (mint (recipient principal) (amount uint))
  (let (
        (current-balance (get-balance-or-zero recipient))
        (current-supply (var-get total-supply))
       )
    (if (is-eq amount u0)
        ERR-INVALID-AMOUNT
        (if (not (is-owner tx-sender))
            ERR-NOT-AUTHORIZED
            (begin
              (map-set balances { owner: recipient } { balance: (+ current-balance amount) })
              (var-set total-supply (+ current-supply amount))
              (ok true)
            )
        )
    )
  )
)

;; Transfer tokens from the caller to a recipient.
(define-public (transfer (amount uint) (sender principal) (recipient principal))
  (if (is-eq amount u0)
      ERR-INVALID-AMOUNT
      (if (not (is-eq tx-sender sender))
          ERR-NOT-AUTHORIZED
          (transfer-core sender recipient amount)
      )
  )
)

;; Transfer tokens on behalf of an owner, using allowance.
(define-public (transfer-from (amount uint) (owner principal) (recipient principal))
  (let (
        (current-allowance
          (default-to u0
            (get amount (map-get? allowances { owner: owner, spender: tx-sender })))
        )
       )
    (if (is-eq amount u0)
        ERR-INVALID-AMOUNT
        (if (< current-allowance amount)
            ERR-INSUFFICIENT-ALLOWANCE
            (begin
              (map-set allowances
                { owner: owner, spender: tx-sender }
                { amount: (- current-allowance amount) }
              )
              (transfer-core owner recipient amount)
            )
        )
    )
  )
)

;; Approve an allowance for a spender.
(define-public (approve (spender principal) (amount uint))
  (if (is-eq amount u0)
      ERR-INVALID-AMOUNT
      (begin
        (map-set allowances { owner: tx-sender, spender: spender } { amount: amount })
        (ok true)
      )
  )
)

;; --------------------
;; Private core transfer logic
;; --------------------

(define-private (transfer-core (sender principal) (recipient principal) (amount uint))
  (let (
        (sender-balance (get-balance-or-zero sender))
       )
    (if (< sender-balance amount)
        ERR-INSUFFICIENT-BALANCE
        (let (
              (new-sender-balance (- sender-balance amount))
              (recipient-balance (get-balance-or-zero recipient))
              (new-recipient-balance (+ recipient-balance amount))
             )
          (begin
            (map-set balances { owner: sender } { balance: new-sender-balance })
            (map-set balances { owner: recipient } { balance: new-recipient-balance })
            (ok true)
          )
        )
    )
  )
)
