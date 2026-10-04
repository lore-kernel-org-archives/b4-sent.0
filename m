From: Amit Sunil Dhamne <amitsd@google.com>
Date: Sun, 04 Oct 2026 03:41:01 +0000
Subject: [PATCH v2 3/3] usb: typec: tcpci_maxim: implement
 get_current_limit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261004-max77759-icl-typec-v2-3-866caf9e7d9a@google.com>
References: <20261004-max77759-icl-typec-v2-0-866caf9e7d9a@google.com>
In-Reply-To: <20261004-max77759-icl-typec-v2-0-866caf9e7d9a@google.com>
To: Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 RD Babiera <rdbabiera@google.com>, Kyle Tso <kyletso@google.com>, 
 Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791085272; l=2320;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=yMUi/gUZfH42/zMSQVOA/fWV4tfGMcFNCeY/cfMzQYo=;
 b=UGFcTCDafrY65XWH2jvhhFQPU0Lvgum1krcDP5N7we1X1s40tn2q4kqj7W8DWCZvljfx51m1v
 9bcyBVU5xafDcWPjDUtyO6jNkBrdUe8u6uvdw9kFm3ym+oHIBzCvzDS
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement tcpci_data::get_current_limit for tcpci_maxim driver to report
a value of 500 mA unconditionally. This is the max current a configured
USB 2.0 device may draw per the USB Type-C Cable and Connector
Specification r2.2, Sec. 4.6.2.1. This helps set a current limit and
thus enable charging for the cases when a port is connected to a non-PD
Type-C port partner advertising Rp-def. This is until a mechanism for
USB core to communicate the current limit to the TCPC driver is
implemented.

Assisted-by: LLM
Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
Reviewed-by: Badhri Jagan Sridharan <badhri@google.com>
---
 drivers/usb/typec/tcpm/tcpci_maxim_core.c | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/drivers/usb/typec/tcpm/tcpci_maxim_core.c b/drivers/usb/typec/tcpm/tcpci_maxim_core.c
index 998693a61839..e6f825931ba0 100644
--- a/drivers/usb/typec/tcpm/tcpci_maxim_core.c
+++ b/drivers/usb/typec/tcpm/tcpci_maxim_core.c
@@ -482,6 +482,20 @@ static bool max_tcpci_attempt_vconn_swap_discovery(struct tcpci *tcpci, struct t
 	return true;
 }
 
+/*
+ * This callback is used by the TCPM to determine the current limit to set when
+ * Rp-def is advertised on the CC pins. The actual current limit comes from
+ * other subsystems such as the USB gadget/host stack (USB 2.0/USB 3.2) and
+ * BC1.2. As a workaround, report the USB 2.0 current limit of 500 mA to enable
+ * charging when the device is connected to a non-PD source advertising Rp-def.
+ * This can be removed once a mechanism for the USB core to communicate the
+ * current limit to this driver is implemented.
+ */
+static int max_tcpci_get_current_limit(struct tcpci *tcpci, struct tcpci_data *tdata)
+{
+	return 500;
+}
+
 static void max_tcpci_unregister_tcpci_port(void *tcpci)
 {
 	tcpci_unregister_port(tcpci);
@@ -523,6 +537,7 @@ static int max_tcpci_probe(struct i2c_client *client)
 	chip->data.check_contaminant = max_tcpci_check_contaminant;
 	chip->data.cable_comm_capable = true;
 	chip->data.attempt_vconn_swap_discovery = max_tcpci_attempt_vconn_swap_discovery;
+	chip->data.get_current_limit = max_tcpci_get_current_limit;
 
 	max_tcpci_init_regs(chip);
 	chip->tcpci = tcpci_register_port(chip->dev, &chip->data);

-- 
2.56.0.rc1.315.gc6ed9934b7-goog

