From: Hleb Shauchenka <me@marleb.org>
Date: Sun, 08 Nov 2026 22:13:45 +0100
Subject: [PATCH net-next v3] net: phy: realtek: return MDIO read errors
 from hwmon
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-realtek-hwmon-tz-v3-1-b4e9fb16d323@marleb.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WOwXLCMAxEf4XxGdHYCTHm1P9gONhGJGqJ3ZFNo
 GXy7yThAjP0uLvS272JhEyYxHZxE4w9JYphFOVyIXxrQ4NAh1ELVahayqIERnvK+A3tpYsB8h+
 YtSq1NUq6oxHj2w/jka4zcicCZgh4zWL/SNLZfaHPE3G6dTYhOLbBt5MVmRoKH52lMKUtpRz5d
 97Wy5n3/4xeggSstdKq9OuNd5+d5RO6VeRmbu/VM0G/ISgooHbG1uZQVZUuXgjDMNwBfY53XS0
 BAAA=
X-Change-ID: 20261103-realtek-hwmon-tz-95237a921bf9
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hleb Shauchenka <me@marleb.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2366; i=me@marleb.org;
 h=from:subject:message-id; bh=5AKdSsLeZoi/+Kn1tEFUpy3mbr1m+5jW94geBAoL4co=;
 b=owJ4nJvAy8zAJTZJnM368y8lXsbTakkMWR+eSVi1KVY4Vc3v8pvwIE/FzeBPUYR6eNP9C1stb
 lpkJNlmr+4oZWEQ42KQFVNk2dRcJPp0ZfRb1+o9WTBzWJlAhjBwcQrARNYrMTJMN1h+qPnclRcX
 hQS6v1kw/FvxLPPM+0y9bxU/v6y/wbp4ASPDx55uD4UdZ73s2oJDuGtDNrM4mKwrF3x3713cvE4
 +nU/sAGBtSQw=
X-Developer-Key: i=me@marleb.org; a=openpgp;
 fpr=B2837215E5A95BED457BBC6A9217063BF3FA220D
X-Endpoint-Received: by B4 Relay for me@marleb.org/default with auth_id=1394
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rtl822x_hwmon_read() masks or shifts the value returned by
phy_read_mmd() without checking it and returns success, so a failed
MDIO read is reported as a temperature: -EIO reads as -2.5 C and
-ETIMEDOUT as -55 C.

Return the error instead, so that readers of the hwmon attributes see
the failure rather than a plausible but wrong temperature.

Signed-off-by: Hleb Shauchenka <me@marleb.org>
---
This patch was prepared with AI assistance (Claude Opus 5.5), after an
AI review of v1 pointed out the problem. It is build-tested only: I
could not provoke a failed MDIO read on hardware.
---
Changes in v3:
- Drop the binding and HWMON_C_REGISTER_TZ patches: their only user is
  out-of-tree code.
- Send this patch alone, without the Fixes tag.
- Move the AI note below the ---.
- Link to v2: https://patch.msgid.link/20261107-realtek-hwmon-tz-v2-0-6b9a69d44470@marleb.org

Changes in v2:
- New patch, in a series with two others.
- Link to v1: https://patch.msgid.link/20261103-realtek-hwmon-tz-v1-1-e672723c58cb@marleb.org
---
 drivers/net/phy/realtek/realtek_hwmon.c | 12 ++++++++----
 1 file changed, 8 insertions(+), 4 deletions(-)

diff --git a/drivers/net/phy/realtek/realtek_hwmon.c b/drivers/net/phy/realtek/realtek_hwmon.c
index ac96e2d1e..b6b2806e2 100644
--- a/drivers/net/phy/realtek/realtek_hwmon.c
+++ b/drivers/net/phy/realtek/realtek_hwmon.c
@@ -30,13 +30,17 @@ static int rtl822x_hwmon_read(struct device *dev, enum hwmon_sensor_types type,
 
 	switch (attr) {
 	case hwmon_temp_input:
-		raw = phy_read_mmd(phydev, MDIO_MMD_VEND2, RTL822X_VND2_TSRR) & 0x3ff;
-		*val = rtl822x_hwmon_get_temp(raw);
+		raw = phy_read_mmd(phydev, MDIO_MMD_VEND2, RTL822X_VND2_TSRR);
+		if (raw < 0)
+			return raw;
+		*val = rtl822x_hwmon_get_temp(raw & 0x3ff);
 		break;
 	case hwmon_temp_max:
 		/* Chip reduces speed to 1G if threshold is exceeded */
-		raw = phy_read_mmd(phydev, MDIO_MMD_VEND2, RTL822X_VND2_TSSR) >> 6;
-		*val = rtl822x_hwmon_get_temp(raw);
+		raw = phy_read_mmd(phydev, MDIO_MMD_VEND2, RTL822X_VND2_TSSR);
+		if (raw < 0)
+			return raw;
+		*val = rtl822x_hwmon_get_temp(raw >> 6);
 		break;
 	default:
 		return -EINVAL;

---
base-commit: fa5196392691051963726787944db872420dfa75
change-id: 20261103-realtek-hwmon-tz-95237a921bf9

Best regards,
--  
Hleb Shauchenka <me@marleb.org>

