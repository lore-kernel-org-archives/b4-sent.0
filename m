From: Sven Peter <sven@kernel.org>
Date: Sun, 14 Sep 2025 12:56:16 +0000
Subject: [PATCH 11/11] usb: typec: tipd: Handle mode transitions for CD321x
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250914-apple-usb3-tipd-v1-11-4e99c8649024@kernel.org>
References: <20250914-apple-usb3-tipd-v1-0-4e99c8649024@kernel.org>
In-Reply-To: <20250914-apple-usb3-tipd-v1-0-4e99c8649024@kernel.org>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Sven Peter <sven@kernel.org>, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=15951; i=sven@kernel.org;
 h=from:subject:message-id; bh=rh1BHrS3f0P6pTaz0xpQMxUHduFv9MoOplUkdu9/z2E=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8ax3Z0ls9tEK4xVL2wTa0vc3KizOFH58GqHR5e8bpucd
 k2O32bZUcrCIMbBICumyLJ9v73pk4dvBJduuvQeZg4rE8gQBi5OAZjIv2qGf0ZTtRhOTePlFMzd
 8eXK+d6bri/EHgV1LH1jypPZ2P139guGf7Y9m6oc+QOupPCqyvl471FrYw089pXVvVT5Vmw744V
 T3AA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

On Apple Silicon machines there is no control over which alt mode is
chosen. The CD321x' firmware negotiates the target mode on its own and
only lets the main CPU know after the mode has already been chosen.
Especially after plugging a new cable in this can result to quick mode
changes from e.g. power only -> USB3 only -> USB3+DisplayPort in a short
time. It is not possile to influence this in any way and we also do not
get direct access to the PDOs or VDOs exchanged via USB PD.

Additionally, mode changes must be tightly synchronized between DWC3 and
the Type C PHY and most mode changes require a full reset of DWC3 to
make the port work correctly.
This is all done synchronously from the role switch handler inside the
DWC3 glue driver on these machines to avoid tripping any failsafes or
watchdogs inside the Type-C PHY that may, in the worst case, reset the
entire SoC.

To be able to control all this we trigger the entire process in the
correct order directly from the TIPD driver and de-bounce any mode
changes to avoid tearing down and re-setting DWC3 back up multiple times
any time a new connection is made.

Signed-off-by: Hector Martin <marcan@marcan.st>
Reviewed-by: Heikki Krogerus <heikki.krogerus@linux.intel.com>
Reviewed-by: Neal Gompa <neal@gompa.dev>
Co-developed-by: Sven Peter <sven@kernel.org>
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/usb/typec/tipd/core.c | 290 +++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 286 insertions(+), 4 deletions(-)

diff --git a/drivers/usb/typec/tipd/core.c b/drivers/usb/typec/tipd/core.c
index f347e5bc625497ddff270e3e9e4d2ddaf3ca6bc1..2b1049c9a6f3c4300f4a25a97fe502c47e82a134 100644
--- a/drivers/usb/typec/tipd/core.c
+++ b/drivers/usb/typec/tipd/core.c
@@ -17,6 +17,7 @@
 #include <linux/usb/typec.h>
 #include <linux/usb/typec_altmode.h>
 #include <linux/usb/typec_dp.h>
+#include <linux/usb/typec_mux.h>
 #include <linux/usb/typec_tbt.h>
 #include <linux/usb/role.h>
 #include <linux/workqueue.h>
@@ -120,6 +121,9 @@ struct tps6598x_intel_vid_status_reg {
 #define TPS_TASK_TIMEOUT		1
 #define TPS_TASK_REJECTED		3
 
+/* Debounce delay for mode changes, in milliseconds */
+#define CD321X_DEBOUNCE_DELAY_MS 500
+
 enum {
 	TPS_MODE_APP,
 	TPS_MODE_BOOT,
@@ -145,6 +149,7 @@ struct tipd_data {
 	irq_handler_t irq_handler;
 	u64 irq_mask1;
 	size_t tps_struct_size;
+	void (*remove)(struct tps6598x *tps);
 	int (*register_port)(struct tps6598x *tps, struct fwnode_handle *node);
 	void (*unregister_port)(struct tps6598x *tps);
 	void (*trace_data_status)(u32 status);
@@ -155,6 +160,7 @@ struct tipd_data {
 	int (*switch_power_state)(struct tps6598x *tps, u8 target_state);
 	bool (*read_data_status)(struct tps6598x *tps);
 	int (*reset)(struct tps6598x *tps);
+	int (*connect)(struct tps6598x *tps, u32 status);
 };
 
 struct tps6598x {
@@ -183,6 +189,17 @@ struct tps6598x {
 	const struct tipd_data *data;
 };
 
+struct cd321x_status {
+	u32 status;
+	u32 pwr_status;
+	u32 data_status;
+	u32 status_changed;
+	struct usb_pd_identity partner_identity;
+	struct tps6598x_dp_sid_status_reg dp_sid_status;
+	struct tps6598x_intel_vid_status_reg intel_vid_status;
+	struct tps6598x_usb4_status_reg usb4_status;
+};
+
 struct cd321x {
 	struct tps6598x tps;
 
@@ -192,6 +209,13 @@ struct cd321x {
 
 	struct typec_altmode *port_altmode_dp;
 	struct typec_altmode *port_altmode_tbt;
+
+	struct typec_mux *mux;
+	struct typec_mux_state state;
+
+	struct cd321x_status update_status;
+	struct delayed_work update_work;
+	struct usb_pd_identity cur_partner_identity;
 };
 
 static enum power_supply_property tps6598x_psy_props[] = {
@@ -613,6 +637,233 @@ static void tps6598x_handle_plug_event(struct tps6598x *tps, u32 status)
 	}
 }
 
+static void cd321x_typec_update_mode(struct tps6598x *tps, struct cd321x_status *st)
+{
+	struct cd321x *cd321x = container_of(tps, struct cd321x, tps);
+
+	if (!(st->data_status & TPS_DATA_STATUS_DATA_CONNECTION)) {
+		if (cd321x->state.mode == TYPEC_STATE_SAFE)
+			return;
+		cd321x->state.alt = NULL;
+		cd321x->state.mode = TYPEC_STATE_SAFE;
+		cd321x->state.data = NULL;
+		typec_mux_set(cd321x->mux, &cd321x->state);
+	} else if (st->data_status & TPS_DATA_STATUS_DP_CONNECTION) {
+		struct typec_displayport_data dp_data;
+		unsigned long mode;
+
+		switch (TPS_DATA_STATUS_DP_SPEC_PIN_ASSIGNMENT(st->data_status)) {
+		case TPS_DATA_STATUS_DP_SPEC_PIN_ASSIGNMENT_A:
+			mode = TYPEC_DP_STATE_A;
+			break;
+		case TPS_DATA_STATUS_DP_SPEC_PIN_ASSIGNMENT_B:
+			mode = TYPEC_DP_STATE_B;
+			break;
+		case TPS_DATA_STATUS_DP_SPEC_PIN_ASSIGNMENT_C:
+			mode = TYPEC_DP_STATE_C;
+			break;
+		case TPS_DATA_STATUS_DP_SPEC_PIN_ASSIGNMENT_D:
+			mode = TYPEC_DP_STATE_D;
+			break;
+		case TPS_DATA_STATUS_DP_SPEC_PIN_ASSIGNMENT_E:
+			mode = TYPEC_DP_STATE_E;
+			break;
+		case TPS_DATA_STATUS_DP_SPEC_PIN_ASSIGNMENT_F:
+			mode = TYPEC_DP_STATE_F;
+			break;
+		default:
+			dev_err(tps->dev, "Invalid DP pin assignment\n");
+			return;
+		}
+
+		if (cd321x->state.alt == cd321x->port_altmode_dp &&
+		   cd321x->state.mode == mode) {
+			return;
+		}
+
+		dp_data.status = le32_to_cpu(st->dp_sid_status.status_rx);
+		dp_data.conf = le32_to_cpu(st->dp_sid_status.configure);
+		cd321x->state.alt = cd321x->port_altmode_dp;
+		cd321x->state.data = &dp_data;
+		cd321x->state.mode = mode;
+		typec_mux_set(cd321x->mux, &cd321x->state);
+	} else if (st->data_status & TPS_DATA_STATUS_TBT_CONNECTION) {
+		struct typec_thunderbolt_data tbt_data;
+
+		if (cd321x->state.alt == cd321x->port_altmode_tbt &&
+		   cd321x->state.mode == TYPEC_TBT_MODE)
+			return;
+
+		tbt_data.cable_mode = le16_to_cpu(st->intel_vid_status.cable_mode);
+		tbt_data.device_mode = le16_to_cpu(st->intel_vid_status.device_mode);
+		tbt_data.enter_vdo = le16_to_cpu(st->intel_vid_status.enter_vdo);
+		cd321x->state.alt = cd321x->port_altmode_tbt;
+		cd321x->state.mode = TYPEC_TBT_MODE;
+		cd321x->state.data = &tbt_data;
+		typec_mux_set(cd321x->mux, &cd321x->state);
+	} else if (st->data_status & CD321X_DATA_STATUS_USB4_CONNECTION) {
+		struct enter_usb_data eusb_data;
+
+		if (cd321x->state.alt == NULL && cd321x->state.mode == TYPEC_MODE_USB4)
+			return;
+
+		eusb_data.eudo = le32_to_cpu(st->usb4_status.eudo);
+		eusb_data.active_link_training =
+			!!(st->data_status & TPS_DATA_STATUS_ACTIVE_LINK_TRAIN);
+
+		cd321x->state.alt = NULL;
+		cd321x->state.data = &eusb_data;
+		cd321x->state.mode = TYPEC_MODE_USB4;
+		typec_mux_set(cd321x->mux, &cd321x->state);
+	} else {
+		if (cd321x->state.alt == NULL && cd321x->state.mode == TYPEC_STATE_USB)
+			return;
+		cd321x->state.alt = NULL;
+		cd321x->state.mode = TYPEC_STATE_USB;
+		cd321x->state.data = NULL;
+		typec_mux_set(cd321x->mux, &cd321x->state);
+	}
+
+	/* Clear data since it's no longer used after typec_mux_set and points to the stack */
+	cd321x->state.data = NULL;
+}
+
+static void cd321x_update_work(struct work_struct *work)
+{
+	struct cd321x *cd321x = container_of(to_delayed_work(work),
+					    struct cd321x, update_work);
+	struct tps6598x *tps = &cd321x->tps;
+	struct cd321x_status st;
+
+	guard(mutex)(&tps->lock);
+
+	st = cd321x->update_status;
+	cd321x->update_status.status_changed = 0;
+
+	bool old_connected = !!tps->partner;
+	bool new_connected = st.status & TPS_STATUS_PLUG_PRESENT;
+	bool was_disconnected = st.status_changed & TPS_STATUS_PLUG_PRESENT;
+
+	bool usb_connection = st.data_status &
+			      (TPS_DATA_STATUS_USB2_CONNECTION | TPS_DATA_STATUS_USB3_CONNECTION);
+
+	enum usb_role old_role = usb_role_switch_get_role(tps->role_sw);
+	enum usb_role new_role = USB_ROLE_NONE;
+	enum typec_pwr_opmode pwr_opmode = TYPEC_PWR_MODE_USB;
+	enum typec_orientation orientation = TYPEC_ORIENTATION_NONE;
+
+	if (usb_connection) {
+		if (tps->data_status & TPS_DATA_STATUS_USB_DATA_ROLE)
+			new_role = USB_ROLE_DEVICE;
+		else
+			new_role = USB_ROLE_HOST;
+	}
+
+	if (new_connected) {
+		pwr_opmode = TPS_POWER_STATUS_PWROPMODE(st.pwr_status);
+		orientation = TPS_STATUS_TO_UPSIDE_DOWN(st.status) ?
+			TYPEC_ORIENTATION_REVERSE : TYPEC_ORIENTATION_NORMAL;
+	}
+
+	bool is_pd = pwr_opmode == TYPEC_PWR_MODE_PD;
+	bool partner_changed = old_connected && new_connected &&
+		(was_disconnected ||
+		 (is_pd && memcmp(&st.partner_identity,
+				  &cd321x->cur_partner_identity, sizeof(struct usb_pd_identity))));
+
+	/* If we are switching from an active role, transition to USB_ROLE_NONE first */
+	if (old_role != USB_ROLE_NONE && (new_role != old_role || was_disconnected))
+		usb_role_switch_set_role(tps->role_sw, USB_ROLE_NONE);
+
+	/* Process partner disconnection or change */
+	if (!new_connected || partner_changed) {
+		if (!IS_ERR(tps->partner))
+			typec_unregister_partner(tps->partner);
+		tps->partner = NULL;
+	}
+
+	/* If there was a disconnection, set PHY to off */
+	if (!new_connected || was_disconnected) {
+		cd321x->state.alt = NULL;
+		cd321x->state.mode = TYPEC_STATE_SAFE;
+		cd321x->state.data = NULL;
+		typec_set_mode(tps->port, TYPEC_STATE_SAFE);
+	}
+
+	/* Update Type-C properties */
+	typec_set_pwr_opmode(tps->port, pwr_opmode);
+	typec_set_pwr_role(tps->port, TPS_STATUS_TO_TYPEC_PORTROLE(st.status));
+	typec_set_vconn_role(tps->port, TPS_STATUS_TO_TYPEC_VCONN(st.status));
+	typec_set_orientation(tps->port, orientation);
+	typec_set_data_role(tps->port, TPS_STATUS_TO_TYPEC_DATAROLE(st.status));
+	power_supply_changed(tps->psy);
+
+	/* If the plug is disconnected, we are done */
+	if (!new_connected)
+		return;
+
+	/* Set up partner if we were previously disconnected (or changed). */
+	if (!tps->partner) {
+		struct typec_partner_desc desc;
+
+		desc.usb_pd = is_pd;
+		desc.accessory = TYPEC_ACCESSORY_NONE; /* XXX: handle accessories */
+		desc.identity = NULL;
+
+		if (desc.usb_pd)
+			desc.identity = &st.partner_identity;
+
+		tps->partner = typec_register_partner(tps->port, &desc);
+		if (IS_ERR(tps->partner))
+			dev_warn(tps->dev, "%s: failed to register partnet\n", __func__);
+
+		if (desc.identity) {
+			typec_partner_set_identity(tps->partner);
+			cd321x->cur_partner_identity = st.partner_identity;
+		}
+	}
+
+	/* Update the TypeC MUX/PHY state */
+	cd321x_typec_update_mode(tps, &st);
+
+	/* Launch the USB role switch */
+	usb_role_switch_set_role(tps->role_sw, new_role);
+
+	power_supply_changed(tps->psy);
+}
+
+static void cd321x_queue_status(struct cd321x *cd321x)
+{
+	cd321x->update_status.status_changed |= cd321x->update_status.status ^ cd321x->tps.status;
+
+	cd321x->update_status.status = cd321x->tps.status;
+	cd321x->update_status.pwr_status = cd321x->tps.pwr_status;
+	cd321x->update_status.data_status = cd321x->tps.data_status;
+
+	cd321x->update_status.partner_identity = cd321x->tps.partner_identity;
+	cd321x->update_status.dp_sid_status = cd321x->dp_sid_status;
+	cd321x->update_status.intel_vid_status = cd321x->intel_vid_status;
+	cd321x->update_status.usb4_status = cd321x->usb4_status;
+}
+
+static int cd321x_connect(struct tps6598x *tps, u32 status)
+{
+	struct cd321x *cd321x = container_of(tps, struct cd321x, tps);
+
+	tps->status = status;
+	cd321x_queue_status(cd321x);
+
+	/*
+	 * Cancel pending work if not already running, then requeue after CD321X_DEBOUNCE_DELAY_MS
+	 * regardless since the work function will check for any plug or altmodes changes since
+	 * its last run anyway.
+	 */
+	cancel_delayed_work(&cd321x->update_work);
+	schedule_delayed_work(&cd321x->update_work, msecs_to_jiffies(CD321X_DEBOUNCE_DELAY_MS));
+
+	return 0;
+}
+
 static irqreturn_t cd321x_interrupt(int irq, void *data)
 {
 	struct tps6598x *tps = data;
@@ -652,9 +903,8 @@ static irqreturn_t cd321x_interrupt(int irq, void *data)
 		if (!tps->data->read_data_status(tps))
 			goto err_unlock;
 
-	/* Handle plug insert or removal */
-	if (event & APPLE_CD_REG_INT_PLUG_EVENT)
-		tps6598x_handle_plug_event(tps, status);
+	/* Can be called uncondtionally since it will check for any changes itself */
+	cd321x_connect(tps, status);
 
 err_unlock:
 	mutex_unlock(&tps->lock);
@@ -1014,6 +1264,8 @@ cd321x_register_port(struct tps6598x *tps, struct fwnode_handle *fwnode)
 	struct cd321x *cd321x = container_of(tps, struct cd321x, tps);
 	int ret;
 
+	INIT_DELAYED_WORK(&cd321x->update_work, cd321x_update_work);
+
 	ret = tps6598x_register_port(tps, fwnode);
 	if (ret)
 		return ret;
@@ -1022,10 +1274,24 @@ cd321x_register_port(struct tps6598x *tps, struct fwnode_handle *fwnode)
 	if (ret)
 		goto err_unregister_port;
 
+	cd321x->mux = fwnode_typec_mux_get(fwnode);
+	if (IS_ERR(cd321x->mux)) {
+		ret = PTR_ERR(cd321x->mux);
+		goto err_unregister_altmodes;
+	}
+
+	cd321x->state.alt = NULL;
+	cd321x->state.mode = TYPEC_STATE_SAFE;
+	cd321x->state.data = NULL;
 	typec_set_mode(tps->port, TYPEC_STATE_SAFE);
 
 	return 0;
 
+err_unregister_altmodes:
+	typec_unregister_altmode(cd321x->port_altmode_dp);
+	typec_unregister_altmode(cd321x->port_altmode_tbt);
+	cd321x->port_altmode_dp = NULL;
+	cd321x->port_altmode_tbt = NULL;
 err_unregister_port:
 	typec_unregister_port(tps->port);
 	return ret;
@@ -1042,6 +1308,8 @@ cd321x_unregister_port(struct tps6598x *tps)
 {
 	struct cd321x *cd321x = container_of(tps, struct cd321x, tps);
 
+	typec_mux_put(cd321x->mux);
+	cd321x->mux = NULL;
 	typec_unregister_altmode(cd321x->port_altmode_dp);
 	cd321x->port_altmode_dp = NULL;
 	typec_unregister_altmode(cd321x->port_altmode_tbt);
@@ -1454,6 +1722,13 @@ tps25750_register_port(struct tps6598x *tps, struct fwnode_handle *fwnode)
 	return 0;
 }
 
+static void cd321x_remove(struct tps6598x *tps)
+{
+	struct cd321x *cd321x = container_of(tps, struct cd321x, tps);
+
+	cancel_delayed_work_sync(&cd321x->update_work);
+}
+
 static int tps6598x_probe(struct i2c_client *client)
 {
 	const struct tipd_data *data;
@@ -1555,7 +1830,7 @@ static int tps6598x_probe(struct i2c_client *client)
 			goto err_unregister_port;
 		if (!tps->data->read_data_status(tps))
 			goto err_unregister_port;
-		ret = tps6598x_connect(tps, status);
+		ret = tps->data->connect(tps, status);
 		if (ret)
 			dev_err(&client->dev, "failed to register partner\n");
 	}
@@ -1612,6 +1887,9 @@ static void tps6598x_remove(struct i2c_client *client)
 	else
 		devm_free_irq(tps->dev, client->irq, tps);
 
+	if (tps->data->remove)
+		tps->data->remove(tps);
+
 	tps6598x_disconnect(tps, 0);
 	tps->data->unregister_port(tps);
 	usb_role_switch_put(tps->role_sw);
@@ -1682,6 +1960,7 @@ static const struct tipd_data cd321x_data = {
 		     APPLE_CD_REG_INT_DATA_STATUS_UPDATE |
 		     APPLE_CD_REG_INT_PLUG_EVENT,
 	.tps_struct_size = sizeof(struct cd321x),
+	.remove = cd321x_remove,
 	.register_port = cd321x_register_port,
 	.unregister_port = cd321x_unregister_port,
 	.trace_data_status = trace_cd321x_data_status,
@@ -1691,6 +1970,7 @@ static const struct tipd_data cd321x_data = {
 	.read_data_status = cd321x_read_data_status,
 	.reset = cd321x_reset,
 	.switch_power_state = cd321x_switch_power_state,
+	.connect = cd321x_connect,
 };
 
 static const struct tipd_data tps6598x_data = {
@@ -1708,6 +1988,7 @@ static const struct tipd_data tps6598x_data = {
 	.init = tps6598x_init,
 	.read_data_status = tps6598x_read_data_status,
 	.reset = tps6598x_reset,
+	.connect = tps6598x_connect,
 };
 
 static const struct tipd_data tps25750_data = {
@@ -1725,6 +2006,7 @@ static const struct tipd_data tps25750_data = {
 	.init = tps25750_init,
 	.read_data_status = tps6598x_read_data_status,
 	.reset = tps25750_reset,
+	.connect = tps6598x_connect,
 };
 
 static const struct of_device_id tps6598x_of_match[] = {

-- 
2.34.1

