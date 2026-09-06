From: Sven Peter <sven@kernel.org>
Date: Sun, 06 Sep 2026 14:24:00 +0200
Subject: [PATCH] usb: typec: tipd: Disable mode control for CD321x
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-b4-tipd-mode-ctrl-v1-1-71032eaaa452@kernel.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw5FMBCA4VeRWZuk6nLwKmJBO5wRt7QlEvHui
 uW3+P8TLBkmC2VwgqGdLS+zRxQGoP7N3BOy9gYpZCYKkWGboONV47RoQuXMiLnI41QXFHc/Cb5
 bDXV8vM+q/my3diDlnhFc1w1X7lvzdQAAAA==
X-Change-ID: 20260906-b4-tipd-mode-ctrl-80835d9e3f72
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: asahi@lists.linux.dev, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1660; i=sven@kernel.org;
 h=from:subject:message-id; bh=PPCoiTnejb2A7HeZJrPTsLj/TNjrcnpr7ZZdHjJJ0t8=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9bc6ERf2TU/jQwrPzo/PDlT5tjjLxdKjH/tDDLLvaXss
 bd3/4YnHaUsDGJcDLJiiizb99ubPnn4RnDppkvvYeawMoEMYeDiFICJrHrIyPBsnqVjSmCM/VTx
 458qpoh86/3ya1V8Y8yFRRfnbDr3+d5BRobGZSuSvFxYdmRa3BKLejqJaeVeoZqnjHzXlwXfsA2
 6/YAPAA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Apple's CD321X firmware controls which alternate mode is entered and
cannot be influenced from Linux. Set the no_mode_control capability to
accurately reflect this to the typec subsystem.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/usb/typec/tipd/core.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/usb/typec/tipd/core.c b/drivers/usb/typec/tipd/core.c
index 522f56742aa9..8fdb37e288b4 100644
--- a/drivers/usb/typec/tipd/core.c
+++ b/drivers/usb/typec/tipd/core.c
@@ -151,6 +151,7 @@ struct tipd_data {
 	irq_handler_t irq_handler;
 	u64 irq_mask1;
 	size_t tps_struct_size;
+	bool no_mode_control;
 	void (*remove)(struct tps6598x *tps);
 	int (*register_port)(struct tps6598x *tps, struct fwnode_handle *node);
 	void (*unregister_port)(struct tps6598x *tps);
@@ -1242,6 +1243,7 @@ tps6598x_register_port(struct tps6598x *tps, struct fwnode_handle *fwnode)
 	typec_cap.driver_data = tps;
 	typec_cap.ops = &tps6598x_ops;
 	typec_cap.fwnode = fwnode;
+	typec_cap.no_mode_control = tps->data->no_mode_control;
 
 	switch (TPS_SYSCONF_PORTINFO(conf)) {
 	case TPS_PORTINFO_SINK_ACCESSORY:
@@ -2015,6 +2017,7 @@ static const struct tipd_data cd321x_data = {
 		     APPLE_CD_REG_INT_DATA_STATUS_UPDATE |
 		     APPLE_CD_REG_INT_PLUG_EVENT,
 	.tps_struct_size = sizeof(struct cd321x),
+	.no_mode_control = true,
 	.remove = cd321x_remove,
 	.register_port = cd321x_register_port,
 	.unregister_port = cd321x_unregister_port,

---
base-commit: cee9395acd8043be0644b25c34bfa86623f2b935
change-id: 20260906-b4-tipd-mode-ctrl-80835d9e3f72

Best regards,
--  
Sven Peter <sven@kernel.org>

