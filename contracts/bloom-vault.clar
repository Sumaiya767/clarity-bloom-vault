;; BloomVault Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-vault-exists (err u101))
(define-constant err-vault-not-found (err u102))
(define-constant err-memory-exists (err u103))
(define-constant err-memory-not-found (err u104))

;; Data structures
(define-map vaults
  { owner: principal }
  { 
    name: (string-utf8 100),
    created-at: uint,
    collaborators: (list 50 principal)
  }
)

(define-map memories
  { vault-owner: principal, memory-id: uint }
  {
    title: (string-utf8 100),
    description: (string-utf8 500),
    metadata: (string-utf8 200),
    created-at: uint,
    shared-with: (list 50 principal)
  }
)

(define-data-var memory-counter uint u0)

;; Vault functions
(define-public (create-vault (name (string-utf8 100)))
  (let ((sender tx-sender))
    (asserts! (is-none (map-get? vaults {owner: sender})) err-vault-exists)
    (ok (map-set vaults
      { owner: sender }
      { 
        name: name,
        created-at: block-height,
        collaborators: (list)
      }
    ))
  )
)

(define-public (add-collaborator (vault-owner principal) (collaborator principal))
  (let ((vault (unwrap! (map-get? vaults {owner: vault-owner}) err-vault-not-found)))
    (asserts! (or (is-eq tx-sender vault-owner) 
                 (is-some (index-of? (get collaborators vault) tx-sender))) 
             err-not-authorized)
    (ok (map-set vaults
      { owner: vault-owner }
      (merge vault { collaborators: (unwrap-panic (as-max-len? 
        (append (get collaborators vault) collaborator) u50)) })
    ))
  )
)

;; Memory functions  
(define-public (create-memory 
  (title (string-utf8 100))
  (description (string-utf8 500))
  (metadata (string-utf8 200)))
  (let (
    (sender tx-sender)
    (memory-id (var-get memory-counter))
    (vault (unwrap! (map-get? vaults {owner: sender}) err-vault-not-found)))
    (var-set memory-counter (+ memory-id u1))
    (ok (map-set memories
      { vault-owner: sender, memory-id: memory-id }
      {
        title: title,
        description: description, 
        metadata: metadata,
        created-at: block-height,
        shared-with: (list)
      }
    ))
  )
)

(define-public (share-memory 
  (vault-owner principal)
  (memory-id uint)
  (recipient principal))
  (let ((memory (unwrap! (map-get? memories {vault-owner: vault-owner, memory-id: memory-id}) 
                        err-memory-not-found)))
    (asserts! (or (is-eq tx-sender vault-owner)
                 (is-some (index-of? (get collaborators 
                   (unwrap! (map-get? vaults {owner: vault-owner}) err-vault-not-found)) 
                   tx-sender)))
             err-not-authorized)
    (ok (map-set memories
      { vault-owner: vault-owner, memory-id: memory-id }
      (merge memory { shared-with: (unwrap-panic (as-max-len? 
        (append (get shared-with memory) recipient) u50)) })
    ))
  )
)

;; Read functions
(define-read-only (get-vault (owner principal))
  (map-get? vaults {owner: owner})
)

(define-read-only (get-memory (vault-owner principal) (memory-id uint))
  (map-get? memories {vault-owner: vault-owner, memory-id: memory-id})
)
