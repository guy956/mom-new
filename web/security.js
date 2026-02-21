/**
 * MOMIT Security Module - Lightweight
 * Security headers are handled by Cloudflare Pages (_headers file).
 * This file only handles client-side link sanitization.
 * @version 2.0.0
 */

const MOMITSecurity = {
  init() {
    this.sanitizeExternalLinks();
    console.log('[MOMIT Security] Initialized');
  },

  sanitizeExternalLinks() {
    document.addEventListener('click', (e) => {
      const link = e.target.closest('a');
      if (link && link.href) {
        try {
          const url = new URL(link.href, window.location.origin);
          if (url.origin !== window.location.origin) {
            link.setAttribute('rel', 'noopener noreferrer');
            link.setAttribute('target', '_blank');
          }
        } catch (err) {
          // Invalid URL
        }
      }
    });
  }
};

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => MOMITSecurity.init());
} else {
  MOMITSecurity.init();
}
