From: Amit Sunil Dhamne <amitsd@google.com>
Date: Thu, 01 Oct 2026 22:51:14 +0000
Subject: [PATCH 2/3] usb: typec: tcpci: implement get_current_limit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261001-max77759-icl-typec-v1-2-99ada1f65ced@google.com>
References: <20261001-max77759-icl-typec-v1-0-99ada1f65ced@google.com>
In-Reply-To: <20261001-max77759-icl-typec-v1-0-99ada1f65ced@google.com>
To: Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 RD Babiera <rdbabiera@google.com>, Kyle Tso <kyletso@google.com>, 
 Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790895080; l=2828;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=8gEXKafzYzCAyr8sjZjUE87dWY/Y625Rw6Tffnk7d5U=;
 b=cGUp52cbQR5MlpMG8YfhKhm5C+KxUMIZ5RYa39qzbveUgbdPIxewqFIo9fXRhjiXwOQhYaKCv
 tuswV5u899ZCaw/wFCYoUuHxMzCdpkeViI2j3LKl3RRq8qUvqQRkkSN
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement a callback for tcpc_dev::get_current_limit. This acts like a
conduit to relay the current limit information from chip level tcpc
drivers.

This does not introduce any functional changes for chip level drivers
that do not implement tcpci_data::get_current_limit.

Assisted-by: LLM
Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
Reviewed-by: Badhri Jagan Sridharan <badhri@google.com>
---
 drivers/usb/typec/tcpm/tcpci.c | 14 ++++++++++++++
 include/linux/usb/tcpci.h      |  6 ++++++
 2 files changed, 20 insertions(+)

diff --git a/drivers/usb/typec/tcpm/tcpci.c b/drivers/usb/typec/tcpm/tcpci.c
index 6717ac914c6a6..f1bc1ac0a5561 100644
--- a/drivers/usb/typec/tcpm/tcpci.c
+++ b/drivers/usb/typec/tcpm/tcpci.c
@@ -250,6 +250,19 @@ static int tcpci_get_cc(struct tcpc_dev *tcpc,
 	return 0;
 }
 
+static int tcpci_get_current_limit(struct tcpc_dev *tcpc)
+{
+	struct tcpci *tcpci = tcpc_to_tcpci(tcpc);
+	int ret;
+
+	if (!tcpci->data->get_current_limit)
+		return 0;
+
+	ret = tcpci->data->get_current_limit(tcpci, tcpci->data);
+
+	return ret < 0 ? 0 : ret;
+}
+
 static int tcpci_set_polarity(struct tcpc_dev *tcpc,
 			      enum typec_cc_polarity polarity)
 {
@@ -861,6 +874,7 @@ struct tcpci *tcpci_register_port(struct device *dev, struct tcpci_data *data)
 	tcpci->tcpc.set_cc = tcpci_set_cc;
 	tcpci->tcpc.apply_rc = tcpci_apply_rc;
 	tcpci->tcpc.get_cc = tcpci_get_cc;
+	tcpci->tcpc.get_current_limit = tcpci_get_current_limit;
 	tcpci->tcpc.set_polarity = tcpci_set_polarity;
 	tcpci->tcpc.set_vconn = tcpci_set_vconn;
 	tcpci->tcpc.start_toggling = tcpci_start_toggling;
diff --git a/include/linux/usb/tcpci.h b/include/linux/usb/tcpci.h
index 9b46a6bc762cc..580fbdac7ede0 100644
--- a/include/linux/usb/tcpci.h
+++ b/include/linux/usb/tcpci.h
@@ -205,6 +205,11 @@ struct tcpci;
  *		swap following Discover Identity on SOP' occurs.
  *		Return true when the TCPM is allowed to request a Vconn swap
  *		after Discovery Identity on SOP.
+ * @get_current_limit:
+ *		Optional; Called when the port is a sink and CC=Rp-def to obtain
+ *		the current limit. Chip level drivers can implement their own
+ *		detection and return the limit in mA, or 0 when it cannot be
+ *		determined.
  * @set_orientation:
  *		Optional; Enable setting the connector orientation
  *		CONFIG_STANDARD_OUTPUT (0x18) bit0.
@@ -228,6 +233,7 @@ struct tcpci_data {
 					     bool capable);
 	void (*check_contaminant)(struct tcpci *tcpci, struct tcpci_data *data);
 	bool (*attempt_vconn_swap_discovery)(struct tcpci *tcpci, struct tcpci_data *data);
+	int (*get_current_limit)(struct tcpci *tcpci, struct tcpci_data *data);
 };
 
 struct tcpci *tcpci_register_port(struct device *dev, struct tcpci_data *data);

-- 
2.56.0.rc1.315.gc6ed9934b7-goog

