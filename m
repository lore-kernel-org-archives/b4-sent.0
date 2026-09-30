From: Nikolay Plastinin <plaztininikolai@gmail.com>
Subject: [PATCH v2 0/2] leds: trigger: input-events: Restore previous
 brightness on input
Date: Wed, 30 Sep 2026 14:54:09 +0800
Message-Id: <20260930-leds-input-events-brightness-v2-0-3948d3cddd83@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43NQQ6CMBCF4auQWTsGCoKw8h6GRYEBJoGWdGqjI
 dzdyglcfm/xvx2EHJNAk+zgKLCwNRHqkkA/azMR8hANKlVlWqsCFxoE2WwvjxTIeMHO8TR7QyK
 oq1JTrauqu98gJjZHI7/P/LONnlm8dZ/zLWS/9c9wyDDDLu1pHHOt8iJ/TKvm5drbFdrjOL5aX
 lTOyAAAAA==
X-Change-ID: 20260924-leds-input-events-brightness-a76ae9a77b85
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>
Cc: Hans de Goede <hansg@kernel.org>, linux-leds@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nikolay Plastinin <plaztininikolai@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790751252; l=1998;
 i=plaztininikolai@gmail.com; s=20260924; h=from:subject:message-id;
 bh=lK5+j3uPBCngGxgIf4uR4HYLN2ER5vovCEytpg+tbyU=;
 b=Pq5O8BlHYjOzvUYYkAC06Aiq5O9fOZpE2qcgdK/ssogHMpyJ8XHHMkoSCqDaUIhoqUV3Iz1Op
 jp/t3zHA2dhBqRI+jj+hX2ffXr64CRmr2UCd8Fd0PVhKK+vjXBGLd7j
X-Developer-Key: i=plaztininikolai@gmail.com; a=ed25519;
 pk=bmHrETa14IbiLNkJSoiLqUMni+IeSFwhOSDM4vVFN4s=
X-Endpoint-Received: by B4 Relay for plaztininikolai@gmail.com/20260924 with auth_id=1052
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The input-events trigger turns LEDs back on with LED_FULL, so a keyboard
backlight with several levels always comes back at maximum after being
idle. This series restores the level the user picked instead.

Patch 1 adds led_trigger_walk_leds() to the LED core, so that a
trigger which needs a different brightness per LED does not have to walk
trig->led_cdevs itself. Patch 2 converts the input-events trigger to a
regular trigger with per-LED state in trigger_data and uses the helper.

This came up while looking at a keyboard backlight idle timeout for ASUS
laptops in asusctl:
https://github.com/OpenGamingCollective/asusctl/issues/98

Tested on an ASUS ROG Flow X13 GV302XV (asus::kbd_backlight, 3 levels)
with the trigger built out of tree against Fedora's 7.2.7 kernel and a
local copy of the helper, since the helper itself lives in the built-in
LED core.

---
Changes in v2:
- Keep the saved brightness in a per-LED struct allocated in activate()
  and freed in deactivate(), stored in led_cdev->trigger_data, instead of
  overloading blink_brightness (Lee Jones).
- Add led_trigger_walk_leds() to led-triggers.c and use it instead of
  walking led_cdevs/trig_list from the trigger (Lee Jones).
- Use the Assisted-by tag format from coding-assistants.rst.
- Link to v1: https://lore.kernel.org/r/20260924-leds-input-events-brightness-v1-1-b0ceff3a2343@gmail.com

---
Nikolay Plastinin (2):
      leds: triggers: Add led_trigger_walk_leds()
      leds: trigger: input-events: Restore previous brightness on input

 drivers/leds/led-triggers.c                 | 25 ++++++++++
 drivers/leds/trigger/ledtrig-input-events.c | 74 ++++++++++++++++++++++++++---
 include/linux/leds.h                        |  7 +++
 3 files changed, 100 insertions(+), 6 deletions(-)
---
base-commit: f475845eaf3d749114a63270bf2efea459e14dd2
change-id: 20260924-leds-input-events-brightness-a76ae9a77b85

Best regards,
-- 
Nikolay Plastinin <plaztininikolai@gmail.com>

