From: Martin Belanger <martin.nvme.dev@gmail.com>
Date: Thu, 12 Nov 2026 16:13:36 -0500
Subject: [PATCH v3 3/3] nvme-tcp: consume TLS records without application
 data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-nvme-tcp-live-ctrlrec-v3-3-49760bd9eaa8@gmail.com>
References: <20261112-nvme-tcp-live-ctrlrec-v3-0-49760bd9eaa8@gmail.com>
In-Reply-To: <20261112-nvme-tcp-live-ctrlrec-v3-0-49760bd9eaa8@gmail.com>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Hannes Reinecke <hare@kernel.org>
Cc: Martin Belanger <martin.nvme.dev@gmail.com>, 
 linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Martin Belanger <martin.belanger@dell.com>, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794518014; l=7069;
 i=martin.nvme.dev@gmail.com; s=20261014; h=from:subject:message-id;
 bh=BXkzTnuE1CdiV8DxLxpXS4wtJqzfrr8MfvY7b3eLfds=;
 b=tMT7D7LfgIfbDrB4BZFfVXM1SOfBdkNW1WY14QcdsyoQsFYX9OtBuhYi9yEJaVDppjF7ZkbrS
 0+7coV9v28BAQZYb91DiLOxb7kd90UWAprZJc5gnPdsutALk3UIpDlC
X-Developer-Key: i=martin.nvme.dev@gmail.com; a=ed25519;
 pk=4K+XXetGK35w2LzRRddd/bbHawZU222BN+YZRuSpN+k=
X-Endpoint-Received: by B4 Relay for martin.nvme.dev@gmail.com/20261014 with auth_id=1176
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Martin Belanger <martin.belanger@dell.com>

A peer may send a TLS record without application data at any time
after the handshake: a NewSessionTicket, a KeyUpdate or an alert.
tls_sw_read_sock() cannot pass such a record to nvme_tcp_recv_skb().
It returns -EINVAL and leaves the record at the head of the receive
queue. nvme_tcp_try_recv() then starts error recovery, and the
controller reconnects.

TLS 1.3 allows a server to send a NewSessionTicket at any time after
the handshake (RFC 8446, section 4.6.1). Alerts can also arrive at any
time.

On -EINVAL, read the record with recvmsg(), which reports the record
type. Discard handshake messages other than KeyUpdate. Log alerts, and
fail the queue on a fatal alert. Fail the queue on a KeyUpdate, which
nvme-tcp cannot answer, and on any other record type. recvmsg() takes
the socket lock, so release it around the read.

Handle these records in one helper, also for the records that arrive
ahead of the ICResp. A warning alert ahead of the ICResp no longer fails
the connection.

On a poll queue, nvme_tcp_poll() and nvme_tcp_io_work() can both see
the record while the socket lock is released. A queue flag makes sure
that only one of them reads it.

svc_tcp_recvfrom() in sunrpc handles -EINVAL from read_sock() the same
way.

Fixes: be8e82caa685 ("nvme-tcp: enable TLS handshake upcall")
Cc: stable@vger.kernel.org
Signed-off-by: Martin Belanger <martin.belanger@dell.com>
---
 drivers/nvme/host/tcp.c | 113 +++++++++++++++++++++++++++++++++++++++++-------
 1 file changed, 97 insertions(+), 16 deletions(-)

diff --git a/drivers/nvme/host/tcp.c b/drivers/nvme/host/tcp.c
index c3bf345c4e92..45e66adcf57d 100644
--- a/drivers/nvme/host/tcp.c
+++ b/drivers/nvme/host/tcp.c
@@ -123,6 +123,7 @@ enum nvme_tcp_queue_flags {
 	NVME_TCP_Q_LIVE		= 1,
 	NVME_TCP_Q_POLLING	= 2,
 	NVME_TCP_Q_IO_CPU_SET	= 3,
+	NVME_TCP_Q_TLS_RECORD	= 4,
 };
 
 #define NVME_TCP_OPT_NR_QUEUES(opts) ((opts)->nr_io_queues + \
@@ -1450,6 +1451,8 @@ static int nvme_tcp_try_send(struct nvme_tcp_queue *queue)
 	return ret;
 }
 
+static int nvme_tcp_recv_tls_record(struct nvme_tcp_queue *queue);
+
 static int nvme_tcp_try_recv(struct nvme_tcp_queue *queue)
 {
 	struct socket *sock = queue->sock;
@@ -1462,10 +1465,31 @@ static int nvme_tcp_try_recv(struct nvme_tcp_queue *queue)
 	lock_sock(sk);
 	queue->nr_cqe = 0;
 	consumed = sock->ops->read_sock(sk, &rd_desc, nvme_tcp_recv_skb);
+	/*
+	 * kTLS cannot pass a TLS record without application data to
+	 * nvme_tcp_recv_skb(). It returns -EINVAL and leaves the record at
+	 * the head of the receive queue. recvmsg() takes the socket lock,
+	 * so read the record without it.
+	 */
+	if (unlikely(consumed == -EINVAL && nvme_tcp_queue_tls(queue) &&
+		     queue->rd_enabled)) {
+		/*
+		 * On a poll queue, nvme_tcp_poll() and nvme_tcp_io_work() can
+		 * both get here for the same record. Only one of them reads it.
+		 */
+		if (test_and_set_bit(NVME_TCP_Q_TLS_RECORD, &queue->flags)) {
+			consumed = 0;
+		} else {
+			release_sock(sk);
+			consumed = nvme_tcp_recv_tls_record(queue);
+			lock_sock(sk);
+			clear_bit(NVME_TCP_Q_TLS_RECORD, &queue->flags);
+		}
+	}
 	/*
 	 * nvme_tcp_recv_skb() handles its own errors, so a queue that is
-	 * still enabled failed inside read_sock(). Handle it before
-	 * release_sock() processes the backlog.
+	 * still enabled failed inside read_sock() or while reading a TLS
+	 * record. Handle it before release_sock() processes the backlog.
 	 */
 	if (unlikely(consumed < 0 && consumed != -EAGAIN &&
 		     queue->rd_enabled)) {
@@ -1666,33 +1690,88 @@ static int nvme_tcp_drain_tls_record(struct nvme_tcp_queue *queue,
 }
 
 /*
- * Discard a TLS record that arrived in place of the ICResp. A peer may send
- * a NewSessionTicket as soon as the handshake completes.
+ * Consume a TLS record without application data. The first @len bytes of
+ * the record were read into @msg and @data.
  *
- * Returns 0 when the record was discarded and the ICResp can be read, or a
- * negative errno if the connection cannot continue.
+ * A KeyUpdate needs new keys that nothing here can supply. Other handshake
+ * messages, such as a NewSessionTicket, are discarded.
+ *
+ * Returns the bytes read after the first @len, or a negative errno if the
+ * connection cannot continue.
  */
-static int nvme_tcp_skip_tls_record(struct nvme_tcp_queue *queue,
-				    struct msghdr *msg, u8 ctype, int len)
+static int nvme_tcp_consume_tls_record(struct nvme_tcp_queue *queue,
+				       struct msghdr *msg, u8 ctype,
+				       const u8 *data, int len, int flags)
 {
 	int ret;
 
 	switch (ctype) {
 	case TLS_RECORD_TYPE_HANDSHAKE:
+		if (data[0] == TLS_HANDSHAKE_KEYUPDATE) {
+			dev_err(queue->ctrl->ctrl.device,
+				"queue %d: TLS KeyUpdate is not supported\n",
+				nvme_tcp_queue_id(queue));
+			return -EKEYEXPIRED;
+		}
 		break;
 	case TLS_RECORD_TYPE_ALERT:
 		ret = nvme_tcp_recv_tls_alert(queue, msg, len);
-		return ret ? : -ENOTCONN;
+		if (ret)
+			return ret;
+		break;
 	default:
-		pr_err("queue %d: unhandled TLS record %u\n",
-		       nvme_tcp_queue_id(queue), ctype);
-		return -ENOTCONN;
+		dev_err(queue->ctrl->ctrl.device,
+			"queue %d: unexpected TLS record %u\n",
+			nvme_tcp_queue_id(queue), ctype);
+		return -EPROTO;
 	}
 
-	/* the ICResp is in a later record, drain this one first */
-	ret = nvme_tcp_drain_tls_record(queue, msg, 0);
+	return nvme_tcp_drain_tls_record(queue, msg, flags);
+}
+
+/*
+ * Read the TLS record that read_sock() could not pass to
+ * nvme_tcp_recv_skb(). The caller must not hold the socket lock.
+ *
+ * Returns the bytes consumed, or a negative errno if the connection cannot
+ * continue.
+ */
+static int nvme_tcp_recv_tls_record(struct nvme_tcp_queue *queue)
+{
+	u8 buf[NVME_TCP_TLS_REC_CHUNK];
+	union nvme_tcp_tls_cmsg u = {};
+	struct kvec iov = {
+		.iov_base = buf,
+		.iov_len = sizeof(buf),
+	};
+	struct msghdr msg = {
+		.msg_control = &u,
+		.msg_controllen = sizeof(u),
+	};
+	int len, ret;
+	u8 ctype;
+
+	len = kernel_recvmsg(queue->sock, &msg, &iov, 1, sizeof(buf),
+			     MSG_DONTWAIT);
+	if (len <= 0)
+		goto fail;
+
+	ctype = tls_get_record_type(queue->sock->sk, &u.cmsg);
+	ret = nvme_tcp_consume_tls_record(queue, &msg, ctype, buf, len,
+					  MSG_DONTWAIT);
+	if (ret < 0) {
+		len = ret;
+		goto fail;
+	}
+
+	return len + ret;
+
+fail:
+	/* read_sock() left a whole record, so none of it can be missing */
+	if (len == -EAGAIN)
+		return -EPROTO;
 
-	return ret < 0 ? ret : 0;
+	return len ? : -ECONNRESET;
 }
 
 /*
@@ -1729,7 +1808,9 @@ static int nvme_tcp_recv_icresp(struct nvme_tcp_queue *queue,
 		if (ctype == TLS_RECORD_TYPE_DATA)
 			return ret;
 
-		ret = nvme_tcp_skip_tls_record(queue, &msg, ctype, ret);
+		/* the ICResp is in a later record */
+		ret = nvme_tcp_consume_tls_record(queue, &msg, ctype,
+						  (const u8 *)icresp, ret, 0);
 		if (ret < 0)
 			return ret;
 	}

-- 
2.53.0

