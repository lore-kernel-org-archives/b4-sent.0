From: Amit Sunil Dhamne <amitsd@google.com>
Date: Tue, 14 Apr 2026 00:58:32 +0000
Subject: [PATCH] usb: typec: tcpm: reset internal port states on soft reset
 AMS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260414-fix-soft-reset-v1-1-01d7cb9764e2@google.com>
X-B4-Tracking: v=1; b=H4sIADeR3WkC/x2MSwqAMBDFriKzdqD+WvUq4kL0VWej0hERine3u
 AwkiaQIAqU+ixRwi8qxJyjyjOZt2lewLImpNKU1tXHs5WE9/MUBiovRNs77Bt1SWUrRGZCMfzi
 M7/sB9IS4XWAAAAA=
X-Change-ID: 20260407-fix-soft-reset-e857ff5e9d36
To: Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Kyle Tso <kyletso@google.com>, Guenter Roeck <groeck@chromium.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 RD Babiera <rdbabiera@google.com>, Amit Sunil Dhamne <amitsd@google.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776128317; l=3756;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=NwZV1h3KslKY2J3kpCMvfsd4RiG9+nem3pcyoUztlBQ=;
 b=L+zGllswkMyHtEnmJRQti/NK1h3u/2HnMp/iO2cCjE6AKAR/VOsOinXE0DbEqjv2eAOmXPU3D
 HijQCI6ofuaCnb2vcFX4QQ1G3hCauX6vX5JfKrIStEYr/36GsyaQhcl
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reset internal port states (such as vdm_sm_running and
explicit_contract) on soft reset AMS as the port needs to negotiate a
new contract. The consequence of leaving the states in as-is cond are as
follows:
  * port is in SRC power role and an explicit contract is negotiated
    with the port partner (in sink role)
  * port partner sends a Soft Reset AMS while VDM State Machine is
    running
  * port accepts the Soft Reset request and the port advertises src caps
  * port partner sends a Request message but since the explicit_contract
    and vdm_sm_running are true from previous negotiation, the port ends
    up sending Soft Reset instead of Accept msg.

Stub Log:
[  203.653942] AMS DISCOVER_IDENTITY start
[  203.653947] PD TX, header: 0x176f
[  203.655901] PD TX complete, status: 0
[  203.657470] PD RX, header: 0x124f [1]
[  203.657477] Rx VDM cmd 0xff008081 type 2 cmd 1 len 1
[  203.657482] AMS DISCOVER_IDENTITY finished
[  203.657484] cc:=4
[  204.155698] PD RX, header: 0x144f [1]
[  204.155718] Rx VDM cmd 0xeeee8001 type 0 cmd 1 len 1
[  204.155741] PD TX, header: 0x196f
[  204.157622] PD TX complete, status: 0
[  204.160060] PD RX, header: 0x4d [1]
[  204.160066] state change SRC_READY -> SOFT_RESET [rev2 SOFT_RESET_AMS]
[  204.160076] PD TX, header: 0x163
[  204.162486] PD TX complete, status: 0
[  204.162832] AMS SOFT_RESET_AMS finished
[  204.162840] cc:=4
[  204.162891] AMS POWER_NEGOTIATION start
[  204.162896] state change SOFT_RESET -> AMS_START [rev2 POWER_NEGOTIATION]
[  204.162908] state change AMS_START -> SRC_SEND_CAPABILITIES [rev2 POWER_NEGOTIATION]
[  204.162913] PD TX, header: 0x1361
[  204.165529] PD TX complete, status: 0
[  204.165571] pending state change SRC_SEND_CAPABILITIES -> SRC_SEND_CAPABILITIES_TIMEOUT @ 60 ms [rev2 POWER_NEGOTIATION]
[  204.166996] PD RX, header: 0x1242 [1]
[  204.167009] state change SRC_SEND_CAPABILITIES -> SRC_SOFT_RESET_WAIT_SNK_TX [rev2 POWER_NEGOTIATION]
[  204.167019] AMS POWER_NEGOTIATION finished
[  204.167020] cc:=4
[  204.167083] AMS SOFT_RESET_AMS start
[  204.167086] state change SRC_SOFT_RESET_WAIT_SNK_TX -> SOFT_RESET_SEND [rev2 SOFT_RESET_AMS]
[  204.167092] PD TX, header: 0x16d
[  204.168824] PD TX complete, status: 0
[  204.168854] pending state change SOFT_RESET_SEND -> HARD_RESET_SEND @ 60 ms [rev2 SOFT_RESET_AMS]
[  204.171876] PD RX, header: 0x43 [1]
[  204.171879] AMS SOFT_RESET_AMS finished

This causes COMMON.PROC.PD.11.2 check failure for
TEST.PD.VDM.SRC.2_Rev2Src test on the PD compliance tester.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
Fixes: 8d3a0578ad1a ("usb: typec: tcpm: Respond Wait if VDM state machine is running")
Fixes: f0690a25a140 ("staging: typec: USB Type-C Port Manager (tcpm)")
Cc: stable@vger.kernel.org
Reviewed-by: Badhri Jagan Sridharan <badhri@google.com>
---
 drivers/usb/typec/tcpm/tcpm.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/usb/typec/tcpm/tcpm.c b/drivers/usb/typec/tcpm/tcpm.c
index 8e0e14a2704e..c73e5daafcf1 100644
--- a/drivers/usb/typec/tcpm/tcpm.c
+++ b/drivers/usb/typec/tcpm/tcpm.c
@@ -5534,6 +5534,8 @@ static void run_state_machine(struct tcpm_port *port)
 		usb_power_delivery_unregister_capabilities(port->partner_source_caps);
 		port->partner_source_caps = NULL;
 		tcpm_pd_send_control(port, PD_CTRL_ACCEPT, TCPC_TX_SOP);
+		port->vdm_sm_running = false;
+		port->explicit_contract = false;
 		tcpm_ams_finish(port);
 		if (port->pwr_role == TYPEC_SOURCE) {
 			port->upcoming_state = SRC_SEND_CAPABILITIES;

---
base-commit: 81dc1e4d32b064ac47abc60b0acbf49b66a34d52
change-id: 20260407-fix-soft-reset-e857ff5e9d36

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

