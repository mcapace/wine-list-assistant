# Wine List Assistant API Specification
## Backend Services & API Design

---

## Overview

This document specifies the REST API that powers the Wine List Assistant mobile application. The API provides wine search, matching, user management, and business analytics capabilities.

---

## Base Information

| Property | Value |
|----------|-------|
| Base URL (Production) | `https://api.winespectator.com/wla/v1` |
| Base URL (Staging) | `https://api-staging.winespectator.com/wla/v1` |
| Protocol | HTTPS (TLS 1.3) |
| Format | JSON |
| Character Encoding | UTF-8 |

---

## Authentication

### Consumer Authentication

Two methods supported:

#### 1. API Key (Anonymous/Limited Access)
```http
X-API-Key: wla_pk_live_xxxxxxxxxxxxx
```
- Limited to free tier functionality
- Rate limited: 100 requests/hour

#### 2. Bearer Token (Authenticated Users)
```http
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
```
- Full access based on subscription tier
- Obtained via `/auth/login` or OAuth flow
- JWT format, expires in 24 hours
- Refresh token valid for 30 days

### B2B Authentication
```http
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
X-Business-Account: biz_xxxxxxxxxxxx
```
- Requires business account ID header
- Higher rate limits based on plan

---

## Rate Limiting

| Tier | Requests/Minute | Requests/Day |
|------|-----------------|--------------|
| Anonymous | 10 | 100 |
| Free User | 30 | 500 |
| Premium User | 120 | 10,000 |
| Business Pro | 300 | 50,000 |
| Enterprise | Custom | Custom |

Rate limit headers returned:
```http
X-RateLimit-Limit: 120
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1699123456
```

---

## Common Response Formats

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "requestId": "req_abc123",
    "processingTime": 45
  }
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "WINE_NOT_FOUND",
    "message": "No wine found with the specified ID",
    "details": { ... }
  },
  "meta": {
    "requestId": "req_abc123"
  }
}
```

### Error Codes
| Code | HTTP Status | Description |
|------|-------------|-------------|
| `UNAUTHORIZED` | 401 | Missing or invalid authentication |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `RATE_LIMITED` | 429 | Too many requests |
| `VALIDATION_ERROR` | 400 | Invalid request parameters |
| `SUBSCRIPTION_REQUIRED` | 402 | Feature requires paid subscription |
| `SERVER_ERROR` | 500 | Internal server error |

---

## API Endpoints

### Wine Search & Matching

#### Search Wines
Find wines matching a text query with optional fuzzy matching.

```http
GET /wines/search
```

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `q` | string | Yes | Search query (wine name, producer, etc.) |
| `fuzzy` | boolean | No | Enable fuzzy matching (default: true) |
| `vintage` | integer | No | Filter by specific vintage |
| `color` | string | No | Filter by color: red, white, rose, sparkling |
| `min_score` | integer | No | Minimum WS score (0-100) |
| `region` | string | No | Filter by region |
| `limit` | integer | No | Results per page (default: 10, max: 50) |
| `offset` | integer | No | Pagination offset |

**Example Request:**
```http
GET /wines/search?q=opus+one+2019&fuzzy=true&limit=5
Authorization: Bearer eyJhbGc...
```

**Example Response:**
```json
{
  "success": true,
  "data": {
    "results": [
      {
        "wine": {
          "id": "wine_abc123",
          "producer": "Opus One",
          "name": "Opus One",
          "vintage": 2019,
          "region": "Napa Valley",
          "country": "USA",
          "color": "red",
          "grape_varieties": ["Cabernet Sauvignon", "Merlot", "Cabernet Franc", "Petit Verdot", "Malbec"],
          "score": 97,
          "tasting_note": "Powerful and polished, with a gorgeous core of black currant, violet and dark chocolate flavors...",
          "reviewer_initials": "JL",
          "drink_window_start": 2024,
          "drink_window_end": 2045,
          "release_price": 425.00,
          "review_date": "2022-03-15"
        },
        "match_confidence": 0.98,
        "match_type": "exact"
      }
    ],
    "total_count": 1,
    "query_normalized": "opus one 2019"
  },
  "meta": {
    "requestId": "req_xyz789",
    "processingTime": 42
  }
}
```

---

#### Batch Match Wines
Match multiple wine text strings in a single request. Optimized for scanning complete wine lists.

```http
POST /wines/batch-match
```

**Request Body:**
```json
{
  "queries": [
    "Opus One 2019",
    "Ch. Margaux 2015",
    "Cloudy Bay SB 2022",
    "Caymus Cab Sauv '18"
  ],
  "options": {
    "fuzzy": true,
    "include_alternatives": false,
    "confidence_threshold": 0.7
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "matches": [
      {
        "query": "Opus One 2019",
        "matched": true,
        "wine": {
          "id": "wine_abc123",
          "producer": "Opus One",
          "name": "Opus One",
          "vintage": 2019,
          "score": 97,
          "drink_window": "2024-2045",
          "release_price": 425.00
        },
        "confidence": 0.98
      },
      {
        "query": "Ch. Margaux 2015",
        "matched": true,
        "wine": {
          "id": "wine_def456",
          "producer": "Château Margaux",
          "name": "Château Margaux",
          "vintage": 2015,
          "score": 99,
          "drink_window": "2025-2060",
          "release_price": 650.00
        },
        "confidence": 0.95
      },
      {
        "query": "Cloudy Bay SB 2022",
        "matched": true,
        "wine": {
          "id": "wine_ghi789",
          "producer": "Cloudy Bay",
          "name": "Sauvignon Blanc",
          "vintage": 2022,
          "score": 91,
          "drink_window": "2023-2025",
          "release_price": 28.00
        },
        "confidence": 0.92
      },
      {
        "query": "Caymus Cab Sauv '18",
        "matched": true,
        "wine": {
          "id": "wine_jkl012",
          "producer": "Caymus Vineyards",
          "name": "Cabernet Sauvignon Napa Valley",
          "vintage": 2018,
          "score": 93,
          "drink_window": "2022-2035",
          "release_price": 85.00
        },
        "confidence": 0.89
      }
    ],
    "match_rate": 1.0,
    "processing_time_ms": 156
  }
}
```

**Limits:**
- Free users: 5 queries per request
- Premium users: 50 queries per request
- Business: 200 queries per request

---

#### Get Wine Details
Retrieve full details for a specific wine.

```http
GET /wines/{wine_id}
```

**Path Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `wine_id` | string | Wine identifier |

**Example Response:**
```json
{
  "success": true,
  "data": {
    "wine": {
      "id": "wine_abc123",
      "producer": "Opus One",
      "name": "Opus One",
      "vintage": 2019,
      "region": "Napa Valley",
      "sub_region": "Oakville",
      "appellation": "Oakville AVA",
      "country": "USA",
      "color": "red",
      "grape_varieties": [
        {"name": "Cabernet Sauvignon", "percentage": 84},
        {"name": "Merlot", "percentage": 6},
        {"name": "Cabernet Franc", "percentage": 6},
        {"name": "Petit Verdot", "percentage": 3},
        {"name": "Malbec", "percentage": 1}
      ],
      "alcohol": 14.5,
      "score": 97,
      "tasting_note": "Powerful and polished, with a gorgeous core of black currant, violet and dark chocolate flavors that are layered with singed alder, roasted coffee bean and warm stone notes. The finish extends, delivering echoes of dark fruit and spice as the fine-grained tannins clamp down. Cabernet Sauvignon, Merlot, Cabernet Franc, Petit Verdot and Malbec. Best from 2024 through 2045.",
      "reviewer": {
        "initials": "JL",
        "name": "James Laube"
      },
      "review_date": "2022-03-15",
      "issue_date": "2022-04-30",
      "drink_window": {
        "start": 2024,
        "end": 2045,
        "display": "2024-2045",
        "status": "ready"
      },
      "pricing": {
        "release_price": 425.00,
        "release_date": "2022-02-01",
        "currency": "USD"
      },
      "producer_info": {
        "id": "producer_opusone",
        "name": "Opus One Winery",
        "website": "https://www.opusonewinery.com"
      }
    },
    "related_vintages": [
      {"vintage": 2018, "score": 98, "id": "wine_abc122"},
      {"vintage": 2017, "score": 96, "id": "wine_abc121"},
      {"vintage": 2020, "score": 96, "id": "wine_abc124"}
    ]
  }
}
```

---

#### Get Wine Reviews
Retrieve all reviews for a wine (across vintages).

```http
GET /wines/{wine_id}/reviews
```

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `include_other_vintages` | boolean | No | Include reviews of other vintages |

**Response:**
```json
{
  "success": true,
  "data": {
    "reviews": [
      {
        "id": "review_xyz789",
        "wine_id": "wine_abc123",
        "score": 97,
        "tasting_note": "Powerful and polished...",
        "reviewer_initials": "JL",
        "review_date": "2022-03-15",
        "issue_date": "2022-04-30"
      }
    ]
  }
}
```

---

### User Management

#### Register User
Create a new user account.

```http
POST /auth/register
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123!",
  "first_name": "John",
  "last_name": "Doe",
  "marketing_consent": true
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "user_abc123",
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "subscription_tier": "free",
      "created_at": "2024-01-15T10:30:00Z"
    },
    "tokens": {
      "access_token": "eyJhbGciOiJSUzI1NiIs...",
      "refresh_token": "rt_xxxxxxxxxx",
      "expires_in": 86400
    }
  }
}
```

---

#### Login
Authenticate an existing user.

```http
POST /auth/login
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123!"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "user_abc123",
      "email": "user@example.com",
      "subscription_tier": "premium",
      "subscription_expires": "2025-01-15T00:00:00Z"
    },
    "tokens": {
      "access_token": "eyJhbGciOiJSUzI1NiIs...",
      "refresh_token": "rt_xxxxxxxxxx",
      "expires_in": 86400
    }
  }
}
```

---

#### Sign in with Apple
Authenticate using Apple ID.

```http
POST /auth/apple
```

**Request Body:**
```json
{
  "identity_token": "eyJraWQiOiJXNldjT0...",
  "authorization_code": "abc123...",
  "user": {
    "email": "user@privaterelay.appleid.com",
    "name": {
      "firstName": "John",
      "lastName": "Doe"
    }
  }
}
```

---

#### Refresh Token
Get new access token using refresh token.

```http
POST /auth/refresh
```

**Request Body:**
```json
{
  "refresh_token": "rt_xxxxxxxxxx"
}
```

---

#### Get Current User
Retrieve authenticated user profile.

```http
GET /users/me
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "user_abc123",
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "subscription": {
        "tier": "premium",
        "status": "active",
        "expires_at": "2025-01-15T00:00:00Z",
        "auto_renew": true,
        "store": "app_store"
      },
      "stats": {
        "wines_saved": 47,
        "scans_this_month": 12,
        "member_since": "2024-01-15"
      },
      "preferences": {
        "preferred_regions": ["Napa Valley", "Burgundy"],
        "min_score_filter": 85,
        "notification_enabled": true
      }
    }
  }
}
```

---

### Saved Wines

#### Get Saved Wines
Retrieve user's saved wine list.

```http
GET /users/me/wines
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `sort` | string | Sort by: `date_added`, `score`, `producer`, `name` |
| `order` | string | `asc` or `desc` |
| `limit` | integer | Results per page (default: 20) |
| `offset` | integer | Pagination offset |

**Response:**
```json
{
  "success": true,
  "data": {
    "wines": [
      {
        "saved_id": "saved_xyz123",
        "wine": {
          "id": "wine_abc123",
          "producer": "Opus One",
          "name": "Opus One",
          "vintage": 2019,
          "score": 97
        },
        "added_at": "2024-02-20T14:30:00Z",
        "notes": "Had this at Michael's birthday dinner",
        "context": {
          "restaurant": "The French Laundry",
          "price_paid": 650.00
        }
      }
    ],
    "total_count": 47
  }
}
```

---

#### Save a Wine
Add wine to user's saved list.

```http
POST /users/me/wines
```

**Request Body:**
```json
{
  "wine_id": "wine_abc123",
  "notes": "Had this at Michael's birthday dinner",
  "context": {
    "restaurant": "The French Laundry",
    "price_paid": 650.00,
    "date": "2024-02-20"
  }
}
```

---

#### Remove Saved Wine
```http
DELETE /users/me/wines/{saved_id}
```

---

### Subscription Management

#### Verify Subscription
Verify App Store/Play Store subscription status.

```http
POST /subscriptions/verify
```

**Request Body (App Store):**
```json
{
  "store": "app_store",
  "receipt_data": "MIIT...",
  "transaction_id": "123456789"
}
```

**Request Body (Play Store):**
```json
{
  "store": "play_store",
  "purchase_token": "xxxxx",
  "subscription_id": "premium_yearly"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "subscription": {
      "tier": "premium",
      "status": "active",
      "product_id": "com.winespectator.wla.premium.yearly",
      "expires_at": "2025-01-15T00:00:00Z",
      "auto_renew": true,
      "trial": false
    }
  }
}
```

---

### B2B: List Analysis

#### Analyze Wine List
Upload and analyze a complete wine list (B2B only).

```http
POST /business/lists/analyze
```

**Request Body (multipart/form-data):**
```
list_file: [PDF or image file]
restaurant_name: "The French Laundry"
options: {"include_markup_analysis": true, "markup_range": [2.5, 3.5]}
```

**Or JSON with pre-extracted text:**
```json
{
  "wines": [
    {"text": "Opus One 2019", "list_price": 850},
    {"text": "Chateau Margaux 2015", "list_price": 1200}
  ],
  "restaurant_name": "The French Laundry",
  "options": {
    "include_markup_analysis": true,
    "markup_range": [2.5, 3.5],
    "include_drink_window_alerts": true
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "analysis_id": "analysis_abc123",
    "summary": {
      "total_wines": 245,
      "matched_wines": 198,
      "match_rate": 0.808,
      "average_score": 91.2,
      "score_distribution": {
        "95-100": 12,
        "90-94": 89,
        "85-89": 67,
        "80-84": 24,
        "below_80": 6
      }
    },
    "alerts": {
      "past_drink_window": [
        {
          "wine": {"producer": "Some Old Wine", "vintage": 2005},
          "drink_window_end": 2020,
          "severity": "high"
        }
      ],
      "markup_outliers": [
        {
          "wine": {"producer": "Opus One", "vintage": 2019},
          "list_price": 1500,
          "release_price": 425,
          "markup_ratio": 3.53,
          "status": "above_range",
          "suggested_range": [1062.50, 1487.50]
        }
      ]
    },
    "wines": [
      {
        "original_text": "Opus One 2019",
        "matched_wine": {
          "id": "wine_abc123",
          "producer": "Opus One",
          "name": "Opus One",
          "vintage": 2019,
          "score": 97
        },
        "list_price": 850,
        "release_price": 425,
        "markup_ratio": 2.0,
        "markup_status": "in_range",
        "drink_window_status": "ready",
        "value_score": 8.2
      }
    ]
  }
}
```

---

#### Get Replacement Suggestions
Get wine replacement suggestions for out-of-stock items.

```http
POST /business/wines/replacements
```

**Request Body:**
```json
{
  "wine_id": "wine_abc123",
  "constraints": {
    "max_price_increase": 0.1,
    "same_region": true,
    "min_score": 90
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "original_wine": {
      "id": "wine_abc123",
      "producer": "Opus One",
      "name": "Opus One",
      "vintage": 2019,
      "score": 97,
      "release_price": 425
    },
    "suggestions": [
      {
        "wine": {
          "id": "wine_abc124",
          "producer": "Opus One",
          "name": "Opus One",
          "vintage": 2020,
          "score": 96,
          "release_price": 450
        },
        "reason": "Same producer, next vintage",
        "similarity_score": 0.95
      },
      {
        "wine": {
          "id": "wine_def456",
          "producer": "Joseph Phelps",
          "name": "Insignia",
          "vintage": 2019,
          "score": 97,
          "release_price": 275
        },
        "reason": "Similar style, same region and score",
        "similarity_score": 0.82
      }
    ]
  }
}
```

---

### Analytics (Internal)

#### Log Scan Event
Record analytics for wine list scan.

```http
POST /analytics/scans
```

**Request Body:**
```json
{
  "event_type": "scan_completed",
  "timestamp": "2024-02-20T14:30:00Z",
  "data": {
    "wines_detected": 15,
    "wines_matched": 12,
    "match_rate": 0.8,
    "processing_time_ms": 450,
    "filters_used": ["score_90_plus"],
    "device_model": "iPhone 15 Pro",
    "ios_version": "17.2"
  }
}
```

---

## Webhooks (B2B)

Business accounts can register webhooks for:

- `list.analyzed` - Wine list analysis completed
- `subscription.renewed` - Subscription renewed
- `subscription.cancelled` - Subscription cancelled

**Webhook Payload:**
```json
{
  "event": "list.analyzed",
  "timestamp": "2024-02-20T14:30:00Z",
  "data": {
    "analysis_id": "analysis_abc123",
    "restaurant_name": "The French Laundry",
    "total_wines": 245,
    "match_rate": 0.808
  },
  "signature": "sha256=xxxxxxx"
}
```

---

## SDK / Client Libraries

### iOS (Swift Package)
```swift
// Package.swift dependency
.package(url: "https://github.com/winespectator/wla-ios-sdk", from: "1.0.0")

// Usage
import WineListAssistantSDK

let client = WLAClient(apiKey: "wla_pk_live_xxx")
let results = try await client.searchWines(query: "Opus One 2019")
```

### Android (Kotlin)
```kotlin
// build.gradle
implementation("com.winespectator:wla-sdk:1.0.0")

// Usage
val client = WLAClient.Builder()
    .apiKey("wla_pk_live_xxx")
    .build()

val results = client.searchWines("Opus One 2019")
```

---

## Changelog

### v1.0.0 (Launch)
- Initial API release
- Wine search and matching
- User authentication
- Saved wines
- Subscription management

### v1.1.0 (Planned)
- B2B list analysis
- Replacement suggestions
- Webhook support

---

*API Version: 1.0*
*Last Updated: December 2024*
