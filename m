From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Fri, 03 Apr 2026 21:36:08 +0530
Subject: [PATCH v2 5/5] net: qrtr: ns: Fix use-after-free in driver
 remove()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-qrtr-fix-v2-5-f88a14859c63@oss.qualcomm.com>
References: <20260403-qrtr-fix-v2-0-f88a14859c63@oss.qualcomm.com>
In-Reply-To: <20260403-qrtr-fix-v2-0-f88a14859c63@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1665;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=EKnJBPyE8K/Uxe3dMOqp6oAHc724HrgGM2UtRYAxcbE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpz+V58HcsafAzCiDUq93S+ISP2Pv+dqaFAy7vX
 VMZ11JAjSWJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCac/leQAKCRBVnxHm/pHO
 9fZRB/0WRME4UaAPVOxxBfAFS6wZkqdpCyfphwoctFAR7hmeHtgnPcSfuhFz5NvDeBGfpMX4GwZ
 R2omrFgpOYXH7q+Zzu9nkqY9hFzL1kQSDhqHVVA1mHvvFTaMkH1rxk6F8hDGANaQwsXbpJxm4ks
 BvvFNB+pmoh+dhddW8cCNLB6Q7feta3EKULMgJQoqxlZOjSqwW39sVybhMQvJjxq5QQT6/H1mYQ
 wz2sLHbGI2KJ2y5gxq2P2RnsEFz8NDuWGjFG5xZFwCtB+4DKjvkT0OGTE8a1OUZJ5JNpXSruUyH
 Ui06PAMD8c+pZGhTPQDU1Obul5IXePJYBlp0rahYZYCa1RM9
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In the remove callback, if a packet arrives after destroy_workqueue() is
called, but before sock_release(), the qrtr_ns_data_ready() callback will
try to queue the work, causing use-after-free issue.

Fix this issue by saving the default 'sk_data_ready' callback during
qrtr_ns_init() and use it to replace the qrtr_ns_data_ready() callback at
the start of remove(). This ensures that even if a packet arrives after
destroy_workqueue(), the work struct will not be dereferenced.

Cc: stable@vger.kernel.org
Fixes: 0c2204a4ad71 ("net: qrtr: Migrate nameservice to kernel from userspace")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 net/qrtr/ns.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/net/qrtr/ns.c b/net/qrtr/ns.c
index dfb5dad9473c..c62d79e03d64 100644
--- a/net/qrtr/ns.c
+++ b/net/qrtr/ns.c
@@ -25,6 +25,7 @@ static struct {
 	u32 lookup_count;
 	struct workqueue_struct *workqueue;
 	struct work_struct work;
+	void (*saved_data_ready)(struct sock *sk);
 	int local_node;
 } qrtr_ns;
 
@@ -754,6 +755,7 @@ int qrtr_ns_init(void)
 		goto err_sock;
 	}
 
+	qrtr_ns.saved_data_ready = qrtr_ns.sock->sk->sk_data_ready;
 	qrtr_ns.sock->sk->sk_data_ready = qrtr_ns_data_ready;
 
 	sq.sq_port = QRTR_PORT_CTRL;
@@ -803,6 +805,10 @@ EXPORT_SYMBOL_GPL(qrtr_ns_init);
 
 void qrtr_ns_remove(void)
 {
+	write_lock_bh(&qrtr_ns.sock->sk->sk_callback_lock);
+	qrtr_ns.sock->sk->sk_data_ready = qrtr_ns.saved_data_ready;
+	write_unlock_bh(&qrtr_ns.sock->sk->sk_callback_lock);
+
 	cancel_work_sync(&qrtr_ns.work);
 	destroy_workqueue(qrtr_ns.workqueue);
 

-- 
2.51.0

