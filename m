From: Sven Peter <sven@kernel.org>
Date: Sun, 14 Sep 2025 12:56:12 +0000
Subject: [PATCH 07/11] usb: typec: tipd: Register DisplayPort and
 Thunderbolt altmodes for cd321x
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250914-apple-usb3-tipd-v1-7-4e99c8649024@kernel.org>
References: <20250914-apple-usb3-tipd-v1-0-4e99c8649024@kernel.org>
In-Reply-To: <20250914-apple-usb3-tipd-v1-0-4e99c8649024@kernel.org>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5651; i=sven@kernel.org;
 h=from:subject:message-id; bh=90KthqrDnapyUT4Ni6YoQa7BmryV8lEQlLoxgEjdzu4=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8ax3Y0a6/95ej9KOTEl/se0C+FfHj7OsuI7V6cmu3vPh
 SlTmoxyOkpZGMQ4GGTFFFm277c3ffLwjeDSTZfew8xhZQIZwsDFKQATMV3PyPB70wbpPsNKvVqm
 3Ts4vya92FFivvZEoUq26FnvL2knFKwZ/unEGt2O6ri8/M+yraUv/m7qtil5PeucjMmL8jUev21
 197EDAA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Ports equipped with a CD321x are only found on Apple Silicon machines
and always support DisplayPort, Thunderbolt and USB4. Register these
port modes unconditionally.

Reviewed-by: Heikki Krogerus <heikki.krogerus@linux.intel.com>
Reviewed-by: Neal Gompa <neal@gompa.dev>
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/usb/typec/tipd/core.c | 85 +++++++++++++++++++++++++++++++++++++++++--
 1 file changed, 82 insertions(+), 3 deletions(-)

diff --git a/drivers/usb/typec/tipd/core.c b/drivers/usb/typec/tipd/core.c
index afd11b3e1ae596c7f3283e4336aaa57874c9378d..c7cf936e5a61a331271c05b68ff1b77b89c0f643 100644
--- a/drivers/usb/typec/tipd/core.c
+++ b/drivers/usb/typec/tipd/core.c
@@ -16,6 +16,8 @@
 #include <linux/interrupt.h>
 #include <linux/usb/typec.h>
 #include <linux/usb/typec_altmode.h>
+#include <linux/usb/typec_dp.h>
+#include <linux/usb/typec_tbt.h>
 #include <linux/usb/role.h>
 #include <linux/workqueue.h>
 #include <linux/firmware.h>
@@ -144,6 +146,7 @@ struct tipd_data {
 	u64 irq_mask1;
 	size_t tps_struct_size;
 	int (*register_port)(struct tps6598x *tps, struct fwnode_handle *node);
+	void (*unregister_port)(struct tps6598x *tps);
 	void (*trace_data_status)(u32 status);
 	void (*trace_power_status)(u16 status);
 	void (*trace_status)(u32 status);
@@ -185,6 +188,9 @@ struct cd321x {
 	struct tps6598x_dp_sid_status_reg dp_sid_status;
 	struct tps6598x_intel_vid_status_reg intel_vid_status;
 	struct tps6598x_usb4_status_reg usb4_status;
+
+	struct typec_altmode *port_altmode_dp;
+	struct typec_altmode *port_altmode_tbt;
 };
 
 static enum power_supply_property tps6598x_psy_props[] = {
@@ -964,6 +970,76 @@ tps6598x_register_port(struct tps6598x *tps, struct fwnode_handle *fwnode)
 	return 0;
 }
 
+static int cd321x_register_port_altmodes(struct cd321x *cd321x)
+{
+	struct typec_altmode_desc desc;
+	struct typec_altmode *amode;
+
+	memset(&desc, 0, sizeof(desc));
+	desc.svid = USB_TYPEC_DP_SID;
+	desc.mode = USB_TYPEC_DP_MODE;
+	desc.vdo = DP_CONF_SET_PIN_ASSIGN(BIT(DP_PIN_ASSIGN_C) | BIT(DP_PIN_ASSIGN_D));
+	desc.vdo |= DP_CAP_DFP_D;
+	amode = typec_port_register_altmode(cd321x->tps.port, &desc);
+	if (IS_ERR(amode))
+		return PTR_ERR(amode);
+	cd321x->port_altmode_dp = amode;
+
+	memset(&desc, 0, sizeof(desc));
+	desc.svid = USB_TYPEC_TBT_SID;
+	desc.mode = TYPEC_ANY_MODE;
+	amode = typec_port_register_altmode(cd321x->tps.port, &desc);
+	if (IS_ERR(amode)) {
+		typec_unregister_altmode(cd321x->port_altmode_dp);
+		cd321x->port_altmode_dp = NULL;
+		return PTR_ERR(amode);
+	}
+	cd321x->port_altmode_tbt = amode;
+
+	return 0;
+}
+
+static int
+cd321x_register_port(struct tps6598x *tps, struct fwnode_handle *fwnode)
+{
+	struct cd321x *cd321x = container_of(tps, struct cd321x, tps);
+	int ret;
+
+	ret = tps6598x_register_port(tps, fwnode);
+	if (ret)
+		return ret;
+
+	ret = cd321x_register_port_altmodes(cd321x);
+	if (ret)
+		goto err_unregister_port;
+
+	typec_set_mode(tps->port, TYPEC_STATE_SAFE);
+
+	return 0;
+
+err_unregister_port:
+	typec_unregister_port(tps->port);
+	return ret;
+}
+
+static void
+tps6598x_unregister_port(struct tps6598x *tps)
+{
+	typec_unregister_port(tps->port);
+}
+
+static void
+cd321x_unregister_port(struct tps6598x *tps)
+{
+	struct cd321x *cd321x = container_of(tps, struct cd321x, tps);
+
+	typec_unregister_altmode(cd321x->port_altmode_dp);
+	cd321x->port_altmode_dp = NULL;
+	typec_unregister_altmode(cd321x->port_altmode_tbt);
+	cd321x->port_altmode_tbt = NULL;
+	typec_unregister_port(tps->port);
+}
+
 static int tps_request_firmware(struct tps6598x *tps, const struct firmware **fw,
 				const char **firmware_name)
 {
@@ -1505,7 +1581,7 @@ static int tps6598x_probe(struct i2c_client *client)
 err_disconnect:
 	tps6598x_disconnect(tps, 0);
 err_unregister_port:
-	typec_unregister_port(tps->port);
+	tps->data->unregister_port(tps);
 err_role_put:
 	usb_role_switch_put(tps->role_sw);
 err_fwnode_put:
@@ -1529,7 +1605,7 @@ static void tps6598x_remove(struct i2c_client *client)
 		devm_free_irq(tps->dev, client->irq, tps);
 
 	tps6598x_disconnect(tps, 0);
-	typec_unregister_port(tps->port);
+	tps->data->unregister_port(tps);
 	usb_role_switch_put(tps->role_sw);
 
 	/* Reset PD controller to remove any applied patch */
@@ -1598,7 +1674,8 @@ static const struct tipd_data cd321x_data = {
 		     APPLE_CD_REG_INT_DATA_STATUS_UPDATE |
 		     APPLE_CD_REG_INT_PLUG_EVENT,
 	.tps_struct_size = sizeof(struct cd321x),
-	.register_port = tps6598x_register_port,
+	.register_port = cd321x_register_port,
+	.unregister_port = cd321x_unregister_port,
 	.trace_data_status = trace_cd321x_data_status,
 	.trace_power_status = trace_tps6598x_power_status,
 	.trace_status = trace_tps6598x_status,
@@ -1615,6 +1692,7 @@ static const struct tipd_data tps6598x_data = {
 		     TPS_REG_INT_PLUG_EVENT,
 	.tps_struct_size = sizeof(struct tps6598x),
 	.register_port = tps6598x_register_port,
+	.unregister_port = tps6598x_unregister_port,
 	.trace_data_status = trace_tps6598x_data_status,
 	.trace_power_status = trace_tps6598x_power_status,
 	.trace_status = trace_tps6598x_status,
@@ -1631,6 +1709,7 @@ static const struct tipd_data tps25750_data = {
 		     TPS_REG_INT_PLUG_EVENT,
 	.tps_struct_size = sizeof(struct tps6598x),
 	.register_port = tps25750_register_port,
+	.unregister_port = tps6598x_unregister_port,
 	.trace_data_status = trace_tps6598x_data_status,
 	.trace_power_status = trace_tps25750_power_status,
 	.trace_status = trace_tps25750_status,

-- 
2.34.1

