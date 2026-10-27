From: Martin Belanger <martin.nvme.dev@gmail.com>
Date: Tue, 27 Oct 2026 06:38:52 -0400
Subject: [PATCH v2 1/2] nvme-tcp: start error recovery when read_sock fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-nvme-tcp-ctrlrec-fixes-v2-1-9656395ebcf2@gmail.com>
References: <20261027-nvme-tcp-ctrlrec-fixes-v2-0-9656395ebcf2@gmail.com>
In-Reply-To: <20261027-nvme-tcp-ctrlrec-fixes-v2-0-9656395ebcf2@gmail.com>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Hannes Reinecke <hare@kernel.org>
Cc: linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Martin Belanger <martin.belanger@dell.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793097538; l=1682;
 i=martin.nvme.dev@gmail.com; s=20261014; h=from:subject:message-id;
 bh=hDUpWm1V3KSmqXGaIokvqiOU1vnqpmBdJKR+jEs0Z8E=;
 b=GLMuaIbGa9+1cdJ/X2rg+kI5ktjvxKfw6FY6iPGzg8gRjGdKFzt1S6+mHkaX++usMNA/PLKps
 d03mkoVUBEdBvqlBicld6/RqO4ZLNQA2a2QpiAV/RQEjwpSsTpaqEuB
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
Do this under the socket lock, as nvme_tcp_recv_skb() does.

Assisted-by: LLM
Reviewed-by: Hannes Reinecke <hare@kernel.org>
Signed-off-by: Martin Belanger <martin.belanger@dell.com>
---
 drivers/nvme/host/tcp.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/nvme/host/tcp.c b/drivers/nvme/host/tcp.c
index 7190eb10c248..0231b95fe4e4 100644
--- a/drivers/nvme/host/tcp.c
+++ b/drivers/nvme/host/tcp.c
@@ -1430,6 +1430,19 @@ static int nvme_tcp_try_recv(struct nvme_tcp_queue *queue)
 	lock_sock(sk);
 	queue->nr_cqe = 0;
 	consumed = sock->ops->read_sock(sk, &rd_desc, nvme_tcp_recv_skb);
+	/*
+	 * nvme_tcp_recv_skb() handles its own errors, so a queue that is
+	 * still enabled failed inside read_sock(). Handle it before
+	 * release_sock() processes the backlog.
+	 */
+	if (unlikely(consumed < 0 && consumed != -EAGAIN &&
+		     queue->rd_enabled)) {
+		dev_err(queue->ctrl->ctrl.device,
+			"queue %d: receive failed: %d\n",
+			nvme_tcp_queue_id(queue), consumed);
+		queue->rd_enabled = false;
+		nvme_tcp_error_recovery(&queue->ctrl->ctrl);
+	}
 	release_sock(sk);
 	return consumed == -EAGAIN ? 0 : consumed;
 }

-- 
2.53.0

