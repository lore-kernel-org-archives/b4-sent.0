From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Tue, 24 Nov 2026 14:09:58 -0800
Subject: [PATCH net-next v12 10/15] net: ethernet: oa_tc6: APIs to
 customize CONFIG0 settings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-s2500-mac-phy-support-v12-10-3575855d99f9@onsemi.com>
References: <20261124-s2500-mac-phy-support-v12-0-3575855d99f9@onsemi.com>
In-Reply-To: <20261124-s2500-mac-phy-support-v12-0-3575855d99f9@onsemi.com>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Richard Cochran <richardcochran@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Eric Dumazet <edumazet@kernel.org>, 
 Piergiorgio Beruto <piergiorgio.beruto@gmail.com>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Ciprian Regus <ciprian.regus@analog.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795558193; l=7885;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=Tn4qWJ+KFSw9aGl6Q6VzMJbvXt57m8JvDM/gl/PybZM=;
 b=p7j4SSbr4p/WbELw+XYJSjjMFLeABk2s9XCiDfhFcNKoYqAwNPwXE/okv24Q9uKPEARIlmr4P
 bEwG/ORqH3yC94obRhUP1MvaBfZk8m8PzWvxjTnVTgcCBjkOPvpxKdq
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add oa_tc6_tx_credit_threshold_set() to let a vendor driver set the
minimum transmit credits the MAC-PHY needs before it asserts the
interrupt.

Add the OA_TC6_CONFIG_RX_CUT_THROUGH quirk flag. When set,
oa_tc6_init() enables receive cut-through before the SYNC bit is set.
This can't be done after oa_tc6_init(), which sets the SYNC bit.
The flag is ignored if the MAC-PHY does not report cut-through
capability.

Existing drivers are not affected: the default credit threshold is
unchanged and cut-through stays disabled unless the quirk is set.

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v12
  - Moved the TX credit threshold API and the RX cut-through
    quirk out of the S2500 driver patch.
  - New patch in v12.
---
 Documentation/networking/oa-tc6-framework.rst | 20 +++++++++
 drivers/net/ethernet/oa_tc6/oa_tc6_main.c     | 62 +++++++++++++++++++++++++++
 drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h  |  1 +
 include/linux/oa_tc6.h                        |  7 +++
 4 files changed, 90 insertions(+)

diff --git a/Documentation/networking/oa-tc6-framework.rst b/Documentation/networking/oa-tc6-framework.rst
index 558dc25038d3..2ce95ae58923 100644
--- a/Documentation/networking/oa-tc6-framework.rst
+++ b/Documentation/networking/oa-tc6-framework.rst
@@ -476,6 +476,9 @@ The quirk_flags field supports:
 
 - OA_TC6_BROKEN_PHY: Leave MDIO bus registration and PHY connection to the
   vendor driver instead of the framework.
+- OA_TC6_CONFIG_RX_CUT_THROUGH: Enable receive cut-through in the CONFIG0
+  register. It is ignored if the MAC-PHY does not report cut-through
+  capability.
 
 A zero value for vend1_mms means no Clause 45 ``MDIO_MMD_VEND1``
 mapping is requested; it does not select MMS 0. For any nonzero value
@@ -519,6 +522,23 @@ Zero align receive frame feature can be enabled to align all receive ethernet
 frames data to start at the beginning of any receive data chunk payload with a
 start word offset (SWO) of zero.
 
+.. c:function:: int oa_tc6_tx_credit_threshold_set(struct oa_tc6 *tc6, \
+                                                   u8 thresh)
+
+Sets the minimum number of free transmit credits that must be available
+before the MAC-PHY asserts the interrupt. The default is one credit
+according to OPEN Alliance 10BASE-T1x MAC-PHY Serial Interface specification.
+
+The thresh argument is the encoded TXCTHRESH field value of the CONFIG0
+register, not the credit count:
+
+- 0: one or more credits (default)
+- 1: four or more credits
+- 2: eight or more credits (OA_TC6_CONFIG0_TXCTHRESH_8)
+- 3: sixteen or more credits
+
+A value above 3 does not fit the field and fails with -EINVAL.
+
 .. c:function:: int oa_tc6_ptp_register(struct oa_tc6 *tc6, \
                                         struct ptp_clock_info *info)
 
diff --git a/drivers/net/ethernet/oa_tc6/oa_tc6_main.c b/drivers/net/ethernet/oa_tc6/oa_tc6_main.c
index 228cc2a3dc2d..c078f22c32d6 100644
--- a/drivers/net/ethernet/oa_tc6/oa_tc6_main.c
+++ b/drivers/net/ethernet/oa_tc6/oa_tc6_main.c
@@ -289,9 +289,29 @@ static int oa_tc6_update_standard_capability(struct oa_tc6 *tc6)
 		return ret;
 	if (regval & OA_TC6_STDCAP_FTSC_CAPABILITY) /* Timestamp */
 		tc6->ftsc_capable = true;
+	if (regval & OA_TC6_STDCAP_CTC_CAPABILITY) /* Cut-through */
+		tc6->ctc_capable = true;
 	return 0;
 }
 
+static int oa_tc6_rx_cut_through_enable(struct oa_tc6 *tc6)
+{
+	u32 regval;
+	int ret;
+
+	if (!tc6->ctc_capable)
+		return 0;
+
+	ret = oa_tc6_read_register(tc6, OA_TC6_REG_CONFIG0, &regval);
+	if (ret)
+		return ret;
+
+	/* Set Receive Cut-Through Enable */
+	regval |= OA_TC6_CONFIG0_RXCTE;
+
+	return oa_tc6_write_register(tc6, OA_TC6_REG_CONFIG0, regval);
+}
+
 static __be32 oa_tc6_prepare_ctrl_header(u32 addr, u8 length,
 					 enum oa_tc6_register_op reg_op)
 {
@@ -1618,6 +1638,36 @@ int oa_tc6_zero_align_receive_frame_enable(struct oa_tc6 *tc6)
 }
 EXPORT_SYMBOL_GPL(oa_tc6_zero_align_receive_frame_enable);
 
+/**
+ * oa_tc6_tx_credit_threshold_set - function to set the minimum number of free
+ * transmit credits needed before the MAC-PHY asserts the interrupt.
+ * @tc6: oa_tc6 struct.
+ * @thresh: transmit credit threshold field value, e.g.
+ *	OA_TC6_CONFIG0_TXCTHRESH_8.
+ *
+ * Return: 0 on success, -EINVAL if @thresh does not fit the TXCTHRESH
+ * field, otherwise a negative error code from the register access.
+ */
+int oa_tc6_tx_credit_threshold_set(struct oa_tc6 *tc6, u8 thresh)
+{
+	u32 regval;
+	int ret;
+
+	if (thresh > OA_TC6_CONFIG0_TXCTHRESH_16)
+		return -EINVAL;
+
+	ret = oa_tc6_read_register(tc6, OA_TC6_REG_CONFIG0, &regval);
+	if (ret)
+		return ret;
+
+	/* Set Transmit Credit Threshold */
+	regval &= ~OA_TC6_CONFIG0_TXCTHRESH_MASK;
+	regval |= FIELD_PREP(OA_TC6_CONFIG0_TXCTHRESH_MASK, thresh);
+
+	return oa_tc6_write_register(tc6, OA_TC6_REG_CONFIG0, regval);
+}
+EXPORT_SYMBOL_GPL(oa_tc6_tx_credit_threshold_set);
+
 /**
  * oa_tc6_start_xmit - function for sending the tx skb which consists ethernet
  * frame.
@@ -1779,6 +1829,18 @@ struct oa_tc6 *oa_tc6_init(struct spi_device *spi, struct net_device *netdev,
 		return ERR_PTR(ret);
 	}
 
+	/* Cut-through bits must be configured before SYNC bit is set
+	 * in CONFIG0 register.
+	 */
+	if (tc6->quirks.quirk_flags & OA_TC6_CONFIG_RX_CUT_THROUGH) {
+		ret = oa_tc6_rx_cut_through_enable(tc6);
+		if (ret) {
+			dev_err(&tc6->spi->dev,
+				"Failed to enable RX cut-through: %d\n", ret);
+			return ERR_PTR(ret);
+		}
+	}
+
 	ret = oa_tc6_unmask_macphy_error_interrupts(tc6);
 	if (ret) {
 		dev_err(&tc6->spi->dev,
diff --git a/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h b/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h
index cc7cda673f1b..245a1b316395 100644
--- a/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h
+++ b/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h
@@ -140,6 +140,7 @@ struct oa_tc6 {
 	struct list_head ttsc_skb_list;
 	struct ptp_clock *ptp_clock;
 	bool ftsc_capable; /* Timestamp capability */
+	bool ctc_capable;  /* cut-through capability */
 	u64 tx_hwtstamp_pkts;
 	u64 tx_hwtstamp_lost;
 	u64 tx_hwtstamp_err;
diff --git a/include/linux/oa_tc6.h b/include/linux/oa_tc6.h
index f34ed8218a7c..35b536741d01 100644
--- a/include/linux/oa_tc6.h
+++ b/include/linux/oa_tc6.h
@@ -20,6 +20,7 @@
 /* Standard Capabilities Register */
 #define OA_TC6_REG_STDCAP			0x0002
 #define OA_TC6_STDCAP_DIRECT_PHY_REG_ACCESS	BIT(8)
+#define OA_TC6_STDCAP_CTC_CAPABILITY		BIT(7)
 #define OA_TC6_STDCAP_FTSC_CAPABILITY		BIT(6)
 
 /* Reset Control and Status Register */
@@ -30,6 +31,10 @@
 #define OA_TC6_REG_CONFIG0			0x0004
 #define OA_TC6_CONFIG0_SYNC			BIT(15)
 #define OA_TC6_CONFIG0_ZARFE_ENABLE		BIT(12)
+#define OA_TC6_CONFIG0_TXCTHRESH_MASK		GENMASK(11, 10)
+#define OA_TC6_CONFIG0_TXCTHRESH_8		2	/* 0b10: >=8 credits */
+#define OA_TC6_CONFIG0_TXCTHRESH_16		3	/* 0b11: >=16 credits */
+#define OA_TC6_CONFIG0_RXCTE			BIT(8)
 #define OA_TC6_CONFIG0_FTSE_ENABLE		BIT(7)
 #define OA_TC6_CONFIG0_FTSS_64BIT_TSTAMP	BIT(6)
 #define OA_TC6_CONFIG0_PROTE			BIT(5)
@@ -82,6 +87,7 @@ struct oa_tc6;
 
 enum oa_tc6_quirk_flag {
 	OA_TC6_BROKEN_PHY = BIT(0),
+	OA_TC6_CONFIG_RX_CUT_THROUGH = BIT(1),
 };
 
 struct oa_tc6_quirks {
@@ -104,6 +110,7 @@ int oa_tc6_read_registers(struct oa_tc6 *tc6, u32 address, u32 value[],
 			  u8 length);
 netdev_tx_t oa_tc6_start_xmit(struct oa_tc6 *tc6, struct sk_buff *skb);
 int oa_tc6_zero_align_receive_frame_enable(struct oa_tc6 *tc6);
+int oa_tc6_tx_credit_threshold_set(struct oa_tc6 *tc6, u8 thresh);
 int oa_tc6_mdiobus_read_c45(struct mii_bus *bus, int addr, int devnum,
 			    int regnum);
 int oa_tc6_mdiobus_write_c45(struct mii_bus *bus, int addr, int devnum,

-- 
2.43.0

