From: Ciprian Regus <ciprian.regus@analog.com>
Date: Wed, 27 May 2026 00:51:48 +0300
Subject: [PATCH net-next v2 03/10] net: ethernet: oa_tc6: add
 OA_TC6_BROKEN_PHY quirk flag
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-adin1140-driver-v2-3-37e5c8d4e0a0@analog.com>
References: <20260527-adin1140-driver-v2-0-37e5c8d4e0a0@analog.com>
In-Reply-To: <20260527-adin1140-driver-v2-0-37e5c8d4e0a0@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779832338; l=5464;
 i=ciprian.regus@analog.com; s=20260330; h=from:subject:message-id;
 bh=MPRIc8vmHW/vXPKJZwVJUFyrwrfcbow4YLTfjncEe+U=;
 b=NjdT2brTF2fS6tAjlgi1zzBHEIQOL5rVJWErUbQWKGoej/DXgNvIM1tsgVPwKM5MvMBSKpqhQ
 njgbUjCcU0SCA22SqJS5BcFcpLVfa8Meof+Li0ShZXWe4HyquckY29k
X-Developer-Key: i=ciprian.regus@analog.com; a=ed25519;
 pk=8WoNhI0kQcQUl8YqJO5ZevROYk9HP8lOIeIgIYgjfbc=
X-Endpoint-Received: by B4 Relay for ciprian.regus@analog.com/20260330 with auth_id=703
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some MAC-PHY devices need custom MDIO bus access functions to work
around hardware issues. Add the OA_TC6_BROKEN_PHY quirk flag so drivers
can opt in to skip oa_tc6's internal PHY init and manage the PHY
themselves. When the flag is set, oa_tc6 skips MDIO bus registration,
PHY discovery and PHY connection, leaving these to the driver.

Drivers that do not set the flag retain the existing behavior.

To avoid extending the oa_tc6_init() signature for each new option,
convert it to take a config struct. Update lan865x and the framework
documentation accordingly.

Signed-off-by: Ciprian Regus <ciprian.regus@analog.com>

---
v2 changelog:
 - Added the quirk flag field in the oa_tc6_config struct and a first
   value entry (OA_TC6_BROKEN_PHY) instead of the mii_bus struct.
---
 Documentation/networking/oa-tc6-framework.rst    |  3 +--
 drivers/net/ethernet/microchip/lan865x/lan865x.c |  6 +++++-
 drivers/net/ethernet/oa_tc6.c                    | 25 +++++++++++++++++-------
 include/linux/oa_tc6.h                           | 12 +++++++++++-
 4 files changed, 35 insertions(+), 11 deletions(-)

diff --git a/Documentation/networking/oa-tc6-framework.rst b/Documentation/networking/oa-tc6-framework.rst
index fe2aabde923a..eaa5b4b85b34 100644
--- a/Documentation/networking/oa-tc6-framework.rst
+++ b/Documentation/networking/oa-tc6-framework.rst
@@ -453,8 +453,7 @@ Device drivers API
 
 The include/linux/oa_tc6.h defines the following functions:
 
-.. c:function:: struct oa_tc6 *oa_tc6_init(struct spi_device *spi, \
-                                           struct net_device *netdev)
+.. c:function:: struct oa_tc6 *oa_tc6_init(struct oa_tc6_config *config);
 
 Initialize OA TC6 lib.
 
diff --git a/drivers/net/ethernet/microchip/lan865x/lan865x.c b/drivers/net/ethernet/microchip/lan865x/lan865x.c
index 0277d9737369..c509c8a3e321 100644
--- a/drivers/net/ethernet/microchip/lan865x/lan865x.c
+++ b/drivers/net/ethernet/microchip/lan865x/lan865x.c
@@ -332,6 +332,7 @@ static const struct net_device_ops lan865x_netdev_ops = {
 
 static int lan865x_probe(struct spi_device *spi)
 {
+	struct oa_tc6_config tc6_config = {};
 	struct net_device *netdev;
 	struct lan865x_priv *priv;
 	int ret;
@@ -346,7 +347,10 @@ static int lan865x_probe(struct spi_device *spi)
 	spi_set_drvdata(spi, priv);
 	INIT_WORK(&priv->multicast_work, lan865x_multicast_work_handler);
 
-	priv->tc6 = oa_tc6_init(spi, netdev);
+	tc6_config.spi = spi;
+	tc6_config.netdev = netdev;
+
+	priv->tc6 = oa_tc6_init(&tc6_config);
 	if (!priv->tc6) {
 		ret = -ENODEV;
 		goto free_netdev;
diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6.c
index baba5aad84df..7ae3639beadd 100644
--- a/drivers/net/ethernet/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6.c
@@ -134,6 +134,7 @@ struct oa_tc6 {
 	bool rx_buf_overflow;
 	bool int_flag;
 	bool prot_ctrl;
+	enum oa_tc6_quirk_flag quirk_flags;
 };
 
 enum oa_tc6_header_type {
@@ -580,6 +581,9 @@ static int oa_tc6_phy_init(struct oa_tc6 *tc6)
 {
 	int ret;
 
+	if (tc6->quirk_flags & OA_TC6_BROKEN_PHY)
+		return 0;
+
 	ret = oa_tc6_check_phy_reg_direct_access_capability(tc6);
 	if (ret) {
 		netdev_err(tc6->netdev,
@@ -616,6 +620,9 @@ static int oa_tc6_phy_init(struct oa_tc6 *tc6)
 
 static void oa_tc6_phy_exit(struct oa_tc6 *tc6)
 {
+	if (tc6->quirk_flags & OA_TC6_BROKEN_PHY)
+		return;
+
 	phy_disconnect(tc6->phydev);
 	oa_tc6_mdiobus_unregister(tc6);
 }
@@ -1277,24 +1284,28 @@ static int oa_tc6_check_ctrl_protection(struct oa_tc6 *tc6)
 
 /**
  * oa_tc6_init - allocates and initializes oa_tc6 structure.
- * @spi: device with which data will be exchanged.
- * @netdev: network device interface structure.
+ * @config: pointer to a caller-filled structure describing the MACPHY
+ *          (SPI device, net_device, and config flags).
  *
  * Return: pointer reference to the oa_tc6 structure if the MAC-PHY
  * initialization is successful otherwise NULL.
  */
-struct oa_tc6 *oa_tc6_init(struct spi_device *spi, struct net_device *netdev)
+struct oa_tc6 *oa_tc6_init(struct oa_tc6_config *config)
 {
 	struct oa_tc6 *tc6;
 	int ret;
 
-	tc6 = devm_kzalloc(&spi->dev, sizeof(*tc6), GFP_KERNEL);
+	if (!config)
+		return NULL;
+
+	tc6 = devm_kzalloc(&config->spi->dev, sizeof(*tc6), GFP_KERNEL);
 	if (!tc6)
 		return NULL;
 
-	tc6->spi = spi;
-	tc6->netdev = netdev;
-	SET_NETDEV_DEV(netdev, &spi->dev);
+	tc6->spi = config->spi;
+	tc6->netdev = config->netdev;
+	tc6->quirk_flags = config->quirk_flags;
+	SET_NETDEV_DEV(tc6->netdev, &tc6->spi->dev);
 	mutex_init(&tc6->spi_ctrl_lock);
 	spin_lock_init(&tc6->tx_skb_lock);
 
diff --git a/include/linux/oa_tc6.h b/include/linux/oa_tc6.h
index 15f58e3c56c7..6c38bf49e2a7 100644
--- a/include/linux/oa_tc6.h
+++ b/include/linux/oa_tc6.h
@@ -12,7 +12,17 @@
 
 struct oa_tc6;
 
-struct oa_tc6 *oa_tc6_init(struct spi_device *spi, struct net_device *netdev);
+enum oa_tc6_quirk_flag {
+	OA_TC6_BROKEN_PHY = BIT(0),
+};
+
+struct oa_tc6_config {
+	struct spi_device *spi;
+	struct net_device *netdev;
+	enum oa_tc6_quirk_flag quirk_flags;
+};
+
+struct oa_tc6 *oa_tc6_init(struct oa_tc6_config *config);
 void oa_tc6_exit(struct oa_tc6 *tc6);
 int oa_tc6_write_register(struct oa_tc6 *tc6, u32 address, u32 value);
 int oa_tc6_write_registers(struct oa_tc6 *tc6, u32 address, u32 value[],

-- 
2.43.0

