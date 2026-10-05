From: Robert Killick <robert@killick.dev>
Date: Mon, 05 Oct 2026 14:56:45 +0100
Subject: [PATCH] power: supply: sysfs: Ratelimit "unavailable enum value"
 warning
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261005-ratelimit-enum-warn-v1-1-b77b48de3c47@killick.dev>
X-B4-Tracking: v=1; b=H4sIAJysw2oC/yXMQQrCMBBG4auUWTuQplDEqxQXk/hXR2wqk1SF0
 rs36vJbvLdShikynZqVDC/NOqeK9tBQvEm6gvVSTd75vnXOs0nBQyctjLRM/BZLPHa9kxAFxwC
 q5dMw6ud3Hc5/5yXcEct3Rdu2A20oTJJ3AAAA
X-Change-ID: 20261002-ratelimit-enum-warn-f360abcae8be
To: Sebastian Reichel <sre@kernel.org>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robert Killick <robert@killick.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791208618; l=1773;
 i=robert@killick.dev; s=20261002; h=from:subject:message-id;
 bh=0hIDydFjkseUzAVKpA0Mfmz7dmmCFwTP/Z/j3AT+hZE=;
 b=sFQgoHZ4wP22jFB/GdDWa/XWgIP/v5TNoGFBwDvVp5cGiKx6Xo15yuEiNq44lNxNVnLkSi5hm
 Otk0mSJu1ofAYCt5TDMig/d6MgIjWz4k6E+gi7NieZPM035PVKox02c
X-Developer-Key: i=robert@killick.dev; a=ed25519;
 pk=mhwmEhQGVPJdSo1NraEdUm+3PmWZr7havGKq6I7tqaE=
X-Endpoint-Received: by B4 Relay for robert@killick.dev/20261002 with auth_id=1103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

power_supply_show_enum_with_available() warns every time a driver
reports a value that is not in its declared set of available values.
For usb_type this happens on every sysfs read and on every uevent, so a
driver that reports such a value and calls power_supply_changed()
frequently can flood the kernel log.

This can happen with drivers that pass a firmware-provided value
through unchanged, as qcom_battmgr does for usb_type. On a OnePlus 10
Pro (SM8450), whose firmware reports a vendor-specific usb_type, this
produced ~128 warnings per second and kept systemd-journald at ~30% CPU.

The bug that causes the bad value needs fixing in the driver itself,
but one misbehaving driver should not be able to flood the kernel log.
Use dev_warn_ratelimited(), as power_supply_show_property() already
does for its own errors, so the problem is still reported, just not on
every read.

Signed-off-by: Robert Killick <robert@killick.dev>
---
 drivers/power/supply/power_supply_sysfs.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/power/supply/power_supply_sysfs.c b/drivers/power/supply/power_supply_sysfs.c
index b0f524d152cf..9704557ffe1d 100644
--- a/drivers/power/supply/power_supply_sysfs.c
+++ b/drivers/power/supply/power_supply_sysfs.c
@@ -310,7 +310,8 @@ static ssize_t power_supply_show_enum_with_available(
 	}
 
 	if (!match) {
-		dev_warn(dev, "driver reporting unavailable enum value %d\n", value);
+		dev_warn_ratelimited(dev, "driver reporting unavailable enum value %d\n",
+				     value);
 		return -EINVAL;
 	}
 

---
base-commit: 4fc88ba435dadbc05990951e3f3fbd8ccd2df140
change-id: 20261002-ratelimit-enum-warn-f360abcae8be

Best regards,
--  
Robert Killick <robert@killick.dev>

