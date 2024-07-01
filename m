From: Luigi Leonardi <luigi.leonardi@outlook.com>
Date: Mon, 01 Jul 2024 16:28:02 +0200
Subject: [PATCH PATCH net-next v2 1/2] vsock/virtio: refactor
 virtio_transport_send_pkt_work
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240701-pinna-v2-1-ac396d181f59@outlook.com>
References: <20240701-pinna-v2-0-ac396d181f59@outlook.com>
In-Reply-To: <20240701-pinna-v2-0-ac396d181f59@outlook.com>
To: Stefan Hajnoczi <stefanha@redhat.com>, 
 Stefano Garzarella <sgarzare@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: kvm@vger.kernel.org, virtualization@lists.linux.dev, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Luigi Leonardi <luigi.leonardi@outlook.com>, 
 Marco Pinna <marco.pinn95@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719844084; l=5134;
 i=luigi.leonardi@outlook.com; s=20240626; h=from:subject:message-id;
 bh=xO3JVID69HzQl8PV89fm/m3BxZXcjSdlPoJGK0Jw7gs=;
 b=3SH8W/K2OBZnYmyJWcn17CJMZdAOGsX6kQ6evtmfz74DIKSsWHv3dHFT4NdqzvQ6Me1ePDEZT
 8D72kfD0W9qBJ3bblQuSPzggue5anmHvTAsgvqQk2OgRqidw7BNm/8s
X-Developer-Key: i=luigi.leonardi@outlook.com; a=ed25519;
 pk=RYXD8JyCxGnx/izNc/6b3g3pgpohJMAI0LJ7ynxXzi8=
X-Endpoint-Received: by B4 Relay for luigi.leonardi@outlook.com/20240626 with auth_id=177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Marco Pinna <marco.pinn95@gmail.com>

Preliminary patch to introduce an optimization to the
enqueue system.

All the code used to enqueue a packet into the virtqueue
is removed from virtio_transport_send_pkt_work()
and moved to the new virtio_transport_send_skb() function.

Co-developed-by: Luigi Leonardi <luigi.leonardi@outlook.com>
Signed-off-by: Luigi Leonardi <luigi.leonardi@outlook.com>
Signed-off-by: Marco Pinna <marco.pinn95@gmail.com>
---
 net/vmw_vsock/virtio_transport.c | 133 +++++++++++++++++++++------------------
 1 file changed, 73 insertions(+), 60 deletions(-)

diff --git a/net/vmw_vsock/virtio_transport.c b/net/vmw_vsock/virtio_transport.c
index 43d405298857..a74083d28120 100644
--- a/net/vmw_vsock/virtio_transport.c
+++ b/net/vmw_vsock/virtio_transport.c
@@ -94,6 +94,77 @@ static u32 virtio_transport_get_local_cid(void)
 	return ret;
 }
 
+/* Caller need to hold vsock->tx_lock on vq */
+static int virtio_transport_send_skb(struct sk_buff *skb, struct virtqueue *vq,
+				     struct virtio_vsock *vsock, bool *restart_rx)
+{
+	int ret, in_sg = 0, out_sg = 0;
+	struct scatterlist **sgs;
+	bool reply;
+
+	reply = virtio_vsock_skb_reply(skb);
+	sgs = vsock->out_sgs;
+	sg_init_one(sgs[out_sg], virtio_vsock_hdr(skb),
+		    sizeof(*virtio_vsock_hdr(skb)));
+	out_sg++;
+
+	if (!skb_is_nonlinear(skb)) {
+		if (skb->len > 0) {
+			sg_init_one(sgs[out_sg], skb->data, skb->len);
+			out_sg++;
+		}
+	} else {
+		struct skb_shared_info *si;
+		int i;
+
+		/* If skb is nonlinear, then its buffer must contain
+		 * only header and nothing more. Data is stored in
+		 * the fragged part.
+		 */
+		WARN_ON_ONCE(skb_headroom(skb) != sizeof(*virtio_vsock_hdr(skb)));
+
+		si = skb_shinfo(skb);
+
+		for (i = 0; i < si->nr_frags; i++) {
+			skb_frag_t *skb_frag = &si->frags[i];
+			void *va;
+
+			/* We will use 'page_to_virt()' for the userspace page
+			 * here, because virtio or dma-mapping layers will call
+			 * 'virt_to_phys()' later to fill the buffer descriptor.
+			 * We don't touch memory at "virtual" address of this page.
+			 */
+			va = page_to_virt(skb_frag_page(skb_frag));
+			sg_init_one(sgs[out_sg],
+				    va + skb_frag_off(skb_frag),
+				    skb_frag_size(skb_frag));
+			out_sg++;
+		}
+	}
+
+	ret = virtqueue_add_sgs(vq, sgs, out_sg, in_sg, skb, GFP_KERNEL);
+	/* Usually this means that there is no more space available in
+	 * the vq
+	 */
+	if (ret < 0)
+		return ret;
+
+	virtio_transport_deliver_tap_pkt(skb);
+
+	if (reply) {
+		struct virtqueue *rx_vq = vsock->vqs[VSOCK_VQ_RX];
+		int val;
+
+		val = atomic_dec_return(&vsock->queued_replies);
+
+		/* Do we now have resources to resume rx processing? */
+		if (val + 1 == virtqueue_get_vring_size(rx_vq))
+			*restart_rx = true;
+	}
+
+	return 0;
+}
+
 static void
 virtio_transport_send_pkt_work(struct work_struct *work)
 {
@@ -111,77 +182,19 @@ virtio_transport_send_pkt_work(struct work_struct *work)
 	vq = vsock->vqs[VSOCK_VQ_TX];
 
 	for (;;) {
-		int ret, in_sg = 0, out_sg = 0;
-		struct scatterlist **sgs;
 		struct sk_buff *skb;
-		bool reply;
+		int ret;
 
 		skb = virtio_vsock_skb_dequeue(&vsock->send_pkt_queue);
 		if (!skb)
 			break;
 
-		reply = virtio_vsock_skb_reply(skb);
-		sgs = vsock->out_sgs;
-		sg_init_one(sgs[out_sg], virtio_vsock_hdr(skb),
-			    sizeof(*virtio_vsock_hdr(skb)));
-		out_sg++;
-
-		if (!skb_is_nonlinear(skb)) {
-			if (skb->len > 0) {
-				sg_init_one(sgs[out_sg], skb->data, skb->len);
-				out_sg++;
-			}
-		} else {
-			struct skb_shared_info *si;
-			int i;
-
-			/* If skb is nonlinear, then its buffer must contain
-			 * only header and nothing more. Data is stored in
-			 * the fragged part.
-			 */
-			WARN_ON_ONCE(skb_headroom(skb) != sizeof(*virtio_vsock_hdr(skb)));
-
-			si = skb_shinfo(skb);
-
-			for (i = 0; i < si->nr_frags; i++) {
-				skb_frag_t *skb_frag = &si->frags[i];
-				void *va;
-
-				/* We will use 'page_to_virt()' for the userspace page
-				 * here, because virtio or dma-mapping layers will call
-				 * 'virt_to_phys()' later to fill the buffer descriptor.
-				 * We don't touch memory at "virtual" address of this page.
-				 */
-				va = page_to_virt(skb_frag_page(skb_frag));
-				sg_init_one(sgs[out_sg],
-					    va + skb_frag_off(skb_frag),
-					    skb_frag_size(skb_frag));
-				out_sg++;
-			}
-		}
-
-		ret = virtqueue_add_sgs(vq, sgs, out_sg, in_sg, skb, GFP_KERNEL);
-		/* Usually this means that there is no more space available in
-		 * the vq
-		 */
+		ret = virtio_transport_send_skb(skb, vq, vsock, &restart_rx);
 		if (ret < 0) {
 			virtio_vsock_skb_queue_head(&vsock->send_pkt_queue, skb);
 			break;
 		}
 
-		virtio_transport_deliver_tap_pkt(skb);
-
-		if (reply) {
-			struct virtqueue *rx_vq = vsock->vqs[VSOCK_VQ_RX];
-			int val;
-
-			val = atomic_dec_return(&vsock->queued_replies);
-
-			/* Do we now have resources to resume rx processing? */
-			if (val + 1 == virtqueue_get_vring_size(rx_vq))
-				restart_rx = true;
-		}
-
 		added = true;
 	}
 

-- 
2.45.2

