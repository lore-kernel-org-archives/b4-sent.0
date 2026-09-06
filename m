From: Sven Peter <sven@kernel.org>
Date: Sun, 06 Sep 2026 20:36:27 +0200
Subject: [PATCH v2 04/22] usb: typec: tipd: Publish CD321x partner
 alternate modes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-b4-apple-soc-tbt-v2-4-1f80085f93fb@kernel.org>
References: <20260906-b4-apple-soc-tbt-v2-0-1f80085f93fb@kernel.org>
In-Reply-To: <20260906-b4-apple-soc-tbt-v2-0-1f80085f93fb@kernel.org>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Konrad Dybcio <konradybcio@kernel.org>, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=12306; i=sven@kernel.org;
 h=from:subject:message-id; bh=B634TnNykRGoLyUS0h7xbpVjfO6WrqvJEEZ0/eEafiM=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9bcTXviH/5qfx0zcX1//lzFxWr8/ee1bqd/7Cw8u9xue
 cHz5e6rOkpZGMS4GGTFFFm277c3ffLwjeDSTZfew8xhZQIZwsDFKQATCXjByPD34s3TlyuOxh1k
 knoff/z71SPmhckX95qnf5bN8H1btmcuw/+090+zcvaayKq8WeSncnVq4tb7ixhOHfTgmMPwtIn
 7PiM7AA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Register Thunderbolt partner and cable modes once their VDOs are
available and USB4 as a partner mode once firmware has negotiated it,
with the EUDO stored in its eudo field. The CD321X firmware still controls
mode selection and entry itself. This just makes the negotiated modes
available to consumers on the Type-C bus.

Mark them active after the Type-C mux has been configured and deactivate
them before the mux is switched back to its safe state to make sure any
consuming driver is initialized and shut down in the correct order.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/usb/typec/tipd/core.c | 224 +++++++++++++++++++++++++++++++++++++++---
 1 file changed, 209 insertions(+), 15 deletions(-)

diff --git a/drivers/usb/typec/tipd/core.c b/drivers/usb/typec/tipd/core.c
index 8c7f93d4270e..218b52b07b5a 100644
--- a/drivers/usb/typec/tipd/core.c
+++ b/drivers/usb/typec/tipd/core.c
@@ -213,6 +213,12 @@ struct cd321x {
 	struct typec_altmode *port_altmode_tbt;
 	struct typec_altmode *port_altmode_usb4;
 
+	struct typec_cable *cable;
+	struct typec_plug *plug;
+	struct typec_altmode *plug_altmode_tbt;
+	struct typec_altmode *partner_altmode_tbt;
+	struct typec_altmode *partner_altmode_usb4;
+
 	struct typec_mux *mux;
 	struct typec_mux_state state;
 
@@ -674,13 +680,156 @@ static void tps6598x_handle_plug_event(struct tps6598x *tps, u32 status)
 	}
 }
 
+static void cd321x_unregister_tbt_altmodes(struct cd321x *cd321x)
+{
+	if (cd321x->partner_altmode_tbt && cd321x->partner_altmode_tbt->active)
+		typec_altmode_update_active(cd321x->partner_altmode_tbt, false);
+	if (cd321x->plug_altmode_tbt && cd321x->plug_altmode_tbt->active)
+		typec_altmode_update_active(cd321x->plug_altmode_tbt, false);
+
+	typec_unregister_altmode(cd321x->partner_altmode_tbt);
+	cd321x->partner_altmode_tbt = NULL;
+	typec_unregister_altmode(cd321x->plug_altmode_tbt);
+	cd321x->plug_altmode_tbt = NULL;
+	typec_unregister_plug(cd321x->plug);
+	cd321x->plug = NULL;
+	typec_unregister_cable(cd321x->cable);
+	cd321x->cable = NULL;
+}
+
+static void cd321x_unregister_usb4_altmode(struct cd321x *cd321x)
+{
+	if (cd321x->partner_altmode_usb4 && cd321x->partner_altmode_usb4->active)
+		typec_altmode_update_active(cd321x->partner_altmode_usb4, false);
+
+	typec_unregister_altmode(cd321x->partner_altmode_usb4);
+	cd321x->partner_altmode_usb4 = NULL;
+}
+
+static void cd321x_unregister_partner_altmodes(struct cd321x *cd321x)
+{
+	cd321x_unregister_tbt_altmodes(cd321x);
+	cd321x_unregister_usb4_altmode(cd321x);
+}
+
+static void cd321x_deactivate_altmodes(struct cd321x *cd321x)
+{
+	if (cd321x->partner_altmode_tbt && cd321x->partner_altmode_tbt->active)
+		typec_altmode_update_active(cd321x->partner_altmode_tbt, false);
+	if (cd321x->plug_altmode_tbt && cd321x->plug_altmode_tbt->active)
+		typec_altmode_update_active(cd321x->plug_altmode_tbt, false);
+	if (cd321x->partner_altmode_usb4 && cd321x->partner_altmode_usb4->active)
+		typec_altmode_update_active(cd321x->partner_altmode_usb4, false);
+}
+
+static int cd321x_register_tbt_altmodes(struct cd321x *cd321x,
+					struct typec_thunderbolt_data *tbt_data,
+					u32 data_status)
+{
+	struct typec_cable_desc cable_desc = {
+		.type = USB_PLUG_TYPE_C,
+		.active = !!(data_status & TPS_DATA_STATUS_ACTIVE_CABLE),
+	};
+	struct typec_plug_desc plug_desc = {
+		.index = TYPEC_PLUG_SOP_P,
+	};
+	struct typec_altmode_desc desc = {
+		.svid = USB_TYPEC_TBT_SID,
+		.mode = TYPEC_ANY_MODE,
+		.mode_selection = true,
+	};
+	int ret;
+
+	if (cd321x->partner_altmode_tbt && cd321x->plug_altmode_tbt &&
+	    cd321x->partner_altmode_tbt->vdo == tbt_data->device_mode &&
+	    cd321x->plug_altmode_tbt->vdo == tbt_data->cable_mode)
+		return 0;
+
+	cd321x_unregister_tbt_altmodes(cd321x);
+
+	cd321x->cable = typec_register_cable(cd321x->tps.port, &cable_desc);
+	if (IS_ERR(cd321x->cable)) {
+		ret = PTR_ERR(cd321x->cable);
+		cd321x->cable = NULL;
+		return ret;
+	}
+
+	cd321x->plug = typec_register_plug(cd321x->cable, &plug_desc);
+	if (IS_ERR(cd321x->plug)) {
+		ret = PTR_ERR(cd321x->plug);
+		cd321x->plug = NULL;
+		goto err_unregister;
+	}
+
+	desc.vdo = tbt_data->cable_mode;
+	cd321x->plug_altmode_tbt = typec_plug_register_altmode(cd321x->plug, &desc);
+	if (IS_ERR(cd321x->plug_altmode_tbt)) {
+		ret = PTR_ERR(cd321x->plug_altmode_tbt);
+		cd321x->plug_altmode_tbt = NULL;
+		goto err_unregister;
+	}
+
+	desc.vdo = tbt_data->device_mode;
+	cd321x->partner_altmode_tbt =
+		typec_partner_register_altmode(cd321x->tps.partner, &desc);
+	if (IS_ERR(cd321x->partner_altmode_tbt)) {
+		ret = PTR_ERR(cd321x->partner_altmode_tbt);
+		cd321x->partner_altmode_tbt = NULL;
+		goto err_unregister;
+	}
+
+	return 0;
+
+err_unregister:
+	cd321x_unregister_tbt_altmodes(cd321x);
+	return ret;
+}
+
+static int cd321x_register_usb4_altmode(struct cd321x *cd321x, u32 eudo)
+{
+	struct typec_altmode_desc desc = {
+		.mode_kind = TYPEC_MODE_KIND_USB4,
+		.eudo = eudo,
+		.mode_selection = true,
+	};
+	int ret;
+
+	if (cd321x->partner_altmode_usb4 &&
+	    cd321x->partner_altmode_usb4->eudo == eudo)
+		return 0;
+
+	cd321x_unregister_usb4_altmode(cd321x);
+	cd321x->partner_altmode_usb4 =
+		typec_partner_register_altmode(cd321x->tps.partner, &desc);
+	if (IS_ERR(cd321x->partner_altmode_usb4)) {
+		ret = PTR_ERR(cd321x->partner_altmode_usb4);
+		cd321x->partner_altmode_usb4 = NULL;
+		return ret;
+	}
+
+	return 0;
+}
+
 static void cd321x_typec_update_mode(struct tps6598x *tps, struct cd321x_status *st)
 {
 	struct cd321x *cd321x = container_of(tps, struct cd321x, tps);
+	int ret;
+
+	if ((st->data_status & TPS_DATA_STATUS_DATA_CONNECTION) &&
+	    !(st->data_status & CD321X_DATA_STATUS_USB4_CONNECTION)) {
+		if (st->data_status & TPS_DATA_STATUS_USB3_CONNECTION)
+			typec_partner_set_usb_mode(tps->partner, USB_MODE_USB3);
+		else if (st->data_status & TPS_DATA_STATUS_USB2_CONNECTION)
+			typec_partner_set_usb_mode(tps->partner, USB_MODE_USB2);
+	}
 
 	if (!(st->data_status & TPS_DATA_STATUS_DATA_CONNECTION)) {
-		if (cd321x->state.mode == TYPEC_STATE_SAFE)
+		if (cd321x->state.mode == TYPEC_STATE_SAFE &&
+		    (!cd321x->partner_altmode_tbt || !cd321x->partner_altmode_tbt->active) &&
+		    (!cd321x->partner_altmode_usb4 || !cd321x->partner_altmode_usb4->active))
 			return;
+
+		cd321x_deactivate_altmodes(cd321x);
 		cd321x->state.alt = NULL;
 		cd321x->state.mode = TYPEC_STATE_SAFE;
 		cd321x->state.data = NULL;
@@ -718,6 +867,7 @@ static void cd321x_typec_update_mode(struct tps6598x *tps, struct cd321x_status
 			return;
 		}
 
+		cd321x_deactivate_altmodes(cd321x);
 		dp_data.status = le32_to_cpu(st->dp_sid_status.status_rx);
 		dp_data.conf = le32_to_cpu(st->dp_sid_status.configure);
 		cd321x->state.alt = cd321x->port_altmode_dp;
@@ -728,7 +878,8 @@ static void cd321x_typec_update_mode(struct tps6598x *tps, struct cd321x_status
 		struct typec_thunderbolt_data tbt_data;
 
 		if (cd321x->state.alt == cd321x->port_altmode_tbt &&
-		   cd321x->state.mode == TYPEC_TBT_MODE)
+		    cd321x->state.mode == TYPEC_TBT_MODE &&
+		    cd321x->partner_altmode_tbt && cd321x->partner_altmode_tbt->active)
 			return;
 
 		tbt_data.cable_mode = TBT_MODE |
@@ -744,27 +895,54 @@ static void cd321x_typec_update_mode(struct tps6598x *tps, struct cd321x_status
 			(u32)le16_to_cpu(st->intel_vid_status.device_mode) << 16;
 		tbt_data.enter_vdo =
 			(u32)le16_to_cpu(st->intel_vid_status.enter_vdo) << 16;
+
+		ret = cd321x_register_tbt_altmodes(cd321x, &tbt_data, st->data_status);
+		if (ret) {
+			dev_err(tps->dev, "failed to register Thunderbolt altmodes: %d\n", ret);
+			return;
+		}
+
+		cd321x_deactivate_altmodes(cd321x);
 		cd321x->state.alt = cd321x->port_altmode_tbt;
 		cd321x->state.mode = TYPEC_TBT_MODE;
 		cd321x->state.data = &tbt_data;
-		typec_mux_set(cd321x->mux, &cd321x->state);
+		ret = typec_mux_set(cd321x->mux, &cd321x->state);
+		if (!ret) {
+			typec_altmode_update_active(cd321x->plug_altmode_tbt, true);
+			typec_altmode_update_active(cd321x->partner_altmode_tbt, true);
+		}
 	} else if (st->data_status & CD321X_DATA_STATUS_USB4_CONNECTION) {
 		struct enter_usb_data eusb_data;
 
-		if (cd321x->state.alt == NULL && cd321x->state.mode == TYPEC_MODE_USB4)
+		if (!cd321x->state.alt &&
+		    cd321x->state.mode == TYPEC_MODE_USB4 &&
+		    cd321x->partner_altmode_usb4 && cd321x->partner_altmode_usb4->active)
 			return;
 
 		eusb_data.eudo = le32_to_cpu(st->usb4_status.eudo);
 		eusb_data.active_link_training =
 			!!(st->data_status & TPS_DATA_STATUS_ACTIVE_LINK_TRAIN);
 
+		ret = cd321x_register_usb4_altmode(cd321x, eusb_data.eudo);
+		if (ret) {
+			dev_err(tps->dev, "failed to register USB4 altmode: %d\n", ret);
+			return;
+		}
+
+		cd321x_deactivate_altmodes(cd321x);
 		cd321x->state.alt = NULL;
 		cd321x->state.data = &eusb_data;
 		cd321x->state.mode = TYPEC_MODE_USB4;
-		typec_mux_set(cd321x->mux, &cd321x->state);
+		ret = typec_mux_set(cd321x->mux, &cd321x->state);
+		if (!ret) {
+			typec_partner_set_usb_mode(tps->partner, USB_MODE_USB4);
+			typec_altmode_update_active(cd321x->partner_altmode_usb4, true);
+		}
 	} else {
 		if (cd321x->state.alt == NULL && cd321x->state.mode == TYPEC_STATE_USB)
 			return;
+
+		cd321x_deactivate_altmodes(cd321x);
 		cd321x->state.alt = NULL;
 		cd321x->state.mode = TYPEC_STATE_USB;
 		cd321x->state.data = NULL;
@@ -819,24 +997,30 @@ static void cd321x_update_work(struct work_struct *work)
 				  &cd321x->cur_partner_identity, sizeof(struct usb_pd_identity))));
 
 	/* If we are switching from an active role, transition to USB_ROLE_NONE first */
-	if (old_role != USB_ROLE_NONE && (new_role != old_role || was_disconnected))
+	if (old_role != USB_ROLE_NONE &&
+	    (new_role != old_role || partner_changed || was_disconnected))
 		usb_role_switch_set_role(tps->role_sw, USB_ROLE_NONE);
 
-	/* Process partner disconnection or change */
-	if (!new_connected || partner_changed) {
-		if (!IS_ERR(tps->partner))
-			typec_unregister_partner(tps->partner);
-		tps->partner = NULL;
-	}
-
-	/* If there was a disconnection, set PHY to off */
-	if (!new_connected || was_disconnected) {
+	/*
+	 * Also deactivate any altmodes and switch to SAFE_STATE if there was an
+	 * active connection.
+	 */
+	if (!new_connected || partner_changed || was_disconnected) {
+		cd321x_deactivate_altmodes(cd321x);
 		cd321x->state.alt = NULL;
 		cd321x->state.mode = TYPEC_STATE_SAFE;
 		cd321x->state.data = NULL;
 		typec_set_mode(tps->port, TYPEC_STATE_SAFE);
 	}
 
+	/* Process partner disconnection or change after all child modes exited. */
+	if (!new_connected || partner_changed) {
+		cd321x_unregister_partner_altmodes(cd321x);
+		if (!IS_ERR(tps->partner))
+			typec_unregister_partner(tps->partner);
+		tps->partner = NULL;
+	}
+
 	/* Update Type-C properties */
 	typec_set_pwr_opmode(tps->port, pwr_opmode);
 	typec_set_pwr_role(tps->port, TPS_STATUS_TO_TYPEC_PORTROLE(st.status));
@@ -863,6 +1047,7 @@ static void cd321x_update_work(struct work_struct *work)
 		tps->partner = typec_register_partner(tps->port, &desc);
 		if (IS_ERR(tps->partner)) {
 			dev_warn(tps->dev, "%s: failed to register partner\n", __func__);
+			tps->partner = NULL;
 			return;
 		}
 
@@ -1380,6 +1565,7 @@ cd321x_unregister_port(struct tps6598x *tps)
 {
 	struct cd321x *cd321x = container_of(tps, struct cd321x, tps);
 
+	cd321x_unregister_partner_altmodes(cd321x);
 	typec_mux_put(cd321x->mux);
 	cd321x->mux = NULL;
 	typec_unregister_altmode(cd321x->port_altmode_dp);
@@ -1802,6 +1988,14 @@ static void cd321x_remove(struct tps6598x *tps)
 	struct cd321x *cd321x = container_of(tps, struct cd321x, tps);
 
 	cancel_delayed_work_sync(&cd321x->update_work);
+
+	guard(mutex)(&tps->lock);
+	cd321x_deactivate_altmodes(cd321x);
+	cd321x->state.alt = NULL;
+	cd321x->state.mode = TYPEC_STATE_SAFE;
+	cd321x->state.data = NULL;
+	typec_set_mode(tps->port, TYPEC_STATE_SAFE);
+	cd321x_unregister_partner_altmodes(cd321x);
 }
 
 static int tps6598x_probe(struct i2c_client *client)

-- 
2.55.0

