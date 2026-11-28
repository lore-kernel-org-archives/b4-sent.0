From: Dickson Wu <dickson.wu@certik.com>
Date: Sat, 28 Nov 2026 01:53:37 +0000
Subject: [PATCH 6.6.y] nvme-tcp: fix usage of page_frag_cache
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-nvme-pfc-66b-v1-1-1e9e62f279aa@certik.com>
X-B4-Tracking: v=1; b=H4sIACA0CmsC/02NwQ7CIBBEf6XZs1uFRFL9FdMDLFuLUWjY2mia/
 rugF4/zMvNmBeEcWODcrJB5CRJSLEHtGqDRxitj8CWDPmijlO4wLg/GaSA0xqH2dOzsoE9sCMp
 kyjyE11d3AdOa9g39D8vT3ZjmqqpFZ4XRZRtprEg4+jmlO1a+/7+AbfsAOJ3hdKQAAAA=
X-Change-ID: 20261128-nvme-pfc-66b-2dc58af29e6c
In-Reply-To: <2026093029-shadily-cattle-6976@gregkh>
References: <2026093029-shadily-cattle-6976@gregkh>
To: stable@vger.kernel.org
Cc: Dmitry Bogdanov <d.bogdanov@yadro.com>, Daniel Wagner <wagi@kernel.org>, 
 Keith Busch <kbusch@kernel.org>, linux-nvme@lists.infradead.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795830816; l=4082;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=CdE6yazXdSUljdqOaRYpG4gOpo7h4tspV/2rkKEFY6s=;
 b=NYsneGD3NMbEmIgR07SkJTCdj2M5Up0H0/CiIhVf7ecGOMBmFFI7NtYc4YfgCoO6TLEUh1cd6
 9hAVeGA+PpAAWdzRT/N+FI1ObvPNbspk+OkxJI3XDiEWz4hlYLDXsN/
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Dmitry Bogdanov <d.bogdanov@yadro.com>

commit 36ac05f7cfd59d90c597071304b14e98090d5dd1 upstream.

nvme uses page_frag_cache to preallocate PDU for each preallocated request
of block device. Block devices are created in parallel threads,
consequently page_frag_cache is used in not thread-safe manner.
That leads to incorrect refcounting of backstore pages and premature free.

That can be catched by !sendpage_ok inside network stack:

WARNING: CPU: 7 PID: 467 at ../net/core/skbuff.c:6931 skb_splice_from_iter+0xfa/0x310.
	tcp_sendmsg_locked+0x782/0xce0
	tcp_sendmsg+0x27/0x40
	sock_sendmsg+0x8b/0xa0
	nvme_tcp_try_send_cmd_pdu+0x149/0x2a0
Then random panic may occur.

Fix that by serializing the usage of page_frag_cache.

Fixes: 4e893ca81170 ("nvme_core: scan namespaces asynchronously")
Signed-off-by: Dmitry Bogdanov <d.bogdanov@yadro.com>
Signed-off-by: Daniel Wagner <wagi@kernel.org>
Signed-off-by: Keith Busch <kbusch@kernel.org>
[ adapted to 6.6.y: no lockdep key cleanup in the queue teardown ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
This failed to apply to 6.6.y. The fix is the same: a per-queue mutex
around the two page_frag_alloc() callers, initialized in
nvme_tcp_alloc_queue() and destroyed on the free and error paths. Only
the context differs, since the 6.6 queue teardown has no lockdep keys.

Tested on 6.6.163: W=1 build of drivers/nvme/host/tcp.o, base vs
patched, no new warnings. Both kernels booted under QEMU, connected to
a loopback NVMe/TCP target, read a block and disconnected. I didn't
reproduce the page_frag_cache race itself.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.
---
 drivers/nvme/host/tcp.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/nvme/host/tcp.c b/drivers/nvme/host/tcp.c
index 83347e01929f..673253762c83 100644
--- a/drivers/nvme/host/tcp.c
+++ b/drivers/nvme/host/tcp.c
@@ -121,6 +121,7 @@ struct nvme_tcp_queue {
 
 	struct mutex		queue_lock;
 	struct mutex		send_mutex;
+	struct mutex		pf_cache_lock;
 	struct llist_head	req_list;
 	struct list_head	send_list;
 
@@ -498,9 +499,11 @@ static int nvme_tcp_init_request(struct blk_mq_tag_set *set,
 	struct nvme_tcp_queue *queue = &ctrl->queues[queue_idx];
 	u8 hdgst = nvme_tcp_hdgst_len(queue);
 
+	mutex_lock(&queue->pf_cache_lock);
 	req->pdu = page_frag_alloc(&queue->pf_cache,
 		sizeof(struct nvme_tcp_cmd_pdu) + hdgst,
 		GFP_KERNEL | __GFP_ZERO);
+	mutex_unlock(&queue->pf_cache_lock);
 	if (!req->pdu)
 		return -ENOMEM;
 
@@ -1438,9 +1441,11 @@ static int nvme_tcp_alloc_async_req(struct nvme_tcp_ctrl *ctrl)
 	struct nvme_tcp_request *async = &ctrl->async_req;
 	u8 hdgst = nvme_tcp_hdgst_len(queue);
 
+	mutex_lock(&queue->pf_cache_lock);
 	async->pdu = page_frag_alloc(&queue->pf_cache,
 		sizeof(struct nvme_tcp_cmd_pdu) + hdgst,
 		GFP_KERNEL | __GFP_ZERO);
+	mutex_unlock(&queue->pf_cache_lock);
 	if (!async->pdu)
 		return -ENOMEM;
 
@@ -1469,6 +1474,7 @@ static void nvme_tcp_free_queue(struct nvme_ctrl *nctrl, int qid)
 	kfree(queue->pdu);
 	mutex_destroy(&queue->send_mutex);
 	mutex_destroy(&queue->queue_lock);
+	mutex_destroy(&queue->pf_cache_lock);
 }
 
 static int nvme_tcp_init_connection(struct nvme_tcp_queue *queue)
@@ -1644,6 +1650,7 @@ static int nvme_tcp_alloc_queue(struct nvme_ctrl *nctrl, int qid)
 	INIT_LIST_HEAD(&queue->send_list);
 	mutex_init(&queue->send_mutex);
 	INIT_WORK(&queue->io_work, nvme_tcp_io_work);
+	mutex_init(&queue->pf_cache_lock);
 
 	if (qid > 0)
 		queue->cmnd_capsule_len = nctrl->ioccsz * 16;
@@ -1771,6 +1778,7 @@ static int nvme_tcp_alloc_queue(struct nvme_ctrl *nctrl, int qid)
 err_destroy_mutex:
 	mutex_destroy(&queue->send_mutex);
 	mutex_destroy(&queue->queue_lock);
+	mutex_destroy(&queue->pf_cache_lock);
 	return ret;
 }
 

---
base-commit: e2bb30811e063ce0db964484357973b855b06572
change-id: 20261128-nvme-pfc-66b-2dc58af29e6c

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

