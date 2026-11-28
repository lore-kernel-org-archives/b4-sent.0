From: Dickson Wu <dickson.wu@certik.com>
Date: Sat, 28 Nov 2026 14:17:55 +0000
Subject: [PATCH 6.1.y] nvme-tcp: sanitize request list handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-nvme-r2t-61-v1-1-2c1875964e5c@certik.com>
X-B4-Tracking: v=1; b=H4sIAJLiCmsC/02NzQ7CIBCEX6XZs1uFRjS+ivHAz9ZiFBoWG5um7
 17Qi8f5MvPNAkzJE8OlWSDR5NnHUILYNWAHHe6E3pUM8iCVEPKMYXoRJplRCbTKud4dO3myHZT
 FmKj3n6/tCqoV7Qy3H+a3eZDN1VSLRjOhSTrYoSKm4HKMT6x8//cA67oBfgNda6IAAAA=
X-Change-ID: 20261128-nvme-r2t-61-c6ddfd5327c3
To: stable@vger.kernel.org
Cc: Hannes Reinecke <hare@kernel.org>, Sagi Grimberg <sagi@grimberg.me>, 
 Christoph Hellwig <hch@lst.de>, Keith Busch <kbusch@kernel.org>, 
 Jens Axboe <axboe@fb.com>, linux-nvme@lists.infradead.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795875474; l=2848;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=yxyohbLELQu0GqhP3UK8ZEJTUCvWETlmMB05ClrCXEs=;
 b=bsPmz2p7CTmGGgLW7ptdKV62lGGGqAWVum9OVA+6XTBN47Fgh1ij0ARibbNbJ3lO/F2VngpLt
 5jZWI3zKvjfDs+Bb1A/U1UPXN6oBa3XZLY0v4XeXA/2Juf3fWOJ/uA+
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hannes Reinecke <hare@kernel.org>

commit 0bf04c874fcb1ae46a863034296e4b33d8fbd66c upstream.

Validate the request in nvme_tcp_handle_r2t() to ensure it's not part of
any list, otherwise a malicious R2T PDU might inject a loop in request
list processing.

Signed-off-by: Hannes Reinecke <hare@kernel.org>
Reviewed-by: Sagi Grimberg <sagi@grimberg.me>
Signed-off-by: Christoph Hellwig <hch@lst.de>
[ adapted to 6.1.y: open-code absent llist node helpers ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
This one went into 6.6.y and 6.12.y but never made it to 6.1.y,
since 6.1 doesn't have init_llist_node() or llist_on_list(). The
backport open-codes them as node->next = node and node->next != node,
which is all the helpers do, at the same four sites as upstream.

Tested on 6.1.193: W=1 build of drivers/nvme/host/tcp.o, base vs
patched, no new warnings. Both kernels booted under KVM with nvme-tcp
built in. Build and boot only - I didn't send a malicious R2T, so the
new check itself wasn't exercised.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.
---
 drivers/nvme/host/tcp.c | 15 ++++++++++++++-
 1 file changed, 14 insertions(+), 1 deletion(-)

diff --git a/drivers/nvme/host/tcp.c b/drivers/nvme/host/tcp.c
index d434c24e035d..b9abd25d9bff 100644
--- a/drivers/nvme/host/tcp.c
+++ b/drivers/nvme/host/tcp.c
@@ -386,7 +386,8 @@ nvme_tcp_fetch_request(struct nvme_tcp_queue *queue)
 			return NULL;
 	}
 
-	list_del(&req->entry);
+	list_del_init(&req->entry);
+	req->lentry.next = &req->lentry;
 	return req;
 }
 
@@ -494,6 +495,8 @@ static int nvme_tcp_init_request(struct blk_mq_tag_set *set,
 	req->queue = queue;
 	nvme_req(rq)->ctrl = &ctrl->ctrl;
 	nvme_req(rq)->cmd = &pdu->cmd;
+	req->lentry.next = &req->lentry;
+	INIT_LIST_HEAD(&req->entry);
 
 	return 0;
 }
@@ -740,6 +743,14 @@ static int nvme_tcp_handle_r2t(struct nvme_tcp_queue *queue,
 		return -EPROTO;
 	}
 
+	if (req->lentry.next != &req->lentry ||
+	    !list_empty(&req->entry)) {
+		dev_err(queue->ctrl->ctrl.device,
+			"req %d unexpected r2t while processing request\n",
+			rq->tag);
+		return -EPROTO;
+	}
+
 	req->pdu_len = 0;
 	req->h2cdata_left = r2t_length;
 	req->h2cdata_offset = r2t_offset;
@@ -2376,6 +2387,8 @@ static void nvme_tcp_submit_async_event(struct nvme_ctrl *arg)
 	ctrl->async_req.offset = 0;
 	ctrl->async_req.curr_bio = NULL;
 	ctrl->async_req.data_len = 0;
+	ctrl->async_req.lentry.next = &ctrl->async_req.lentry;
+	INIT_LIST_HEAD(&ctrl->async_req.entry);
 
 	nvme_tcp_queue_request(&ctrl->async_req, true, true);
 }

---
base-commit: 1ca1436ccc68275d0b43b6a730b3940fcc46b7c2
change-id: 20261128-nvme-r2t-61-c6ddfd5327c3

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

