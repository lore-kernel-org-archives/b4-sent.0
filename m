From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Wed, 08 Jul 2026 10:12:40 -0700
Subject: [PATCH net-next v7 10/15] net: ethernet: oa_tc6: read, write
 interface with MMS option
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-s2500-mac-phy-support-v7-10-478c877aa1a9@onsemi.com>
References: <20260708-s2500-mac-phy-support-v7-0-478c877aa1a9@onsemi.com>
In-Reply-To: <20260708-s2500-mac-phy-support-v7-0-478c877aa1a9@onsemi.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783530757; l=13396;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=uClvJf2x0lJjvG+k5KxNXMXLE6Y1WZlQrMXIDEmRFIw=;
 b=4q8RTvrG/v+DORZDtpfKQ/jGJ6Ol7NSIlHkTXjNX4KVdKOLHZsaAR0BzlPTQJq30rPyjpaG1S
 n3jeP+aBxe4BVuxKK7XVE0Pl90mGBoKVhajEVrxqyg+3fbb9JUj6B/P
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Vendors are allowed to use any memory map selector that
is between 10 and 15.

Current read/write API interface expects register address with
the value of MMS (memory map selector) embedded in it.

This requires vendors to encoding the address whenever the call
to read/write register is made. To avoid this extra step, and
to bring consistency in usage of the API by different vendors,
new APIs have been added to write and read registers with
MMS as one of the parameters.

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v7
  - No change
changes in v6
  - No change
changes in v5
  - No change
changes in v4
  - New API added to take MMS as a parameter to avoid need for
    read/write calls to encode MMS to the address.
  - first patch
---
 drivers/net/ethernet/microchip/lan865x/lan865x.c | 61 +++++++++------
 drivers/net/ethernet/oa_tc6/oa_tc6.c             | 97 +++++++++++++++++++++---
 include/linux/oa_tc6.h                           |  8 ++
 3 files changed, 131 insertions(+), 35 deletions(-)

diff --git a/drivers/net/ethernet/microchip/lan865x/lan865x.c b/drivers/net/ethernet/microchip/lan865x/lan865x.c
index 0277d9737369..3b555ee69804 100644
--- a/drivers/net/ethernet/microchip/lan865x/lan865x.c
+++ b/drivers/net/ethernet/microchip/lan865x/lan865x.c
@@ -13,27 +13,27 @@
 #define DRV_NAME			"lan8650"
 
 /* MAC Network Control Register */
-#define LAN865X_REG_MAC_NET_CTL		0x00010000
+#define LAN865X_REG_MAC_NET_CTL		0x0
 #define MAC_NET_CTL_TXEN		BIT(3) /* Transmit Enable */
 #define MAC_NET_CTL_RXEN		BIT(2) /* Receive Enable */
 
 /* MAC Network Configuration Reg */
-#define LAN865X_REG_MAC_NET_CFG		0x00010001
+#define LAN865X_REG_MAC_NET_CFG		0x1
 #define MAC_NET_CFG_PROMISCUOUS_MODE	BIT(4)
 #define MAC_NET_CFG_MULTICAST_MODE	BIT(6)
 #define MAC_NET_CFG_UNICAST_MODE	BIT(7)
 
 /* MAC Hash Register Bottom */
-#define LAN865X_REG_MAC_L_HASH		0x00010020
+#define LAN865X_REG_MAC_L_HASH		0x20
 /* MAC Hash Register Top */
-#define LAN865X_REG_MAC_H_HASH		0x00010021
+#define LAN865X_REG_MAC_H_HASH		0x21
 /* MAC Specific Addr 1 Bottom Reg */
-#define LAN865X_REG_MAC_L_SADDR1	0x00010022
+#define LAN865X_REG_MAC_L_SADDR1	0x22
 /* MAC Specific Addr 1 Top Reg */
-#define LAN865X_REG_MAC_H_SADDR1	0x00010023
+#define LAN865X_REG_MAC_H_SADDR1	0x23
 
 /* MAC TSU Timer Increment Register */
-#define LAN865X_REG_MAC_TSU_TIMER_INCR		0x00010077
+#define LAN865X_REG_MAC_TSU_TIMER_INCR		0x77
 #define MAC_TSU_TIMER_INCR_COUNT_NANOSECONDS	0x0028
 
 struct lan865x_priv {
@@ -49,7 +49,8 @@ static int lan865x_set_hw_macaddr_low_bytes(struct oa_tc6 *tc6, const u8 *mac)
 
 	regval = (mac[3] << 24) | (mac[2] << 16) | (mac[1] << 8) | mac[0];
 
-	return oa_tc6_write_register(tc6, LAN865X_REG_MAC_L_SADDR1, regval);
+	return oa_tc6_write_register_mms(tc6, LAN865X_REG_MAC_L_SADDR1,
+					 OA_TC6_PHY_C45_MAC_MMS1, regval);
 }
 
 static int lan865x_set_hw_macaddr(struct lan865x_priv *priv, const u8 *mac)
@@ -65,8 +66,8 @@ static int lan865x_set_hw_macaddr(struct lan865x_priv *priv, const u8 *mac)
 
 	/* Prepare and configure MAC address high bytes */
 	regval = (mac[5] << 8) | mac[4];
-	ret = oa_tc6_write_register(priv->tc6, LAN865X_REG_MAC_H_SADDR1,
-				    regval);
+	ret = oa_tc6_write_register_mms(priv->tc6, LAN865X_REG_MAC_H_SADDR1,
+					OA_TC6_PHY_C45_MAC_MMS1, regval);
 	if (!ret)
 		return 0;
 
@@ -146,14 +147,16 @@ static int lan865x_set_specific_multicast_addr(struct lan865x_priv *priv)
 	}
 
 	/* Enabling specific multicast addresses */
-	ret = oa_tc6_write_register(priv->tc6, LAN865X_REG_MAC_H_HASH, hash_hi);
+	ret = oa_tc6_write_register_mms(priv->tc6, LAN865X_REG_MAC_H_HASH,
+					OA_TC6_PHY_C45_MAC_MMS1, hash_hi);
 	if (ret) {
 		netdev_err(priv->netdev, "Failed to write reg_hashh: %d\n",
 			   ret);
 		return ret;
 	}
 
-	ret = oa_tc6_write_register(priv->tc6, LAN865X_REG_MAC_L_HASH, hash_lo);
+	ret = oa_tc6_write_register_mms(priv->tc6, LAN865X_REG_MAC_L_HASH,
+					OA_TC6_PHY_C45_MAC_MMS1, hash_lo);
 	if (ret)
 		netdev_err(priv->netdev, "Failed to write reg_hashl: %d\n",
 			   ret);
@@ -166,16 +169,16 @@ static int lan865x_set_all_multicast_addr(struct lan865x_priv *priv)
 	int ret;
 
 	/* Enabling all multicast addresses */
-	ret = oa_tc6_write_register(priv->tc6, LAN865X_REG_MAC_H_HASH,
-				    0xffffffff);
+	ret = oa_tc6_write_register_mms(priv->tc6, LAN865X_REG_MAC_H_HASH,
+					OA_TC6_PHY_C45_MAC_MMS1, 0xffffffff);
 	if (ret) {
 		netdev_err(priv->netdev, "Failed to write reg_hashh: %d\n",
 			   ret);
 		return ret;
 	}
 
-	ret = oa_tc6_write_register(priv->tc6, LAN865X_REG_MAC_L_HASH,
-				    0xffffffff);
+	ret = oa_tc6_write_register_mms(priv->tc6, LAN865X_REG_MAC_L_HASH,
+					OA_TC6_PHY_C45_MAC_MMS1, 0xffffffff);
 	if (ret)
 		netdev_err(priv->netdev, "Failed to write reg_hashl: %d\n",
 			   ret);
@@ -187,14 +190,16 @@ static int lan865x_clear_all_multicast_addr(struct lan865x_priv *priv)
 {
 	int ret;
 
-	ret = oa_tc6_write_register(priv->tc6, LAN865X_REG_MAC_H_HASH, 0);
+	ret = oa_tc6_write_register_mms(priv->tc6, LAN865X_REG_MAC_H_HASH,
+					OA_TC6_PHY_C45_MAC_MMS1, 0);
 	if (ret) {
 		netdev_err(priv->netdev, "Failed to write reg_hashh: %d\n",
 			   ret);
 		return ret;
 	}
 
-	ret = oa_tc6_write_register(priv->tc6, LAN865X_REG_MAC_L_HASH, 0);
+	ret = oa_tc6_write_register_mms(priv->tc6, LAN865X_REG_MAC_L_HASH,
+					OA_TC6_PHY_C45_MAC_MMS1, 0);
 	if (ret)
 		netdev_err(priv->netdev, "Failed to write reg_hashl: %d\n",
 			   ret);
@@ -235,7 +240,8 @@ static void lan865x_multicast_work_handler(struct work_struct *work)
 		if (lan865x_clear_all_multicast_addr(priv))
 			return;
 	}
-	ret = oa_tc6_write_register(priv->tc6, LAN865X_REG_MAC_NET_CFG, regval);
+	ret = oa_tc6_write_register_mms(priv->tc6, LAN865X_REG_MAC_NET_CFG,
+					OA_TC6_PHY_C45_MAC_MMS1, regval);
 	if (ret)
 		netdev_err(priv->netdev, "Failed to enable promiscuous/multicast/normal mode: %d\n",
 			   ret);
@@ -260,12 +266,14 @@ static int lan865x_hw_disable(struct lan865x_priv *priv)
 {
 	u32 regval;
 
-	if (oa_tc6_read_register(priv->tc6, LAN865X_REG_MAC_NET_CTL, &regval))
+	if (oa_tc6_read_register_mms(priv->tc6, LAN865X_REG_MAC_NET_CTL,
+				     OA_TC6_PHY_C45_MAC_MMS1, &regval))
 		return -ENODEV;
 
 	regval &= ~(MAC_NET_CTL_TXEN | MAC_NET_CTL_RXEN);
 
-	if (oa_tc6_write_register(priv->tc6, LAN865X_REG_MAC_NET_CTL, regval))
+	if (oa_tc6_write_register_mms(priv->tc6, LAN865X_REG_MAC_NET_CTL,
+				      OA_TC6_PHY_C45_MAC_MMS1, regval))
 		return -ENODEV;
 
 	return 0;
@@ -291,12 +299,14 @@ static int lan865x_hw_enable(struct lan865x_priv *priv)
 {
 	u32 regval;
 
-	if (oa_tc6_read_register(priv->tc6, LAN865X_REG_MAC_NET_CTL, &regval))
+	if (oa_tc6_read_register_mms(priv->tc6, LAN865X_REG_MAC_NET_CTL,
+				     OA_TC6_PHY_C45_MAC_MMS1, &regval))
 		return -ENODEV;
 
 	regval |= MAC_NET_CTL_TXEN | MAC_NET_CTL_RXEN;
 
-	if (oa_tc6_write_register(priv->tc6, LAN865X_REG_MAC_NET_CTL, regval))
+	if (oa_tc6_write_register_mms(priv->tc6, LAN865X_REG_MAC_NET_CTL,
+				      OA_TC6_PHY_C45_MAC_MMS1, regval))
 		return -ENODEV;
 
 	return 0;
@@ -359,8 +369,9 @@ static int lan865x_probe(struct spi_device *spi)
 	 * stamping at the end of the Start of Frame Delimiter (SFD) and set the
 	 * Timer Increment reg to 40 ns to be used as a 25 MHz internal clock.
 	 */
-	ret = oa_tc6_write_register(priv->tc6, LAN865X_REG_MAC_TSU_TIMER_INCR,
-				    MAC_TSU_TIMER_INCR_COUNT_NANOSECONDS);
+	ret = oa_tc6_write_register_mms(priv->tc6, LAN865X_REG_MAC_TSU_TIMER_INCR,
+					OA_TC6_PHY_C45_MAC_MMS1,
+					MAC_TSU_TIMER_INCR_COUNT_NANOSECONDS);
 	if (ret) {
 		dev_err(&spi->dev, "Failed to config TSU Timer Incr reg: %d\n",
 			ret);
diff --git a/drivers/net/ethernet/oa_tc6/oa_tc6.c b/drivers/net/ethernet/oa_tc6/oa_tc6.c
index 422f3f10b992..d4e94724f649 100644
--- a/drivers/net/ethernet/oa_tc6/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6/oa_tc6.c
@@ -383,6 +383,83 @@ int oa_tc6_read_register(struct oa_tc6 *tc6, u32 address, u32 *value)
 }
 EXPORT_SYMBOL_GPL(oa_tc6_read_register);
 
+/**
+ * oa_tc6_read_registers_mms - function for reading multiple consecutive
+ * registers for the given address, memory map selector pair.
+ * @tc6: oa_tc6 struct.
+ * @address: address of the first register to be read in the MAC-PHY.
+ * @mms: Memory map selector for the registers to be read.
+ * @value: values to be read from the starting register address @address.
+ * @length: number of consecutive registers to be read from @address.
+ *
+ * Return: 0 on success otherwise failed.
+ */
+int oa_tc6_read_registers_mms(struct oa_tc6 *tc6, u16 address, u16 mms,
+			      u32 value[], u8 length)
+{
+	u32 mms_addr = (u32)mms << 16 | (u32)address;
+
+	return oa_tc6_read_registers(tc6, mms_addr, value, length);
+}
+EXPORT_SYMBOL_GPL(oa_tc6_read_registers_mms);
+
+/**
+ * oa_tc6_read_register_mms - function for reading a MAC-PHY register
+ * for the given address, memory map selector pair.
+ * @tc6: oa_tc6 struct.
+ * @address: register address of the MAC-PHY to be read.
+ * @mms: Memory Map Selector for the given address
+ * @value: value read from the @address register address of the MAC-PHY.
+ *
+ * Return: 0 on success otherwise failed.
+ */
+int oa_tc6_read_register_mms(struct oa_tc6 *tc6, u16 address, u16 mms,
+			     u32 *value)
+{
+	return oa_tc6_read_registers_mms(tc6, address, mms, value, 1);
+}
+EXPORT_SYMBOL_GPL(oa_tc6_read_register_mms);
+
+/**
+ * oa_tc6_write_registers_mms - function for writing multiple consecutive
+ * registers for the given address, memory map selector pair.
+ * @tc6: oa_tc6 struct.
+ * @address: address of the first register to be written in the MAC-PHY.
+ * @mms: memory map Selector for the given register.
+ * @value: values to be written from the starting register address @address.
+ * @length: number of consecutive registers to be written from @address.
+ *
+ * Maximum of 128 consecutive registers can be written starting at @address.
+ *
+ * Return: 0 on success otherwise failed.
+ */
+int oa_tc6_write_registers_mms(struct oa_tc6 *tc6, u16 address, u16 mms,
+			       u32 value[], u8 length)
+{
+	u32 mms_addr = (u32)mms << 16 | (u32)address;
+
+	return oa_tc6_write_registers(tc6, mms_addr, value, length);
+}
+EXPORT_SYMBOL_GPL(oa_tc6_write_registers_mms);
+
+/**
+ * oa_tc6_write_register_mms - function for writing a MAC-PHY register
+ * associated with the given memory map selector.
+ * @tc6: oa_tc6 struct.
+ * @address: register address of the MAC-PHY to be written.
+ * @mms: memory map selector for the given register.
+ * @value: value to be written in the @address register address of
+ * the MAC-PHY.
+ *
+ * Return: 0 on success otherwise failed.
+ */
+int oa_tc6_write_register_mms(struct oa_tc6 *tc6, u16 address, u16 mms,
+			      u32 value)
+{
+	return oa_tc6_write_registers_mms(tc6, address, mms, &value, 1);
+}
+EXPORT_SYMBOL_GPL(oa_tc6_write_register_mms);
+
 /**
  * oa_tc6_write_registers - function for writing multiple consecutive registers.
  * @tc6: oa_tc6 struct.
@@ -496,14 +573,14 @@ static int oa_tc6_mdiobus_read_c45(struct mii_bus *bus, int addr, int devnum,
 				   int regnum)
 {
 	struct oa_tc6 *tc6 = bus->priv;
+	int mms, ret;
 	u32 regval;
-	int ret;
 
-	ret = oa_tc6_get_phy_c45_mms(tc6, devnum);
-	if (ret < 0)
-		return ret;
+	mms = oa_tc6_get_phy_c45_mms(tc6, devnum);
+	if (mms < 0)
+		return mms;
 
-	ret = oa_tc6_read_register(tc6, (ret << 16) | regnum, &regval);
+	ret = oa_tc6_read_register_mms(tc6, (u16)regnum, (u16)mms, &regval);
 	if (ret)
 		return ret;
 
@@ -514,13 +591,13 @@ static int oa_tc6_mdiobus_write_c45(struct mii_bus *bus, int addr, int devnum,
 				    int regnum, u16 val)
 {
 	struct oa_tc6 *tc6 = bus->priv;
-	int ret;
+	int mms;
 
-	ret = oa_tc6_get_phy_c45_mms(tc6, devnum);
-	if (ret < 0)
-		return ret;
+	mms = oa_tc6_get_phy_c45_mms(tc6, devnum);
+	if (mms < 0)
+		return mms;
 
-	return oa_tc6_write_register(tc6, (ret << 16) | regnum, val);
+	return oa_tc6_write_register_mms(tc6, (u16)regnum, (u16)mms, val);
 }
 
 static int oa_tc6_mdiobus_register(struct oa_tc6 *tc6)
diff --git a/include/linux/oa_tc6.h b/include/linux/oa_tc6.h
index 58668f169ea2..17ac3e0751e1 100644
--- a/include/linux/oa_tc6.h
+++ b/include/linux/oa_tc6.h
@@ -37,6 +37,14 @@ int oa_tc6_read_registers(struct oa_tc6 *tc6, u32 address, u32 value[],
 			  u8 length);
 netdev_tx_t oa_tc6_start_xmit(struct oa_tc6 *tc6, struct sk_buff *skb);
 int oa_tc6_zero_align_receive_frame_enable(struct oa_tc6 *tc6);
+int oa_tc6_write_registers_mms(struct oa_tc6 *tc6, u16 address, u16 mms,
+			       u32 value[], u8 length);
+int oa_tc6_write_register_mms(struct oa_tc6 *tc6, u16 address, u16 mms,
+			      u32 value);
+int oa_tc6_read_registers_mms(struct oa_tc6 *tc6, u16 address, u16 mms,
+			      u32 value[], u8 length);
+int oa_tc6_read_register_mms(struct oa_tc6 *tc6, u16 address, u16 mms,
+			     u32 *value);
 int oa_tc6_ptp_register(struct oa_tc6 *tc6, struct ptp_clock_info *info);
 int oa_tc6_ioctl(struct oa_tc6 *tc6, struct ifreq *rq, int cmd);
 int oa_tc6_get_ts_info(struct oa_tc6 *tc6,

-- 
2.43.0

