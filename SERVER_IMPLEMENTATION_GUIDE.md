# ClassFlow Server Implementation Guide

Complete guide for building a cloud sync server for ClassFlow using TypeScript and Express.

## Table of Contents

1. [Overview](#overview)
2. [Technology Stack](#technology-stack)
3. [Database Schema](#database-schema)
4. [API Endpoints](#api-endpoints)
5. [Authentication & Security](#authentication--security)
6. [Sync Algorithm](#sync-algorithm)
7. [Setup Instructions](#setup-instructions)
8. [Environment Variables](#environment-variables)
9. [Deployment](#deployment)

---

## Overview

The ClassFlow server provides cloud sync capabilities, user authentication, and data storage for the ClassFlow mobile/desktop app. It follows a RESTful API design with JWT authentication and supports offline-first synchronization.

### Key Features

- User registration and authentication with JWT
- Two-factor authentication (2FA) via TOTP
- Email verification and password reset
- Cloud storage for subjects, books, lessons, and timetables
- Conflict-free data synchronization
- Server selection (official or self-hosted)
- Account management (password change, email update, 2FA)

---

## Technology Stack

```json
{
  "runtime": "Node.js 20+",
  "language": "TypeScript",
  "framework": "Express.js",
  "database": "PostgreSQL",
  "authentication": "JWT (jsonwebtoken)",
  "2fa": "speakeasy (TOTP)",
  "email": "nodemailer",
  "validation": "joi",
  "encryption": "bcrypt",
  "logging": "winston",
  "rate-limiting": "express-rate-limit"
}
```

### NPM Dependencies

```bash
npm install express typescript @types/express
npm install pg typeorm reflect-metadata
npm install jsonwebtoken @types/jsonwebtoken
npm install bcrypt @types/bcrypt
npm install speakeasy @types/speakeasy
npm install qrcode @types/qrcode
npm install nodemailer @types/nodemailer
npm install joi
npm install dotenv
npm install winston
npm install express-rate-limit
npm install helmet
npm install cors
npm install uuid @types/uuid

# Dev dependencies
npm install -D ts-node nodemon @types/node
```

---

## Database Schema

### PostgreSQL Tables

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    verification_token VARCHAR(255),
    reset_token VARCHAR(255),
    reset_token_expires TIMESTAMP,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- User settings table
CREATE TABLE user_settings (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    auto_sync BOOLEAN DEFAULT TRUE,
    sync_interval INTEGER DEFAULT 15, -- minutes
    theme VARCHAR(50) DEFAULT 'system',
    notifications_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Subjects table
CREATE TABLE subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    local_id INTEGER, -- Client-side ID for reference
    name VARCHAR(100) NOT NULL,
    color_value INTEGER,
    book_ids JSONB DEFAULT '[]', -- Array of book IDs
    version INTEGER DEFAULT 1,
    deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Books table
CREATE TABLE books (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES subjects(id) ON DELETE CASCADE,
    local_id INTEGER,
    book_id INTEGER NOT NULL, -- QR code book number
    version INTEGER DEFAULT 1,
    deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Lessons table
CREATE TABLE lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES subjects(id) ON DELETE CASCADE,
    local_id INTEGER,
    day_of_week INTEGER NOT NULL, -- 1-7 (Monday-Sunday)
    start_hour INTEGER NOT NULL,
    start_minute INTEGER NOT NULL,
    end_hour INTEGER NOT NULL,
    end_minute INTEGER NOT NULL,
    notes TEXT,
    status VARCHAR(50) DEFAULT 'normal', -- normal, cancelled, modified, rescheduled
    version INTEGER DEFAULT 1,
    deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Special lessons table (one-time events)
CREATE TABLE special_lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES subjects(id) ON DELETE CASCADE,
    local_id INTEGER,
    date DATE NOT NULL,
    start_hour INTEGER NOT NULL,
    start_minute INTEGER NOT NULL,
    end_hour INTEGER NOT NULL,
    end_minute INTEGER NOT NULL,
    notes TEXT,
    status VARCHAR(50) DEFAULT 'normal',
    version INTEGER DEFAULT 1,
    deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sync log table (for conflict resolution)
CREATE TABLE sync_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(255),
    entity_type VARCHAR(50), -- subject, book, lesson, special_lesson
    entity_id UUID,
    action VARCHAR(50), -- create, update, delete
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data JSONB
);

-- Create indexes
CREATE INDEX idx_subjects_user_id ON subjects(user_id);
CREATE INDEX idx_books_user_id ON books(user_id);
CREATE INDEX idx_lessons_user_id ON lessons(user_id);
CREATE INDEX idx_special_lessons_user_id ON special_lessons(user_id);
CREATE INDEX idx_sync_log_user_id ON sync_log(user_id);
CREATE INDEX idx_sync_log_timestamp ON sync_log(timestamp);
```

---

## API Endpoints

### Base URL

```
https://api.classflow.app/api
```

All endpoints are prefixed with `/api`. Example: `POST /api/auth/register`

---

### Authentication Endpoints

#### 1. Register User

```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "User registered successfully. Please verify your email.",
  "userId": "uuid-here"
}
```

#### 2. Verify Email

```http
POST /api/auth/verify-email
Content-Type: application/json

{
  "token": "verification-token-from-email"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Email verified successfully"
}
```

#### 3. Login

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```

**Response (200):**
```json
{
  "success": true,
  "token": "jwt-token-here",
  "refreshToken": "refresh-token-here",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "emailVerified": true,
    "twoFactorEnabled": false
  }
}
```

**With 2FA Enabled (200):**
```json
{
  "success": true,
  "requiresTwoFactor": true,
  "tempToken": "temporary-token-for-2fa"
}
```

#### 4. Verify 2FA Code

```http
POST /api/auth/verify-2fa
Content-Type: application/json
Authorization: Bearer {tempToken}

{
  "code": "123456"
}
```

**Response (200):**
```json
{
  "success": true,
  "token": "jwt-token-here",
  "refreshToken": "refresh-token-here"
}
```

#### 5. Request Password Reset

```http
POST /api/auth/forgot-password
Content-Type: application/json

{
  "email": "user@example.com"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Password reset email sent"
}
```

#### 6. Reset Password

```http
POST /api/auth/reset-password
Content-Type: application/json

{
  "token": "reset-token-from-email",
  "newPassword": "NewSecurePassword123!"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Password reset successfully"
}
```

#### 7. Refresh Token

```http
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "refresh-token-here"
}
```

**Response (200):**
```json
{
  "success": true,
  "token": "new-jwt-token",
  "refreshToken": "new-refresh-token"
}
```

#### 8. Logout

```http
POST /api/auth/logout
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

### Account Management Endpoints

#### 1. Get Account Info

```http
GET /api/account/info
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "emailVerified": true,
    "twoFactorEnabled": false,
    "createdAt": "2025-01-01T00:00:00Z",
    "lastLogin": "2025-11-30T12:00:00Z"
  },
  "settings": {
    "autoSync": true,
    "syncInterval": 15,
    "theme": "dark",
    "notificationsEnabled": true
  }
}
```

#### 2. Update Email

```http
PUT /api/account/email
Authorization: Bearer {token}
Content-Type: application/json

{
  "newEmail": "newemail@example.com",
  "password": "CurrentPassword123!"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Verification email sent to new address"
}
```

#### 3. Change Password

```http
PUT /api/account/password
Authorization: Bearer {token}
Content-Type: application/json

{
  "currentPassword": "OldPassword123!",
  "newPassword": "NewPassword123!"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

#### 4. Enable 2FA

```http
POST /api/account/2fa/enable
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "secret": "base32-secret-here",
  "qrCode": "data:image/png;base64,...",
  "backupCodes": [
    "12345678",
    "23456789",
    "34567890"
  ]
}
```

#### 5. Verify and Activate 2FA

```http
POST /api/account/2fa/verify
Authorization: Bearer {token}
Content-Type: application/json

{
  "code": "123456"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "2FA enabled successfully"
}
```

#### 6. Disable 2FA

```http
POST /api/account/2fa/disable
Authorization: Bearer {token}
Content-Type: application/json

{
  "password": "CurrentPassword123!",
  "code": "123456"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "2FA disabled successfully"
}
```

#### 7. Update Settings

```http
PUT /api/account/settings
Authorization: Bearer {token}
Content-Type: application/json

{
  "autoSync": true,
  "syncInterval": 30,
  "theme": "dark",
  "notificationsEnabled": true
}
```

**Response (200):**
```json
{
  "success": true,
  "settings": {
    "autoSync": true,
    "syncInterval": 30,
    "theme": "dark",
    "notificationsEnabled": true
  }
}
```

#### 8. Delete Account

```http
DELETE /api/account
Authorization: Bearer {token}
Content-Type: application/json

{
  "password": "CurrentPassword123!",
  "confirmation": "DELETE MY ACCOUNT"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Account deleted successfully"
}
```

---

### Sync Endpoints

#### 1. Get All Data (Initial Sync)

```http
GET /api/sync/data
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "lastSync": "2025-11-30T12:00:00Z",
  "data": {
    "subjects": [
      {
        "id": "uuid",
        "localId": 1,
        "name": "MATHEMATICS",
        "colorValue": 4280391411,
        "bookIds": [1, 2, 3],
        "version": 1,
        "deleted": false,
        "updatedAt": "2025-11-30T10:00:00Z"
      }
    ],
    "books": [
      {
        "id": "uuid",
        "subjectId": "subject-uuid",
        "localId": 1,
        "bookId": 1,
        "version": 1,
        "deleted": false,
        "updatedAt": "2025-11-30T10:00:00Z"
      }
    ],
    "lessons": [
      {
        "id": "uuid",
        "subjectId": "subject-uuid",
        "localId": 1,
        "dayOfWeek": 1,
        "startHour": 9,
        "startMinute": 0,
        "endHour": 10,
        "endMinute": 0,
        "notes": "Bring textbook",
        "status": "normal",
        "version": 1,
        "deleted": false,
        "updatedAt": "2025-11-30T10:00:00Z"
      }
    ],
    "specialLessons": []
  }
}
```

#### 2. Push Changes (Incremental Sync)

```http
POST /api/sync/push
Authorization: Bearer {token}
Content-Type: application/json

{
  "deviceId": "device-uuid",
  "lastSync": "2025-11-30T11:00:00Z",
  "changes": {
    "subjects": {
      "created": [
        {
          "localId": 2,
          "name": "ENGLISH",
          "colorValue": 4286141768,
          "bookIds": [],
          "version": 1
        }
      ],
      "updated": [
        {
          "id": "uuid",
          "localId": 1,
          "name": "MATHEMATICS ADVANCED",
          "colorValue": 4280391411,
          "bookIds": [1, 2, 3, 4],
          "version": 2
        }
      ],
      "deleted": ["uuid-of-deleted-subject"]
    },
    "books": {
      "created": [],
      "updated": [],
      "deleted": []
    },
    "lessons": {
      "created": [],
      "updated": [],
      "deleted": []
    },
    "specialLessons": {
      "created": [],
      "updated": [],
      "deleted": []
    }
  }
}
```

**Response (200):**
```json
{
  "success": true,
  "synced": {
    "subjects": {
      "created": [
        {
          "localId": 2,
          "serverId": "new-uuid",
          "version": 1
        }
      ],
      "updated": [
        {
          "localId": 1,
          "serverId": "uuid",
          "version": 2
        }
      ],
      "deleted": ["uuid"]
    },
    "books": {},
    "lessons": {},
    "specialLessons": {}
  },
  "conflicts": [],
  "serverTime": "2025-11-30T12:00:00Z"
}
```

#### 3. Pull Changes (Get Updates)

```http
POST /api/sync/pull
Authorization: Bearer {token}
Content-Type: application/json

{
  "lastSync": "2025-11-30T11:00:00Z"
}
```

**Response (200):**
```json
{
  "success": true,
  "changes": {
    "subjects": {
      "created": [],
      "updated": [
        {
          "id": "uuid",
          "localId": 1,
          "name": "MATHEMATICS",
          "colorValue": 4280391411,
          "bookIds": [1, 2, 3],
          "version": 3,
          "updatedAt": "2025-11-30T11:30:00Z"
        }
      ],
      "deleted": []
    },
    "books": {},
    "lessons": {},
    "specialLessons": {}
  },
  "serverTime": "2025-11-30T12:00:00Z"
}
```

#### 4. Resolve Conflicts

```http
POST /api/sync/resolve-conflict
Authorization: Bearer {token}
Content-Type: application/json

{
  "entityType": "subject",
  "entityId": "uuid",
  "resolution": "server" | "client",
  "clientData": {
    // Full entity data if resolution is "client"
  }
}
```

**Response (200):**
```json
{
  "success": true,
  "resolved": {
    "id": "uuid",
    "version": 4,
    "data": {
      // Resolved entity data
    }
  }
}
```

---

### Server Info Endpoints

#### 1. Get Server Info

```http
GET /api/info
```

**Response (200):**
```json
{
  "name": "ClassFlow Official Server",
  "version": "1.0.0",
  "apiVersion": "v1",
  "features": {
    "registration": true,
    "emailVerification": true,
    "twoFactorAuth": true,
    "cloudSync": true
  },
  "limits": {
    "maxSubjects": 100,
    "maxBooks": 1000,
    "maxLessons": 500,
    "storageMB": 100
  },
  "status": "online"
}
```

#### 2. Health Check

```http
GET /api/health
```

**Response (200):**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-30T12:00:00Z",
  "database": "connected",
  "uptime": 86400
}
```

---

## Authentication & Security

### JWT Implementation

```typescript
// Token payload structure
interface JWTPayload {
  userId: string;
  email: string;
  iat: number; // Issued at
  exp: number; // Expiration
}

// Token configuration
const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = '7d'; // Access token
const REFRESH_TOKEN_EXPIRES_IN = '30d';

// Generate tokens
import jwt from 'jsonwebtoken';

function generateAccessToken(userId: string, email: string): string {
  return jwt.sign({ userId, email }, JWT_SECRET, {
    expiresIn: JWT_EXPIRES_IN
  });
}

function generateRefreshToken(userId: string): string {
  return jwt.sign({ userId }, JWT_SECRET, {
    expiresIn: REFRESH_TOKEN_EXPIRES_IN
  });
}

// Verify token middleware
import { Request, Response, NextFunction } from 'express';

interface AuthRequest extends Request {
  userId?: string;
  email?: string;
}

async function authenticate(
  req: AuthRequest,
  res: Response,
  next: NextFunction
) {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required'
      });
    }

    const decoded = jwt.verify(token, JWT_SECRET) as JWTPayload;
    req.userId = decoded.userId;
    req.email = decoded.email;
    
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      error: 'Invalid or expired token'
    });
  }
}
```

### Password Hashing

```typescript
import bcrypt from 'bcrypt';

const SALT_ROUNDS = 12;

async function hashPassword(password: string): Promise<string> {
  return await bcrypt.hash(password, SALT_ROUNDS);
}

async function verifyPassword(
  password: string,
  hash: string
): Promise<boolean> {
  return await bcrypt.compare(password, hash);
}

// Password validation
function validatePassword(password: string): boolean {
  // At least 8 characters, 1 uppercase, 1 lowercase, 1 number, 1 special char
  const regex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
  return regex.test(password);
}
```

### Two-Factor Authentication (2FA)

```typescript
import speakeasy from 'speakeasy';
import QRCode from 'qrcode';

// Generate 2FA secret
async function generate2FASecret(email: string) {
  const secret = speakeasy.generateSecret({
    name: `ClassFlow (${email})`,
    issuer: 'ClassFlow'
  });

  // Generate QR code
  const qrCodeDataUrl = await QRCode.toDataURL(secret.otpauth_url!);

  // Generate backup codes
  const backupCodes = Array.from({ length: 8 }, () =>
    Math.random().toString(36).substring(2, 10).toUpperCase()
  );

  return {
    secret: secret.base32,
    qrCode: qrCodeDataUrl,
    backupCodes
  };
}

// Verify 2FA code
function verify2FACode(secret: string, code: string): boolean {
  return speakeasy.totp.verify({
    secret,
    encoding: 'base32',
    token: code,
    window: 2 // Allow 2 time steps before/after
  });
}
```

### Rate Limiting

```typescript
import rateLimit from 'express-rate-limit';

// General API rate limiter
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Max 100 requests per window
  message: 'Too many requests, please try again later'
});

// Auth endpoints rate limiter
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // Max 5 login attempts per window
  message: 'Too many login attempts, please try again later'
});

// Apply to routes
app.use('/api/', apiLimiter);
app.use('/api/auth/login', authLimiter);
app.use('/api/auth/register', authLimiter);
```

### Security Headers

```typescript
import helmet from 'helmet';
import cors from 'cors';

// Security headers
app.use(helmet());

// CORS configuration
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
```

---

## Sync Algorithm

### Conflict-Free Synchronization

The sync algorithm uses **vector clocks** and **last-write-wins** strategy with version numbers.

#### Key Principles

1. **Version Numbers**: Each entity has a version number that increments on every update
2. **Timestamps**: Track `updatedAt` for each change
3. **Soft Deletes**: Use `deleted` flag instead of hard deletes
4. **Device Tracking**: Each sync includes `deviceId` to track origin
5. **Change Log**: Server maintains a log of all changes for conflict resolution

#### Sync Flow

```typescript
// Client sync flow
async function syncWithServer() {
  const lastSync = getLastSyncTimestamp();
  
  // 1. Push local changes to server
  const localChanges = getLocalChangesSince(lastSync);
  const pushResponse = await pushChanges(localChanges);
  
  // 2. Handle conflicts from push
  if (pushResponse.conflicts.length > 0) {
    await resolveConflicts(pushResponse.conflicts);
  }
  
  // 3. Pull server changes
  const pullResponse = await pullChanges(lastSync);
  
  // 4. Apply server changes locally
  await applyServerChanges(pullResponse.changes);
  
  // 5. Update last sync timestamp
  setLastSyncTimestamp(pullResponse.serverTime);
}
```

#### Conflict Resolution

```typescript
interface Conflict {
  entityType: 'subject' | 'book' | 'lesson' | 'special_lesson';
  entityId: string;
  localVersion: number;
  serverVersion: number;
  localData: any;
  serverData: any;
  localUpdatedAt: string;
  serverUpdatedAt: string;
}

function detectConflict(
  localEntity: any,
  serverEntity: any
): Conflict | null {
  // No conflict if versions match
  if (localEntity.version === serverEntity.version) {
    return null;
  }
  
  // Conflict if both were modified since last sync
  if (
    localEntity.updatedAt > localEntity.syncedAt &&
    serverEntity.updatedAt > localEntity.syncedAt
  ) {
    return {
      entityType: localEntity.type,
      entityId: localEntity.id,
      localVersion: localEntity.version,
      serverVersion: serverEntity.version,
      localData: localEntity,
      serverData: serverEntity,
      localUpdatedAt: localEntity.updatedAt,
      serverUpdatedAt: serverEntity.updatedAt
    };
  }
  
  return null;
}

// Resolution strategies
enum ResolutionStrategy {
  SERVER_WINS = 'server', // Use server version
  CLIENT_WINS = 'client', // Use client version
  LATEST_WINS = 'latest', // Use most recent timestamp
  MERGE = 'merge' // Merge both (for specific fields)
}

async function resolveConflict(
  conflict: Conflict,
  strategy: ResolutionStrategy
): Promise<any> {
  switch (strategy) {
    case ResolutionStrategy.SERVER_WINS:
      return conflict.serverData;
      
    case ResolutionStrategy.CLIENT_WINS:
      return conflict.localData;
      
    case ResolutionStrategy.LATEST_WINS:
      return new Date(conflict.localUpdatedAt) > new Date(conflict.serverUpdatedAt)
        ? conflict.localData
        : conflict.serverData;
        
    case ResolutionStrategy.MERGE:
      // Custom merge logic based on entity type
      return mergeEntities(conflict.localData, conflict.serverData);
  }
}
```

---

## Setup Instructions

### 1. Initialize Project

```bash
mkdir classflow-server
cd classflow-server
npm init -y
npm install [dependencies from Technology Stack section]
```

### 2. Project Structure

```
classflow-server/
├── src/
│   ├── index.ts                 # Entry point
│   ├── config/
│   │   ├── database.ts          # Database configuration
│   │   └── email.ts             # Email configuration
│   ├── middleware/
│   │   ├── auth.ts              # Authentication middleware
│   │   ├── validation.ts        # Request validation
│   │   └── errorHandler.ts     # Error handling
│   ├── routes/
│   │   ├── auth.routes.ts       # Auth endpoints
│   │   ├── account.routes.ts   # Account management
│   │   ├── sync.routes.ts       # Sync endpoints
│   │   └── info.routes.ts       # Server info
│   ├── controllers/
│   │   ├── auth.controller.ts
│   │   ├── account.controller.ts
│   │   ├── sync.controller.ts
│   │   └── info.controller.ts
│   ├── services/
│   │   ├── auth.service.ts
│   │   ├── email.service.ts
│   │   ├── sync.service.ts
│   │   └── conflict.service.ts
│   ├── models/
│   │   ├── User.ts
│   │   ├── Subject.ts
│   │   ├── Book.ts
│   │   ├── Lesson.ts
│   │   └── SpecialLesson.ts
│   └── utils/
│       ├── logger.ts
│       ├── validation.ts
│       └── crypto.ts
├── .env
├── .env.example
├── tsconfig.json
├── package.json
└── README.md
```

### 3. TypeScript Configuration

Create `tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "moduleResolution": "node",
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### 4. Entry Point (`src/index.ts`)

```typescript
import express, { Application } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import dotenv from 'dotenv';
import { createConnection } from 'typeorm';
import authRoutes from './routes/auth.routes';
import accountRoutes from './routes/account.routes';
import syncRoutes from './routes/sync.routes';
import infoRoutes from './routes/info.routes';
import { errorHandler } from './middleware/errorHandler';
import { logger } from './utils/logger';

dotenv.config();

const app: Application = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(','),
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/account', accountRoutes);
app.use('/api/sync', syncRoutes);
app.use('/api', infoRoutes);

// Error handler
app.use(errorHandler);

// Database connection and server start
async function start() {
  try {
    await createConnection({
      type: 'postgres',
      host: process.env.DB_HOST,
      port: parseInt(process.env.DB_PORT || '5432'),
      username: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      entities: ['src/models/**/*.ts'],
      synchronize: process.env.NODE_ENV === 'development',
      logging: process.env.NODE_ENV === 'development'
    });

    logger.info('Database connected');

    app.listen(PORT, () => {
      logger.info(`Server running on port ${PORT}`);
      logger.info(`Environment: ${process.env.NODE_ENV}`);
    });
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
}

start();
```

### 5. Package Scripts

Add to `package.json`:

```json
{
  "scripts": {
    "dev": "nodemon --exec ts-node src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "migrate": "ts-node src/migrations/run.ts",
    "test": "jest"
  }
}
```

---

## Environment Variables

Create `.env.example`:

```env
# Server Configuration
NODE_ENV=development
PORT=3000
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=classflow
DB_PASSWORD=your_secure_password
DB_NAME=classflow_db

# JWT
JWT_SECRET=your_jwt_secret_key_minimum_32_characters
JWT_EXPIRES_IN=7d
REFRESH_TOKEN_EXPIRES_IN=30d

# Email (SMTP)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your_email@gmail.com
SMTP_PASSWORD=your_app_specific_password
EMAIL_FROM=ClassFlow <noreply@classflow.app>

# URLs
API_BASE_URL=https://api.classflow.app
CLIENT_BASE_URL=https://classflow.app

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Security
BCRYPT_ROUNDS=12
```

Copy to `.env` and fill in real values:

```bash
cp .env.example .env
```

---

## Deployment

### Option 1: Docker Deployment

Create `Dockerfile`:

```dockerfile
FROM node:20-alpine

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy source
COPY . .

# Build TypeScript
RUN npm run build

# Expose port
EXPOSE 3000

# Start server
CMD ["npm", "start"]
```

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: classflow_db
      POSTGRES_USER: classflow
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped

  api:
    build: .
    environment:
      NODE_ENV: production
      DB_HOST: postgres
      DB_PORT: 5432
      DB_USER: classflow
      DB_PASSWORD: ${DB_PASSWORD}
      DB_NAME: classflow_db
      JWT_SECRET: ${JWT_SECRET}
      SMTP_HOST: ${SMTP_HOST}
      SMTP_PORT: ${SMTP_PORT}
      SMTP_USER: ${SMTP_USER}
      SMTP_PASSWORD: ${SMTP_PASSWORD}
    ports:
      - "3000:3000"
    depends_on:
      - postgres
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./certs:/etc/nginx/certs
    depends_on:
      - api
    restart: unless-stopped

volumes:
  postgres_data:
```

Deploy:

```bash
docker-compose up -d
```

### Option 2: Cloud Platforms

#### Heroku

```bash
heroku create classflow-api
heroku addons:create heroku-postgresql:hobby-dev
heroku config:set JWT_SECRET=your_secret
git push heroku main
```

#### Railway

```bash
railway init
railway add postgresql
railway up
```

#### DigitalOcean App Platform

1. Create app from GitHub repo
2. Add PostgreSQL database
3. Set environment variables
4. Deploy

### Option 3: VPS (Ubuntu)

```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PostgreSQL
sudo apt-get install postgresql postgresql-contrib

# Clone repository
git clone https://github.com/yourusername/classflow-server
cd classflow-server

# Install dependencies
npm install

# Build
npm run build

# Setup systemd service
sudo nano /etc/systemd/system/classflow.service
```

Create systemd service:

```ini
[Unit]
Description=ClassFlow API Server
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/classflow-server
ExecStart=/usr/bin/node dist/index.js
Restart=on-failure
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl enable classflow
sudo systemctl start classflow
```

### Nginx Reverse Proxy

```nginx
server {
    listen 80;
    server_name api.classflow.app;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable SSL with Let's Encrypt:

```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d api.classflow.app
```

---

## Testing

### Example API Tests

```typescript
// test/auth.test.ts
import request from 'supertest';
import app from '../src/index';

describe('Authentication', () => {
  it('should register a new user', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'test@example.com',
        password: 'TestPassword123!'
      });

    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);
  });

  it('should login with valid credentials', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'test@example.com',
        password: 'TestPassword123!'
      });

    expect(response.status).toBe(200);
    expect(response.body.token).toBeDefined();
  });
});
```

Run tests:

```bash
npm test
```

---

## Monitoring & Logging

### Winston Logger Setup

```typescript
// src/utils/logger.ts
import winston from 'winston';

export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' })
  ]
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.combine(
      winston.format.colorize(),
      winston.format.simple()
    )
  }));
}
```

---

## Additional Resources

### Email Templates

Located in `src/templates/`:

- `verify-email.html` - Email verification template
- `reset-password.html` - Password reset template
- `2fa-enabled.html` - 2FA activation notification
- `account-deleted.html` - Account deletion confirmation

### API Documentation

Use Swagger/OpenAPI for interactive API docs:

```typescript
import swaggerUi from 'swagger-ui-express';
import swaggerDocument from './swagger.json';

app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
```

### Performance Optimization

- Enable Redis caching for frequently accessed data
- Use database connection pooling
- Implement request compression with `compression` middleware
- Add database indexes for query optimization
- Use CDN for static assets

---

## Support & Maintenance

### Backup Strategy

Daily automated backups of PostgreSQL:

```bash
# Backup script
pg_dump -U classflow classflow_db > backup_$(date +%Y%m%d).sql

# Restore
psql -U classflow classflow_db < backup_20251130.sql
```

### Monitoring

Recommended tools:
- **Uptime monitoring**: UptimeRobot, Pingdom
- **Application monitoring**: New Relic, DataDog
- **Error tracking**: Sentry
- **Log aggregation**: Loggly, Papertrail

---

## Conclusion

This guide provides everything needed to implement a production-ready cloud sync server for ClassFlow. The implementation follows industry best practices for security, scalability, and maintainability.

For questions or support, contact the development team or open an issue on GitHub.

**Happy coding! 🚀**
