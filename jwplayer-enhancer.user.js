// ==UserScript==
// @name         JWPlayer tweaks
// @version      1.1
// @description  Improve JWPlayer stuff like time seek and auto fullscreen.
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
  // Controls the net seconds skipped by Arrow keys after JWPlayer's default ±5s.
  const DEFAULT_ARROW_SKIP_SECONDS = 5;



  let arrowTweakSeconds = Number(GM_getValue('arrowTweakSeconds', 1));
  if (!Number.isFinite(arrowTweakSeconds)) arrowTweakSeconds = 1;
  // Open via Tampermonkey menu ➝ "Settings: Arrow skip seconds"
  if (typeof GM_registerMenuCommand === 'function') {
    GM_registerMenuCommand('Settings: Arrow skip seconds', () => {
      const v = prompt('Net Arrow skip seconds (0–4 recommended):', String(arrowTweakSeconds));
      if (v === null) return; // canceled
      const n = Number(v);
      if (!Number.isFinite(n)) { alert('Invalid number'); return; }
      const clamped = Math.max(0, Math.min(4, n));
      arrowTweakSeconds = clamped;
      GM_setValue('arrowTweakSeconds', clamped);
    });
    GM_registerMenuCommand('Settings: Reset to 5s', () => {
      arrowTweakSeconds = 5;
      GM_setValue('arrowTweakSeconds', 5);
    });
  }
  window.onload = setTimeout(function() {
    if (document.querySelector('.jw-media') !== null) {
      var next;
      const Player = unsafeWindow.jwplayer(unsafeWindow.jwplayer().getContainer());
      const container = Player.getContainer();


      setTimeout(function() {
        function focusPlayer() {
          const target = container.querySelector('video') || container;
          setTimeout(() => target.focus(), 100);
        }
        function Visibility() {
          if (document.visibilityState === 'visible') {
            Player.play();
            Player.setFullscreen(true);
            focusPlayer();
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

        Player.on('fullscreen', function(e) {
          if (e && e.fullscreen) {
            const target = container.querySelector('video') || container;
            setTimeout(() => target.focus(), 100);
          }
        });
      }, 500);

      Player.on('complete', function() {
        Player.setFullscreen(false);
      });
      Player.on('pause', function() {
        Player.setFullscreen(false);
      });

      document.head.insertAdjacentHTML('beforeend', '<style>.jw-rightclick { display: none !important; }</style>');

      document.getElementById(unsafeWindow.jwplayer().id).addEventListener('click', function(e) {
        setTimeout(function() {
          if (Player.getState() === 'paused') {
            Player.setFullscreen(false);
          } else {
            Player.setFullscreen(true);
            const target = container.querySelector('video') || container;
            setTimeout(() => target.focus(), 100);
          }
        }, 500);
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
          // Default is +5s. Post-adjust to net +arrowTweakSeconds.
          setTimeout(function() {
            try {
              Player.seek(Player.getPosition() - (DEFAULT_ARROW_SKIP_SECONDS - arrowTweakSeconds));
            } catch (_) {}
          }, 0);
        }
        if (e.key === 'ArrowLeft') {
          // Default is -5s. Post-adjust to net -arrowTweakSeconds.
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
