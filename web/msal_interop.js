// Microsoft sign-in glue over MSAL.js (@azure/msal-browser, bundled locally as
// msal-browser.min.js). Exposes window.xdMsal.
//
// REDIRECT flow: signInRedirect() navigates the whole tab to Microsoft; the
// response is processed on the return load via handleRedirectPromise(), which
// (default navigateToLoginRequestUrl) delivers the finalized result on the
// login-request URL '/'. authBootstrapProvider reads it via getRedirectResult().
// Popup was abandoned because Microsoft's login pages send Cross-Origin-Opener-
// Policy, which severs the opener<->popup link. Single-tab flow means the PKCE
// request cache (sessionStorage) is present on return.
//
// Diagnostic logging is gated by the enableMicrosoftLoginLogs feature flag. The
// flag lives in Dart config (AppConfig), which loads AFTER this script runs, so
// we always BUFFER log lines into window.xdMsalLog and only stream them to the
// console when live logging is enabled. On startup Dart reads the flag and, if
// on, calls setLogsLive(true) + dumps the buffer — capturing even the load-time
// lines that fired before Dart booted.
(function () {
  window.xdMsalLog = window.xdMsalLog || [];
  function xlog(message) {
    var line = '[xdMsal] ' + message;
    window.xdMsalLog.push(line);
    if (window.xdMsalLogsLive) console.log(line);
  }

  xlog('script load; path=' + window.location.pathname +
    ' hashLen=' + window.location.hash.length +
    ' searchLen=' + window.location.search.length);

  var MSAL_CONFIG = {
    auth: {
      clientId: 'eb4d44fd-888c-4c12-9de2-ea25cf46a55f',
      authority: 'https://login.microsoftonline.com/organizations',
      redirectUri: window.location.origin + '/auth/microsoft-callback',
    },
    cache: {
      cacheLocation: 'sessionStorage',
    },
  };

  var SCOPES = ['openid', 'profile', 'email', 'User.Read'];

  var appPromise = (async function () {
    var app = new msal.PublicClientApplication(MSAL_CONFIG);
    await app.initialize();
    xlog('MSAL initialized');
    return app;
  })();

  // handleRedirectPromise() must run once on every load; called here and shared.
  // Resolves to the Microsoft ID token on a successful return, or '' otherwise.
  var redirectResultPromise = (async function () {
    var app = await appPromise;
    xlog('calling handleRedirectPromise; hashLen=' + window.location.hash.length);
    try {
      var result = await app.handleRedirectPromise();
      xlog('handleRedirectPromise resolved: hasIdToken=' +
        !!(result && result.idToken) +
        ' idTokenLen=' + (result && result.idToken ? result.idToken.length : 0) +
        ' account=' + (result && result.account ? result.account.username : 'null'));
      return (result && result.idToken) ? result.idToken : '';
    } catch (e) {
      xlog('handleRedirectPromise ERROR: ' + (e && (e.errorCode || e)));
      return '';
    }
  })();

  window.xdMsal = {
    signInRedirect: function () {
      xlog('signInRedirect() called');
      return appPromise.then(function (app) {
        return app.loginRedirect({ scopes: SCOPES, prompt: 'select_account' });
      });
    },
    getRedirectResult: function () {
      return redirectResultPromise.then(function (t) {
        xlog('getRedirectResult() -> token length ' + t.length);
        return t;
      });
    },
    // Enable live console streaming (Dart calls this when the log flag is on).
    setLogsLive: function (on) {
      window.xdMsalLogsLive = !!on;
    },
    // Return the full buffered log as one string (Dart flushes it to the console
    // so load-time lines that preceded Dart boot are not lost).
    dumpLog: function () {
      return window.xdMsalLog.join('\n');
    },
  };
})();
