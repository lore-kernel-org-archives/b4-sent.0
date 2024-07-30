From: Luigi Leonardi <luigi.leonardi@outlook.com>
Date: Tue, 30 Jul 2024 21:47:31 +0200
Subject: [PATCH net-next v4 1/2] vsock/virtio: refactor
 virtio_transport_send_pkt_work
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240730-pinna-v4-1-5c9179164db5@outlook.com>
References: <20240730-pinna-v4-0-5c9179164db5@outlook.com>
In-Reply-To: <20240730-pinna-v4-0-5c9179164db5@outlook.com>
To: Stefan Hajnoczi <stefanha@redhat.com>, 
 Stefano Garzarella <sgarzare@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: kvm@vger.kernel.org, virtualization@lists.linux.dev, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Marco Pinna <marco.pinn95@gmail.com>, 
 Luigi Leonardi <luigi.leonardi@outlook.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722368854; l=4578;
 i=luigi.leonardi@outlook.com; s=20240730; h=from:subject:message-id;
 bh=dteu3Blw+MRiUGi1vBnZUYUosVBG21vCipOvGurj8rI=;
 b=NrQLEA9QfsrS7CfLZiI3Tulfrj9WRZ264Ln3z/5IiWBVKx0eKme1sRPS7A0bZ9S9GI0RqbNVE
 baotP8yymUOBh+JMLMRpcOzzPbvJ/ZclPXeK2Y/XdIkyRRNy7Riwz7h
X-Developer-Key: i=luigi.leonardi@outlook.com; a=ed25519;
 pk=rejHGgcyJQFeByIJsRIz/gA6pOPZJ1I2fpxoFD/jris=
X-Endpoint-Received: by B4 Relay for luigi.leonardi@outlook.com/20240730 with auth_id=192
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
Reviewed-by: Stefano Garzarella <sgarzare@redhat.com>
---
 net/vmw_vsock/virtio_transport.c | 105 ++++++++++++++++++++++-----------------
 1 file changed, 59 insertions(+), 46 deletions(-)

diff --git a/net/vmw_vsock/virtio_transport.c b/net/vmw_vsock/virtio_transport.c
index 64a07acfef12..f641e906f351 100644
--- a/net/vmw_vsock/virtio_transport.c
+++ b/net/vmw_vsock/virtio_transport.c
@@ -94,6 +94,63 @@ static u32 virtio_transport_get_local_cid(void)
 	return ret;
 }
 
+/* Caller need to hold vsock->tx_lock on vq */
+static int virtio_transport_send_skb(struct sk_buff *skb, struct virtqueue *vq,
+				     struct virtio_vsock *vsock)
+{
+	int ret, in_sg = 0, out_sg = 0;
+	struct scatterlist **sgs;
+
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
+	return 0;
+}
+
 static void
 virtio_transport_send_pkt_work(struct work_struct *work)
 {
@@ -111,66 +168,22 @@ virtio_transport_send_pkt_work(struct work_struct *work)
 	vq = vsock->vqs[VSOCK_VQ_TX];
 
 	for (;;) {
-		int ret, in_sg = 0, out_sg = 0;
-		struct scatterlist **sgs;
 		struct sk_buff *skb;
 		bool reply;
+		int ret;
 
 		skb = virtio_vsock_skb_dequeue(&vsock->send_pkt_queue);
 		if (!skb)
 			break;
 
 		reply = virtio_vsock_skb_reply(skb);
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
+		ret = virtio_transport_send_skb(skb, vq, vsock);
 		if (ret < 0) {
 			virtio_vsock_skb_queue_head(&vsock->send_pkt_queue, skb);
 			break;
 		}
 
-		virtio_transport_deliver_tap_pkt(skb);
-
 		if (reply) {
 			struct virtqueue *rx_vq = vsock->vqs[VSOCK_VQ_RX];
 			int val;

-- 
2.45.2

