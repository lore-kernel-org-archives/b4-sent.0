From: Martin Belanger <martin.nvme.dev@gmail.com>
Date: Thu, 12 Nov 2026 16:13:34 -0500
Subject: [PATCH v3 1/3] nvme-tcp: use an aligned buffer for the TLS record
 type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-nvme-tcp-live-ctrlrec-v3-1-49760bd9eaa8@gmail.com>
References: <20261112-nvme-tcp-live-ctrlrec-v3-0-49760bd9eaa8@gmail.com>
In-Reply-To: <20261112-nvme-tcp-live-ctrlrec-v3-0-49760bd9eaa8@gmail.com>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Hannes Reinecke <hare@kernel.org>
Cc: Martin Belanger <martin.nvme.dev@gmail.com>, 
 linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Martin Belanger <martin.belanger@dell.com>, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794518014; l=3013;
 i=martin.nvme.dev@gmail.com; s=20261014; h=from:subject:message-id;
 bh=Ma7L0R61+9cK+Zp1EpkyOdXzdsPbkTNSuJ4iBIcEyCk=;
 b=MyASM8GqlsM7/OJqtpmmhqczhiI+As6ScjBdZuIN1wAotPnjJEKfAJOtrw82/M9KVvRjWm2Bw
 5sM5FDAl0K+BCN7P1C3Aq6pNxIshloUN2ddPkC/jCKVevCf3Oc2FHAh
X-Developer-Key: i=martin.nvme.dev@gmail.com; a=ed25519;
 pk=4K+XXetGK35w2LzRRddd/bbHawZU222BN+YZRuSpN+k=
X-Endpoint-Received: by B4 Relay for martin.nvme.dev@gmail.com/20261014 with auth_id=1176
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Martin Belanger <martin.belanger@dell.com>

The buffers that receive the TLS record type are char arrays.
put_cmsg() and tls_get_record_type() access them as struct cmsghdr,
which needs a stricter alignment than a char array has.

Use a union with struct cmsghdr, sized with CMSG_SPACE(), as
svc_tcp_recv_cmsg() and xs_tls_read_record() in sunrpc do.

Fixes: 2837966ab2a8 ("nvme-tcp: control message handling for recvmsg()")
Cc: stable@vger.kernel.org
Signed-off-by: Martin Belanger <martin.belanger@dell.com>
Reviewed-by: Hannes Reinecke <hare@kernel.org>
---
 drivers/nvme/host/tcp.c | 23 ++++++++++++++---------
 1 file changed, 14 insertions(+), 9 deletions(-)

diff --git a/drivers/nvme/host/tcp.c b/drivers/nvme/host/tcp.c
index 7ecc6c007f8d..749d77b4e172 100644
--- a/drivers/nvme/host/tcp.c
+++ b/drivers/nvme/host/tcp.c
@@ -77,6 +77,12 @@ MODULE_PARM_DESC(tls_handshake_timeout,
 /* TLS records read while waiting for the ICResp, the ICResp included */
 #define NVME_TCP_ICRESP_MAX_RECORDS 8
 
+/* control message buffer for the TLS record type */
+union nvme_tcp_tls_cmsg {
+	struct cmsghdr	cmsg;
+	u8		buf[CMSG_SPACE(sizeof(u8))];
+};
+
 static int nvme_tcp_cpu_queues[NR_CPUS];
 static DEFINE_SPINLOCK(nvme_tcp_cpu_queues_lock);
 
@@ -1653,11 +1659,11 @@ static int nvme_tcp_skip_tls_record(struct nvme_tcp_queue *queue,
 			.iov_base = buf,
 			.iov_len = sizeof(buf),
 		};
-		char cbuf[CMSG_LEN(sizeof(char))] = {};
+		union nvme_tcp_tls_cmsg u = {};
 		/* kTLS fails a control record read without a cmsg buffer */
 		struct msghdr drain = {
-			.msg_control = cbuf,
-			.msg_controllen = sizeof(cbuf),
+			.msg_control = &u,
+			.msg_controllen = sizeof(u),
 		};
 
 		ret = kernel_recvmsg(queue->sock, &drain, &iov, 1, sizeof(buf),
@@ -1682,7 +1688,7 @@ static int nvme_tcp_skip_tls_record(struct nvme_tcp_queue *queue,
 static int nvme_tcp_recv_icresp(struct nvme_tcp_queue *queue,
 				struct nvme_tcp_icresp_pdu *icresp)
 {
-	char cbuf[CMSG_LEN(sizeof(char))];
+	union nvme_tcp_tls_cmsg u;
 	struct msghdr msg;
 	struct kvec iov;
 	u8 ctype;
@@ -1690,12 +1696,12 @@ static int nvme_tcp_recv_icresp(struct nvme_tcp_queue *queue,
 
 	for (i = 0; i < NVME_TCP_ICRESP_MAX_RECORDS; i++) {
 		memset(&msg, 0, sizeof(msg));
-		memset(cbuf, 0, sizeof(cbuf));
+		memset(&u, 0, sizeof(u));
 		iov.iov_base = icresp;
 		iov.iov_len = sizeof(*icresp);
 		if (nvme_tcp_queue_tls(queue)) {
-			msg.msg_control = cbuf;
-			msg.msg_controllen = sizeof(cbuf);
+			msg.msg_control = &u;
+			msg.msg_controllen = sizeof(u);
 		}
 		msg.msg_flags = MSG_WAITALL;
 		ret = kernel_recvmsg(queue->sock, &msg, &iov, 1,
@@ -1703,8 +1709,7 @@ static int nvme_tcp_recv_icresp(struct nvme_tcp_queue *queue,
 		if (ret <= 0 || !nvme_tcp_queue_tls(queue))
 			return ret;
 
-		ctype = tls_get_record_type(queue->sock->sk,
-					    (struct cmsghdr *)cbuf);
+		ctype = tls_get_record_type(queue->sock->sk, &u.cmsg);
 		if (ctype == TLS_RECORD_TYPE_DATA)
 			return ret;
 

-- 
2.53.0

