From: Nikolay Plastinin <plaztininikolai@gmail.com>
Subject: [PATCH v3 0/2] leds: trigger: input-events: Restore previous
 brightness on input
Date: Fri, 16 Oct 2026 02:56:48 +0800
Message-Id: <20261016-leds-input-events-brightness-v3-0-2c462cafe020@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43NvQ6CMBSG4VshnT2mtMiPk/dhHEp7gJNgIW1tN
 IR7tzDppOP7Dc+3MI+O0LNztjCHkTxNNoU8ZEwPyvYIZFIzwUXJG1HAiMYD2fkRACPa4KF11A/
 BovegqlJho6qqrU8sEbPDjp47f72lHsiHyb32t5hv659wzCGHlmvsOqmELOSlvysaj3q6sw2O4
 gOT/AcmgINsitpIbYypv7B1Xd806sqvFQEAAA==
X-Change-ID: 20260924-leds-input-events-brightness-a76ae9a77b85
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>
Cc: Hans de Goede <hansg@kernel.org>, linux-leds@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nikolay Plastinin <plaztininikolai@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792090610; l=2781;
 i=plaztininikolai@gmail.com; s=20260924; h=from:subject:message-id;
 bh=1NQFXQy9NKOiM7FADs3pvz5L9QzecnjgPohJ0Yn0gV0=;
 b=EM7JP7tSgOEg4+OwkXUu/gVvvTiezSY9aJEr/Ik8o3hvupC30nK65Bb47KVCgxCpXVtQ0wyOm
 CnTNRyBg4JmCiol3WIxCSx6woo+QAtT2Odt19o+IXalY462Hf3PNkdE
X-Developer-Key: i=plaztininikolai@gmail.com; a=ed25519;
 pk=bmHrETa14IbiLNkJSoiLqUMni+IeSFwhOSDM4vVFN4s=
X-Endpoint-Received: by B4 Relay for plaztininikolai@gmail.com/20260924 with auth_id=1052
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The input-events trigger turns LEDs back on with LED_FULL, so a keyboard
backlight with several levels always comes back at maximum after being
idle. This series restores the level the user picked instead.

Patch 1 adds led_trigger_for_each_led(), an RCU list iterator in leds.h.
Patch 2 uses it to save and restore each LED's brightness in one loop,
with per-LED state allocated in activate() and freed in deactivate().
There is no new exported function or callback API.

This came up while looking at a keyboard backlight idle timeout for ASUS
laptops in asusctl:
https://github.com/OpenGamingCollective/asusctl/issues/98

Tested on an ASUS ROG Flow X13 GV302XV (asus::kbd_backlight, 3 levels).
The trigger was built out of tree against Fedora 7.2.9-200.fc44.x86_64
with the modified leds.h and W=1. Brightness levels 1 and 2 were restored
after idle timeout and keyboard input. Twenty activate/deactivate cycles
completed, and no kernel messages appeared during the test. This was
not a full kernel build or a leak test.

LLM assistance was used to implement the review changes, prepare the
hardware test script, and draft the commit messages and this letter.
The hardware test was run locally by the submitter.

---
Changes in v3:
- Replace led_trigger_walk_leds() with led_trigger_for_each_led(), an
  RCU list iterator in include/linux/leds.h, as suggested by Lee Jones.
- Remove the exported helper, callback typedef, and void-pointer argument.
- Keep saving and restoring brightness in input_events_set_leds(), using
  guard(rcu)() and a single loop for both the on and off paths.
- Link to v2: https://lore.kernel.org/r/20260930-leds-input-events-brightness-v2-0-3948d3cddd83@gmail.com

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
      leds: triggers: Add led_trigger_for_each_led()
      leds: trigger: input-events: Restore previous brightness on input

 drivers/leds/trigger/ledtrig-input-events.c | 70 ++++++++++++++++++++++++++---
 include/linux/leds.h                        | 12 +++++
 2 files changed, 76 insertions(+), 6 deletions(-)
---
base-commit: f475845eaf3d749114a63270bf2efea459e14dd2
change-id: 20260924-leds-input-events-brightness-a76ae9a77b85

Best regards,
-- 
Nikolay Plastinin <plaztininikolai@gmail.com>

