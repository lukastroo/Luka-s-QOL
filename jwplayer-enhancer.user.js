

// ==UserScript==
// @name         JWPlayer tweaks
// @version      1.2
// @description  Improve JWPlayer seek, auto fullscreen, right-click skip, and fullscreen UI hide toggle.
// @author       Lukluk
// @namespace    https://github.com/lukastroo
// @include      *
// @run-at       document-end
// @grant        unsafeWindow
// @grant        GM_registerMenuCommand
// @grant        GM_getValue
// @grant        GM_setValue
// @downloadURL  https://raw.githubusercontent.com/lukastroo/Luka-s-QOL/main/jwplayer-enhancer.user.js
// @updateURL    https://raw.githubusercontent.com/lukastroo/Luka-s-QOL/main/jwplayer-enhancer.user.js
// ==/UserScript==
(function() {
  'use strict';
  // === Settings (Tampermonkey menu) ===
  const DEFAULT_ARROW_SKIP_SECONDS = 5;
  let arrowTweakSeconds = Number(GM_getValue('arrowTweakSeconds', 1));
  if (!Number.isFinite(arrowTweakSeconds)) arrowTweakSeconds = 1;
  if (typeof GM_registerMenuCommand === 'function') {
    GM_registerMenuCommand('Settings: Arrow skip seconds', () => {
      const v = prompt('Net Arrow skip seconds (0–4 recommended):', String(arrowTweakSeconds));
      if (v === null) return;
      const n = Number(v);
      if (!Number.isFinite(n)) { alert('Invalid number'); return; }
      const clamped = Math.max(0, Math.min(4, n));
      arrowTweakSeconds = clamped;
      GM_setValue('arrowTweakSeconds', clamped);
      alert('Saved: ' + clamped + 's');
    });
    GM_registerMenuCommand('Settings: Reset to 1s', () => {
      arrowTweakSeconds = 1;
      GM_setValue('arrowTweakSeconds', 1);
      alert('Reset to 1s');
    });
  }

  window.onload = setTimeout(function() {
    if (document.querySelector('.jw-media') !== null) {
      const Player = unsafeWindow.jwplayer(unsafeWindow.jwplayer().getContainer());
  Player.setCurrentQuality(1);
 Player.setCaptions({
            "fontSize": "10",
            "fontFamily": "Verdana",
            "edgeStyle": "raised",
            "color": "#ffffff",
            "backgroundColor": "#000000",
            "backgroundOpacity": 0
        });



      setTimeout(function() {
        function Visibility() {
          if (document.visibilityState === 'visible') {

            Player.play();
            Player.setFullscreen(true);
            Player.getContainer().focus();
          }
        }
        Visibility();
        document.addEventListener("visibilitychange", function() {
          setTimeout(function() {
            Visibility();
          }, 500);
          if (document.hidden) {
            Player.pause();
          }
        }, false);
      }, 500);

      Player.on('complete', function() {
        Player.setFullscreen(false);
      });
      Player.on('pause', function() {
        Player.setFullscreen(false);
      });

      // Hide unwanted UI, overlays, gradients, and cursor in fullscreen
      // Hide unwanted UI, overlays, gradients, and cursor in fullscreen
      let styleEl;
      function applyHideUI(enabled) {
        if (styleEl) styleEl.remove();
        if (!enabled) return;
        styleEl = document.createElement('style');
        styleEl.textContent = `
          .jwplayer.jw-flag-fullscreen .jw-controls-backdrop { background: none !important; }
          .jw-rightclick { display: none !important; }
          .jwplayer.jw-flag-fullscreen .jw-controls,
          .jwplayer.jw-flag-fullscreen .jw-overlays,
          .jwplayer.jw-flag-fullscreen .jw-controlbar,
          .jwplayer.jw-flag-fullscreen .jw-gradient-bottom,
          .jwplayer.jw-flag-fullscreen .jw-nextup-container,
          .jwplayer.jw-flag-fullscreen .jw-tooltip {
            display: none !important;
            background: transparent !important;
          }
          .jwplayer.jw-flag-fullscreen,
          .jwplayer.jw-flag-fullscreen video,
          .jwplayer.jw-flag-fullscreen .jw-media,
          .jwplayer.jw-flag-fullscreen .jw-display-icon-container,
          .jwplayer.jw-flag-fullscreen .jw-preview,
          .jwplayer.jw-flag-fullscreen .jwplayer video {
            cursor: none !important;
          }
        `;
        document.head.appendChild(styleEl);
      }
      let hideUI = GM_getValue('hideUI', true);
      applyHideUI(hideUI);
      if (typeof GM_registerMenuCommand === 'function') {
        GM_registerMenuCommand('Toggle: Hide UI in fullscreen', () => {
          hideUI = !hideUI;
          GM_setValue('hideUI', hideUI);
          applyHideUI(hideUI);
          alert('Hide UI in fullscreen: ' + (hideUI ? 'ON' : 'OFF'));
        });
      }



      const playerContainer = document.getElementById(unsafeWindow.jwplayer().id);
      playerContainer.addEventListener('click', function() {
        setTimeout(function() {
          if (Player.getState() === 'paused') {
            Player.setFullscreen(false);
          } else {
            Player.setFullscreen(true);
            Player.getContainer().focus();
          }
        }, 500);
      });

      // Right-click to skip forward
      playerContainer.addEventListener('contextmenu', function(e) {
        e.preventDefault();
        try {
          Player.seek(Player.getPosition() + arrowTweakSeconds);
        } catch (_) {}
        return false;
      });

      document.addEventListener("keydown", e => {
        if (e.key === 'n') {
          Player.setFullscreen(false);
          if (location.href.match('mateus7g') !== null) {
            console.log("key N 2 pressed");
            Player.next();
          }
        }
        if (e.key === 'o') {
          Player.seek(Player.getPosition() + 85);
        }
        if (e.key === 'ArrowRight') {
          setTimeout(function() {
            try {
              Player.seek(Player.getPosition() - (DEFAULT_ARROW_SKIP_SECONDS - arrowTweakSeconds));
            } catch (_) {}
          }, 0);
        }
        if (e.key === 'ArrowLeft') {
          setTimeout(function() {
            try {
              Player.seek(Player.getPosition() + (DEFAULT_ARROW_SKIP_SECONDS - arrowTweakSeconds));
            } catch (_) {}
          }, 0);
        }
      });
    }
  }, 500);
})();
