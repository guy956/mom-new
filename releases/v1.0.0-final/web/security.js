/**
 * MOMIT Security Module
 * Handles security headers, CSP, and CORS configuration
 * @version 1.1.0
 */

const MOMITSecurity = {
  // Configuration
  config: {
    // Allowed domains for CORS
    allowedOrigins: [
      'https://momit.pages.dev',
      'https://mom-it.com',
      'https://www.mom-it.com',
      'https://momit.co.il',
      'https://www.momit.co.il',
      'https://momit-8f27d.web.app',
      'https://momit-8f27d.firebaseapp.com'
    ],
    // Development origins (comment out in production)
    devOrigins: [
      'http://localhost:*',
      'http://127.0.0.1:*'
    ],
    // Reporting endpoint for CSP violations
    reportUri: '/csp-report',
    // Whether to use report-only mode for CSP (useful for testing)
    cspReportOnly: false
  },

  /**
   * Initialize all security measures
   */
  init() {
    this.setSecurityHeaders();
    this.configureCSP();
    this.setupCORS();
    this.preventClickjacking();
    this.sanitizeExternalLinks();
    this.setupReporting();
    console.log('[MOMIT Security] Initialized successfully');
  },

  /**
   * Set security-related meta tags
   */
  setSecurityHeaders() {
    const headers = [
      // X-Content-Type-Options: Prevent MIME sniffing
      { httpEquiv: 'X-Content-Type-Options', content: 'nosniff' },
      
      // X-Frame-Options: Prevent clickjacking
      { httpEquiv: 'X-Frame-Options', content: 'SAMEORIGIN' },
      
      // Referrer-Policy: Control referrer information
      { name: 'referrer', content: 'strict-origin-when-cross-origin' },
      
      // X-XSS-Protection: Legacy XSS protection for older browsers
      { httpEquiv: 'X-XSS-Protection', content: '1; mode=block' },
      
      // Permissions-Policy: Restrict browser features
      { httpEquiv: 'Permissions-Policy', content: this.getPermissionsPolicy() },
      
      // Cross-Origin-Embedder-Policy
      { httpEquiv: 'Cross-Origin-Embedder-Policy', content: 'credentialless' },
      
      // Cross-Origin-Opener-Policy
      { httpEquiv: 'Cross-Origin-Opener-Policy', content: 'same-origin-allow-popups' },
      
      // Cross-Origin-Resource-Policy
      { httpEquiv: 'Cross-Origin-Resource-Policy', content: 'cross-origin' }
    ];

    headers.forEach(header => {
      if (!this.metaTagExists(header.httpEquiv || header.name)) {
        const meta = document.createElement('meta');
        if (header.httpEquiv) {
          meta.httpEquiv = header.httpEquiv;
        } else {
          meta.name = header.name;
        }
        meta.content = header.content;
        document.head.appendChild(meta);
      }
    });
  },

  /**
   * Configure Content Security Policy
   */
  configureCSP() {
    const cspDirectives = [
      // Default fallback
      "default-src 'self'",
      
      // Scripts: Allow inline for Flutter, Google APIs
      "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://apis.google.com https://accounts.google.com https://www.gstatic.com",
      
      // Styles: Allow inline for Flutter
      "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
      
      // Images: Allow data URIs and common sources
      "img-src 'self' data: blob: https: https://*.googleapis.com https://*.googleusercontent.com https://*.firebaseapp.com",
      
      // Fonts
      "font-src 'self' https://fonts.gstatic.com data:",
      
      // Connect: API calls, Firebase, Google
      "connect-src 'self' https://*.googleapis.com https://*.firebaseio.com https://*.firebaseapp.com https://identitytoolkit.googleapis.com https://securetoken.googleapis.com https://firestore.googleapis.com https://storage.googleapis.com wss://*.firebaseio.com",
      
      // Media: Audio/Video
      "media-src 'self' blob: https:",
      
      // Frames: Limited embedding
      "frame-src 'self' https://accounts.google.com https://*.firebaseapp.com",
      
      // Objects: Restrict plugins
      "object-src 'none'",
      
      // Base URI
      "base-uri 'self'",
      
      // Form action
      "form-action 'self'",
      
      // Upgrade insecure requests
      "upgrade-insecure-requests",
      
      // Frame ancestors (frame-ancestors for CSP)
      "frame-ancestors 'self'",
      
      // Trusted Types (if supported)
      "require-trusted-types-for 'script'",
      "trusted-types default",
      
      // CSP violation reporting (optional)
      "report-uri /csp-report",
      "report-to default"
    ];

    const cspString = cspDirectives.join('; ');
    
    // Try to set CSP header - first try report-only if configured
    if (this.config.cspReportOnly && !this.metaTagExists('Content-Security-Policy-Report-Only')) {
      const meta = document.createElement('meta');
      meta.httpEquiv = 'Content-Security-Policy-Report-Only';
      meta.content = cspString;
      document.head.appendChild(meta);
    } else if (!this.metaTagExists('Content-Security-Policy')) {
      const meta = document.createElement('meta');
      meta.httpEquiv = 'Content-Security-Policy';
      meta.content = cspString;
      document.head.appendChild(meta);
    }
  },

  /**
   * Setup CORS handling
   */
  setupCORS() {
    // Intercept fetch requests to ensure proper CORS
    const originalFetch = window.fetch;
    const self = this;
    
    window.fetch = async function(...args) {
      const [url, options = {}] = args;
      
      // Add CORS mode for cross-origin requests
      if (self.isCrossOrigin(url)) {
        options.mode = options.mode || 'cors';
        options.credentials = options.credentials || 'include';
      }
      
      try {
        const response = await originalFetch.apply(window, args);
        self.validateCORSResponse(response);
        return response;
      } catch (error) {
        if (error.message && error.message.includes('CORS')) {
          console.error('[MOMIT Security] CORS Error:', error);
          self.handleCORSError(url, error);
        }
        throw error;
      }
    };

    // Monitor XMLHttpRequest for CORS issues
    const originalXHR = window.XMLHttpRequest;
    const self2 = this;
    
    window.XMLHttpRequest = function() {
      const xhr = new originalXHR();
      const originalOpen = xhr.open;
      
      xhr.open = function(method, url, ...rest) {
        xhr._url = url;
        if (self2.isCrossOrigin(url)) {
          xhr.withCredentials = true; // Enable credentials for cross-origin
        }
        return originalOpen.call(xhr, method, url, ...rest);
      };
      
      return xhr;
    };
  },

  /**
   * Prevent clickjacking with additional JS protection
   */
  preventClickjacking() {
    // Prevent framing from unauthorized domains
    if (window.top !== window.self) {
      const allowedParents = this.config.allowedOrigins;
      try {
        if (window.top.location && window.top.location.origin) {
          const parentOrigin = window.top.location.origin;
          if (!allowedParents.some(origin => this.matchOrigin(parentOrigin, origin))) {
            console.error('[MOMIT Security] Unauthorized framing detected');
            document.body.innerHTML = '<h1 style="text-align:center;margin-top:50px;font-family:sans-serif;">Access Denied</h1>';
            return;
          }
        }
      } catch (e) {
        // Cross-origin access denied - might be legitimate but risky
        console.warn('[MOMIT Security] Cannot verify parent frame origin');
      }
    }
  },

  /**
   * Sanitize external links
   */
  sanitizeExternalLinks() {
    document.addEventListener('click', (e) => {
      const link = e.target.closest('a');
      if (link && link.href) {
        try {
          const url = new URL(link.href, window.location.origin);
          
          // External links
          if (url.origin !== window.location.origin) {
            // Add security attributes
            link.setAttribute('rel', 'noopener noreferrer');
            link.setAttribute('target', '_blank');
          }
        } catch (err) {
          // Invalid URL, ignore
        }
      }
    });
  },

  /**
   * Setup Reporting API
   */
  setupReporting() {
    // Report CSP violations if endpoint exists
    if (this.config.reportUri) {
      document.addEventListener('securitypolicyviolation', (e) => {
        console.warn('[MOMIT Security] CSP Violation:', {
          blockedURI: e.blockedURI,
          violatedDirective: e.violatedDirective,
          originalPolicy: e.originalPolicy
        });
        
        // Send to analytics in production
        if (window.gtag) {
          window.gtag('event', 'csp_violation', {
            blocked_uri: e.blockedURI,
            violated_directive: e.violatedDirective
          });
        }
      });
    }
  },

  /**
   * Helper: Check if meta tag exists
   */
  metaTagExists(name) {
    return document.querySelector(`meta[http-equiv="${name}"], meta[name="${name}"]`) !== null;
  },

  /**
   * Helper: Get permissions policy string
   */
  getPermissionsPolicy() {
    const policies = [
      'camera=(self)',
      'microphone=(self)',
      'geolocation=(self)',
      'payment=()',
      'usb=()',
      'magnetometer=()',
      'gyroscope=()',
      'accelerometer=()',
      'clipboard-read=(self)',
      'clipboard-write=(self)',
      'display-capture=(self)',
      'fullscreen=(self)',
      'picture-in-picture=(self)',
      'publickey-credentials-get=(self)',
      'publickey-credentials-create=(self)',
      'web-share=(self)'
    ];
    return policies.join(', ');
  },

  /**
   * Helper: Check if URL is cross-origin
   */
  isCrossOrigin(url) {
    try {
      if (typeof url !== 'string') return false;
      const parsed = new URL(url, window.location.origin);
      return parsed.origin !== window.location.origin;
    } catch {
      return false;
    }
  },

  /**
   * Helper: Match origin with pattern
   */
  matchOrigin(origin, pattern) {
    if (pattern.includes('*')) {
      const regex = new RegExp('^' + pattern.replace(/\*/g, '.*') + '$');
      return regex.test(origin);
    }
    return origin === pattern;
  },

  /**
   * Helper: Validate CORS response
   */
  validateCORSResponse(response) {
    if (!response || !response.headers) return;
    const acao = response.headers.get('Access-Control-Allow-Origin');
    if (acao && acao !== '*' && acao !== window.location.origin) {
      console.warn('[MOMIT Security] Unexpected CORS origin:', acao);
    }
  },

  /**
   * Helper: Handle CORS error
   */
  handleCORSError(url, error) {
    // Report to analytics/monitoring
    if (window.gtag) {
      try {
        const urlStr = typeof url === 'string' ? url : url.toString();
        window.gtag('event', 'cors_error', {
          url: urlStr.split('?')[0],
          error: error.message
        });
      } catch (e) {
        // Ignore analytics errors
      }
    }
  }
};

// Auto-initialize on DOM ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => MOMITSecurity.init());
} else {
  MOMITSecurity.init();
}

// Expose for debugging (only in development)
// Check for development environment safely
const isDev = (() => {
  try {
    if (typeof process !== 'undefined' && process.env && process.env.NODE_ENV === 'development') {
      return true;
    }
  } catch (e) {
    // process not available in browser
  }
  return window.location.hostname === 'localhost' || 
         window.location.hostname === '127.0.0.1' ||
         window.location.hostname.includes('staging') ||
         window.location.hostname.includes('preview');
})();

if (isDev) {
  window.MOMITSecurity = MOMITSecurity;
}

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
  module.exports = MOMITSecurity;
}
