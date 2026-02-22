import http.server
import socketserver
import os

os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'build', 'web'))

class SecureCORSHandler(http.server.SimpleHTTPRequestHandler):
    """Secure HTTP handler with proper CORS and security headers"""
    
    # Allowed origins - configure for production
    ALLOWED_ORIGINS = [
        'https://momit.app',
        'https://www.momit.app',
        'https://admin.momit.app',
    ]
    
    def end_headers(self):
        origin = self.headers.get('Origin', '')
        
        # CORS: Only allow specific origins (not '*')
        if origin in self.ALLOWED_ORIGINS:
            self.send_header('Access-Control-Allow-Origin', origin)
            self.send_header('Access-Control-Allow-Credentials', 'true')
            self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-CSRF-Token')
            self.send_header('Access-Control-Max-Age', '86400')
        
        # Security Headers (like Helmet.js)
        # Prevent clickjacking
        self.send_header('X-Frame-Options', 'SAMEORIGIN')
        
        # Prevent MIME type sniffing
        self.send_header('X-Content-Type-Options', 'nosniff')
        
        # XSS Protection
        self.send_header('X-XSS-Protection', '1; mode=block')
        
        # Referrer Policy
        self.send_header('Referrer-Policy', 'strict-origin-when-cross-origin')
        
        # Permissions Policy
        self.send_header('Permissions-Policy', 'camera=(), microphone=(), geolocation=(self)')
        
        # Strict Transport Security (HSTS) - only in production
        self.send_header('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload')
        
        # Content Security Policy
        csp = (
            "default-src 'self'; "
            "script-src 'self' 'unsafe-inline' 'unsafe-eval' 'wasm-unsafe-eval' blob: https://www.gstatic.com https://apis.google.com https://www.googleapis.com https://accounts.google.com; "
            "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://accounts.google.com; "
            "font-src 'self' https://fonts.gstatic.com https://fonts.googleapis.com data:; "
            "img-src 'self' data: https: blob:; "
            "connect-src 'self' blob: https://www.gstatic.com https://fonts.gstatic.com https://fonts.googleapis.com https://*.googleapis.com https://*.firebaseio.com https://*.firebaseapp.com https://*.cloudfunctions.net wss://*.firebaseio.com https://firestore.googleapis.com https://identitytoolkit.googleapis.com https://securetoken.googleapis.com; "
            "frame-src 'self' https://*.firebaseapp.com https://accounts.google.com https://www.gstatic.com; "
            "worker-src 'self' blob:; "
            "object-src 'none'; "
            "base-uri 'self';"
        )
        self.send_header('Content-Security-Policy', csp)
        
        # Remove server identification
        self.send_header('X-Powered-By', '')
        
        # Cache control
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        
        # Cross-Origin Resource Policy
        self.send_header('Cross-Origin-Resource-Policy', 'same-origin')
        
        # Cross-Origin Opener Policy
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        
        # Cross-Origin Embedder Policy
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        
        super().end_headers()
    
    def do_OPTIONS(self):
        """Handle CORS preflight requests"""
        origin = self.headers.get('Origin', '')
        if origin in self.ALLOWED_ORIGINS:
            self.send_response(204)
            self.end_headers()
        else:
            self.send_response(403)
            self.end_headers()
    
    def log_message(self, format, *args):
        """Custom logging - in production, use proper logging"""
        # Don't log sensitive information
        if self.path and not any(sensitive in self.path.lower() for sensitive in ['token', 'auth', 'password', 'secret']):
            print(f"[{self.log_date_time_string()}] {self.address_string()} - {format % args}")

socketserver.TCPServer.allow_reuse_address = True
httpd = socketserver.TCPServer(('0.0.0.0', 5060), SecureCORSHandler)
print('🔒 MOMIT Secure Server running on port 5060', flush=True)
print('🛡️  Security features enabled:', flush=True)
print('   ✓ Strict CORS (no wildcard origins)', flush=True)
print('   ✓ Security headers (X-Frame-Options, HSTS, CSP)', flush=True)
print('   ✓ XSS Protection', flush=True)
print('   ✓ Content-Type sniffing prevention', flush=True)
print('   ✓ Referrer Policy', flush=True)
print('   ✓ Permissions Policy', flush=True)
httpd.serve_forever()
