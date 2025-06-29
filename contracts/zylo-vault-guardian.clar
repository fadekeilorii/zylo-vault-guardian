;; ZyloVault-ContentGuardian: Advanced digital asset management system

;; --------------------------------------------------------------------------
;; Global State Management Variables
;; --------------------------------------------------------------------------

;; Sequential counter for generating unique content identifiers
(define-data-var content-identifier-counter uint u0)

;; --------------------------------------------------------------------------
;; System Constants and Error Definitions
;; --------------------------------------------------------------------------

;; Administrator principal with elevated system privileges
(define-constant SYSTEM_ADMINISTRATOR tx-sender)

;; Comprehensive error code definitions for various failure scenarios
(define-constant ERROR_PERMISSION_DENIED (err u300))
(define-constant ERROR_CONTENT_NOT_FOUND (err u301))
(define-constant ERROR_DUPLICATE_CONTENT (err u302))
(define-constant ERROR_INVALID_HEADING (err u303))
(define-constant ERROR_INVALID_VOLUME (err u304))
(define-constant ERROR_ACCESS_RESTRICTED (err u305))

;; --------------------------------------------------------------------------
;; Primary Storage Structures
;; --------------------------------------------------------------------------

;; Core content registry mapping each unique identifier to its metadata
(define-map digital-content-registry
  { content-identifier: uint }
  {
    content-heading: (string-ascii 80),
    content-creator: principal,
    content-volume: uint,
    creation-timestamp: uint,
    content-summary: (string-ascii 256),
    content-tags: (list 8 (string-ascii 40))
  }
)

;; Access permissions matrix for granular control over content visibility
(define-map content-permission-matrix
  { content-identifier: uint, permitted-user: principal }
  { viewing-authorized: bool }
)


;; --------------------------------------------------------------------------
;; Content Information Retrieval Functions
;; --------------------------------------------------------------------------

;; Retrieves essential content metadata for efficient display purposes
(define-public (fetch-content-basics (content-identifier uint))
  (let
    (
      (content-record (unwrap! (map-get? digital-content-registry { content-identifier: content-identifier }) ERROR_CONTENT_NOT_FOUND))
    )
    ;; Return fundamental content properties for quick access
    (ok {
      content-heading: (get content-heading content-record),
      content-creator: (get content-creator content-record),
      content-volume: (get content-volume content-record)
    })
  )
)

;; Provides minimal content data for ultra-fast retrieval operations
(define-public (fetch-content-minimal (content-identifier uint))
  (let
    (
      (content-record (unwrap! (map-get? digital-content-registry { content-identifier: content-identifier }) ERROR_CONTENT_NOT_FOUND))
    )
    ;; Return only critical identification data
    (ok {
      content-heading: (get content-heading content-record),
      content-creator: (get content-creator content-record)
    })
  )
)

;; Comprehensive content view with complete metadata structure
(define-public (fetch-comprehensive-content-details (content-identifier uint))
  (let
    (
      (content-record (unwrap! (map-get? digital-content-registry { content-identifier: content-identifier }) ERROR_CONTENT_NOT_FOUND))
    )
    ;; Construct complete content presentation object
    (ok {
      title: (get content-heading content-record),
      creator: (get content-creator content-record),
      volume: (get content-volume content-record),
      summary: (get content-summary content-record),
      tags: (get content-tags content-record)
    })
  )
)

;; Specialized function for retrieving content summary information only
(define-public (extract-content-summary (content-identifier uint))
  (let
    (
      (content-record (unwrap! (map-get? digital-content-registry { content-identifier: content-identifier }) ERROR_CONTENT_NOT_FOUND))
    )
    (ok (get content-summary content-record))
  )
)

;; --------------------------------------------------------------------------
;; Content Modification and Management Functions
;; --------------------------------------------------------------------------

;; Comprehensive metadata update function with full validation
(define-public (modify-content-attributes 
                (content-identifier uint) 
                (updated-heading (string-ascii 80)) 
                (updated-volume uint) 
                (updated-summary (string-ascii 256)) 
                (updated-tags (list 8 (string-ascii 40))))
  (let
    (
      (content-record (unwrap! (map-get? digital-content-registry { content-identifier: content-identifier }) ERROR_CONTENT_NOT_FOUND))
    )
    ;; Verify content existence and ownership permissions
    (asserts! (verify-content-exists content-identifier) ERROR_CONTENT_NOT_FOUND)
    (asserts! (is-eq (get content-creator content-record) tx-sender) ERROR_ACCESS_RESTRICTED)

    ;; Comprehensive input validation for all parameters
    (asserts! (> (len updated-heading) u0) ERROR_INVALID_HEADING)
    (asserts! (< (len updated-heading) u81) ERROR_INVALID_HEADING)
    (asserts! (> updated-volume u0) ERROR_INVALID_VOLUME)
    (asserts! (< updated-volume u2000000000) ERROR_INVALID_VOLUME)
    (asserts! (> (len updated-summary) u0) ERROR_INVALID_HEADING)
    (asserts! (< (len updated-summary) u257) ERROR_INVALID_HEADING)
    (asserts! (validate-tag-collection updated-tags) ERROR_INVALID_HEADING)

    ;; Apply metadata updates to content record
    (map-set digital-content-registry
      { content-identifier: content-identifier }
      (merge content-record { 
        content-heading: updated-heading, 
        content-volume: updated-volume, 
        content-summary: updated-summary, 
        content-tags: updated-tags 
      })
    )
    (ok true)
  )
)

;; Permanent content removal with ownership verification
(define-public (delete-content-permanently (content-identifier uint))
  (let
    (
      (content-record (unwrap! (map-get? digital-content-registry { content-identifier: content-identifier }) ERROR_CONTENT_NOT_FOUND))
    )
    ;; Verify content existence and creator authorization
    (asserts! (verify-content-exists content-identifier) ERROR_CONTENT_NOT_FOUND)
    (asserts! (is-eq (get content-creator content-record) tx-sender) ERROR_ACCESS_RESTRICTED)

    ;; Execute permanent content removal from registry
    (map-delete digital-content-registry { content-identifier: content-identifier })
    (ok true)
  )
)

;; --------------------------------------------------------------------------
;; Content Registration and Creation Functions  
;; --------------------------------------------------------------------------

;; Primary content registration function with comprehensive validation
(define-public (register-digital-content 
                (heading (string-ascii 80)) 
                (volume uint) 
                (summary (string-ascii 256)) 
                (tags (list 8 (string-ascii 40))))
  (let
    (
      (content-identifier (+ (var-get content-identifier-counter) u1))
    )
    ;; Thorough input parameter validation
    (asserts! (> (len heading) u0) ERROR_INVALID_HEADING)
    (asserts! (< (len heading) u81) ERROR_INVALID_HEADING)
    (asserts! (> volume u0) ERROR_INVALID_VOLUME)
    (asserts! (< volume u2000000000) ERROR_INVALID_VOLUME)
    (asserts! (> (len summary) u0) ERROR_INVALID_HEADING)
    (asserts! (< (len summary) u257) ERROR_INVALID_HEADING)
    (asserts! (validate-tag-collection tags) ERROR_INVALID_HEADING)

    ;; Create new content entry in digital registry
    (map-insert digital-content-registry
      { content-identifier: content-identifier }
      {
        content-heading: heading,
        content-creator: tx-sender,
        content-volume: volume,
        creation-timestamp: block-height,
        content-summary: summary,
        content-tags: tags
      }
    )

    ;; Establish creator access permissions automatically
    (map-insert content-permission-matrix
      { content-identifier: content-identifier, permitted-user: tx-sender }
      { viewing-authorized: true }
    )
    
    ;; Increment counter and return new content identifier
    (var-set content-identifier-counter content-identifier)
    (ok content-identifier)
  )
)

;; Enhanced content registration with improved structure and clarity
(define-public (create-enhanced-content-entry 
                (heading (string-ascii 80)) 
                (volume uint) 
                (summary (string-ascii 256)) 
                (tags (list 8 (string-ascii 40))))
  (let
    (
      (content-identifier (+ (var-get content-identifier-counter) u1))
    )
    ;; Rigorous input validation phase
    (asserts! (> (len heading) u0) ERROR_INVALID_HEADING)
    (asserts! (< (len heading) u81) ERROR_INVALID_HEADING)
    (asserts! (> volume u0) ERROR_INVALID_VOLUME)
    (asserts! (< volume u2000000000) ERROR_INVALID_VOLUME)
    (asserts! (> (len summary) u0) ERROR_INVALID_HEADING)
    (asserts! (< (len summary) u257) ERROR_INVALID_HEADING)
    (asserts! (validate-tag-collection tags) ERROR_INVALID_HEADING)

    ;; Content metadata storage operation
    (map-insert digital-content-registry
      { content-identifier: content-identifier }
      {
        content-heading: heading,
        content-creator: tx-sender,
        content-volume: volume,
        creation-timestamp: block-height,
        content-summary: summary,
        content-tags: tags
      }
    )

    ;; Creator permission establishment
    (map-insert content-permission-matrix
      { content-identifier: content-identifier, permitted-user: tx-sender }
      { viewing-authorized: true }
    )
    
    ;; Counter update and successful response
    (var-set content-identifier-counter content-identifier)
    (ok content-identifier)
  )
)

;; --------------------------------------------------------------------------
;; Content Validation and Verification Functions
;; --------------------------------------------------------------------------

;; Comprehensive content submission validation with detailed checks
(define-public (validate-content-submission-data (heading (string-ascii 80)) (volume uint) (summary (string-ascii 256)) (tags (list 8 (string-ascii 40))))
  (begin
    ;; Heading parameter validation checks
    (asserts! (> (len heading) u0) ERROR_INVALID_HEADING)
    (asserts! (< (len heading) u81) ERROR_INVALID_HEADING)
    ;; Volume parameter validation checks
    (asserts! (> volume u0) ERROR_INVALID_VOLUME)
    (asserts! (< volume u2000000000) ERROR_INVALID_VOLUME)
    ;; Summary parameter validation checks
    (asserts! (> (len summary) u0) ERROR_INVALID_HEADING)
    (asserts! (< (len summary) u257) ERROR_INVALID_HEADING)
    ;; Tag collection validation checks
    (asserts! (validate-tag-collection tags) ERROR_INVALID_HEADING)
    (ok true)
  )
)

;; --------------------------------------------------------------------------
;; User Interface Generation Functions
;; --------------------------------------------------------------------------

;; Generates formatted dashboard view for content presentation
(define-public (create-content-dashboard-view (content-identifier uint))
  (let
    (
      (content-record (unwrap! (map-get? digital-content-registry { content-identifier: content-identifier }) ERROR_CONTENT_NOT_FOUND))
    )
    ;; Return structured dashboard compatible data object
    (ok {
      interface-title: "Content Management Dashboard",
      content-heading: (get content-heading content-record),
      content-creator: (get content-creator content-record),
      content-summary: (get content-summary content-record),
      content-tags: (get content-tags content-record)
    })
  )
)

;; --------------------------------------------------------------------------
;; Internal Helper and Utility Functions
;; --------------------------------------------------------------------------

;; Verifies content existence in the digital registry
(define-private (verify-content-exists (content-identifier uint))
  (is-some (map-get? digital-content-registry { content-identifier: content-identifier }))
)

;; Checks if specified principal owns the content
(define-private (verify-content-ownership (content-identifier uint) (creator principal))
  (match (map-get? digital-content-registry { content-identifier: content-identifier })
    content-data (is-eq (get content-creator content-data) creator)
    false
  )
)

;; Retrieves content volume with safe default handling
(define-private (extract-content-volume (content-identifier uint))
  (default-to u0 
    (get content-volume 
      (map-get? digital-content-registry { content-identifier: content-identifier })
    )
  )
)

;; Validates tag collection structure and content
(define-private (validate-tag-collection (tags (list 8 (string-ascii 40))))
  (and
    (> (len tags) u0)
    (<= (len tags) u8)
    (is-eq (len (filter validate-individual-tag tags)) (len tags))
  )
)

;; Validates individual tag format and constraints
(define-private (validate-individual-tag (tag (string-ascii 40)))
  (and 
    (> (len tag) u0)
    (< (len tag) u41)
  )
)

