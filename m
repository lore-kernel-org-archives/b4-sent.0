From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 12 Jun 2026 21:10:33 -0500
Subject: [PATCH] Input: goodix - clamp the device-reported contact count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260612-b4-disp-6844625d-v1-1-df0aed080c9d@proton.me>
X-B4-Tracking: v=1; b=H4sIABi8LGoC/x3MPQqAMAxA4atIZgP2xyheRRy0TTWLlhZEKN7d4
 vgN7xXInIQzTE2BxLdkuc4K1TbgjvXcGcVXg+40daQ0bha95Ig0Wku692jJhFGpwXhHULOYOMj
 zL+flfT8IznHBYgAAAA==
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Hans de Goede <hansg@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781316632; l=2188;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=8Qj7c/zb9l+DCDhqBZQh8IHkrnwoVRmOpltbzUeTh9w=;
 b=inOWvX4CMyP+Ep+Qnn4+GrGd5mVgMpKH3p+6iWXdPmMrSvQjTr9oNI/CgNeh97LY9KqGCUKur
 kbULJ1LuAaVB+4OEWnc20OB4mBnQeAgntflkGwO5cK1DZHcBX3M6gcO
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

goodix_ts_read_input_report() copies the number of touch points reported
by the device into an on-stack buffer

	u8 point_data[2 + GOODIX_MAX_CONTACT_SIZE * GOODIX_MAX_CONTACTS];

which is sized for at most GOODIX_MAX_CONTACTS (10) contacts. The only
runtime check bounds the per-interrupt count against ts->max_touch_num,
but that value is taken verbatim from a 4-bit field of the device
configuration block and is never clamped:

	ts->max_touch_num = ts->config[MAX_CONTACTS_LOC] & 0x0f;

The nibble can be 0..15, so a malfunctioning, malicious or counterfeit
controller (or an attacker tampering with the I2C bus) can advertise up
to 15 contacts. goodix_ts_read_input_report() then accepts a touch_num
of up to 15 and the second goodix_i2c_read() writes
ts->contact_size * (touch_num - 1) bytes past the one-contact header into
point_data - up to 30 bytes (45 with the 9-byte report format) beyond the
92-byte buffer: a stack out-of-bounds write.

Clamp max_touch_num to GOODIX_MAX_CONTACTS, the number of contacts
point_data[] is sized for, when reading it from the configuration.

Fixes: a7ac7c95d468 ("Input: goodix - use max touch number from device config")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/input/touchscreen/goodix.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/input/touchscreen/goodix.c b/drivers/input/touchscreen/goodix.c
index f8798d11ec03..17fcfe45988c 100644
--- a/drivers/input/touchscreen/goodix.c
+++ b/drivers/input/touchscreen/goodix.c
@@ -1057,7 +1057,8 @@ static void goodix_read_config(struct goodix_ts_data *ts)
 	}
 
 	ts->int_trigger_type = ts->config[TRIGGER_LOC] & 0x03;
-	ts->max_touch_num = ts->config[MAX_CONTACTS_LOC] & 0x0f;
+	ts->max_touch_num = min(ts->config[MAX_CONTACTS_LOC] & 0x0f,
+				GOODIX_MAX_CONTACTS);
 
 	x_max = get_unaligned_le16(&ts->config[RESOLUTION_LOC]);
 	y_max = get_unaligned_le16(&ts->config[RESOLUTION_LOC + 2]);

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260612-b4-disp-6844625d-463f81173dc6

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

