From: Hleb Shauchenka <me@marleb.org>
Date: Sat, 07 Nov 2026 18:00:46 +0100
Subject: [PATCH net-next v2 2/3] net: phy: realtek: return MDIO read errors
 from hwmon
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-realtek-hwmon-tz-v2-2-6b9a69d44470@marleb.org>
References: <20261107-realtek-hwmon-tz-v2-0-6b9a69d44470@marleb.org>
In-Reply-To: <20261107-realtek-hwmon-tz-v2-0-6b9a69d44470@marleb.org>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hleb Shauchenka <me@marleb.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1888; i=me@marleb.org;
 h=from:subject:message-id; bh=6gM5E4J0rm2zZGPKen73mZQlszekR/xfc4TyxcghaYg=;
 b=owJ4nJvAy8zAJTZJnM368y8lXsbTakkMWe8jUxXnvfZNqxCsenZs1ZQEq0JH59TA2bLLrKfvj
 lP9mbgo6lVHKQuDGBeDrJgiy6bmItGnK6PfulbvyYKZw8oEMoSBi1MAJtK+mJFh1UTJyj1FoSKu
 u56KRQaof1vyPzbxVr7cLuUHK6qOzLz8g+F/bEjTtIcF3yuVZ1m0HxFlnPGp8wDbkWbNNTu4265
 OdvvDDgBC6UmZ
X-Developer-Key: i=me@marleb.org; a=openpgp;
 fpr=B2837215E5A95BED457BBC6A9217063BF3FA220D
X-Endpoint-Received: by B4 Relay for me@marleb.org/default with auth_id=1394
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rtl822x_hwmon_read() masks or shifts the value returned by
phy_read_mmd() without checking it and returns success, so a failed
MDIO read is reported as a temperature: -EIO reads as -2.5 C and
-ETIMEDOUT as -55 C.

Return the error instead. Once the sensor feeds a thermal zone, the
thermal core then keeps its previous state rather than acting on a
bogus reading.

The problem was found by an AI review of the previous posting, and
this patch was prepared with AI assistance (Claude Opus 5.5). It is
build-tested only: I could not provoke a failed MDIO read on hardware.

Fixes: 33700ca45b7d ("net: phy: realtek: add hwmon support for temp sensor on RTL822x")
Signed-off-by: Hleb Shauchenka <me@marleb.org>
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

-- 
2.56.0

