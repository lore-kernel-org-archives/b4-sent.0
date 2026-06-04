From: Ciprian Regus <ciprian.regus@analog.com>
Date: Thu, 04 Jun 2026 19:32:52 +0300
Subject: [PATCH net-next v3 07/13] net: ethernet: oa_tc6: Add
 read_mms/write_mms register access functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260604-adin1140-driver-v3-7-5debdb3173c4@analog.com>
References: <20260604-adin1140-driver-v3-0-5debdb3173c4@analog.com>
In-Reply-To: <20260604-adin1140-driver-v3-0-5debdb3173c4@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780590775; l=4012;
 i=ciprian.regus@analog.com; s=20260330; h=from:subject:message-id;
 bh=Qs1tSOe329iuRsJjQ6kWAX76EG3tpe12rcHknybT5xg=;
 b=aQwHUpEu648jILW5oYDKeC4CrUlr9oSoVWw7s+vTR1bG7LryUBbYFgDyMqS+GsAhp72segH7o
 C43csDrPmFuDKAiwJCmxgTjUH+SgPgYOaL6R3AeZlzZZVut8lg1NYM3
X-Developer-Key: i=ciprian.regus@analog.com; a=ed25519;
 pk=8WoNhI0kQcQUl8YqJO5ZevROYk9HP8lOIeIgIYgjfbc=
X-Endpoint-Received: by B4 Relay for ciprian.regus@analog.com/20260330 with auth_id=703
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Open Alliance TC6 standard defines multiple memory maps for the
MAC-PHY's register space. These are used to separate standard, vendor
and PHY MMD specific registers. Define register access functions that
allow the caller to specify the MMS.

Signed-off-by: Ciprian Regus <ciprian.regus@analog.com>

---
v3 changelog:
 - replace the OA_TC6_MMS_REG() macro with the register access functions
   that allow passing an mms parameter.
v2 changelog:
 - New patch
---
 drivers/net/ethernet/oa_tc6.c | 47 +++++++++++++++++++++++++++++++++++++++++++
 include/linux/oa_tc6.h        |  4 ++++
 2 files changed, 51 insertions(+)

diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6.c
index 92da5bb74cc7..3807265bf0b5 100644
--- a/drivers/net/ethernet/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6.c
@@ -61,6 +61,9 @@
 #define STATUS0_RESETC_POLL_DELAY		1000
 #define STATUS0_RESETC_POLL_TIMEOUT		1000000
 
+#define OA_TC6_REG_MMS_MASK		GENMASK(19, 16)
+#define OA_TC6_REG_ADDR_MASK		GENMASK(15, 0)
+
 /* Internal structure for MAC-PHY drivers */
 struct oa_tc6 {
 	struct device *dev;
@@ -344,6 +347,28 @@ int oa_tc6_read_register(struct oa_tc6 *tc6, u32 address, u32 *value)
 }
 EXPORT_SYMBOL_GPL(oa_tc6_read_register);
 
+/**
+ * oa_tc6_read_register_mms - function for reading a MAC-PHY register in a
+ * memory map other than 0.
+ * @tc6: oa_tc6 struct.
+ * @mms: Memory map selector for the register.
+ * @address: register address of the MAC-PHY to be read.
+ * @value: value read from the @address register address of the MAC-PHY.
+ *
+ * Return: 0 on success otherwise failed.
+ */
+int oa_tc6_read_register_mms(struct oa_tc6 *tc6, u8 mms, u32 address,
+			     u32 *value)
+{
+	u32 mms_reg;
+
+	mms_reg = FIELD_PREP(OA_TC6_REG_MMS_MASK, mms) |
+		  FIELD_PREP(OA_TC6_REG_ADDR_MASK, address);
+
+	return oa_tc6_read_registers(tc6, mms_reg, value, 1);
+}
+EXPORT_SYMBOL_GPL(oa_tc6_read_register_mms);
+
 /**
  * oa_tc6_write_registers - function for writing multiple consecutive registers.
  * @tc6: oa_tc6 struct.
@@ -388,6 +413,28 @@ int oa_tc6_write_register(struct oa_tc6 *tc6, u32 address, u32 value)
 }
 EXPORT_SYMBOL_GPL(oa_tc6_write_register);
 
+/**
+ * oa_tc6_write_register_mms - function for writing a MAC-PHY register in a
+ * memory map other than 0.
+ * @tc6: oa_tc6 struct.
+ * @mms: Memory map selector for the register.
+ * @address: register address of the MAC-PHY to be written.
+ * @value: value to be written in the @address register address of the MAC-PHY.
+ *
+ * Return: 0 on success otherwise failed.
+ */
+int oa_tc6_write_register_mms(struct oa_tc6 *tc6, u8 mms, u32 address,
+			      u32 value)
+{
+	u32 mms_reg;
+
+	mms_reg = FIELD_PREP(OA_TC6_REG_MMS_MASK, mms) |
+		  FIELD_PREP(OA_TC6_REG_ADDR_MASK, address);
+
+	return oa_tc6_write_registers(tc6, mms_reg, &value, 1);
+}
+EXPORT_SYMBOL_GPL(oa_tc6_write_register_mms);
+
 static int oa_tc6_check_phy_reg_direct_access_capability(struct oa_tc6 *tc6)
 {
 	u32 regval;
diff --git a/include/linux/oa_tc6.h b/include/linux/oa_tc6.h
index bd369aac9c3b..9fa4397303d1 100644
--- a/include/linux/oa_tc6.h
+++ b/include/linux/oa_tc6.h
@@ -72,9 +72,13 @@ struct oa_tc6 *oa_tc6_init(struct spi_device *spi, struct net_device *netdev,
 			   struct oa_tc6_quirks *quirks);
 void oa_tc6_exit(struct oa_tc6 *tc6);
 int oa_tc6_write_register(struct oa_tc6 *tc6, u32 address, u32 value);
+int oa_tc6_write_register_mms(struct oa_tc6 *tc6, u8 mms, u32 address,
+			      u32 value);
 int oa_tc6_write_registers(struct oa_tc6 *tc6, u32 address, u32 value[],
 			   u8 length);
 int oa_tc6_read_register(struct oa_tc6 *tc6, u32 address, u32 *value);
+int oa_tc6_read_register_mms(struct oa_tc6 *tc6, u8 mms, u32 address,
+			     u32 *value);
 int oa_tc6_read_registers(struct oa_tc6 *tc6, u32 address, u32 value[],
 			  u8 length);
 netdev_tx_t oa_tc6_start_xmit(struct oa_tc6 *tc6, struct sk_buff *skb);

-- 
2.43.0

