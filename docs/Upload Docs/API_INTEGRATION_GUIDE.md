# API Integration Guide - Upload Feature

## Overview

This guide documents how to integrate the real backend API for the Upload feature. Currently, all operations use mock data. When your backend is ready, follow this guide to switch to real API calls.

## Quick Start

To switch from mock to real API:

1. Open `Billix/Services/Upload/BillUploadServiceFactory.swift`
2. Change line 20 from:
   ```swift
   return .development  // Uses mock
   ```
   to:
   ```swift
   return .staging  // Uses real API
   ```

That's it! The app will now use real API calls.

---

## Base URLs

```swift
Development: Uses MockBillUploadService (no API calls)
Staging:     https://staging-api.billixapp.com/v1
Production:  https://api.billixapp.com/v1
```

---

## Authentication

All API requests require Bearer token authentication:

```
Authorization: Bearer {token}
```

Get the token from `AuthService.shared.currentUser?.id.uuidString`

---

## API Endpoints

### 1. Get Bill Types

**Endpoint:** `GET /bill-types`

**Description:** Fetch list of available bill types for Quick Add

**Request Headers:**
```
Content-Type: application/json
Authorization: Bearer {token}
```

**Response:** `200 OK`
```json
[
  {
    "id": "electric",
    "name": "Electric",
    "icon": "bolt.fill",
    "category": "Utilities"
  },
  {
    "id": "internet",
    "name": "Internet",
    "icon": "wifi",
    "category": "Telecom"
  }
]
```

**Implementation:** See `RealBillUploadService.swift:28`

---

### 2. Get Providers

**Endpoint:** `GET /providers?zipCode={zipCode}&billTypeId={billTypeId}`

**Description:** Fetch providers available in a specific ZIP code for a bill type

**Request Headers:**
```
Content-Type: application/json
Authorization: Bearer {token}
```

**Query Parameters:**
- `zipCode` (string, required): 5-digit ZIP code
- `billTypeId` (string, required): Bill type ID from `/bill-types`

**Response:** `200 OK`
```json
[
  {
    "id": "dte",
    "name": "DTE Energy",
    "logoName": "dte_logo",
    "serviceArea": "Michigan"
  },
  {
    "id": "consumers",
    "name": "Consumers Energy",
    "logoName": "consumers_logo",
    "serviceArea": "Michigan"
  }
]
```

**Error:** `400 Bad Request`
```json
{
  "error": "validation_error",
  "message": "Invalid ZIP code format"
}
```

**Implementation:** See `RealBillUploadService.swift:62`

---

### 3. Submit Quick Add

**Endpoint:** `POST /quick-add`

**Description:** Submit a quick-added bill and get comparison result

**Request Headers:**
```
Content-Type: application/json
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "billTypeId": "electric",
  "providerId": "dte",
  "zipCode": "48104",
  "amount": 124.56,
  "frequency": "monthly"
}
```

**Response:** `200 OK`
```json
{
  "billType": {
    "id": "electric",
    "name": "Electric",
    "icon": "bolt.fill",
    "category": "Utilities"
  },
  "provider": {
    "id": "dte",
    "name": "DTE Energy",
    "logoName": "dte_logo",
    "serviceArea": "Michigan"
  },
  "amount": 124.56,
  "frequency": "monthly",
  "areaAverage": 110.0,
  "percentDifference": 13.2,
  "status": "overpaying",
  "potentialSavings": 10.19,
  "message": "You're paying 13% more than average in your area",
  "ctaMessage": "Upload your full bill to see where you can save"
}
```

**Status Values:**
- `overpaying`: User pays more than area average
- `underpaying`: User pays less than area average
- `average`: User pays close to area average

**Error:** `400 Bad Request`
```json
{
  "error": "validation_error",
  "message": "Amount must be greater than zero"
}
```

**Implementation:** See `RealBillUploadService.swift:97`

---

### 4. Upload and Analyze Bill

**Endpoint:** `POST /bills/upload`

**Description:** Upload bill document (photo/PDF) for full analysis

**Request Headers:**
```
Content-Type: multipart/form-data; boundary={boundary}
Authorization: Bearer {token}
```

**Request Body:** (multipart/form-data)
```
--boundary
Content-Disposition: form-data; name="file"; filename="bill.pdf"
Content-Type: application/pdf

{binary file data}
--boundary
Content-Disposition: form-data; name="source"

camera
--boundary--
```

**Form Fields:**
- `file` (binary, required): Bill document (PDF, JPG, PNG, HEIC)
- `source` (string, required): One of `camera`, `photos`, `documentScanner`, `documentPicker`

**File Constraints:**
- Min size: 100 bytes
- Max size: 10 MB (10,485,760 bytes)
- Allowed types: PDF, JPG, JPEG, PNG, HEIC

**Response:** `200 OK`
```json
{
  "provider": "DTE Energy",
  "amount": 124.56,
  "billDate": "2025-01-10T00:00:00Z",
  "dueDate": "2025-01-25T00:00:00Z",
  "accountNumber": "1234567890",
  "category": "Utilities",
  "zipCode": "48104",
  "keyFacts": [
    {
      "label": "Usage",
      "value": "450 kWh",
      "icon": "bolt.fill"
    }
  ],
  "lineItems": [
    {
      "description": "Electricity Supply",
      "amount": 80.00,
      "category": "Supply",
      "quantity": 450,
      "rate": 0.18,
      "unit": "kWh",
      "explanation": "Cost of electricity generation"
    }
  ],
  "costBreakdown": [
    {
      "category": "Supply",
      "amount": 80.00,
      "percentage": 64.2
    }
  ],
  "insights": [
    {
      "type": "warning",
      "title": "Higher Than Average",
      "description": "Your bill is 13% above the area average"
    }
  ],
  "marketplaceComparison": {
    "areaAverage": 110.00,
    "percentDiff": 13.2,
    "zipPrefix": "481",
    "position": "above"
  }
}
```

**Error:** `413 Payload Too Large`
```json
{
  "error": "file_too_large",
  "message": "File exceeds maximum size of 10MB"
}
```

**Implementation:** See `RealBillUploadService.swift:159`

---

### 5. Get Recent Uploads

**Endpoint:** `GET /bills/recent?limit=20`

**Description:** Fetch user's recent upload history

**Request Headers:**
```
Content-Type: application/json
Authorization: Bearer {token}
```

**Query Parameters:**
- `limit` (number, optional): Max results (default: 20)

**Response:** `200 OK`
```json
[
  {
    "id": "uuid-here",
    "provider": "DTE Energy",
    "amount": 124.56,
    "source": "camera",
    "status": "analyzed",
    "uploadDate": "2025-01-22T10:30:00Z",
    "thumbnailName": "thumb.jpg"
  }
]
```

**Status Values:**
- `processing`: Upload is being analyzed
- `analyzed`: Analysis complete
- `needsConfirmation`: Requires user review
- `failed`: Analysis failed

**Implementation:** See `RealBillUploadService.swift:227`

---

### 6. Get Upload Status

**Endpoint:** `GET /bills/{uploadId}/status`

**Description:** Check status of a specific upload

**Request Headers:**
```
Content-Type: application/json
Authorization: Bearer {token}
```

**Path Parameters:**
- `uploadId` (UUID, required): Upload ID

**Response:** `200 OK`
```json
{
  "status": "processing"
}
```

**Implementation:** See `RealBillUploadService.swift:258`

---

## Error Handling

All errors follow this format:

```json
{
  "error": "error_code",
  "message": "Human-readable error message"
}
```

### Common HTTP Status Codes

- `200` - Success
- `400` - Bad Request (validation error)
- `401` - Unauthorized (invalid/missing token)
- `413` - Payload Too Large (file too big)
- `500` - Internal Server Error

### Error Types (from `UploadError` enum)

```swift
case validationFailed(String)    // Client-side validation
case uploadFailed(String)        // Upload operation failed
case networkError(String)        // Network/connection issue
case unauthorized                // Auth token invalid
case serverError(String)         // Backend error
case invalidURL                  // Malformed URL
case invalidResponse             // Unexpected response format
```

---

## Testing the Integration

### Step 1: Update Environment

```swift
// In BillUploadServiceFactory.swift
static var current: AppEnvironment {
    #if DEBUG
    return .staging  // ← Change this line
    #else
    return .production
    #endif
}
```

### Step 2: Run the App

```bash
xcodebuild -project Billix.xcodeproj -scheme Billix -destination 'platform=iOS Simulator,name=iPhone 17 Pro' run
```

### Step 3: Test Each Flow

1. **Quick Add:**
   - Tap "Quick Add a Bill"
   - Select bill type → Should call `/bill-types`
   - Enter ZIP → Should call `/providers?zipCode=...`
   - Submit → Should call `/quick-add`

2. **Scan/Upload:**
   - Tap "Scan / Upload Bill"
   - Select file → Should call `/bills/upload`
   - View results

3. **Recent Uploads:**
   - Scroll to bottom → Should call `/bills/recent`

---

## Switching Between Mock and Real

You can create a debug menu to switch at runtime:

```swift
#if DEBUG
.toolbar {
    Menu("Debug") {
        Button("Use Mock API") {
            // Recreate ViewModels with MockBillUploadService
        }
        Button("Use Real API") {
            // Recreate ViewModels with RealBillUploadService
        }
    }
}
#endif
```

---

## Next Steps

1. ✅ Implement all backend endpoints
2. ✅ Deploy to staging server
3. ✅ Update `AppEnvironment.current` to `.staging`
4. ✅ Test all flows in staging
5. ✅ Fix any API mismatches
6. ✅ Deploy to production
7. ✅ Update `AppEnvironment.current` to `.production` for release builds

---

## Support

For questions about the API integration, see:
- `RealBillUploadService.swift` - Full implementation with TODOs
- `MockBillUploadService.swift` - Reference for expected behavior
- `UPLOAD_ARCHITECTURE.md` - System architecture overview
