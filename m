From: Oliver Facklam <oliver.facklam@zuehlke.com>
Date: Thu, 07 Nov 2024 12:43:27 +0100
Subject: [PATCH 1/4] usb: typec: hd3ss3220: configure advertised power
 opmode based on fwnode property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241107-usb-typec-controller-enhancements-v1-1-3886c1acced2@zuehlke.com>
References: <20241107-usb-typec-controller-enhancements-v1-0-3886c1acced2@zuehlke.com>
In-Reply-To: <20241107-usb-typec-controller-enhancements-v1-0-3886c1acced2@zuehlke.com>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Oliver Facklam <oliver.facklam@zuehlke.com>, 
 Benedict von Heyl <benedict.vonheyl@zuehlke.com>, 
 Mathis Foerst <mathis.foerst@zuehlke.com>, 
 Michael Glettig <michael.glettig@zuehlke.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730979838; l=3492;
 i=oliver.facklam@zuehlke.com; s=20241107; h=from:subject:message-id;
 bh=xQEWItvO4K2hmgsVC5C+clRiGDX0sc04fruShxWbObY=;
 b=Tqye3+C+vb15i1SGLnSaSimixcm0SjmZ31zzyMIapThQJyi051aNEe82OlBkwdUKDm5CpER0k
 LhT95ki85z0A24A8UK8uE6zVtvqQYATagSVIufnge5fWpJJVeLWN4UQ
X-Developer-Key: i=oliver.facklam@zuehlke.com; a=ed25519;
 pk=bMlB+nko+ewJHQJLwq2t26VDbmRmNDPr/1woleqp7Lw=
X-Endpoint-Received: by B4 Relay for oliver.facklam@zuehlke.com/20241107 with auth_id=271
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TI HD3SS3220 Type-C controller supports configuring its advertised
power operation mode over I2C using the CURRENT_MODE_ADVERTISE field
of the Connection Status Register.

Configure this power mode based on the existing (optional) property
"typec-power-opmode" of /schemas/connector/usb-connector.yaml

Signed-off-by: Oliver Facklam <oliver.facklam@zuehlke.com>
---
 drivers/usb/typec/hd3ss3220.c | 53 +++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 53 insertions(+)

diff --git a/drivers/usb/typec/hd3ss3220.c b/drivers/usb/typec/hd3ss3220.c
index fb1242e82ffdc64a9a3330f50155bb8f0fe45685..56f74bf70895ca701083bde44a5bbe0b691551e1 100644
--- a/drivers/usb/typec/hd3ss3220.c
+++ b/drivers/usb/typec/hd3ss3220.c
@@ -16,10 +16,17 @@
 #include <linux/delay.h>
 #include <linux/workqueue.h>
 
+#define HD3SS3220_REG_CN_STAT		0x08
 #define HD3SS3220_REG_CN_STAT_CTRL	0x09
 #define HD3SS3220_REG_GEN_CTRL		0x0A
 #define HD3SS3220_REG_DEV_REV		0xA0
 
+/* Register HD3SS3220_REG_CN_STAT */
+#define HD3SS3220_REG_CN_STAT_CURRENT_MODE_MASK		(BIT(7) | BIT(6))
+#define HD3SS3220_REG_CN_STAT_CURRENT_MODE_DEFAULT	0x00
+#define HD3SS3220_REG_CN_STAT_CURRENT_MODE_MID		BIT(6)
+#define HD3SS3220_REG_CN_STAT_CURRENT_MODE_HIGH		BIT(7)
+
 /* Register HD3SS3220_REG_CN_STAT_CTRL*/
 #define HD3SS3220_REG_CN_STAT_CTRL_ATTACHED_STATE_MASK	(BIT(7) | BIT(6))
 #define HD3SS3220_REG_CN_STAT_CTRL_AS_DFP		BIT(6)
@@ -43,6 +50,31 @@ struct hd3ss3220 {
 	bool poll;
 };
 
+static int hd3ss3220_set_power_opmode(struct hd3ss3220 *hd3ss3220, int power_opmode)
+{
+	int current_mode;
+
+	switch (power_opmode) {
+	case TYPEC_PWR_MODE_USB:
+		current_mode = HD3SS3220_REG_CN_STAT_CURRENT_MODE_DEFAULT;
+		break;
+	case TYPEC_PWR_MODE_1_5A:
+		current_mode = HD3SS3220_REG_CN_STAT_CURRENT_MODE_MID;
+		break;
+	case TYPEC_PWR_MODE_3_0A:
+		current_mode = HD3SS3220_REG_CN_STAT_CURRENT_MODE_HIGH;
+		break;
+	case TYPEC_PWR_MODE_PD: /* Power delivery not supported */
+	default:
+		dev_err(hd3ss3220->dev, "bad power operation mode: %d\n", power_opmode);
+		return -EINVAL;
+	}
+
+	return regmap_update_bits(hd3ss3220->regmap, HD3SS3220_REG_CN_STAT,
+				  HD3SS3220_REG_CN_STAT_CURRENT_MODE_MASK,
+				  current_mode);
+}
+
 static int hd3ss3220_set_source_pref(struct hd3ss3220 *hd3ss3220, int src_pref)
 {
 	return regmap_update_bits(hd3ss3220->regmap, HD3SS3220_REG_GEN_CTRL,
@@ -162,6 +194,23 @@ static irqreturn_t hd3ss3220_irq_handler(int irq, void *data)
 	return hd3ss3220_irq(hd3ss3220);
 }
 
+static int hd3ss3220_configure_power_opmode(struct hd3ss3220 *hd3ss3220,
+					    struct fwnode_handle *connector)
+{
+	/*
+	 * Supported power operation mode can be configured through device tree
+	 */
+	const char *cap_str;
+	int ret, power_opmode;
+
+	ret = fwnode_property_read_string(connector, "typec-power-opmode", &cap_str);
+	if (ret)
+		return 0;
+
+	power_opmode = typec_find_pwr_opmode(cap_str);
+	return hd3ss3220_set_power_opmode(hd3ss3220, power_opmode);
+}
+
 static const struct regmap_config config = {
 	.reg_bits = 8,
 	.val_bits = 8,
@@ -223,6 +272,10 @@ static int hd3ss3220_probe(struct i2c_client *client)
 		goto err_put_role;
 	}
 
+	ret = hd3ss3220_configure_power_opmode(hd3ss3220, connector);
+	if (ret < 0)
+		goto err_unreg_port;
+
 	hd3ss3220_set_role(hd3ss3220);
 	ret = regmap_read(hd3ss3220->regmap, HD3SS3220_REG_CN_STAT_CTRL, &data);
 	if (ret < 0)

-- 
2.34.1

