From: Martin Belanger <martin.nvme.dev@gmail.com>
Date: Wed, 11 Nov 2026 15:42:41 -0500
Subject: [PATCH v2 3/3] nvme-tcp: consume TLS records without application
 data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-nvme-tcp-live-ctrlrec-v2-3-6295202b84de@gmail.com>
References: <20261111-nvme-tcp-live-ctrlrec-v2-0-6295202b84de@gmail.com>
In-Reply-To: <20261111-nvme-tcp-live-ctrlrec-v2-0-6295202b84de@gmail.com>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Hannes Reinecke <hare@kernel.org>
Cc: Martin Belanger <martin.nvme.dev@gmail.com>, 
 linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Martin Belanger <martin.belanger@dell.com>, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794429760; l=5497;
 i=martin.nvme.dev@gmail.com; s=20261014; h=from:subject:message-id;
 bh=m228vdxP3ZzFl+gT3m3W5yTlx4aQ1XbuGpyRUHeWzeg=;
 b=tjSB6muxQQMw6dnrZQgd+BNhSPHA4JJ0d9L3x048ettB5iD72O5kJEeqM0fK0kMBsBy43jg4v
 lXszNakTBErA8ajamBX5FF/aZ93Vk4/0WZBoDwPkDuG1pdDByi2tb4p
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

On a poll queue, nvme_tcp_poll() and nvme_tcp_io_work() can both see
the record while the socket lock is released. A queue flag makes sure
that only one of them reads it.

svc_tcp_recvfrom() in sunrpc handles -EINVAL from read_sock() the same
way.

Fixes: be8e82caa685 ("nvme-tcp: enable TLS handshake upcall")
Cc: stable@vger.kernel.org
Signed-off-by: Martin Belanger <martin.belanger@dell.com>
---
 drivers/nvme/host/tcp.c | 96 +++++++++++++++++++++++++++++++++++++++++++++++--
 1 file changed, 94 insertions(+), 2 deletions(-)

diff --git a/drivers/nvme/host/tcp.c b/drivers/nvme/host/tcp.c
index c3bf345c4e92..cc6a46f118b2 100644
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
@@ -1665,6 +1689,74 @@ static int nvme_tcp_drain_tls_record(struct nvme_tcp_queue *queue,
 	return drained;
 }
 
+/*
+ * Read the TLS record that read_sock() could not pass to
+ * nvme_tcp_recv_skb(). The caller must not hold the socket lock.
+ *
+ * A KeyUpdate needs new keys that nothing here can supply. Other handshake
+ * messages, such as a NewSessionTicket, are discarded.
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
+	switch (ctype) {
+	case TLS_RECORD_TYPE_HANDSHAKE:
+		if (buf[0] == TLS_HANDSHAKE_KEYUPDATE) {
+			dev_err(queue->ctrl->ctrl.device,
+				"queue %d: peer sent a TLS KeyUpdate, which is not supported\n",
+				nvme_tcp_queue_id(queue));
+			return -EKEYEXPIRED;
+		}
+		break;
+	case TLS_RECORD_TYPE_ALERT:
+		ret = nvme_tcp_recv_tls_alert(queue, &msg, len);
+		if (ret)
+			return ret;
+		break;
+	default:
+		dev_err(queue->ctrl->ctrl.device,
+			"queue %d: unexpected TLS record %u\n",
+			nvme_tcp_queue_id(queue), ctype);
+		return -EPROTO;
+	}
+
+	ret = nvme_tcp_drain_tls_record(queue, &msg, MSG_DONTWAIT);
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
+
+	return len ? : -ECONNRESET;
+}
+
 /*
  * Discard a TLS record that arrived in place of the ICResp. A peer may send
  * a NewSessionTicket as soon as the handshake completes.

-- 
2.53.0

