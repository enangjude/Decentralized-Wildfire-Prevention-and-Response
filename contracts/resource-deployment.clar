;; Resource Deployment Contract
;; Coordinates firefighting equipment and personnel

(define-data-var admin principal tx-sender)

;; Resource types: 0 = Fire Engine, 1 = Helicopter, 2 = Firefighter Team, 3 = Water Tanker
(define-map resources
  { resource-id: uint }
  {
    resource-type: uint,
    capacity: uint,
    current-region-id: uint,
    available: bool,
    last-deployed: uint
  }
)

(define-map deployments
  { deployment-id: uint }
  {
    resource-id: uint,
    region-id: uint,
    start-time: uint,
    end-time: (optional uint),
    status: uint  ;; 0 = Pending, 1 = Active, 2 = Completed, 3 = Cancelled
  }
)

(define-read-only (get-resource (resource-id uint))
  (default-to
    {
      resource-type: u0,
      capacity: u0,
      current-region-id: u0,
      available: false,
      last-deployed: u0
    }
    (map-get? resources { resource-id: resource-id })
  )
)

(define-public (register-resource
    (resource-id uint)
    (resource-type uint)
    (capacity uint)
    (current-region-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (<= resource-type u3) (err u400))
    (ok (map-set resources
      { resource-id: resource-id }
      {
        resource-type: resource-type,
        capacity: capacity,
        current-region-id: current-region-id,
        available: true,
        last-deployed: u0
      }
    ))
  )
)

(define-public (deploy-resource
    (deployment-id uint)
    (resource-id uint)
    (region-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (let ((resource (get-resource resource-id)))
      (asserts! (get available resource) (err u400))

      ;; Update resource availability
      (map-set resources
        { resource-id: resource-id }
        (merge resource
          {
            available: false,
            current-region-id: region-id,
            last-deployed: block-height
          }
        )
      )

      ;; Create deployment record
      (ok (map-set deployments
        { deployment-id: deployment-id }
        {
          resource-id: resource-id,
          region-id: region-id,
          start-time: block-height,
          end-time: none,
          status: u1  ;; Active
        }
      ))
    )
  )
)

(define-public (complete-deployment (deployment-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (let ((deployment (default-to
                        {
                          resource-id: u0,
                          region-id: u0,
                          start-time: u0,
                          end-time: none,
                          status: u0
                        }
                        (map-get? deployments { deployment-id: deployment-id }))))
      (asserts! (is-eq (get status deployment) u1) (err u400))

      ;; Update deployment status
      (map-set deployments
        { deployment-id: deployment-id }
        (merge deployment
          {
            end-time: (some block-height),
            status: u2  ;; Completed
          }
        )
      )

      ;; Make resource available again
      (let ((resource (get-resource (get resource-id deployment))))
        (ok (map-set resources
          { resource-id: (get resource-id deployment) }
          (merge resource { available: true })
        ))
      )
    )
  )
)

(define-read-only (get-deployment (deployment-id uint))
  (default-to
    {
      resource-id: u0,
      region-id: u0,
      start-time: u0,
      end-time: none,
      status: u0
    }
    (map-get? deployments { deployment-id: deployment-id })
  )
)

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)

