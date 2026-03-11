From: Henry Barnor <hbarnor@chromium.org>
Date: Wed, 11 Mar 2026 00:08:08 -0700
Subject: [PATCH] Input: atkbd - skip cleanup when used as a wakeup source
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260311-wakeup-v1-1-de0ca1e997bf@chromium.org>
X-B4-Tracking: v=1; b=H4sIANcUsWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDY0MD3fLE7NTSAt3UZFPzRAuLRANDMyMloOKCotS0zAqwQdGxtbUAhyE
 m0FgAAAA=
X-Change-ID: 20260310-wakeup-ec57a88a0162
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Henry Barnor <hbarnor@chromium.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773212911; l=2223;
 i=hbarnor@chromium.org; s=20260310; h=from:subject:message-id;
 bh=MfJP1wyUZPDCLJM5KFWSmvdvXpl3DMtCkHxzp2gMujI=;
 b=EBNBVb+wFXuXKnmjDMVhfSzLCXBhJPFehNEnDOCPmgoB2jjUIBCiEsu3tw4C9QgbzCtUbQCOM
 vNH4MK6pc7TChRhImfj7YJyvbz4fz31jidkcxBehsnZCSRNYBFVsbtX
X-Developer-Key: i=hbarnor@chromium.org; a=ed25519;
 pk=JKPg5qzWEnyydlog1gYUHR7MFuQ8kSrmT8lacyNN9JI=
X-Endpoint-Received: by B4 Relay for hbarnor@chromium.org/20260310 with auth_id=673
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In systems using suspend-to-idle, the serio core calls atkbd_cleanup()
during the suspend transition. Currently, this function unconditionally
calls atkbd_disable(), setting atkbd->enabled to false.

This creates a race condition during wakeup: when a key is pressed to
wake the system, atkbd_receive_byte() is triggered. It correctly signals
a wakeup event to the PM core, but then checks atkbd->enabled. Because
the driver was disabled during suspend, the scancode is discarded.
The system wakes up, but the initial keystroke is lost.

This is particularly problematic for platforms like Android that rely on
the input event itself to complete the wakeup transition and turn on the
screen. On these systems, the device wakes up but remains in a dim state
because the initial interaction was lost.

This patch modifies atkbd_cleanup() to skip disabling and resetting
the keyboard if the device is configured as a wakeup source. This
preserves atkbd->enabled = true through the sleep duration, ensuring
the wake-up scancode is reported to the input subsystem.

Note that this also affects the shutdown path. However, if a device is
configured for wakeup, skipping the reset to "default" state is
consistent with the goal of allowing the hardware to trigger a
system-state transition. Modern BIOS/UEFI implementations perform their
own keyboard initialization, so skipping the legacy reset on reboot
for these devices poses minimal risk.

Signed-off-by: Henry Barnor <hbarnor@chromium.org>
---
 drivers/input/keyboard/atkbd.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/input/keyboard/atkbd.c b/drivers/input/keyboard/atkbd.c
index 4560d3964eee..1fba1932412e 100644
--- a/drivers/input/keyboard/atkbd.c
+++ b/drivers/input/keyboard/atkbd.c
@@ -958,6 +958,9 @@ static void atkbd_cleanup(struct serio *serio)
 {
 	struct atkbd *atkbd = atkbd_from_serio(serio);
 
+	if (device_may_wakeup(&serio->dev))
+		return;
+
 	atkbd_disable(atkbd);
 	ps2_command(&atkbd->ps2dev, NULL, ATKBD_CMD_RESET_DEF);
 }

---
base-commit: 6d4b67a2a76a4ff2393fe88119ae4332821b82b4
change-id: 20260310-wakeup-ec57a88a0162

Best regards,
-- 
Henry Barnor <hbarnor@chromium.org>

