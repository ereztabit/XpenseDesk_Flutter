// Fix Flutter web autofill issues
// Flutter web generates autocomplete="off" by default, blocking browser autofill
// This script fixes the HTML attributes after rendering

function fixAutocomplete() {
  const inputs = document.querySelectorAll('input[type="text"]');
  inputs.forEach(input => {
    if (input.classList.contains('flt-text-editing')) {
      // Check if this is an email input by checking nearby elements or placeholder
      const placeholder = input.getAttribute('placeholder') || '';
      const ariaLabel = input.getAttribute('aria-label') || '';
      if (placeholder.includes('@') || ariaLabel.toLowerCase().includes('email')) {
        input.setAttribute('autocomplete', 'email');
        input.setAttribute('type', 'email');
        input.setAttribute('name', 'email');
      }
    }
  });
}

// Run on load and periodically to catch dynamically added inputs
window.addEventListener('load', () => {
  setTimeout(fixAutocomplete, 500);
  setTimeout(fixAutocomplete, 1000);
  setTimeout(fixAutocomplete, 2000);
  
  // Also use MutationObserver to catch changes
  const observer = new MutationObserver(fixAutocomplete);
  observer.observe(document.body, { childList: true, subtree: true });
});
