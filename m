From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Fri, 09 Oct 2026 10:12:26 -0700
Subject: [PATCH net-next v9 06/11] net: ethernet: oa_tc6: Support for
 vendor specific MMS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-s2500-mac-phy-support-v9-6-dcefe1d0bf0d@onsemi.com>
References: <20261009-s2500-mac-phy-support-v9-0-dcefe1d0bf0d@onsemi.com>
In-Reply-To: <20261009-s2500-mac-phy-support-v9-0-dcefe1d0bf0d@onsemi.com>
To: Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Richard Cochran <richardcochran@gmail.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Eric Dumazet <edumazet@kernel.org>, 
 Piergiorgio Beruto <piergiorgio.beruto@gmail.com>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: Selva Rajagopal <Selvamani.Rajagopal@onsemi.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Ciprian Regus <ciprian.regus@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791565943; l=4055;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=Ks5Fh9DsOCyqNGrCtIQYE/j/irrW7WmmO/xSglCfHKA=;
 b=ipxWyONeSKUkCF3wnygvpaIXTL+pONjHsjzyfo/oiNjXbzZYoF1p1QBVmtnKN23JpMjuUPlvV
 FUWB2jq/JKVCuZ+SoerHcsSmLlK7gWwEbwf6YyCxBtg/5oY9PWkfMMm
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

OPEN Alliance 10BASE-T1x Serial Interface specification, table 6
allows vendors to use any memory map select (MMS) value between
10 and 15. This new API interface enables vendor to map one of
thes MMS values to MDIO_MMD_VEND1.

Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v9
  - Added the missing vend1_mms initializer to where it belonged
  - Added Reviewed tag
changes in v8
  - No change
changes in v7
  - No change
changes in v6
  - No change
changes in v5
  - no change
changes in v4
  - no change
changes in v3
  - no change
changes in v2
  - Moved the handling of vendor specific MMS mapping to separate patch
  - new patch
---
 drivers/net/ethernet/oa_tc6/oa_tc6.c         | 21 ++++++++++++++++++---
 drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h |  1 +
 include/linux/oa_tc6.h                       |  1 +
 3 files changed, 20 insertions(+), 3 deletions(-)

diff --git a/drivers/net/ethernet/oa_tc6/oa_tc6.c b/drivers/net/ethernet/oa_tc6/oa_tc6.c
index 0b6e216de8a1..0c4f7d3f978f 100644
--- a/drivers/net/ethernet/oa_tc6/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6/oa_tc6.c
@@ -248,6 +248,18 @@ static int oa_tc6_update_standard_capability(struct oa_tc6 *tc6)
 	return 0;
 }
 
+/**
+ * oa_tc6_set_vend1_mms - Add vendor specific MDIO_MMD to OA TC6 MMS
+ * mapper value.
+ * @tc6: oa_tc6 struct.
+ * @mms: vendor defined MMS value for VEND1 mdio device.
+ */
+void oa_tc6_set_vend1_mms(struct oa_tc6 *tc6, int mms)
+{
+	tc6->vend1_mms = mms;
+}
+EXPORT_SYMBOL_GPL(oa_tc6_set_vend1_mms);
+
 static __be32 oa_tc6_prepare_ctrl_header(u32 addr, u8 length,
 					 enum oa_tc6_register_op reg_op)
 {
@@ -575,7 +587,7 @@ static int oa_tc6_mdiobus_write(struct mii_bus *bus, int addr, int regnum,
 				     val);
 }
 
-static int oa_tc6_get_phy_c45_mms(int devnum)
+static int oa_tc6_get_phy_c45_mms(struct oa_tc6 *tc6, int devnum)
 {
 	switch (devnum) {
 	case MDIO_MMD_PCS:
@@ -588,6 +600,8 @@ static int oa_tc6_get_phy_c45_mms(int devnum)
 		return OA_TC6_PHY_C45_AUTO_NEG_MMS5;
 	case MDIO_MMD_POWER_UNIT:
 		return OA_TC6_PHY_C45_POWER_UNIT_MMS6;
+	case MDIO_MMD_VEND1:
+		return tc6->vend1_mms;
 	default:
 		return -EOPNOTSUPP;
 	}
@@ -601,7 +615,7 @@ int oa_tc6_mdiobus_read_c45(struct mii_bus *bus, int addr, int devnum,
 	int mms;
 	int ret;
 
-	mms = oa_tc6_get_phy_c45_mms(devnum);
+	mms = oa_tc6_get_phy_c45_mms(tc6, devnum);
 	if (mms < 0)
 		return mms;
 
@@ -619,7 +633,7 @@ int oa_tc6_mdiobus_write_c45(struct mii_bus *bus, int addr, int devnum,
 	struct oa_tc6 *tc6 = bus->priv;
 	int mms;
 
-	mms = oa_tc6_get_phy_c45_mms(devnum);
+	mms = oa_tc6_get_phy_c45_mms(tc6, devnum);
 	if (mms < 0)
 		return mms;
 
@@ -1643,6 +1657,7 @@ struct oa_tc6 *oa_tc6_init(struct spi_device *spi, struct net_device *netdev,
 	SET_NETDEV_DEV(netdev, &spi->dev);
 	mutex_init(&tc6->spi_ctrl_lock);
 	spin_lock_init(&tc6->tx_skb_lock);
+	tc6->vend1_mms = -EOPNOTSUPP;
 	tc6->ttsc_current_id = OA_TC6_TTSCA_REG_ID;
 	INIT_LIST_HEAD(&tc6->tx_ts_skb_q);
 
diff --git a/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h b/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h
index 92e936a18490..cd62071d7f60 100644
--- a/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h
+++ b/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h
@@ -138,6 +138,7 @@ struct oa_tc6 {
 	u64 tx_hwtstamp_err;
 	u8 ts_ttsc_pending;
 	u8 ttsc_current_id;
+	int vend1_mms;
 };
 
 enum oa_tc6_header_type {
diff --git a/include/linux/oa_tc6.h b/include/linux/oa_tc6.h
index 365abdbf60d3..88e7d5491b20 100644
--- a/include/linux/oa_tc6.h
+++ b/include/linux/oa_tc6.h
@@ -114,5 +114,6 @@ void oa_tc6_get_ts_stats(struct oa_tc6 *tc6,
 			 struct ethtool_ts_stats *stats);
 int oa_tc6_hwtstamp_set(struct oa_tc6 *tc6,
 			struct kernel_hwtstamp_config *cfg);
+void oa_tc6_set_vend1_mms(struct oa_tc6 *tc6, int mms);
 void oa_tc6_ptp_unregister(struct oa_tc6 *tc6);
 #endif /* _LINUX_OA_TC6_H */

-- 
2.43.0

