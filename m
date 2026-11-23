From: Markus Haberlander <markus.haberlander@rosenberger.com>
Date: Mon, 23 Nov 2026 08:27:01 +0100
Subject: [PATCH] hwmon: (cgbc-hwmon) Add module alias
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-cgbc-hwmon-alias-v1-1-3054681f984a@rosenberger.com>
X-B4-Tracking: v=1; b=H4sIAMTqA2sC/yXMTQqDMBBA4avIrB0waSviVcRFMhl1pI2S6R+Id
 2+sy2/x3gbKSVihLTZI/BaVJWaYsgCaXBwZJWSDrWxtjL0gjZ5w+jyWiO4uTrEeODSer+RvFnK
 2Jh7k+192/Wl9+ZnpeXxg338lcVuKdAAAAA==
X-Change-ID: 20261123-cgbc-hwmon-alias-6fed8be4cb52
To: Thomas Richard <thomas.richard@bootlin.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-hwmon@vger.kernel.org, stable@vger.kernel.org, 
 Markus Haberlander <markus.haberlander@rosenberger.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795418823; l=1376;
 i=markus.haberlander@rosenberger.com; s=20261123; h=from:subject:message-id;
 bh=I1G2jkZQpMOQFY8S2qM+BAuBa5MQsimUYIi/nZNT3CA=;
 b=OPb4kGeErThGeH31e2Fvv0Y1ezpEFO3smdYlSDWT5OvuRRONVNquQBPgXYmnV3OBpGIJ2PD+p
 DFaxfT6oeeOBHFOkoVSsQR8d9mxOURiycJfjK6EZDumLkBGfkH+m5KH
X-Developer-Key: i=markus.haberlander@rosenberger.com; a=ed25519;
 pk=baNIWlZCf58g17gE2FS6ir0ymNwyBXguoQENSJkXdeQ=
X-Endpoint-Received: by B4 Relay for markus.haberlander@rosenberger.com/20261123 with auth_id=1612
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The board controller's core driver adds the hwmon cell as platform
device "cgbc-hwmon", but the driver declares no matching module alias.
Built as a module, it is therefore not loaded automatically, unlike the
GPIO, I2C and backlight drivers, and the sensors stay missing until it
is loaded by hand.

Tested on a conga-PA7: with the alias, the driver loads at boot.

The patch and this changelog were drafted with the help of Claude
Opus 5.5 and reviewed and tested by me.

Fixes: 08ebc9def79f ("hwmon: Add Congatec Board Controller monitoring driver")
Cc: stable@vger.kernel.org
Signed-off-by: Markus Haberlander <markus.haberlander@rosenberger.com>
---
 drivers/hwmon/cgbc-hwmon.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/hwmon/cgbc-hwmon.c b/drivers/hwmon/cgbc-hwmon.c
index ba21ed8f0..d1f20db4b 100644
--- a/drivers/hwmon/cgbc-hwmon.c
+++ b/drivers/hwmon/cgbc-hwmon.c
@@ -336,3 +336,4 @@ module_platform_driver(cgbc_hwmon_driver);
 MODULE_AUTHOR("Thomas Richard <thomas.richard@bootlin.com>");
 MODULE_DESCRIPTION("Congatec Board Controller Hardware Monitoring Driver");
 MODULE_LICENSE("GPL");
+MODULE_ALIAS("platform:cgbc-hwmon");

---
base-commit: 7940d60c4b165cd7c265bf17f86b8299b7f204b1
change-id: 20261123-cgbc-hwmon-alias-6fed8be4cb52

Best regards,
--  
Markus Haberlander <markus.haberlander@rosenberger.com>

