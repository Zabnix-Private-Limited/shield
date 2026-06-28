(() => {
  function render(
    containerId,
    siteKey,
    tokenCallbackName,
    expiredCallbackName,
    errorCallbackName,
  ) {
    const container = document.getElementById(containerId);
    if (!container || !window.turnstile) {
      return null;
    }

    container.innerHTML = "";

    return window.turnstile.render(container, {
      sitekey: siteKey,
      theme: "light",
      size: "flexible",
      callback: function (token) {
        if (
          tokenCallbackName &&
          typeof window[tokenCallbackName] === "function"
        ) {
          window[tokenCallbackName](token);
        }
      },
      "expired-callback": function () {
        if (
          expiredCallbackName &&
          typeof window[expiredCallbackName] === "function"
        ) {
          window[expiredCallbackName]();
        }
      },
      "error-callback": function () {
        if (
          errorCallbackName &&
          typeof window[errorCallbackName] === "function"
        ) {
          window[errorCallbackName]();
        }
      },
    });
  }

  function remove(widgetId) {
    if (!window.turnstile || !widgetId) {
      return;
    }
    window.turnstile.remove(widgetId);
  }

  window.shieldTurnstile = {
    render,
    remove,
  };
})();
