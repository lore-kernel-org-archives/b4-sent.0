From: Yassine Oudjana <y.oudjana@protonmail.com>
Date: Thu, 10 Jul 2025 09:06:29 +0100
Subject: [PATCH v2 3/4] net: qrtr: Define macro to convert QMI version and
 instance to QRTR instance
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250710-qcom-smgr-v2-3-f6e198b7aa8e@protonmail.com>
References: <20250710-qcom-smgr-v2-0-f6e198b7aa8e@protonmail.com>
In-Reply-To: <20250710-qcom-smgr-v2-0-f6e198b7aa8e@protonmail.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Masahiro Yamada <masahiroy@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nicolas Schier <nicolas.schier@linux.dev>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Luca Weiss <luca@lucaweiss.eu>
Cc: linux-arm-msm@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-kbuild@vger.kernel.org, 
 linux-iio@vger.kernel.org, Yassine Oudjana <y.oudjana@protonmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752134788; l=2801;
 i=y.oudjana@protonmail.com; s=20250710; h=from:subject:message-id;
 bh=CdngQtC98LuPwMh1HJPPpnlIAibI0ynHsnrmaihvPoY=;
 b=pCKWZ0ajdUSXjuOj+1zI1jFgI6sXqzY9ZdCsJKqO/pHK1PARy7YA7K879AiWTOGokzg1p6CFd
 2Ldzt/tAsWHDcDlxn28PKaYJ8zmXMeSMbQoYaiA6h+5xtwi+kB322Mq
X-Developer-Key: i=y.oudjana@protonmail.com; a=ed25519;
 pk=kZKEHR1e5QKCbhElU9LF/T1SbfTr8xzy2cO8fN70QgY=
X-Endpoint-Received: by B4 Relay for y.oudjana@protonmail.com/20250710 with auth_id=455
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move QRTR instance conversion from qmi_interface into a new macro in order
to reuse it in QRTR device ID tables.

Signed-off-by: Yassine Oudjana <y.oudjana@protonmail.com>
---
 drivers/soc/qcom/qmi_interface.c |  5 +++--
 include/linux/soc/qcom/qrtr.h    | 10 ++++++++++
 2 files changed, 13 insertions(+), 2 deletions(-)

diff --git a/drivers/soc/qcom/qmi_interface.c b/drivers/soc/qcom/qmi_interface.c
index 6500f863aae5ca218892d13233d4c9bf4b63a0f4..bd97b006757fc20778e4bb512945d85f4cd31b24 100644
--- a/drivers/soc/qcom/qmi_interface.c
+++ b/drivers/soc/qcom/qmi_interface.c
@@ -14,6 +14,7 @@
 #include <linux/workqueue.h>
 #include <trace/events/sock.h>
 #include <linux/soc/qcom/qmi.h>
+#include <linux/soc/qcom/qrtr.h>
 
 static struct socket *qmi_sock_create(struct qmi_handle *qmi,
 				      struct sockaddr_qrtr *sq);
@@ -173,7 +174,7 @@ static void qmi_send_new_lookup(struct qmi_handle *qmi, struct qmi_service *svc)
 	memset(&pkt, 0, sizeof(pkt));
 	pkt.cmd = cpu_to_le32(QRTR_TYPE_NEW_LOOKUP);
 	pkt.server.service = cpu_to_le32(svc->service);
-	pkt.server.instance = cpu_to_le32(svc->version | svc->instance << 8);
+	pkt.server.instance = cpu_to_le32(QRTR_INSTANCE(svc->version, svc->instance));
 
 	sq.sq_family = qmi->sq.sq_family;
 	sq.sq_node = qmi->sq.sq_node;
@@ -236,7 +237,7 @@ static void qmi_send_new_server(struct qmi_handle *qmi, struct qmi_service *svc)
 	memset(&pkt, 0, sizeof(pkt));
 	pkt.cmd = cpu_to_le32(QRTR_TYPE_NEW_SERVER);
 	pkt.server.service = cpu_to_le32(svc->service);
-	pkt.server.instance = cpu_to_le32(svc->version | svc->instance << 8);
+	pkt.server.instance = cpu_to_le32(QRTR_INSTANCE(svc->version, svc->instance));
 	pkt.server.node = cpu_to_le32(qmi->sq.sq_node);
 	pkt.server.port = cpu_to_le32(qmi->sq.sq_port);
 
diff --git a/include/linux/soc/qcom/qrtr.h b/include/linux/soc/qcom/qrtr.h
index e9249d9422b8ca96baa43073cf07c4a75c163219..e2aca520fdbe22bc855004143dc8baa7a3f67517 100644
--- a/include/linux/soc/qcom/qrtr.h
+++ b/include/linux/soc/qcom/qrtr.h
@@ -3,6 +3,8 @@
 #ifndef __QCOM_QRTR_H__
 #define __QCOM_QRTR_H__
 
+#include <linux/bitfield.h>
+#include <linux/bits.h>
 #include <linux/mod_devicetable.h>
 
 struct qrtr_device {
@@ -15,6 +17,14 @@ struct qrtr_device {
 
 #define to_qrtr_device(d) container_of(d, struct qrtr_device, dev)
 
+#define QRTR_INSTANCE(qmi_version, qmi_instance) \
+	(FIELD_PREP(GENMASK(7, 0), qmi_version) | \
+	 FIELD_PREP(GENMASK(15, 8), qmi_instance))
+
+#define QRTR_INSTANCE_CONST(qmi_version, qmi_instance) \
+	(FIELD_PREP_CONST(GENMASK(7, 0), qmi_version) | \
+	 FIELD_PREP_CONST(GENMASK(15, 8), qmi_instance))
+
 struct qrtr_driver {
 	int (*probe)(struct qrtr_device *qdev);
 	void (*remove)(struct qrtr_device *qdev);

-- 
2.50.0

