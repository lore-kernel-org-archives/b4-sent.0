From: Martin Belanger <martin.nvme.dev@gmail.com>
Date: Mon, 26 Oct 2026 14:09:44 -0400
Subject: [PATCH 1/2] nvme-tcp: start error recovery when read_sock fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-nvme-tcp-ctrlrec-fixes-v1-1-ebf6ff7eff34@gmail.com>
References: <20261026-nvme-tcp-ctrlrec-fixes-v1-0-ebf6ff7eff34@gmail.com>
In-Reply-To: <20261026-nvme-tcp-ctrlrec-fixes-v1-0-ebf6ff7eff34@gmail.com>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Hannes Reinecke <hare@kernel.org>
Cc: linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Martin Belanger <martin.belanger@dell.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793038187; l=1609;
 i=martin.nvme.dev@gmail.com; s=20261014; h=from:subject:message-id;
 bh=ggidawoLoKfpkMXbqKndiLcxYd4qxdMDfKr5YsSgVnk=;
 b=VFIrA0yEclOqssaEnOt9moNoMSkIDzLHTFipPmWLmams9r1umzRKoQ4yGnggqc3TvwySHMjIQ
 O/XZ2KJkldcBMOfXFCYA+Xnyynr571JTUsbUbcw+dTFqIxBB6BqNv5R
X-Developer-Key: i=martin.nvme.dev@gmail.com; a=ed25519;
 pk=4K+XXetGK35w2LzRRddd/bbHawZU222BN+YZRuSpN+k=
X-Endpoint-Received: by B4 Relay for martin.nvme.dev@gmail.com/20261014 with auth_id=1176
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Martin Belanger <martin.belanger@dell.com>

nvme_tcp_recv_skb() disables the queue and starts error recovery for
errors it detects itself. An error returned by the transport reaches
nvme_tcp_try_recv() without either action.

nvme_tcp_io_work() returns on a negative result and does not requeue
itself, so the queue stops receiving and remains stalled until a command
times out.

Report the error and start error recovery when the queue is still
enabled, which indicates that the error was not handled by the actor.

Assisted-by: LLM
Signed-off-by: Martin Belanger <martin.belanger@dell.com>
---
 drivers/nvme/host/tcp.c | 16 +++++++++++++++-
 1 file changed, 15 insertions(+), 1 deletion(-)

diff --git a/drivers/nvme/host/tcp.c b/drivers/nvme/host/tcp.c
index 7190eb10c248..a03476f0f69d 100644
--- a/drivers/nvme/host/tcp.c
+++ b/drivers/nvme/host/tcp.c
@@ -1431,7 +1431,21 @@ static int nvme_tcp_try_recv(struct nvme_tcp_queue *queue)
 	queue->nr_cqe = 0;
 	consumed = sock->ops->read_sock(sk, &rd_desc, nvme_tcp_recv_skb);
 	release_sock(sk);
-	return consumed == -EAGAIN ? 0 : consumed;
+	if (consumed == -EAGAIN)
+		return 0;
+
+	/* nvme_tcp_recv_skb() does both of these itself, so a queue that is
+	 * still enabled failed inside read_sock() instead
+	 */
+	if (unlikely(consumed < 0 && queue->rd_enabled)) {
+		dev_err(queue->ctrl->ctrl.device,
+			"queue %d: receive failed: %d\n",
+			nvme_tcp_queue_id(queue), consumed);
+		queue->rd_enabled = false;
+		nvme_tcp_error_recovery(&queue->ctrl->ctrl);
+	}
+
+	return consumed;
 }
 
 static void nvme_tcp_io_work(struct work_struct *w)

-- 
2.53.0

