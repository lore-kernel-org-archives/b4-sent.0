From: Oliver Facklam <oliver.facklam@zuehlke.com>
Date: Thu, 07 Nov 2024 12:43:29 +0100
Subject: [PATCH 3/4] usb: typec: hd3ss3220: support configuring port type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241107-usb-typec-controller-enhancements-v1-3-3886c1acced2@zuehlke.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730979838; l=4521;
 i=oliver.facklam@zuehlke.com; s=20241107; h=from:subject:message-id;
 bh=RoJ3L9O4AN+n7NPifu/hwf1btjsUL9d+mOMPJO0VD04=;
 b=ROIfT6svIEQiIdOfNTksvubjgWdQrobqW8MYz+gm2mXTODPw8LFK8qmdrsJ8mjcv9XX3bbggo
 HcusLZntEMlDVlBIo2t16wQDaJUzN87QucIyWbvTpwedAMtSzG7t/qH
X-Developer-Key: i=oliver.facklam@zuehlke.com; a=ed25519;
 pk=bMlB+nko+ewJHQJLwq2t26VDbmRmNDPr/1woleqp7Lw=
X-Endpoint-Received: by B4 Relay for oliver.facklam@zuehlke.com/20241107 with auth_id=271
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TI HD3SS3220 Type-C controller supports configuring the port type
it will operate as through the MODE_SELECT field of the General
Control Register.

Configure the port type based on the fwnode property "power-role"
during probe, and through the port_type_set typec_operation.

The MODE_SELECT field can only be changed when the controller is in
unattached state, so follow the sequence recommended by the datasheet to:
1. disable termination on CC pins to disable the controller
2. change the mode
3. re-enable termination

This will effectively cause a connected device to disconnect
for the duration of the mode change.

Signed-off-by: Oliver Facklam <oliver.facklam@zuehlke.com>
---
 drivers/usb/typec/hd3ss3220.c | 66 ++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 65 insertions(+), 1 deletion(-)

diff --git a/drivers/usb/typec/hd3ss3220.c b/drivers/usb/typec/hd3ss3220.c
index e6e4b1871b5d805f8c367131509f4e6ec0d2b5f0..357c4e9491a2e3047046db91858ac98ab484ef62 100644
--- a/drivers/usb/typec/hd3ss3220.c
+++ b/drivers/usb/typec/hd3ss3220.c
@@ -35,10 +35,16 @@
 #define HD3SS3220_REG_CN_STAT_CTRL_INT_STATUS		BIT(4)
 
 /* Register HD3SS3220_REG_GEN_CTRL*/
+#define HD3SS3220_REG_GEN_CTRL_DISABLE_TERM		BIT(0)
 #define HD3SS3220_REG_GEN_CTRL_SRC_PREF_MASK		(BIT(2) | BIT(1))
 #define HD3SS3220_REG_GEN_CTRL_SRC_PREF_DRP_DEFAULT	0x00
 #define HD3SS3220_REG_GEN_CTRL_SRC_PREF_DRP_TRY_SNK	BIT(1)
 #define HD3SS3220_REG_GEN_CTRL_SRC_PREF_DRP_TRY_SRC	(BIT(2) | BIT(1))
+#define HD3SS3220_REG_GEN_CTRL_MODE_SELECT_MASK		(BIT(5) | BIT(4))
+#define HD3SS3220_REG_GEN_CTRL_MODE_SELECT_DEFAULT	0x00
+#define HD3SS3220_REG_GEN_CTRL_MODE_SELECT_DFP		BIT(5)
+#define HD3SS3220_REG_GEN_CTRL_MODE_SELECT_UFP		BIT(4)
+#define HD3SS3220_REG_GEN_CTRL_MODE_SELECT_DRP		(BIT(5) | BIT(4))
 
 struct hd3ss3220 {
 	struct device *dev;
@@ -75,6 +81,52 @@ static int hd3ss3220_set_power_opmode(struct hd3ss3220 *hd3ss3220, int power_opm
 				  current_mode);
 }
 
+static int hd3ss3220_set_port_type(struct hd3ss3220 *hd3ss3220, int type)
+{
+	int mode_select, err;
+
+	switch (type) {
+	case TYPEC_PORT_SRC:
+		mode_select = HD3SS3220_REG_GEN_CTRL_MODE_SELECT_DFP;
+		break;
+	case TYPEC_PORT_SNK:
+		mode_select = HD3SS3220_REG_GEN_CTRL_MODE_SELECT_UFP;
+		break;
+	case TYPEC_PORT_DRP:
+		mode_select = HD3SS3220_REG_GEN_CTRL_MODE_SELECT_DRP;
+		break;
+	default:
+		dev_err(hd3ss3220->dev, "bad port type: %d\n", type);
+		return -EINVAL;
+	}
+
+	/* Disable termination before changing MODE_SELECT as required by datasheet */
+	err = regmap_update_bits(hd3ss3220->regmap, HD3SS3220_REG_GEN_CTRL,
+				 HD3SS3220_REG_GEN_CTRL_DISABLE_TERM,
+				 HD3SS3220_REG_GEN_CTRL_DISABLE_TERM);
+	if (err < 0) {
+		dev_err(hd3ss3220->dev, "Failed to disable port for mode change: %d\n", err);
+		return err;
+	}
+
+	err = regmap_update_bits(hd3ss3220->regmap, HD3SS3220_REG_GEN_CTRL,
+				 HD3SS3220_REG_GEN_CTRL_MODE_SELECT_MASK,
+				 mode_select);
+	if (err < 0) {
+		dev_err(hd3ss3220->dev, "Failed to change mode: %d\n", err);
+		regmap_update_bits(hd3ss3220->regmap, HD3SS3220_REG_GEN_CTRL,
+				   HD3SS3220_REG_GEN_CTRL_DISABLE_TERM, 0);
+		return err;
+	}
+
+	err = regmap_update_bits(hd3ss3220->regmap, HD3SS3220_REG_GEN_CTRL,
+				 HD3SS3220_REG_GEN_CTRL_DISABLE_TERM, 0);
+	if (err < 0)
+		dev_err(hd3ss3220->dev, "Failed to re-enable port after mode change: %d\n", err);
+
+	return err;
+}
+
 static int hd3ss3220_set_source_pref(struct hd3ss3220 *hd3ss3220, int src_pref)
 {
 	return regmap_update_bits(hd3ss3220->regmap, HD3SS3220_REG_GEN_CTRL,
@@ -131,8 +183,16 @@ static int hd3ss3220_dr_set(struct typec_port *port, enum typec_data_role role)
 	return ret;
 }
 
+static int hd3ss3220_port_type_set(struct typec_port *port, enum typec_port_type type)
+{
+	struct hd3ss3220 *hd3ss3220 = typec_get_drvdata(port);
+
+	return hd3ss3220_set_port_type(hd3ss3220, type);
+}
+
 static const struct typec_operations hd3ss3220_ops = {
-	.dr_set = hd3ss3220_dr_set
+	.dr_set = hd3ss3220_dr_set,
+	.port_type_set = hd3ss3220_port_type_set,
 };
 
 static void hd3ss3220_set_role(struct hd3ss3220 *hd3ss3220)
@@ -263,6 +323,10 @@ static int hd3ss3220_probe(struct i2c_client *client)
 	if (ret)
 		goto err_put_role;
 
+	ret = hd3ss3220_set_port_type(hd3ss3220, typec_cap.type);
+	if (ret < 0)
+		goto err_put_role;
+
 	typec_cap.driver_data = hd3ss3220;
 	typec_cap.ops = &hd3ss3220_ops;
 

-- 
2.34.1

