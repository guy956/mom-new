/**
 * MOMIT Secure API Server
 * Security fixes implemented:
 * 1. Rate limiting on auth endpoints
 * 2. Helmet.js security headers
 * 3. Secure CORS configuration
 * 4. Secure cookie settings (httpOnly, secure, SameSite)
 * 5. XSS protection
 * 6. CSRF protection
 * 7. Input sanitization
 */

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const slowDown = require('express-slow-down');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const cookieParser = require('cookie-parser');
const csrf = require('csurf');
const hpp = require('hpp');
const xss = require('xss-clean');
const mongoSanitize = require('mongo-sanitize');
const crypto = require('crypto');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// ===============================
// SECURITY CONFIGURATION
// ===============================

// 1. HELMET - Security headers
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'"],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"],
    },
  },
  crossOriginEmbedderPolicy: false,
  hsts: {
    maxAge: 31536000, // 1 year
    includeSubDomains: true,
    preload: true
  },
  referrerPolicy: {
    policy: "strict-origin-when-cross-origin"
  },
  hidePoweredBy: true,
  ieNoOpen: true,
  noSniff: true,
  originAgentCluster: true,
  dnsPrefetchControl: { allow: false },
  permittedCrossDomainPolicies: { permittedPolicies: 'none' },
  xssFilter: true,
}));

// 2. CORS - Secure configuration
const corsOptions = {
  origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : ['https://momit.app', 'https://www.momit.app'],
  credentials: true, // Allow cookies
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-CSRF-Token'],
  exposedHeaders: ['X-CSRF-Token'],
  maxAge: 86400, // 24 hours
  preflightContinue: false,
  optionsSuccessStatus: 204
};
app.use(cors(corsOptions));

// 3. Body parsing with size limits
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: true, limit: '10kb' }));
app.use(cookieParser());

// 4. Data sanitization against XSS
app.use(xss());

// 5. Prevent parameter pollution
app.use(hpp());

// 6. MongoDB sanitization middleware
app.use((req, res, next) => {
  if (req.body) {
    req.body = mongoSanitize(req.body);
  }
  if (req.query) {
    req.query = mongoSanitize(req.query);
  }
  if (req.params) {
    req.params = mongoSanitize(req.params);
  }
  next();
});

// ===============================
// RATE LIMITING
// ===============================

// General API rate limiter
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: {
    status: 'error',
    message: 'Too many requests from this IP, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: false,
});
app.use('/api/', generalLimiter);

// Strict rate limiter for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts per 15 minutes
  skipSuccessfulRequests: true,
  message: {
    status: 'error',
    message: 'Too many authentication attempts. Please try again after 15 minutes.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Speed limiter - slows down responses after certain threshold
const speedLimiter = slowDown({
  windowMs: 15 * 60 * 1000, // 15 minutes
  delayAfter: 10, // allow 10 requests at full speed
  delayMs: (used, req) => {
    const delayAfter = req.slowDown.limit;
    return (used - delayAfter) * 500; // add 500ms delay per request after delayAfter
  },
});

// Apply strict rate limiting to auth endpoints
app.use('/api/auth/login', authLimiter);
app.use('/api/auth/register', authLimiter);
app.use('/api/auth/forgot-password', authLimiter);
app.use('/api/auth/reset-password', authLimiter);
app.use('/api/auth/refresh-token', authLimiter);

// ===============================
// CSRF PROTECTION
// ===============================

const csrfProtection = csrf({
  cookie: {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict'
  }
});

// Apply CSRF protection to state-changing routes
app.use('/api/auth/', csrfProtection);
app.use('/api/user/', csrfProtection);

// ===============================
// SECURE JWT CONFIGURATION
// ===============================

// JWT secrets from environment (NOT hardcoded)
const JWT_ACCESS_SECRET = process.env.JWT_ACCESS_SECRET || (() => {
  throw new Error('JWT_ACCESS_SECRET must be set in environment variables');
})();

const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || (() => {
  throw new Error('JWT_REFRESH_SECRET must be set in environment variables');
})();

const JWT_ACCESS_EXPIRY = '15m';
const JWT_REFRESH_EXPIRY = '7d';

// Secure cookie options
const getCookieOptions = (maxAge) => ({
  httpOnly: true, // Prevents XSS attacks
  secure: process.env.NODE_ENV === 'production', // HTTPS only in production
  sameSite: 'strict', // CSRF protection
  maxAge: maxAge,
  path: '/',
  domain: process.env.COOKIE_DOMAIN || undefined
});

// ===============================
// CRYPTO UTILITIES (Replacing Math.random())
// ===============================

/**
 * Generate cryptographically secure random bytes
 * @param {number} length - Number of bytes
 * @returns {Buffer} Random bytes
 */
function generateSecureRandomBytes(length = 32) {
  return crypto.randomBytes(length);
}

/**
 * Generate cryptographically secure random string
 * @param {number} length - Length of string
 * @returns {string} Random hex string
 */
function generateSecureRandomString(length = 32) {
  return crypto.randomBytes(Math.ceil(length / 2)).toString('hex').slice(0, length);
}

/**
 * Generate secure random number between min and max
 * @param {number} min - Minimum value
 * @param {number} max - Maximum value
 * @returns {number} Random number
 */
function generateSecureRandomNumber(min = 0, max = 1) {
  const range = max - min;
  const randomBytes = crypto.randomBytes(4);
  const randomValue = randomBytes.readUInt32LE(0) / 0xFFFFFFFF;
  return min + (randomValue * range);
}

/**
 * Generate secure OTP
 * @param {number} digits - Number of digits
 * @returns {string} OTP code
 */
function generateSecureOTP(digits = 6) {
  const min = Math.pow(10, digits - 1);
  const max = Math.pow(10, digits) - 1;
  const randomBytes = crypto.randomBytes(4);
  const randomValue = randomBytes.readUInt32LE(0) / 0xFFFFFFFF;
  const otp = Math.floor(min + (randomValue * (max - min + 1)));
  return otp.toString().padStart(digits, '0');
}

// ===============================
// JWT UTILITIES
// ===============================

function generateTokens(userId) {
  const accessToken = jwt.sign(
    { userId, type: 'access' },
    JWT_ACCESS_SECRET,
    { expiresIn: JWT_ACCESS_EXPIRY, algorithm: 'HS256' }
  );
  
  const refreshToken = jwt.sign(
    { userId, type: 'refresh', jti: generateSecureRandomString(16) },
    JWT_REFRESH_SECRET,
    { expiresIn: JWT_REFRESH_EXPIRY, algorithm: 'HS256' }
  );
  
  return { accessToken, refreshToken };
}

function verifyAccessToken(token) {
  try {
    return jwt.verify(token, JWT_ACCESS_SECRET, { algorithms: ['HS256'] });
  } catch (error) {
    return null;
  }
}

function verifyRefreshToken(token) {
  try {
    return jwt.verify(token, JWT_REFRESH_SECRET, { algorithms: ['HS256'] });
  } catch (error) {
    return null;
  }
}

// ===============================
// AUTHENTICATION MIDDLEWARE
// ===============================

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN
  
  if (!token) {
    return res.status(401).json({
      status: 'error',
      message: 'Access token required'
    });
  }
  
  const decoded = verifyAccessToken(token);
  if (!decoded) {
    return res.status(403).json({
      status: 'error',
      message: 'Invalid or expired access token'
    });
  }
  
  req.userId = decoded.userId;
  next();
}

// ===============================
// IN-MEMORY USER STORE (Replace with database in production)
// ===============================

const users = new Map();
const refreshTokens = new Map();

// ===============================
// AUTH ROUTES
// ===============================

// Get CSRF token
app.get('/api/auth/csrf-token', csrfProtection, (req, res) => {
  res.json({ csrfToken: req.csrfToken() });
});

// Register
app.post('/api/auth/register', speedLimiter, async (req, res) => {
  try {
    const { email, password, fullName } = req.body;
    
    // Validate input
    if (!email || !password || !fullName) {
      return res.status(400).json({
        status: 'error',
        message: 'Email, password, and full name are required'
      });
    }
    
    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid email format'
      });
    }
    
    // Password validation
    if (password.length < 8) {
      return res.status(400).json({
        status: 'error',
        message: 'Password must be at least 8 characters long'
      });
    }
    
    // Check if user exists
    const emailLower = email.toLowerCase().trim();
    if (users.has(emailLower)) {
      return res.status(409).json({
        status: 'error',
        message: 'User already exists'
      });
    }
    
    // Hash password
    const saltRounds = 12;
    const passwordHash = await bcrypt.hash(password, saltRounds);
    
    // Create user
    const userId = generateSecureRandomString(24);
    const user = {
      id: userId,
      email: emailLower,
      passwordHash,
      fullName,
      createdAt: new Date().toISOString(),
      isAdmin: false
    };
    
    users.set(emailLower, user);
    
    // Generate tokens
    const { accessToken, refreshToken } = generateTokens(userId);
    
    // Store refresh token
    refreshTokens.set(refreshToken, { userId, createdAt: new Date() });
    
    // Set secure cookies
    res.cookie('accessToken', accessToken, getCookieOptions(15 * 60 * 1000)); // 15 minutes
    res.cookie('refreshToken', refreshToken, getCookieOptions(7 * 24 * 60 * 60 * 1000)); // 7 days
    
    res.status(201).json({
      status: 'success',
      message: 'User registered successfully',
      data: {
        userId,
        email: emailLower,
        fullName,
        accessToken,
        csrfToken: req.csrfToken ? req.csrfToken() : null
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Internal server error'
    });
  }
});

// Login
app.post('/api/auth/login', speedLimiter, async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Validate input
    if (!email || !password) {
      return res.status(400).json({
        status: 'error',
        message: 'Email and password are required'
      });
    }
    
    const emailLower = email.toLowerCase().trim();
    const user = users.get(emailLower);
    
    // Check user exists and password
    if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
      return res.status(401).json({
        status: 'error',
        message: 'Invalid email or password'
      });
    }
    
    // Generate tokens
    const { accessToken, refreshToken } = generateTokens(user.id);
    
    // Store refresh token
    refreshTokens.set(refreshToken, { userId: user.id, createdAt: new Date() });
    
    // Set secure cookies
    res.cookie('accessToken', accessToken, getCookieOptions(15 * 60 * 1000));
    res.cookie('refreshToken', refreshToken, getCookieOptions(7 * 24 * 60 * 60 * 1000));
    
    res.json({
      status: 'success',
      message: 'Login successful',
      data: {
        userId: user.id,
        email: user.email,
        fullName: user.fullName,
        isAdmin: user.isAdmin,
        accessToken,
        csrfToken: req.csrfToken ? req.csrfToken() : null
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Internal server error'
    });
  }
});

// Refresh token
app.post('/api/auth/refresh-token', (req, res) => {
  try {
    const refreshToken = req.cookies.refreshToken || req.body.refreshToken;
    
    if (!refreshToken) {
      return res.status(401).json({
        status: 'error',
        message: 'Refresh token required'
      });
    }
    
    // Check if token exists in store
    if (!refreshTokens.has(refreshToken)) {
      return res.status(403).json({
        status: 'error',
        message: 'Invalid refresh token'
      });
    }
    
    const decoded = verifyRefreshToken(refreshToken);
    if (!decoded) {
      refreshTokens.delete(refreshToken);
      return res.status(403).json({
        status: 'error',
        message: 'Invalid or expired refresh token'
      });
    }
    
    // Remove old refresh token
    refreshTokens.delete(refreshToken);
    
    // Generate new tokens
    const { accessToken, refreshToken: newRefreshToken } = generateTokens(decoded.userId);
    
    // Store new refresh token
    refreshTokens.set(newRefreshToken, { userId: decoded.userId, createdAt: new Date() });
    
    // Update cookies
    res.cookie('accessToken', accessToken, getCookieOptions(15 * 60 * 1000));
    res.cookie('refreshToken', newRefreshToken, getCookieOptions(7 * 24 * 60 * 60 * 1000));
    
    res.json({
      status: 'success',
      data: {
        accessToken,
        csrfToken: req.csrfToken ? req.csrfToken() : null
      }
    });
  } catch (error) {
    console.error('Refresh token error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Internal server error'
    });
  }
});

// Logout
app.post('/api/auth/logout', (req, res) => {
  const refreshToken = req.cookies.refreshToken;
  if (refreshToken) {
    refreshTokens.delete(refreshToken);
  }
  
  // Clear cookies
  res.clearCookie('accessToken');
  res.clearCookie('refreshToken');
  
  res.json({
    status: 'success',
    message: 'Logged out successfully'
  });
});

// ===============================
// PROTECTED ROUTES
// ===============================

// Get current user
app.get('/api/user/me', authenticateToken, csrfProtection, (req, res) => {
  // Find user by ID
  let user = null;
  for (const u of users.values()) {
    if (u.id === req.userId) {
      user = u;
      break;
    }
  }
  
  if (!user) {
    return res.status(404).json({
      status: 'error',
      message: 'User not found'
    });
  }
  
  res.json({
    status: 'success',
    data: {
      userId: user.id,
      email: user.email,
      fullName: user.fullName,
      isAdmin: user.isAdmin,
      createdAt: user.createdAt
    }
  });
});

// ===============================
// HEALTH CHECK
// ===============================

app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version || '1.0.0'
  });
});

// ===============================
// ERROR HANDLING
// ===============================

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    status: 'error',
    message: 'Route not found'
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  
  // Don't leak error details in production
  const message = process.env.NODE_ENV === 'production' 
    ? 'Internal server error' 
    : err.message;
  
  res.status(err.status || 500).json({
    status: 'error',
    message
  });
});

// ===============================
// START SERVER
// ===============================

app.listen(PORT, () => {
  console.log(`🚀 MOMIT Secure API running on port ${PORT}`);
  console.log(`🔒 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🛡️  Security features enabled:`);
  console.log('   ✓ Helmet.js security headers');
  console.log('   ✓ Rate limiting on auth endpoints');
  console.log('   ✓ Secure CORS configuration');
  console.log('   ✓ httpOnly, secure, SameSite cookies');
  console.log('   ✓ XSS protection');
  console.log('   ✓ CSRF protection');
  console.log('   ✓ Input sanitization');
  console.log('   ✓ Crypto-secure random generation');
});

module.exports = app;
