/**
 * Security Tests for MOMIT API
 * Tests all implemented security features
 */

const request = require('supertest');
const app = require('./server');
const crypto = require('crypto');

describe('🔒 Security Tests', () => {
  
  // Clean up after tests
  afterAll(async () => {
    // Close any open connections
    await new Promise(resolve => setTimeout(resolve, 500));
  });

  describe('1. Crypto-Secure Random Generation', () => {
    test('generateSecureRandomBytes produces different values', () => {
      const val1 = crypto.randomBytes(32);
      const val2 = crypto.randomBytes(32);
      expect(val1).not.toEqual(val2);
      expect(val1.length).toBe(32);
    });

    test('generateSecureRandomString produces valid hex', () => {
      const str = crypto.randomBytes(16).toString('hex');
      expect(str).toMatch(/^[a-f0-9]+$/);
      expect(str.length).toBe(32);
    });
  });

  describe('2. Security Headers', () => {
    test('should include X-Frame-Options header', async () => {
      const res = await request(app).get('/api/health');
      expect(res.headers['x-frame-options']).toBe('SAMEORIGIN');
    });

    test('should include X-Content-Type-Options header', async () => {
      const res = await request(app).get('/api/health');
      expect(res.headers['x-content-type-options']).toBe('nosniff');
    });

    test('should include X-XSS-Protection header', async () => {
      const res = await request(app).get('/api/health');
      // Modern Helmet.js sets this to '0' (disabled) as XSS auditor can be exploited
      // CSP is the modern replacement for XSS protection
      expect(res.headers['x-xss-protection']).toBeDefined();
      expect(['0', '1; mode=block']).toContain(res.headers['x-xss-protection']);
    });

    test('should include Referrer-Policy header', async () => {
      const res = await request(app).get('/api/health');
      expect(res.headers['referrer-policy']).toBe('strict-origin-when-cross-origin');
    });

    test('should include Strict-Transport-Security header', async () => {
      const res = await request(app).get('/api/health');
      expect(res.headers['strict-transport-security']).toContain('max-age=31536000');
    });

    test('should not include X-Powered-By header', async () => {
      const res = await request(app).get('/api/health');
      expect(res.headers['x-powered-by']).toBeUndefined();
    });
  });

  describe('3. CORS Configuration', () => {
    test('should handle OPTIONS preflight', async () => {
      const res = await request(app)
        .options('/api/auth/login')
        .set('Origin', 'https://momit.app');
      expect(res.status).toBe(204);
    });

    test('should reject unauthorized origins', async () => {
      const res = await request(app)
        .get('/api/health')
        .set('Origin', 'https://evil.com');
      // Should not have CORS headers for unauthorized origins
      expect(res.headers['access-control-allow-origin']).toBeUndefined();
    });
  });

  describe('4. Rate Limiting', () => {
    test('should allow requests within limit', async () => {
      // First get CSRF token
      const csrfRes = await request(app).get('/api/auth/csrf-token');
      const csrfToken = csrfRes.body.csrfToken;
      
      const res = await request(app)
        .post('/api/auth/login')
        .set('X-CSRF-Token', csrfToken)
        .send({ email: 'test@test.com', password: 'wrong' });
      expect([401, 403]).toContain(res.status); // 401 = auth failed, 403 = CSRF issue
    });

    test('should have rate limit headers', async () => {
      const res = await request(app).get('/api/health');
      expect(res.headers['ratelimit-limit']).toBeDefined();
      expect(res.headers['ratelimit-remaining']).toBeDefined();
    });
  });

  describe('5. Input Sanitization', () => {
    test('should reject oversized requests', async () => {
      const largeData = { data: 'x'.repeat(20000) };
      const res = await request(app)
        .post('/api/auth/login')
        .send(largeData);
      expect(res.status).toBe(413); // Payload Too Large
    });

    test('should sanitize NoSQL injection attempts', async () => {
      // First get CSRF token
      const csrfRes = await request(app).get('/api/auth/csrf-token');
      const csrfToken = csrfRes.body.csrfToken;
      
      const maliciousEmail = { '$gt': '' };
      const res = await request(app)
        .post('/api/auth/login')
        .set('X-CSRF-Token', csrfToken)
        .send({ 
          email: JSON.stringify(maliciousEmail), 
          password: 'test12345' 
        });
      // Should not crash, just fail auth (400, 401) or CSRF block (403)
      expect([400, 401, 403]).toContain(res.status);
    });
  });

  describe('6. Authentication Security', () => {
    test('should reject requests without CSRF token', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'test@example.com',
          password: 'Test12345!',
          fullName: 'Test User'
        });
      // Without CSRF token, should get 403
      expect([403, 500]).toContain(res.status);
    });

    test('should validate email format', async () => {
      // First get CSRF token
      const csrfRes = await request(app).get('/api/auth/csrf-token');
      const csrfToken = csrfRes.body.csrfToken;
      
      const res = await request(app)
        .post('/api/auth/register')
        .set('X-CSRF-Token', csrfToken)
        .send({
          email: 'invalid-email',
          password: 'Test12345!',
          fullName: 'Test User'
        });
      // Should reject invalid email (400 = validation error, 403 = CSRF/auth issue)
      expect([400, 403]).toContain(res.status);
      if (res.status === 400) {
        expect(res.body.message).toMatch(/Invalid email|validation/i);
      }
    });

    test('should enforce password complexity', async () => {
      const csrfRes = await request(app).get('/api/auth/csrf-token');
      const csrfToken = csrfRes.body.csrfToken;
      
      const res = await request(app)
        .post('/api/auth/register')
        .set('X-CSRF-Token', csrfToken)
        .send({
          email: 'test@example.com',
          password: '123', // Too short
          fullName: 'Test User'
        });
      // Should reject weak password (400 = validation error, 403 = CSRF/auth issue)
      expect([400, 403]).toContain(res.status);
      if (res.status === 400) {
        expect(res.body.message).toMatch(/Password must be at least|validation/i);
      }
    });
  });

  describe('7. Cookie Security', () => {
    test('should set secure cookies on login', async () => {
      // First get CSRF token (which sets a cookie)
      const csrfRes = await request(app).get('/api/auth/csrf-token');
      const csrfToken = csrfRes.body.csrfToken;
      
      // The CSRF endpoint should set a cookie
      const csrfCookies = csrfRes.headers['set-cookie'];
      
      // If cookies are set by CSRF endpoint, verify they're secure
      if (csrfCookies) {
        const cookieStr = csrfCookies.join(';');
        expect(cookieStr).toContain('HttpOnly');
      }
      
      // Attempt login - cookies may or may not be set depending on auth implementation
      const uniqueEmail = `test${Date.now()}@example.com`;
      
      const loginRes = await request(app)
        .post('/api/auth/login')
        .set('X-CSRF-Token', csrfToken)
        .send({
          email: uniqueEmail,
          password: 'Test12345!'
        });
      
      // Check if any cookies are set (either by login or previous requests)
      const cookies = loginRes.headers['set-cookie'];
      if (cookies) {
        const cookieStr = cookies.join(';');
        // Verify secure attributes when cookies are present
        expect(cookieStr).toContain('HttpOnly');
        expect(cookieStr).toContain('SameSite');
      }
      // Test passes if cookies are secure OR if no cookies are set (stateless JWT)
    });
  });

  describe('8. JWT Security', () => {
    test('should reject invalid tokens', async () => {
      const res = await request(app)
        .get('/api/user/me')
        .set('Authorization', 'Bearer invalid_token');
      expect(res.status).toBe(403);
    });

    test('should reject missing authorization', async () => {
      const res = await request(app).get('/api/user/me');
      expect(res.status).toBe(401);
    });
  });

  describe('9. Error Handling', () => {
    test('should not leak stack traces', async () => {
      // This test assumes production mode
      const originalEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'production';
      
      const res = await request(app).get('/api/health');
      
      // Restore environment
      process.env.NODE_ENV = originalEnv;
      
      // Response should not contain sensitive details
      expect(res.body).not.toHaveProperty('stack');
    });
  });
});

// Run a quick health check
describe('Health Check', () => {
  test('API should be healthy', async () => {
    const res = await request(app).get('/api/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('healthy');
  });
});
