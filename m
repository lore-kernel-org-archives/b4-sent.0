From: Amit Sunil Dhamne <amitsd@google.com>
Date: Tue, 14 Jul 2026 23:06:47 +0000
Subject: [PATCH] usb: typec: tcpm: Add support for Battery Cap response
 message
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260714-batt-caps-upstream-v1-1-c86f0a7fbbda@google.com>
X-B4-Tracking: v=1; b=H4sIAAfBVmoC/0XMSw7CIBSF4a00jCXhIVS7FdMB93JRBn0ItDFpu
 nexHTj8T3K+jWVKkTLrmo0lWmOO01hDXhqGLzc+iUdfmymhrGjllYMrhaObM1/mXBK5gZs2KAS
 6EXnN6nFOFOLnQB/92YneS7XLOf7prjlgI+QJ5+LKkrm0YFsrUQDIbjU/FFwmjtMwxNI1grSBO
 1hCEQKiIaURfK17MGiVct5oBUazft+/2wLvs+MAAAA=
X-Change-ID: 20260714-batt-caps-upstream-57f2cbe8eed3
To: Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Kyle Tso <kyletso@google.com>, RD Babiera <rdbabiera@google.com>, 
 Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784070557; l=7924;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=Pd+vfdxONEvemhiZz0c9A9V4n9jluqOyO39dTwdDP0c=;
 b=9n+caiMryAdKHXcSCaxDIBfxtzqrPZcMIZ3EDm7Mpi1Nk7eEcXp1BD10k3q8YsyEYWOSCX3wP
 F2DmJWDgiPcB7leWtkAeKUtcBIw0BO9+yeH0wBUhe/30vY6vVBRPMal
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for responding to Get_Battery_Cap (extended) request with a
a Battery_Capabilities (extended) msg. The requester will request
Battery Cap for a specific battery using an index in Get_Battery_Cap. In
case of failure to identify battery, TCPM shall reply with an
appropriate message indicating so.

As the Battery Cap Data Block size is 9 Bytes (lesser than
MaxExtendedMsgChunkLen of 26B), only a single chunk is required to
complete the AMS.

Support for Battery_Capabilities message is required for sinks that
contain battery as specified in USB PD Rev3.1 v1.8
("Applicability of Data Messages" section).

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
Reviewed-by: Badhri Jagan Sridharan <badhri@google.com>
---
This patch depends on the series [1].

[1] https://lore.kernel.org/all/20260714-batt-status-v5-0-9de4aa900b69@google.com/
---
 drivers/usb/typec/tcpm/tcpm.c | 108 +++++++++++++++++++++++++++++++++++++-----
 include/linux/usb/pd.h        |  22 +++++++++
 2 files changed, 117 insertions(+), 13 deletions(-)

diff --git a/drivers/usb/typec/tcpm/tcpm.c b/drivers/usb/typec/tcpm/tcpm.c
index cd33ee131ebd..393266dd55f8 100644
--- a/drivers/usb/typec/tcpm/tcpm.c
+++ b/drivers/usb/typec/tcpm/tcpm.c
@@ -234,7 +234,8 @@ enum pd_msg_request {
 	PD_MSG_DATA_SOURCE_CAP,
 	PD_MSG_DATA_REV,
 	PD_MSG_EXT_SINK_CAP_EXT,
-	PD_MSG_DATA_BATT_STATUS
+	PD_MSG_DATA_BATT_STATUS,
+	PD_MSG_EXT_BATT_CAP,
 };
 
 enum adev_actions {
@@ -1559,6 +1560,14 @@ static int tcpm_pd_send_sink_cap_ext(struct tcpm_port *port)
 	return tcpm_pd_transmit(port, TCPC_TX_SOP, &msg);
 }
 
+static u16 tcpm_charge_to_energy(int charge, int voltage)
+{
+	u64 energy = div_u64((u64)charge * voltage, 1000000);
+
+	/* Battery telemetry is reported in increments of 0.1Wh */
+	return (u16)UW_TO_W(energy * 10);
+}
+
 static int tcpm_pd_send_batt_status(struct tcpm_port *port)
 {
 	u16 present_charge = BATTERY_PROPERTY_UNKNOWN;
@@ -1569,7 +1578,6 @@ static int tcpm_pd_send_batt_status(struct tcpm_port *port)
 	u8 charging_status = 0;
 	struct pd_message msg;
 	int ret, charge_now;
-	u64 energy_now;
 	u32 bsdo;
 
 	tcpm_get_fixed_batt(port);
@@ -1595,16 +1603,9 @@ static int tcpm_pd_send_batt_status(struct tcpm_port *port)
 		ret = power_supply_get_property(batt,
 						POWER_SUPPLY_PROP_VOLTAGE_AVG,
 						&val);
-		if (!ret) {
-			energy_now = div_u64((u64)charge_now * val.intval,
-					     1000000);
-
-			/*
-			 * Battery Present Charge is reported in
-			 * increments of 0.1WH.
-			 */
-			present_charge = (u16)UW_TO_W(energy_now * 10);
-		}
+		if (!ret)
+			present_charge = tcpm_charge_to_energy(charge_now,
+							       val.intval);
 	}
 
 	ret = power_supply_get_property(batt, POWER_SUPPLY_PROP_STATUS, &val);
@@ -1640,6 +1641,71 @@ static int tcpm_pd_send_batt_status(struct tcpm_port *port)
 	return tcpm_pd_transmit(port, TCPC_TX_SOP, &msg);
 }
 
+static int tcpm_pd_send_batt_cap(struct tcpm_port *port)
+{
+	u16 design_cap = BATTERY_PROPERTY_UNKNOWN;
+	u16 charge_cap = BATTERY_PROPERTY_UNKNOWN;
+	u32 batt_id = port->batt_request_id;
+	union power_supply_propval val;
+	struct batt_cap_ext_msg bcdb;
+	struct power_supply *batt;
+	bool invalid_ref = true;
+	struct pd_message msg;
+	u8 data_obj_cnt;
+	int ret, vol;
+
+	tcpm_get_fixed_batt(port);
+	memset(&msg, 0, sizeof(msg));
+
+	if (batt_id >= port->fixed_batt_cnt || batt_id >= MAX_NUM_FIXED_BATT)
+		goto send_cap;
+
+	invalid_ref = false;
+	batt = port->fixed_batt[batt_id];
+	ret = power_supply_get_property(batt, POWER_SUPPLY_PROP_VOLTAGE_AVG,
+					&val);
+	if (!ret) {
+		vol = val.intval;
+		ret = power_supply_get_property(batt,
+						POWER_SUPPLY_PROP_CHARGE_FULL_DESIGN,
+						&val);
+		if (!ret)
+			design_cap = tcpm_charge_to_energy(val.intval, vol);
+
+		ret = power_supply_get_property(batt,
+						POWER_SUPPLY_PROP_CHARGE_FULL,
+						&val);
+		if (!ret)
+			charge_cap = tcpm_charge_to_energy(val.intval, vol);
+	}
+
+send_cap:
+
+	/*
+	 * As per the USB PD Rev3.1 v1.8 spec, if a battery VID (assigned by the
+	 * USB-IF) does not exist or an invalid battery reference is made by the
+	 * requestor, then set the VID field to 0xffff. If the VID field is
+	 * 0xffff, set the PID field to 0.
+	 */
+	bcdb.vid = BATTERY_PROPERTY_UNKNOWN;
+	bcdb.pid = 0;
+	bcdb.batt_design_cap = cpu_to_le16(design_cap);
+	bcdb.batt_last_chg_cap = cpu_to_le16(charge_cap);
+	bcdb.batt_type = invalid_ref ? BATT_CAP_BATT_TYPE_INVALID_REF : 0;
+	memcpy(msg.ext_msg.data, &bcdb, sizeof(bcdb));
+	msg.ext_msg.header = PD_EXT_HDR_LE(sizeof(bcdb),
+					   0, /* Denotes if request chunk */
+					   0, /* Chunk number */
+					   1  /* Chunked */);
+
+	data_obj_cnt = count_chunked_data_objs(sizeof(bcdb));
+	msg.header = PD_HEADER_EXT_LE(PD_EXT_BATT_CAP, port->pwr_role,
+				      port->data_role, port->negotiated_rev,
+				      port->message_id, data_obj_cnt);
+
+	return tcpm_pd_transmit(port, TCPC_TX_SOP, &msg);
+}
+
 static void mod_tcpm_delayed_work(struct tcpm_port *port, unsigned int delay_ms)
 {
 	if (delay_ms) {
@@ -4041,8 +4107,16 @@ static void tcpm_pd_ext_msg_request(struct tcpm_port *port,
 			tcpm_set_state(port, SOFT_RESET_SEND, 0);
 		}
 		break;
-	case PD_EXT_SOURCE_CAP_EXT:
 	case PD_EXT_GET_BATT_CAP:
+		if (data_size >= 1) {
+			port->batt_request_id = ext_msg->data[0];
+			tcpm_pd_handle_msg(port, PD_MSG_EXT_BATT_CAP,
+					   GETTING_BATTERY_CAPABILITIES);
+		} else {
+			tcpm_set_state(port, SOFT_RESET_SEND, 0);
+		}
+		break;
+	case PD_EXT_SOURCE_CAP_EXT:
 	case PD_EXT_BATT_CAP:
 	case PD_EXT_GET_MANUFACTURER_INFO:
 	case PD_EXT_MANUFACTURER_INFO:
@@ -4261,6 +4335,14 @@ static bool tcpm_send_queued_message(struct tcpm_port *port)
 					 ret);
 			tcpm_ams_finish(port);
 			break;
+		case PD_MSG_EXT_BATT_CAP:
+			ret = tcpm_pd_send_batt_cap(port);
+			if (ret)
+				tcpm_log(port,
+					 "Failed to send battery cap ret=%d",
+					 ret);
+			tcpm_ams_finish(port);
+			break;
 		default:
 			break;
 		}
diff --git a/include/linux/usb/pd.h b/include/linux/usb/pd.h
index afb9c2c65588..10ff4af7dedc 100644
--- a/include/linux/usb/pd.h
+++ b/include/linux/usb/pd.h
@@ -106,6 +106,9 @@ enum pd_ext_msg_type {
 #define PD_HEADER_LE(type, pwr, data, rev, id, cnt) \
 	cpu_to_le16(PD_HEADER((type), (pwr), (data), (rev), (id), (cnt), (0)))
 
+#define PD_HEADER_EXT_LE(type, pwr, data, rev, id, cnt) \
+	cpu_to_le16(PD_HEADER((type), (pwr), (data), (rev), (id), (cnt), (1)))
+
 static inline unsigned int pd_header_cnt(u16 header)
 {
 	return (header >> PD_HEADER_CNT_SHIFT) & PD_HEADER_CNT_MASK;
@@ -219,6 +222,25 @@ static inline u8 count_chunked_data_objs(u32 size)
 	return ((size / 4) + (size % 4 ? 1 : 0));
 }
 
+/**
+ * batt_cap_ext_msg - Battery capability extended PD message
+ * @vid: Battery Vendor ID (assigned by USB-IF)
+ * @pid: Battery Product ID (assigned by battery or device vendor)
+ * @batt_design_cap: Battery design capacity in 0.1Wh
+ * @batt_last_chg_cap: Battery last full charge capacity in 0.1Wh
+ * @batt_type: Battery Type. bit0 when set indicates invalid battery reference.
+ *             Rest of the bits are reserved.
+ */
+struct batt_cap_ext_msg {
+	__le16 vid;
+	__le16 pid;
+	__le16 batt_design_cap;
+	__le16 batt_last_chg_cap;
+	u8 batt_type;
+} __packed;
+
+#define BATT_CAP_BATT_TYPE_INVALID_REF BIT(0)
+
 /* Sink Caps Extended Data Block Version */
 #define SKEDB_VER_1_0				1
 

---
base-commit: 0e35b9b6ec0ffcc5e23cbdec09f5c622ad532b53
change-id: 20260714-batt-caps-upstream-57f2cbe8eed3
prerequisite-change-id: 20260501-batt-status-16b6761c0bb1:v5
prerequisite-patch-id: 39dd78a0bb18e681fcd8efb01b6879dbeb881a3a
prerequisite-patch-id: 621fa71ad856f4b3246ec480ab17f8089b082932

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

