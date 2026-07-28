From: Daniel Schaefer <dhs@frame.work>
Date: Wed, 29 Jul 2026 00:38:16 +0800
Subject: [PATCH] hwmon: (cros_ec): Hide unconfigured temperature thresholds
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260729-crosec-hwmon-warn-default-v1-1-d1eb39656a60@frame.work>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MTQrDIBBA4auEWWfAWjAxVylZiI7NQKJlbH5Ac
 vdKl9/ivQqFhKnA1FUQOrhwTg2PvgO/uPQm5NAMWmmjBm3RSy7kcTm3nPB0kjBQdPv6RRuf3o2
 GwqgstP4jFPn6v1/zff8AeixSrWsAAAA=
X-Change-ID: 20260729-crosec-hwmon-warn-default-9f3ca86ed809
To: =?utf-8?q?Thomas_Wei=C3=9Fschuh?= <linux@weissschuh.net>, 
 Guenter Roeck <linux@roeck-us.net>, Benson Leung <bleung@chromium.org>
Cc: Guenter Roeck <groeck@chromium.org>, chrome-platform@lists.linux.dev, 
 linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Tzung-Bi Shih <tzungbi@kernel.org>, linux@frame.work, 
 Daniel Schaefer <dhs@frame.work>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785256715; l=2383;
 i=dhs@frame.work; s=20260705; h=from:subject:message-id;
 bh=omT2q4whEkcOxIo9J62StUBGxjYSON9mpSvOGW/FPB0=;
 b=5zdOPE+UO3y/L/rqzb0IEk89jDSc4q711o3or0oJz0xKy5PD1Rnmq9V3RiA5qpEALEkEGOPcs
 MDv1WmTiZnvAS+gLp0BvoqgxSdSmOBxpHSpFVqNZ2/yGocxgk2kzNh+
X-Developer-Key: i=dhs@frame.work; a=ed25519;
 pk=O1zF7VDnmz6EZNc7sEiawR+KK650uRg1XteQ8jHwScw=
X-Endpoint-Received: by B4 Relay for dhs@frame.work/20260705 with auth_id=852
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The EC reports a threshold of 0 K for host thresholds that are not
configured. Most Framework Computer systems don't use all thresholds.
E.g. temp_host_warn is left unset and stays at its -273 C / 0 K
default), see the EC code in zephyr/shim/src/thermal.c:

  DT_PROP_OR(node_id, temp_host_warn,  -273)

Previously these unconfigured thresholds were exposed as sysfs limits
that read back as -273.15 C, which userspace (e.g. s-tui) interpreted as
a real, permanently-exceeded limit.

To avoid this we can hide the sysfs attribute for that threshold.
See truncated example below.

Before:

> sensors cros_ec-isa-000c
cpu_f75303@4d:       +36.9°C  (crit = +74.8°C, emerg = +84.8°C)

After:

> sensors cros_ec-isa-000c
cpu_f75303@4d:       +36.9°C  (high = -273.1°C, crit = +74.8°C)
                              (emerg = +84.8°C)

Cc: Tzung-Bi Shih <tzungbi@kernel.org>
Cc: Thomas Weißschuh <linux@weissschuh.net>
Cc: linux@frame.work
Signed-off-by: Daniel Schaefer <dhs@frame.work>
---
 drivers/hwmon/cros_ec_hwmon.c | 14 ++++++++++++--
 1 file changed, 12 insertions(+), 2 deletions(-)

diff --git a/drivers/hwmon/cros_ec_hwmon.c b/drivers/hwmon/cros_ec_hwmon.c
index 03bfcc40bb7c..57158443dafe 100644
--- a/drivers/hwmon/cros_ec_hwmon.c
+++ b/drivers/hwmon/cros_ec_hwmon.c
@@ -319,6 +319,7 @@ static umode_t cros_ec_hwmon_is_visible(const void *data, enum hwmon_sensor_type
 					u32 attr, int channel)
 {
 	const struct cros_ec_hwmon_priv *priv = data;
+	u32 threshold;
 	u16 speed;
 
 	if (type == hwmon_fan) {
@@ -334,8 +335,17 @@ static umode_t cros_ec_hwmon_is_visible(const void *data, enum hwmon_sensor_type
 	} else if (type == hwmon_temp) {
 		if (priv->temp_sensor_names[channel]) {
 			if (cros_ec_hwmon_attr_is_temp_threshold(attr)) {
-				if (priv->temp_threshold_supported)
-					return 0444;
+				if (!priv->temp_threshold_supported)
+					return 0;
+
+				if (cros_ec_hwmon_read_temp_threshold(priv->cros_ec, channel,
+								      cros_ec_hwmon_attr_to_thres(attr),
+								      &threshold) != 0)
+					return 0;
+				if (threshold == 0)
+					return 0;
+
+				return 0444;
 			} else {
 				return 0444;
 			}

---
base-commit: 58717b2a1365d06c8c64b72aa948541b53fe31eb
change-id: 20260729-crosec-hwmon-warn-default-9f3ca86ed809

Best regards,
-- 
Daniel Schaefer <dhs@frame.work>

