From: Martin Belanger <martin.nvme.dev@gmail.com>
Date: Mon, 09 Nov 2026 14:04:53 -0500
Subject: [PATCH 1/2] nvme-tcp: move the TLS record read loop into a helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-nvme-tcp-live-ctrlrec-v1-1-47ba61670e65@gmail.com>
References: <20261109-nvme-tcp-live-ctrlrec-v1-0-47ba61670e65@gmail.com>
In-Reply-To: <20261109-nvme-tcp-live-ctrlrec-v1-0-47ba61670e65@gmail.com>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Hannes Reinecke <hare@kernel.org>
Cc: Martin Belanger <martin.nvme.dev@gmail.com>, 
 linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Martin Belanger <martin.belanger@dell.com>, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794251097; l=3262;
 i=martin.nvme.dev@gmail.com; s=20261014; h=from:subject:message-id;
 bh=I4tNXDC3YZTae17hei8TZK0tGRXfiT5ZPYdrswIwZ+c=;
 b=1kbWCQoRGlIaN5Ypz1TLuG8zQn3jMAb+c8snPAK0dO/VssR/HwmDS5nDoV9ZaJnoCKCbU5uLB
 b1UD11paE1WA6G+Qk0VF55nQQLiYHPCp4E6+rKjJyXEu4AfscHdR5ft
X-Developer-Key: i=martin.nvme.dev@gmail.com; a=ed25519;
 pk=4K+XXetGK35w2LzRRddd/bbHawZU222BN+YZRuSpN+k=
X-Endpoint-Received: by B4 Relay for martin.nvme.dev@gmail.com/20261014 with auth_id=1176
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Martin Belanger <martin.belanger@dell.com>

Move the read loop out of nvme_tcp_skip_tls_record() into a new
helper, nvme_tcp_drain_tls_record(). The next patch uses the helper
to read TLS records that arrive on a live queue.

No functional change.

Cc: stable@vger.kernel.org
Signed-off-by: Martin Belanger <martin.belanger@dell.com>
---
 drivers/nvme/host/tcp.c | 60 +++++++++++++++++++++++++++++++------------------
 1 file changed, 38 insertions(+), 22 deletions(-)

diff --git a/drivers/nvme/host/tcp.c b/drivers/nvme/host/tcp.c
index 7ecc6c007f8d..bf71e6f6a6ef 100644
--- a/drivers/nvme/host/tcp.c
+++ b/drivers/nvme/host/tcp.c
@@ -1623,31 +1623,16 @@ static int nvme_tcp_recv_tls_alert(struct nvme_tcp_queue *queue,
 }
 
 /*
- * Discard a TLS record that arrived in place of the ICResp. A peer may send
- * a NewSessionTicket as soon as the handshake completes.
+ * Read the rest of a TLS record whose first part was read into @msg.
  *
- * Returns 0 when the record was discarded and the ICResp can be read, or a
- * negative errno if the connection cannot continue.
+ * Returns the bytes read, or a negative errno.
  */
-static int nvme_tcp_skip_tls_record(struct nvme_tcp_queue *queue,
-				    struct msghdr *msg, u8 ctype, int len)
+static int nvme_tcp_drain_tls_record(struct nvme_tcp_queue *queue,
+				     struct msghdr *msg, int flags)
 {
 	u8 buf[NVME_TCP_TLS_REC_CHUNK];
-	int ret;
+	int ret, drained = 0;
 
-	switch (ctype) {
-	case TLS_RECORD_TYPE_HANDSHAKE:
-		break;
-	case TLS_RECORD_TYPE_ALERT:
-		ret = nvme_tcp_recv_tls_alert(queue, msg, len);
-		return ret ? : -ENOTCONN;
-	default:
-		pr_err("queue %d: unhandled TLS record %u\n",
-		       nvme_tcp_queue_id(queue), ctype);
-		return -ENOTCONN;
-	}
-
-	/* the ICResp is in a later record, drain this one first */
 	while (!(msg->msg_flags & MSG_EOR)) {
 		struct kvec iov = {
 			.iov_base = buf,
@@ -1661,16 +1646,47 @@ static int nvme_tcp_skip_tls_record(struct nvme_tcp_queue *queue,
 		};
 
 		ret = kernel_recvmsg(queue->sock, &drain, &iov, 1, sizeof(buf),
-				     0);
+				     flags);
 		if (ret <= 0) {
 			pr_warn("queue %d: failed to drain TLS record: %d\n",
 				nvme_tcp_queue_id(queue), ret);
 			return ret ? : -ECONNRESET;
 		}
+		drained += ret;
 		msg->msg_flags = drain.msg_flags;
 	}
 
-	return 0;
+	return drained;
+}
+
+/*
+ * Discard a TLS record that arrived in place of the ICResp. A peer may send
+ * a NewSessionTicket as soon as the handshake completes.
+ *
+ * Returns 0 when the record was discarded and the ICResp can be read, or a
+ * negative errno if the connection cannot continue.
+ */
+static int nvme_tcp_skip_tls_record(struct nvme_tcp_queue *queue,
+				    struct msghdr *msg, u8 ctype, int len)
+{
+	int ret;
+
+	switch (ctype) {
+	case TLS_RECORD_TYPE_HANDSHAKE:
+		break;
+	case TLS_RECORD_TYPE_ALERT:
+		ret = nvme_tcp_recv_tls_alert(queue, msg, len);
+		return ret ? : -ENOTCONN;
+	default:
+		pr_err("queue %d: unhandled TLS record %u\n",
+		       nvme_tcp_queue_id(queue), ctype);
+		return -ENOTCONN;
+	}
+
+	/* the ICResp is in a later record, drain this one first */
+	ret = nvme_tcp_drain_tls_record(queue, msg, 0);
+
+	return ret < 0 ? ret : 0;
 }
 
 /*

-- 
2.53.0

