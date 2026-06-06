From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Fri, 05 Jun 2026 22:42:33 -0700
Subject: [PATCH net-next v4 02/16] net: phy: Helper to modify PHY loopback
 mode only.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-s2500-mac-phy-support-v4-2-de0fbc13c6d8@onsemi.com>
References: <20260605-s2500-mac-phy-support-v4-0-de0fbc13c6d8@onsemi.com>
In-Reply-To: <20260605-s2500-mac-phy-support-v4-0-de0fbc13c6d8@onsemi.com>
To: Andrew Lunn <andrew@lunn.ch>, 
 Piergiorgio Beruto <pier.beruto@onsemi.com>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Richard Cochran <richardcochran@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780724562; l=3209;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=QFlNGDq2qBU9Dz3lBBmjbo5FS53f0zd8GFs5ucZ/t5o=;
 b=cBCxfDAUn3mw+TZzZG7myc4Jw3MgR+2ppDD/Nb3CmgKcYxqPID8t1piZxnZdC+ukdgJ3fNB1J
 hesWwabsixjC1YY1UeHyvF0bEFR190Z+SJfiyI6FBOfXtu8njBhCD8Z
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Generic helper function to modify loopback bit of the PHY without
modifying any other bit. This will help the PHYs that may have fixed
speed, like 10Base-T1S or PHYs that don't need any other settings
to set them in loopback mode.

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
---
 drivers/net/phy/dp83867.c    | 11 +----------
 drivers/net/phy/phy_device.c | 20 ++++++++++++++++++++
 include/linux/phy.h          |  2 ++
 3 files changed, 23 insertions(+), 10 deletions(-)

diff --git a/drivers/net/phy/dp83867.c b/drivers/net/phy/dp83867.c
index 88255e92b4cd..01ea2e8dd253 100644
--- a/drivers/net/phy/dp83867.c
+++ b/drivers/net/phy/dp83867.c
@@ -991,15 +991,6 @@ static void dp83867_link_change_notify(struct phy_device *phydev)
 	}
 }
 
-static int dp83867_loopback(struct phy_device *phydev, bool enable, int speed)
-{
-	if (enable && speed)
-		return -EOPNOTSUPP;
-
-	return phy_modify(phydev, MII_BMCR, BMCR_LOOPBACK,
-			  enable ? BMCR_LOOPBACK : 0);
-}
-
 static int
 dp83867_led_brightness_set(struct phy_device *phydev,
 			   u8 index, enum led_brightness brightness)
@@ -1204,7 +1195,7 @@ static struct phy_driver dp83867_driver[] = {
 		.resume		= dp83867_resume,
 
 		.link_change_notify = dp83867_link_change_notify,
-		.set_loopback	= dp83867_loopback,
+		.set_loopback	= genphy_loopback_fixed_speed,
 
 		.led_brightness_set = dp83867_led_brightness_set,
 		.led_hw_is_supported = dp83867_led_hw_is_supported,
diff --git a/drivers/net/phy/phy_device.c b/drivers/net/phy/phy_device.c
index 20c92fde4fbb..738c995e11d2 100644
--- a/drivers/net/phy/phy_device.c
+++ b/drivers/net/phy/phy_device.c
@@ -2836,6 +2836,26 @@ int genphy_phy_write_mmd(struct phy_device *phydev, int devnum,
 }
 EXPORT_SYMBOL(genphy_phy_write_mmd);
 
+/**
+ * genphy_loopback_fixed_speed - Helper to modify the PHY loopback mode
+ * without affecting any other settings.
+ * @phydev: The phy_device struct
+ * @enable: Flag to enable or disable the PHY level loopback.
+ * @speed: Speed setting. Not expected to be set. Error if it is set.
+ *
+ * Returns: 0 if successful, negative error code on failure.
+ */
+int genphy_loopback_fixed_speed(struct phy_device *phydev, bool enable,
+				int speed)
+{
+	if (enable && speed)
+		return -EOPNOTSUPP;
+
+	return phy_modify(phydev, MII_BMCR, BMCR_LOOPBACK,
+			  enable ? BMCR_LOOPBACK : 0);
+}
+EXPORT_SYMBOL(genphy_loopback_fixed_speed);
+
 int genphy_suspend(struct phy_device *phydev)
 {
 	return phy_set_bits(phydev, MII_BMCR, BMCR_PDOWN);
diff --git a/include/linux/phy.h b/include/linux/phy.h
index 8266dd4a8dbe..61bcd71a3143 100644
--- a/include/linux/phy.h
+++ b/include/linux/phy.h
@@ -2301,6 +2301,8 @@ int genphy_read_mmd_unsupported(struct phy_device *phdev, int devad,
 				u16 regnum);
 int genphy_write_mmd_unsupported(struct phy_device *phdev, int devnum,
 				 u16 regnum, u16 val);
+int genphy_loopback_fixed_speed(struct phy_device *phydev, bool enable,
+				int speed);
 int genphy_phy_write_mmd(struct phy_device *phydev, int devnum,
 			 u16 regnum, u16 val);
 int genphy_phy_read_mmd(struct phy_device *phydev, int devnum,

-- 
2.43.0

