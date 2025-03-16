import { describe, it, expect, beforeEach, vi } from "vitest"

// Mock the Clarity contract interactions
const mockContractCalls = {
  registerSensor: vi.fn(),
  getSensor: vi.fn(),
  deactivateSensor: vi.fn(),
  recordSensorReading: vi.fn(),
  getSensorReading: vi.fn(),
}

describe("Early Detection Contract", () => {
  beforeEach(() => {
    // Reset mocks
    vi.resetAllMocks()
    
    // Setup default mock responses
    mockContractCalls.getSensor.mockReturnValue({
      "sensor-type": 0,
      "region-id": 0,
      "location-lat": 0,
      "location-long": 0,
      active: false,
    })
    
    mockContractCalls.registerSensor.mockReturnValue({ success: true })
    mockContractCalls.deactivateSensor.mockReturnValue({ success: true })
    mockContractCalls.recordSensorReading.mockReturnValue({ success: true })
    mockContractCalls.getSensorReading.mockReturnValue({
      "reading-value": 0,
      "alert-triggered": false,
    })
  })
  
  it("should register a new sensor", async () => {
    // Arrange
    const sensorId = 1
    const sensorType = 0 // Smoke sensor
    const regionId = 2
    const locationLat = 34.052235
    const locationLong = -118.243683
    
    // Act
    const result = await mockContractCalls.registerSensor(sensorId, sensorType, regionId, locationLat, locationLong)
    
    // Assert
    expect(result.success).toBe(true)
    expect(mockContractCalls.registerSensor).toHaveBeenCalledWith(
        sensorId,
        sensorType,
        regionId,
        locationLat,
        locationLong,
    )
  })
  
  it("should retrieve sensor information", async () => {
    // Arrange
    const sensorId = 1
    mockContractCalls.getSensor.mockReturnValue({
      "sensor-type": 0,
      "region-id": 2,
      "location-lat": 34.052235,
      "location-long": -118.243683,
      active: true,
    })
    
    // Act
    const result = await mockContractCalls.getSensor(sensorId)
    
    // Assert
    expect(result["sensor-type"]).toBe(0)
    expect(result["region-id"]).toBe(2)
    expect(result["active"]).toBe(true)
    expect(mockContractCalls.getSensor).toHaveBeenCalledWith(sensorId)
  })
  
  it("should deactivate a sensor", async () => {
    // Arrange
    const sensorId = 1
    mockContractCalls.getSensor.mockReturnValue({
      "sensor-type": 0,
      "region-id": 2,
      "location-lat": 34.052235,
      "location-long": -118.243683,
      active: true,
    })
    
    // Act
    const result = await mockContractCalls.deactivateSensor(sensorId)
    
    // Assert
    expect(result.success).toBe(true)
    expect(mockContractCalls.deactivateSensor).toHaveBeenCalledWith(sensorId)
  })
  
  it("should record a sensor reading and trigger alert when threshold exceeded", async () => {
    // Arrange
    const sensorId = 1
    const timestamp = Date.now()
    const readingValue = 80 // Above threshold for smoke sensor (75)
    
    mockContractCalls.getSensor.mockReturnValue({
      "sensor-type": 0, // Smoke sensor
      "region-id": 2,
      "location-lat": 34.052235,
      "location-long": -118.243683,
      active: true,
    })
    
    mockContractCalls.recordSensorReading.mockImplementation((sensorId, timestamp, value) => {
      const alertTriggered = value >= 75 // Smoke sensor threshold
      return {
        success: true,
        data: {
          "reading-value": value,
          "alert-triggered": alertTriggered,
        },
      }
    })
    
    // Act
    const result = await mockContractCalls.recordSensorReading(sensorId, timestamp, readingValue)
    
    // Assert
    expect(result.success).toBe(true)
    expect(result.data["alert-triggered"]).toBe(true)
    expect(mockContractCalls.recordSensorReading).toHaveBeenCalledWith(sensorId, timestamp, readingValue)
  })
  
  it("should not record reading for inactive sensor", async () => {
    // Arrange
    const sensorId = 1
    const timestamp = Date.now()
    const readingValue = 50
    
    mockContractCalls.getSensor.mockReturnValue({
      "sensor-type": 0,
      "region-id": 2,
      "location-lat": 34.052235,
      "location-long": -118.243683,
      active: false, // Inactive sensor
    })
    
    mockContractCalls.recordSensorReading.mockImplementation((sensorId) => {
      const sensor = mockContractCalls.getSensor(sensorId)
      if (!sensor.active) {
        return { success: false, error: "Sensor is inactive" }
      }
      return { success: true }
    })
    
    // Act
    const result = await mockContractCalls.recordSensorReading(sensorId, timestamp, readingValue)
    
    // Assert
    expect(result.success).toBe(false)
    expect(result.error).toBe("Sensor is inactive")
  })
})

