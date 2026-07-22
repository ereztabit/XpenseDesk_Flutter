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
  // Resolves to {idToken, state} on a successful return, or empty strings
  // otherwise. `state` is the opaque string the app passed to signInRedirect()
  // (e.g. 'onboarding'); MSAL echoes it back so the return load knows which flow
  // started the sign-in. Client-side routing data only — never sent to our API.
  var redirectResultPromise = (async function () {
    var app = await appPromise;
    xlog('calling handleRedirectPromise; hashLen=' + window.location.hash.length);
    try {
      var result = await app.handleRedirectPromise();
      xlog('handleRedirectPromise resolved: hasIdToken=' +
        !!(result && result.idToken) +
        ' idTokenLen=' + (result && result.idToken ? result.idToken.length : 0) +
        ' state=' + (result && result.state ? result.state : '') +
        ' account=' + (result && result.account ? result.account.username : 'null'));
      return {
        idToken: (result && result.idToken) ? result.idToken : '',
        state: (result && result.state) ? result.state : '',
      };
    } catch (e) {
      xlog('handleRedirectPromise ERROR: ' + (e && (e.errorCode || e)));
      return { idToken: '', state: '' };
    }
  })();

  window.xdMsal = {
    signInRedirect: function (state) {
      xlog('signInRedirect() called; state=' + (state || ''));
      return appPromise.then(function (app) {
        var request = { scopes: SCOPES, prompt: 'select_account' };
        if (state) request.state = state;
        return app.loginRedirect(request);
      });
    },
    // Returns a JSON string {"idToken": "...", "state": "..."} — JSON keeps the
    // Dart interop to a single JSString crossing.
    getRedirectResult: function () {
      return redirectResultPromise.then(function (r) {
        xlog('getRedirectResult() -> token length ' + r.idToken.length +
          ' state=' + r.state);
        return JSON.stringify(r);
      });
    },
    // Silently re-acquire a FRESH ID token for the signed-in account (ID tokens
    // live ~1h and the user may park on a wizard step). Resolves to '' when
    // there is no cached account or silent renewal fails — caller falls back to
    // the interactive sign-in.
    acquireTokenSilent: function () {
      return appPromise.then(function (app) {
        var accounts = app.getAllAccounts();
        if (!accounts.length) {
          xlog('acquireTokenSilent: no cached account');
          return '';
        }
        return app
          .acquireTokenSilent({
            scopes: SCOPES,
            account: accounts[0],
            forceRefresh: true,
          })
          .then(function (result) {
            xlog('acquireTokenSilent ok; idTokenLen=' +
              (result && result.idToken ? result.idToken.length : 0));
            return (result && result.idToken) ? result.idToken : '';
          })
          .catch(function (e) {
            xlog('acquireTokenSilent ERROR: ' + (e && (e.errorCode || e)));
            return '';
          });
      });
    },
    // Drop the cached MSAL account/tokens without a logout redirect ("Use a
    // different account" restarts the onboarding flow from scratch).
    clearCache: function () {
      return appPromise.then(function (app) {
        xlog('clearCache() called');
        return app.clearCache().catch(function (e) {
          xlog('clearCache ERROR: ' + (e && (e.errorCode || e)));
        });
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
