;; Early Detection Contract
;; Manages data from smoke and heat sensors

(define-data-var admin principal tx-sender)

;; Sensor types: 0 = Smoke, 1 = Heat, 2 = Camera, 3 = Satellite
(define-map sensors
  { sensor-id: uint }
  {
    sensor-type: uint,
    region-id: uint,
    location-lat: int,
    location-long: int,
    active: bool
  }
)

(define-map sensor-readings
  { sensor-id: uint, timestamp: uint }
  {
    reading-value: uint,
    alert-triggered: bool
  }
)

(define-read-only (get-sensor (sensor-id uint))
  (default-to
    {
      sensor-type: u0,
      region-id: u0,
      location-lat: 0,
      location-long: 0,
      active: false
    }
    (map-get? sensors { sensor-id: sensor-id })
  )
)

(define-public (register-sensor
    (sensor-id uint)
    (sensor-type uint)
    (region-id uint)
    (location-lat int)
    (location-long int))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (<= sensor-type u3) (err u400))
    (ok (map-set sensors
      { sensor-id: sensor-id }
      {
        sensor-type: sensor-type,
        region-id: region-id,
        location-lat: location-lat,
        location-long: location-long,
        active: true
      }
    ))
  )
)

(define-public (deactivate-sensor (sensor-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (let ((sensor (get-sensor sensor-id)))
      (asserts! (get active sensor) (err u404))
      (ok (map-set sensors
        { sensor-id: sensor-id }
        (merge sensor { active: false })
      ))
    )
  )
)

(define-public (record-sensor-reading
    (sensor-id uint)
    (timestamp uint)
    (reading-value uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (let ((sensor (get-sensor sensor-id)))
      (asserts! (get active sensor) (err u404))
      (let ((alert-threshold
              (if (is-eq (get sensor-type sensor) u0)
                u75  ;; Smoke sensor threshold
                u100 ;; Heat sensor threshold
              )))
        (ok (map-set sensor-readings
          { sensor-id: sensor-id, timestamp: timestamp }
          {
            reading-value: reading-value,
            alert-triggered: (>= reading-value alert-threshold)
          }
        ))
      )
    )
  )
)

(define-read-only (get-sensor-reading (sensor-id uint) (timestamp uint))
  (default-to
    { reading-value: u0, alert-triggered: false }
    (map-get? sensor-readings { sensor-id: sensor-id, timestamp: timestamp })
  )
)

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)

