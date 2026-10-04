From: Amit Sunil Dhamne <amitsd@google.com>
Date: Sun, 04 Oct 2026 02:58:29 +0000
Subject: [PATCH 2/2] usb: typec: tcpm: Allow configuring tSenderResponse
 via fwnode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261004-tcpm-sender-response-time-v1-2-3f8b43084acc@google.com>
References: <20261004-tcpm-sender-response-time-v1-0-3f8b43084acc@google.com>
In-Reply-To: <20261004-tcpm-sender-response-time-v1-0-3f8b43084acc@google.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, RD Babiera <rdbabiera@google.com>, 
 Kyle Tso <kyletso@google.com>, Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791082733; l=6688;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=0TUzZuylnRbCPwFggtwjk0FNtto6f0i0yOFiygZDlHk=;
 b=YtPB4xF6ZOaHk7CXgkWP/nFdUmHmPpJtFLzCqH7sp0tJVsAcwIrTBPa34iMQ47Cr9+LW5c/Gr
 fXkc1NUZi0WClWT9q78Mvv/5k+92PSmArfspeodEp9chVNW+3RkEL7y
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The USB PD specification defines a range of values for tSenderResponse.
TCPM currently uses a fixed, relaxed value of 60 ms
(PD_T_SENDER_RESPONSE), which may not suit all platforms.

Allow platforms to specify their own tSenderResponse deadline through
the "sender-response-time-ms" fwnode property. Platforms that do not
set the property keep the existing 60 ms default.

Assisted-by: LLM
Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
Reviewed-by: Badhri Jagan Sridharan <badhri@google.com>
---
 drivers/usb/typec/tcpm/tcpm.c | 35 ++++++++++++++++++++++-------------
 1 file changed, 22 insertions(+), 13 deletions(-)

diff --git a/drivers/usb/typec/tcpm/tcpm.c b/drivers/usb/typec/tcpm/tcpm.c
index 2d6b14aa2085..9f98c87957b1 100644
--- a/drivers/usb/typec/tcpm/tcpm.c
+++ b/drivers/usb/typec/tcpm/tcpm.c
@@ -399,12 +399,14 @@ struct pd_revision_info {
  * @sink_wait_cap_time: Deadline (in ms) for tTypeCSinkWaitCap timer
  * @ps_src_wait_off_time: Deadline (in ms) for tPSSourceOff timer
  * @cc_debounce_time: Deadline (in ms) for tCCDebounce timer
+ * @sender_response_time: Deadline (in ms) for tSenderResponse timer
  */
 struct pd_timings {
 	u32 sink_wait_cap_time;
 	u32 ps_src_off_time;
 	u32 cc_debounce_time;
 	u32 snk_bc12_cmpletion_time;
+	u32 sender_response_time;
 };
 
 /* Convert microwatt to watt */
@@ -4316,7 +4318,7 @@ static bool tcpm_send_queued_message(struct tcpm_port *port)
 			} else if (port->pwr_role == TYPEC_SOURCE) {
 				tcpm_ams_finish(port);
 				tcpm_set_state(port, HARD_RESET_SEND,
-					       PD_T_SENDER_RESPONSE);
+					       port->timings.sender_response_time);
 			} else {
 				tcpm_ams_finish(port);
 			}
@@ -5549,7 +5551,7 @@ static void run_state_machine(struct tcpm_port *port)
 			port->caps_count = 0;
 			port->pd_capable = true;
 			tcpm_set_state_cond(port, SRC_SEND_CAPABILITIES_TIMEOUT,
-					    PD_T_SENDER_RESPONSE);
+					    port->timings.sender_response_time);
 		}
 		break;
 	case SRC_SEND_CAPABILITIES_TIMEOUT:
@@ -5896,7 +5898,7 @@ static void run_state_machine(struct tcpm_port *port)
 			tcpm_set_state(port, SNK_WAIT_CAPABILITIES, 0);
 		} else {
 			tcpm_set_state_cond(port, hard_reset_state(port),
-					    PD_T_SENDER_RESPONSE);
+					    port->timings.sender_response_time);
 		}
 		break;
 	case SNK_NEGOTIATE_PPS_CAPABILITIES:
@@ -5921,7 +5923,7 @@ static void run_state_machine(struct tcpm_port *port)
 				tcpm_set_state(port, SNK_READY, 0);
 		} else {
 			tcpm_set_state_cond(port, hard_reset_state(port),
-					    PD_T_SENDER_RESPONSE);
+					    port->timings.sender_response_time);
 		}
 		break;
 	case SNK_TRANSITION_SINK:
@@ -6208,7 +6210,8 @@ static void run_state_machine(struct tcpm_port *port)
 			port->message_id_prime = 0;
 			port->rx_msgid_prime = -1;
 			tcpm_pd_send_control(port, PD_CTRL_SOFT_RESET, TCPC_TX_SOP_PRIME);
-			tcpm_set_state_cond(port, ready_state(port), PD_T_SENDER_RESPONSE);
+			tcpm_set_state_cond(port, ready_state(port),
+					    port->timings.sender_response_time);
 		} else {
 			port->message_id = 0;
 			port->rx_msgid = -1;
@@ -6218,7 +6221,7 @@ static void run_state_machine(struct tcpm_port *port)
 				tcpm_set_state_cond(port, hard_reset_state(port), 0);
 			else
 				tcpm_set_state_cond(port, hard_reset_state(port),
-						    PD_T_SENDER_RESPONSE);
+						    port->timings.sender_response_time);
 		}
 		break;
 
@@ -6226,7 +6229,7 @@ static void run_state_machine(struct tcpm_port *port)
 	case DR_SWAP_SEND:
 		tcpm_pd_send_control(port, PD_CTRL_DR_SWAP, TCPC_TX_SOP);
 		tcpm_set_state_cond(port, DR_SWAP_SEND_TIMEOUT,
-				    PD_T_SENDER_RESPONSE);
+				    port->timings.sender_response_time);
 		break;
 	case DR_SWAP_ACCEPT:
 		tcpm_pd_send_control(port, PD_CTRL_ACCEPT, TCPC_TX_SOP);
@@ -6256,7 +6259,7 @@ static void run_state_machine(struct tcpm_port *port)
 			tcpm_set_state(port, ERROR_RECOVERY, 0);
 			break;
 		}
-		tcpm_set_state_cond(port, FR_SWAP_SEND_TIMEOUT, PD_T_SENDER_RESPONSE);
+		tcpm_set_state_cond(port, FR_SWAP_SEND_TIMEOUT, port->timings.sender_response_time);
 		break;
 	case FR_SWAP_SEND_TIMEOUT:
 		tcpm_set_state(port, ERROR_RECOVERY, 0);
@@ -6288,7 +6291,7 @@ static void run_state_machine(struct tcpm_port *port)
 	case PR_SWAP_SEND:
 		tcpm_pd_send_control(port, PD_CTRL_PR_SWAP, TCPC_TX_SOP);
 		tcpm_set_state_cond(port, PR_SWAP_SEND_TIMEOUT,
-				    PD_T_SENDER_RESPONSE);
+				    port->timings.sender_response_time);
 		break;
 	case PR_SWAP_SEND_TIMEOUT:
 		tcpm_swap_complete(port, -ETIMEDOUT);
@@ -6385,7 +6388,7 @@ static void run_state_machine(struct tcpm_port *port)
 	case VCONN_SWAP_SEND:
 		tcpm_pd_send_control(port, PD_CTRL_VCONN_SWAP, TCPC_TX_SOP);
 		tcpm_set_state(port, VCONN_SWAP_SEND_TIMEOUT,
-			       PD_T_SENDER_RESPONSE);
+			       port->timings.sender_response_time);
 		break;
 	case VCONN_SWAP_SEND_TIMEOUT:
 		tcpm_swap_complete(port, -ETIMEDOUT);
@@ -6467,7 +6470,7 @@ static void run_state_machine(struct tcpm_port *port)
 	case GET_STATUS_SEND:
 		tcpm_pd_send_control(port, PD_CTRL_GET_STATUS, TCPC_TX_SOP);
 		tcpm_set_state(port, GET_STATUS_SEND_TIMEOUT,
-			       PD_T_SENDER_RESPONSE);
+			       port->timings.sender_response_time);
 		break;
 	case GET_STATUS_SEND_TIMEOUT:
 		tcpm_set_state(port, ready_state(port), 0);
@@ -6475,14 +6478,14 @@ static void run_state_machine(struct tcpm_port *port)
 	case GET_PPS_STATUS_SEND:
 		tcpm_pd_send_control(port, PD_CTRL_GET_PPS_STATUS, TCPC_TX_SOP);
 		tcpm_set_state(port, GET_PPS_STATUS_SEND_TIMEOUT,
-			       PD_T_SENDER_RESPONSE);
+			       port->timings.sender_response_time);
 		break;
 	case GET_PPS_STATUS_SEND_TIMEOUT:
 		tcpm_set_state(port, ready_state(port), 0);
 		break;
 	case GET_SINK_CAP:
 		tcpm_pd_send_control(port, PD_CTRL_GET_SINK_CAP, TCPC_TX_SOP);
-		tcpm_set_state(port, GET_SINK_CAP_TIMEOUT, PD_T_SENDER_RESPONSE);
+		tcpm_set_state(port, GET_SINK_CAP_TIMEOUT, port->timings.sender_response_time);
 		break;
 	case GET_SINK_CAP_TIMEOUT:
 		port->sink_cap_done = true;
@@ -8160,6 +8163,12 @@ static void tcpm_fw_get_timings(struct tcpm_port *port, struct fwnode_handle *fw
 	ret = fwnode_property_read_u32(fwnode, "sink-bc12-completion-time-ms", &val);
 	if (!ret)
 		port->timings.snk_bc12_cmpletion_time = val;
+
+	ret = fwnode_property_read_u32(fwnode, "sender-response-time-ms", &val);
+	if (!ret)
+		port->timings.sender_response_time = val;
+	else
+		port->timings.sender_response_time = PD_T_SENDER_RESPONSE;
 }
 
 static void tcpm_fw_get_pd_ident(struct tcpm_port *port)

-- 
2.56.0.rc1.315.gc6ed9934b7-goog

