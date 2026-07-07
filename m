From: Ciprian Regus <ciprian.regus@analog.com>
Date: Wed, 08 Jul 2026 01:33:31 +0300
Subject: [PATCH net-next v5 03/13] net: ethernet: oa_tc6: add
 OA_TC6_BROKEN_PHY quirk flag
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-adin1140-driver-v5-3-4aca7b51a58b@analog.com>
References: <20260708-adin1140-driver-v5-0-4aca7b51a58b@analog.com>
In-Reply-To: <20260708-adin1140-driver-v5-0-4aca7b51a58b@analog.com>
To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org, devicetree@vger.kernel.org, 
 Ciprian Regus <ciprian.regus@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783463678; l=5163;
 i=ciprian.regus@analog.com; s=20260330; h=from:subject:message-id;
 bh=QpAiZBACFI2kW4Gp87tAl5cBMGywT0kMsfk7UIJvwmQ=;
 b=xx821xG6z4+MFaTdZgjm3yd1mRaW3y4TAPk9hGk3Hc+j88se/u2JW7a2j36Tp3JYVwZEjS/ZE
 valz3zDebY2DwSpTXMx9SvJ1gEygiZG2iuAICN0my7Jkpvx5C/QROR7
X-Developer-Key: i=ciprian.regus@analog.com; a=ed25519;
 pk=8WoNhI0kQcQUl8YqJO5ZevROYk9HP8lOIeIgIYgjfbc=
X-Endpoint-Received: by B4 Relay for ciprian.regus@analog.com/20260330 with auth_id=703
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some MAC-PHY devices need custom MDIO bus access functions to work
around hardware issues. Add the OA_TC6_BROKEN_PHY quirk flag so drivers
can opt in to skip oa_tc6's internal PHY init and manage the PHY
themselves. When the flag is set, oa_tc6 skips MDIO bus registration,
PHY discovery and PHY connection, leaving these to the driver.

Drivers that do not set the flag retain the existing behavior. Update
lan865x and the framework documentation accordingly.

Signed-off-by: Ciprian Regus <ciprian.regus@analog.com>

---
v5:
 - no change
v4 changelog:
 - no change
v3 changelog:
 - add the oa_tc6_quirks struct to the oa_tc6_init() parameters (along
   the spi_device and net_device), instead of adding everything in a
   single struct.
v2 changelog:
 - Added the quirk flag field in the oa_tc6_config struct and a first
   value entry (OA_TC6_BROKEN_PHY) instead of the mii_bus struct.
---
 Documentation/networking/oa-tc6-framework.rst    |  3 ++-
 drivers/net/ethernet/microchip/lan865x/lan865x.c |  2 +-
 drivers/net/ethernet/oa_tc6.c                    | 14 +++++++++++++-
 include/linux/oa_tc6.h                           | 11 ++++++++++-
 4 files changed, 26 insertions(+), 4 deletions(-)

diff --git a/Documentation/networking/oa-tc6-framework.rst b/Documentation/networking/oa-tc6-framework.rst
index fe2aabde923a..013824078cea 100644
--- a/Documentation/networking/oa-tc6-framework.rst
+++ b/Documentation/networking/oa-tc6-framework.rst
@@ -454,7 +454,8 @@ Device drivers API
 The include/linux/oa_tc6.h defines the following functions:
 
 .. c:function:: struct oa_tc6 *oa_tc6_init(struct spi_device *spi, \
-                                           struct net_device *netdev)
+                                           struct net_device *netdev, \
+                                           struct oa_tc6_quirks *quirks)
 
 Initialize OA TC6 lib.
 
diff --git a/drivers/net/ethernet/microchip/lan865x/lan865x.c b/drivers/net/ethernet/microchip/lan865x/lan865x.c
index 0277d9737369..26a2761332a5 100644
--- a/drivers/net/ethernet/microchip/lan865x/lan865x.c
+++ b/drivers/net/ethernet/microchip/lan865x/lan865x.c
@@ -346,7 +346,7 @@ static int lan865x_probe(struct spi_device *spi)
 	spi_set_drvdata(spi, priv);
 	INIT_WORK(&priv->multicast_work, lan865x_multicast_work_handler);
 
-	priv->tc6 = oa_tc6_init(spi, netdev);
+	priv->tc6 = oa_tc6_init(spi, netdev, NULL);
 	if (!priv->tc6) {
 		ret = -ENODEV;
 		goto free_netdev;
diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6.c
index 8b9655883496..fa1359224535 100644
--- a/drivers/net/ethernet/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6.c
@@ -135,6 +135,7 @@ struct oa_tc6 {
 	bool int_flag;
 	bool disable_traffic;
 	bool prot_ctrl;
+	enum oa_tc6_quirk_flag quirk_flags;
 };
 
 enum oa_tc6_header_type {
@@ -581,6 +582,9 @@ static int oa_tc6_phy_init(struct oa_tc6 *tc6)
 {
 	int ret;
 
+	if (tc6->quirk_flags & OA_TC6_BROKEN_PHY)
+		return 0;
+
 	ret = oa_tc6_check_phy_reg_direct_access_capability(tc6);
 	if (ret) {
 		netdev_err(tc6->netdev,
@@ -617,6 +621,9 @@ static int oa_tc6_phy_init(struct oa_tc6 *tc6)
 
 static void oa_tc6_phy_exit(struct oa_tc6 *tc6)
 {
+	if (tc6->quirk_flags & OA_TC6_BROKEN_PHY)
+		return;
+
 	phy_disconnect(tc6->phydev);
 	oa_tc6_mdiobus_unregister(tc6);
 }
@@ -1327,11 +1334,13 @@ static int oa_tc6_check_ctrl_protection(struct oa_tc6 *tc6)
  * oa_tc6_init - allocates and initializes oa_tc6 structure.
  * @spi: device with which data will be exchanged.
  * @netdev: network device interface structure.
+ * @quirks: device specific modifiers for the OA TC6 protocol.
  *
  * Return: pointer reference to the oa_tc6 structure if the MAC-PHY
  * initialization is successful otherwise NULL.
  */
-struct oa_tc6 *oa_tc6_init(struct spi_device *spi, struct net_device *netdev)
+struct oa_tc6 *oa_tc6_init(struct spi_device *spi, struct net_device *netdev,
+			   struct oa_tc6_quirks *quirks)
 {
 	struct oa_tc6 *tc6;
 	int ret;
@@ -1346,6 +1355,9 @@ struct oa_tc6 *oa_tc6_init(struct spi_device *spi, struct net_device *netdev)
 	mutex_init(&tc6->spi_ctrl_lock);
 	spin_lock_init(&tc6->tx_skb_lock);
 
+	if (quirks)
+		tc6->quirk_flags = quirks->quirk_flags;
+
 	/* Set the SPI controller to pump at realtime priority */
 	tc6->spi->rt = true;
 	if (spi_setup(tc6->spi) < 0)
diff --git a/include/linux/oa_tc6.h b/include/linux/oa_tc6.h
index 15f58e3c56c7..62e3d89f80ed 100644
--- a/include/linux/oa_tc6.h
+++ b/include/linux/oa_tc6.h
@@ -12,7 +12,16 @@
 
 struct oa_tc6;
 
-struct oa_tc6 *oa_tc6_init(struct spi_device *spi, struct net_device *netdev);
+enum oa_tc6_quirk_flag {
+	OA_TC6_BROKEN_PHY = BIT(0),
+};
+
+struct oa_tc6_quirks {
+	enum oa_tc6_quirk_flag quirk_flags;
+};
+
+struct oa_tc6 *oa_tc6_init(struct spi_device *spi, struct net_device *netdev,
+			   struct oa_tc6_quirks *quirks);
 void oa_tc6_exit(struct oa_tc6 *tc6);
 int oa_tc6_write_register(struct oa_tc6 *tc6, u32 address, u32 value);
 int oa_tc6_write_registers(struct oa_tc6 *tc6, u32 address, u32 value[],

-- 
2.43.0

