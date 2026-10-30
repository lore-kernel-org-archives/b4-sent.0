From: Nikolay Plastinin <plaztininikolai@gmail.com>
Subject: [PATCH v4 0/2] leds: trigger: input-events: Restore previous
 brightness on input
Date: Fri, 30 Oct 2026 21:51:30 +0800
Message-Id: <20261030-leds-input-events-brightness-v4-0-5ea0ead7480c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43Nu47CMBCF4VdBrhlkj00uVLzHagvHniQjgRPZW
 WsRyrtjKBASBZT/Kb5zFYkiUxKHzVVEypx4CiXMdiPcaMNAwL60QImVbNHAiXwCDvPfApQpLAm
 6yMO4BEoJbF1Zam1dd81eFGKO1PP/g//5LT1yWqZ4ebxldV+/hLMCBZ101Pfaojb6OJwtn3ZuO
 os7nPEF0/IDhiBBt6bx2nnvmzdMPzElVfUB0wVDZyp0tieJ8hVb1/UGcwEvD2IBAAA=
X-Change-ID: 20260924-leds-input-events-brightness-a76ae9a77b85
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>
Cc: Hans de Goede <hansg@kernel.org>, linux-leds@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nikolay Plastinin <plaztininikolai@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793368292; l=3666;
 i=plaztininikolai@gmail.com; s=20260924; h=from:subject:message-id;
 bh=TqfNC0LMUz3nz/opoj1+J7OcrmSpnFYU8zd02dPuZfo=;
 b=L3LbvudhFfLquOXHsn845Su6kFcFrxuQCzBgVsheOXwjGRXtmYd/SRGpeX/inSfaRveFKZyG5
 8ts/vXyEKtvDyR9TV/Kptezr5pTv4qxa44UFRoVfowNtqrHDc7ZtXjh
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

Validation for v4: the module builds out of tree with W=1 against Fedora
7.2.12-200.fc44.x86_64 using the patched leds.h. A user-space harness using
the driver functions reproduces a heap-use-after-free with v3 when the
LED remains in the iteration after deactivate(), modelling the
attribute-creation error path. With v4, the same test, brightness restore,
and 10,000 concurrent deactivate/reinitialise cycles pass ASan/UBSan.
The harness substitutes mutexes and a one-element list for kernel
primitives; it is not kernel fault injection or an RCU implementation test.

V4 was tested on an ASUS ROG Flow X13 GV302XV with kernel
7.2.12-200.fc44.x86_64 and no external monitor: brightness levels 1 and 2
were restored after idle timeout and keyboard input, and 20 trigger
activate/deactivate cycles passed. No kernel messages appeared during
the test. The original brightness and trigger were restored afterwards.
No full kernel build has been performed.

LLM assistance was used for the implementation, tests and message drafts.

---
Changes in v4:
- Clear trigger_data under input_events_data.lock before freeing per-LED
  state in deactivate(), as suggested by Lee Jones. This also covers the
  device_add_groups() error path, which deactivates before list removal.
- Update the NULL-state comment to cover activation error unwind.
- Patch 1 is unchanged.
- Link to v3: https://lore.kernel.org/r/20261016-leds-input-events-brightness-v3-0-2c462cafe020@gmail.com

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

 drivers/leds/trigger/ledtrig-input-events.c | 76 ++++++++++++++++++++++++++---
 include/linux/leds.h                        | 12 +++++
 2 files changed, 82 insertions(+), 6 deletions(-)
---
base-commit: f475845eaf3d749114a63270bf2efea459e14dd2
change-id: 20260924-leds-input-events-brightness-a76ae9a77b85

Best regards,
-- 
Nikolay Plastinin <plaztininikolai@gmail.com>

