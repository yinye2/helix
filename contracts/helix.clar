;; Helix - Generative Art Breeding Platform
;; Smart contract for breeding generative NFTs with trait inheritance and creator royalties

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-breeding (err u103))
(define-constant err-insufficient-payment (err u104))
(define-constant err-already-exists (err u105))

;; Data Variables
(define-data-var next-token-id uint u1)
(define-data-var breeding-fee uint u1000000) ;; 1 STX in microSTX
(define-data-var royalty-percentage uint u250) ;; 2.5% (250 basis points)

;; Maps
(define-map tokens uint {
    owner: principal,
    generation: uint,
    parent-a: (optional uint),
    parent-b: (optional uint),
    traits: (string-ascii 500),
    creator: principal,
    breed-count: uint
})

(define-map token-creators uint principal)
(define-map breeding-permissions principal bool)
(define-map creator-royalties principal uint)

;; NFT Trait Definition
(define-non-fungible-token helix-art uint)

;; Public Functions

;; Mint genesis NFT (generation 0)
(define-public (mint-genesis (traits (string-ascii 500)) (to principal))
    (let ((token-id (var-get next-token-id)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (try! (nft-mint? helix-art token-id to))
        (map-set tokens token-id {
            owner: to,
            generation: u0,
            parent-a: none,
            parent-b: none,
            traits: traits,
            creator: tx-sender,
            breed-count: u0
        })
        (map-set token-creators token-id tx-sender)
        (var-set next-token-id (+ token-id u1))
        (ok token-id)))

;; Breed two NFTs to create offspring
(define-public (breed-nfts (parent-a-id uint) (parent-b-id uint) (offspring-traits (string-ascii 500)))
    (let (
        (parent-a (unwrap! (map-get? tokens parent-a-id) err-not-found))
        (parent-b (unwrap! (map-get? tokens parent-b-id) err-not-found))
        (token-id (var-get next-token-id))
        (breeding-cost (var-get breeding-fee))
        (new-generation (+ (max (get generation parent-a) (get generation parent-b)) u1))
    )
        ;; Verify ownership or permission
        (asserts! (or 
            (is-eq tx-sender (get owner parent-a))
            (is-eq tx-sender (get owner parent-b))
            (default-to false (map-get? breeding-permissions tx-sender))
        ) err-unauthorized)
        
        ;; Verify different parents
        (asserts! (not (is-eq parent-a-id parent-b-id)) err-invalid-breeding)
        
        ;; Pay breeding fee
        (try! (stx-transfer? breeding-cost tx-sender contract-owner))
        
        ;; Mint new NFT
        (try! (nft-mint? helix-art token-id tx-sender))
        
        ;; Store token data
        (map-set tokens token-id {
            owner: tx-sender,
            generation: new-generation,
            parent-a: (some parent-a-id),
            parent-b: (some parent-b-id),
            traits: offspring-traits,
            creator: tx-sender,
            breed-count: u0
        })
        
        ;; Update parent breed counts
        (map-set tokens parent-a-id (merge parent-a {breed-count: (+ (get breed-count parent-a) u1)}))
        (map-set tokens parent-b-id (merge parent-b {breed-count: (+ (get breed-count parent-b) u1)}))
        
        ;; Set token creator
        (map-set token-creators token-id tx-sender)
        
        ;; Update next token ID
        (var-set next-token-id (+ token-id u1))
        
        ;; Distribute royalties to parent creators
        (try! (distribute-breeding-royalties parent-a-id parent-b-id))
        
        (ok token-id)))

;; Transfer NFT
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender sender) err-unauthorized)
        (asserts! (is-some (nft-get-owner? helix-art token-id)) err-not-found)
        (try! (nft-transfer? helix-art token-id sender recipient))
        (match (map-get? tokens token-id)
            token-data (map-set tokens token-id (merge token-data {owner: recipient}))
            false)
        (ok true)))

;; Set breeding permission for address
(define-public (set-breeding-permission (breeder principal) (permission bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set breeding-permissions breeder permission)
        (ok true)))

;; Admin function to set breeding fee
(define-public (set-breeding-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set breeding-fee new-fee)
        (ok true)))

;; Admin function to set royalty percentage
(define-public (set-royalty-percentage (new-percentage uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= new-percentage u1000) err-invalid-breeding) ;; Max 10%
        (var-set royalty-percentage new-percentage)
        (ok true)))

;; Withdraw accumulated royalties
(define-public (withdraw-royalties)
    (let ((amount (default-to u0 (map-get? creator-royalties tx-sender))))
        (asserts! (> amount u0) err-not-found)
        (map-set creator-royalties tx-sender u0)
        (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
        (ok amount)))

;; Private Functions

;; Distribute royalties to parent creators
(define-private (distribute-breeding-royalties (parent-a-id uint) (parent-b-id uint))
    (let (
        (creator-a (unwrap! (map-get? token-creators parent-a-id) err-not-found))
        (creator-b (unwrap! (map-get? token-creators parent-b-id) err-not-found))
        (total-royalty (/ (* (var-get breeding-fee) (var-get royalty-percentage)) u10000))
        (royalty-per-parent (/ total-royalty u2))
    )
        ;; Add royalties to creator balances
        (map-set creator-royalties creator-a 
            (+ (default-to u0 (map-get? creator-royalties creator-a)) royalty-per-parent))
        (map-set creator-royalties creator-b 
            (+ (default-to u0 (map-get? creator-royalties creator-b)) royalty-per-parent))
        (ok true)))

;; Read-only Functions

;; Get token details
(define-read-only (get-token-info (token-id uint))
    (map-get? tokens token-id))

;; Get token owner
(define-read-only (get-owner (token-id uint))
    (ok (nft-get-owner? helix-art token-id)))

;; Get next token ID
(define-read-only (get-next-token-id)
    (var-get next-token-id))

;; Get breeding fee
(define-read-only (get-breeding-fee)
    (var-get breeding-fee))

;; Get creator royalty balance
(define-read-only (get-creator-royalties (creator principal))
    (default-to u0 (map-get? creator-royalties creator)))

;; Get token lineage (parents)
(define-read-only (get-lineage (token-id uint))
    (match (map-get? tokens token-id)
        token-data (ok {
            parent-a: (get parent-a token-data),
            parent-b: (get parent-b token-data),
            generation: (get generation token-data)
        })
        err-not-found))

;; Check if address has breeding permission
(define-read-only (has-breeding-permission (breeder principal))
    (default-to false (map-get? breeding-permissions breeder)))

;; Get contract stats
(define-read-only (get-contract-stats)
    (ok {
        total-tokens: (- (var-get next-token-id) u1),
        breeding-fee: (var-get breeding-fee),
        royalty-percentage: (var-get royalty-percentage)
    }))

;; Helper function to get max of two uints
(define-private (max (a uint) (b uint))
    (if (> a b) a b))