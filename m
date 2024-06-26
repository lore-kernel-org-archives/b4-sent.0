From: Luigi Leonardi <luigi.leonardi@outlook.com>
Date: Wed, 26 Jun 2024 14:08:36 +0200
Subject: [PATCH net-next v3 2/3] vsock/virtio: add SIOCOUTQ support for all
 virtio based transports
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240626-ioctl_next-v3-2-63be5bf19a40@outlook.com>
References: <20240626-ioctl_next-v3-0-63be5bf19a40@outlook.com>
In-Reply-To: <20240626-ioctl_next-v3-0-63be5bf19a40@outlook.com>
To: Stefano Garzarella <sgarzare@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Stefan Hajnoczi <stefanha@redhat.com>, 
 "Michael S. Tsirkin" <mst@redhat.com>, Jason Wang <jasowang@redhat.com>, 
 =?utf-8?q?Eugenio_P=C3=A9rez?= <eperezma@redhat.com>, 
 Xuan Zhuo <xuanzhuo@linux.alibaba.com>
Cc: virtualization@lists.linux.dev, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kvm@vger.kernel.org, 
 Luigi Leonardi <luigi.leonardi@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719403717; l=6371;
 i=luigi.leonardi@outlook.com; s=20240626; h=from:subject:message-id;
 bh=sI4aKzv65G8Vd6esvUjfpOdcZxrW87hFO3L+yINHGpI=;
 b=MJgAWqdl5ujUmscMJMELnSlpGJy6V8fNgMjp8s4GaxTHDXY+3yYOEW3ILFijsBEwDC2rigKza
 DbwuczPf0d/BzEWuW0Wz6oONwx/49gtUR6QmaXWW7aeLBI2GvApKe0g
X-Developer-Key: i=luigi.leonardi@outlook.com; a=ed25519;
 pk=RYXD8JyCxGnx/izNc/6b3g3pgpohJMAI0LJ7ynxXzi8=
X-Endpoint-Received: by B4 Relay for luigi.leonardi@outlook.com/20240626 with auth_id=177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce support for stream_bytes_unsent and seqpacket_bytes_unsent
ioctl for virtio_transport, vhost_vsock and vsock_loopback.

For all transports the unsent bytes counter is incremented
in virtio_transport_get_credit.

In the virtio_transport (G2H) the counter is decremented each
time the host notifies the guest that it consumed the skbuffs.
In vhost-vsock (H2G) the counter is decremented after the skbuff
is queued in the virtqueue.
In vsock_loopback the counter is decremented after the skbuff is
dequeued.

Signed-off-by: Luigi Leonardi <luigi.leonardi@outlook.com>
---
 drivers/vhost/vsock.c                   |  4 +++-
 include/linux/virtio_vsock.h            |  7 +++++++
 net/vmw_vsock/virtio_transport.c        |  4 +++-
 net/vmw_vsock/virtio_transport_common.c | 35 +++++++++++++++++++++++++++++++++
 net/vmw_vsock/vsock_loopback.c          |  7 +++++++
 5 files changed, 55 insertions(+), 2 deletions(-)

diff --git a/drivers/vhost/vsock.c b/drivers/vhost/vsock.c
index ec20ecff85c7..dba8b3ea37bf 100644
--- a/drivers/vhost/vsock.c
+++ b/drivers/vhost/vsock.c
@@ -244,7 +244,7 @@ vhost_transport_do_send_pkt(struct vhost_vsock *vsock,
 					restart_tx = true;
 			}
 
-			consume_skb(skb);
+			virtio_transport_consume_skb_sent(skb, true);
 		}
 	} while(likely(!vhost_exceeds_weight(vq, ++pkts, total_len)));
 	if (added)
@@ -451,6 +451,8 @@ static struct virtio_transport vhost_transport = {
 		.notify_buffer_size       = virtio_transport_notify_buffer_size,
 		.notify_set_rcvlowat      = virtio_transport_notify_set_rcvlowat,
 
+		.unsent_bytes             = virtio_transport_bytes_unsent,
+
 		.read_skb = virtio_transport_read_skb,
 	},
 
diff --git a/include/linux/virtio_vsock.h b/include/linux/virtio_vsock.h
index c82089dee0c8..e74c12878213 100644
--- a/include/linux/virtio_vsock.h
+++ b/include/linux/virtio_vsock.h
@@ -134,6 +134,8 @@ struct virtio_vsock_sock {
 	u32 peer_fwd_cnt;
 	u32 peer_buf_alloc;
 
+	size_t bytes_unsent;
+
 	/* Protected by rx_lock */
 	u32 fwd_cnt;
 	u32 last_fwd_cnt;
@@ -193,6 +195,11 @@ s64 virtio_transport_stream_has_data(struct vsock_sock *vsk);
 s64 virtio_transport_stream_has_space(struct vsock_sock *vsk);
 u32 virtio_transport_seqpacket_has_data(struct vsock_sock *vsk);
 
+size_t virtio_transport_bytes_unsent(struct vsock_sock *vsk);
+
+void virtio_transport_consume_skb_sent(struct sk_buff *skb,
+				       bool consume);
+
 int virtio_transport_do_socket_init(struct vsock_sock *vsk,
 				 struct vsock_sock *psk);
 int
diff --git a/net/vmw_vsock/virtio_transport.c b/net/vmw_vsock/virtio_transport.c
index 43d405298857..fc62d2818c2c 100644
--- a/net/vmw_vsock/virtio_transport.c
+++ b/net/vmw_vsock/virtio_transport.c
@@ -311,7 +311,7 @@ static void virtio_transport_tx_work(struct work_struct *work)
 
 		virtqueue_disable_cb(vq);
 		while ((skb = virtqueue_get_buf(vq, &len)) != NULL) {
-			consume_skb(skb);
+			virtio_transport_consume_skb_sent(skb, true);
 			added = true;
 		}
 	} while (!virtqueue_enable_cb(vq));
@@ -540,6 +540,8 @@ static struct virtio_transport virtio_transport = {
 		.notify_buffer_size       = virtio_transport_notify_buffer_size,
 		.notify_set_rcvlowat      = virtio_transport_notify_set_rcvlowat,
 
+		.unsent_bytes             = virtio_transport_bytes_unsent,
+
 		.read_skb = virtio_transport_read_skb,
 	},
 
diff --git a/net/vmw_vsock/virtio_transport_common.c b/net/vmw_vsock/virtio_transport_common.c
index 16ff976a86e3..3a7fa36f306b 100644
--- a/net/vmw_vsock/virtio_transport_common.c
+++ b/net/vmw_vsock/virtio_transport_common.c
@@ -463,6 +463,26 @@ void virtio_transport_inc_tx_pkt(struct virtio_vsock_sock *vvs, struct sk_buff *
 }
 EXPORT_SYMBOL_GPL(virtio_transport_inc_tx_pkt);
 
+void virtio_transport_consume_skb_sent(struct sk_buff *skb, bool consume)
+{
+	struct sock *s = skb->sk;
+
+	if (s && skb->len) {
+		struct vsock_sock *vs = vsock_sk(s);
+		struct virtio_vsock_sock *vvs;
+
+		vvs = vs->trans;
+
+		spin_lock_bh(&vvs->tx_lock);
+		vvs->bytes_unsent -= skb->len;
+		spin_unlock_bh(&vvs->tx_lock);
+	}
+
+	if (consume)
+		consume_skb(skb);
+}
+EXPORT_SYMBOL_GPL(virtio_transport_consume_skb_sent);
+
 u32 virtio_transport_get_credit(struct virtio_vsock_sock *vvs, u32 credit)
 {
 	u32 ret;
@@ -475,6 +495,7 @@ u32 virtio_transport_get_credit(struct virtio_vsock_sock *vvs, u32 credit)
 	if (ret > credit)
 		ret = credit;
 	vvs->tx_cnt += ret;
+	vvs->bytes_unsent += ret;
 	spin_unlock_bh(&vvs->tx_lock);
 
 	return ret;
@@ -488,6 +509,7 @@ void virtio_transport_put_credit(struct virtio_vsock_sock *vvs, u32 credit)
 
 	spin_lock_bh(&vvs->tx_lock);
 	vvs->tx_cnt -= credit;
+	vvs->bytes_unsent -= credit;
 	spin_unlock_bh(&vvs->tx_lock);
 }
 EXPORT_SYMBOL_GPL(virtio_transport_put_credit);
@@ -1090,6 +1112,19 @@ void virtio_transport_destruct(struct vsock_sock *vsk)
 }
 EXPORT_SYMBOL_GPL(virtio_transport_destruct);
 
+size_t virtio_transport_bytes_unsent(struct vsock_sock *vsk)
+{
+	struct virtio_vsock_sock *vvs = vsk->trans;
+	size_t ret;
+
+	spin_lock_bh(&vvs->tx_lock);
+	ret = vvs->bytes_unsent;
+	spin_unlock_bh(&vvs->tx_lock);
+
+	return ret;
+}
+EXPORT_SYMBOL_GPL(virtio_transport_bytes_unsent);
+
 static int virtio_transport_reset(struct vsock_sock *vsk,
 				  struct sk_buff *skb)
 {
diff --git a/net/vmw_vsock/vsock_loopback.c b/net/vmw_vsock/vsock_loopback.c
index 6dea6119f5b2..9098613561e3 100644
--- a/net/vmw_vsock/vsock_loopback.c
+++ b/net/vmw_vsock/vsock_loopback.c
@@ -98,6 +98,8 @@ static struct virtio_transport loopback_transport = {
 		.notify_buffer_size       = virtio_transport_notify_buffer_size,
 		.notify_set_rcvlowat      = virtio_transport_notify_set_rcvlowat,
 
+		.unsent_bytes             = virtio_transport_bytes_unsent,
+
 		.read_skb = virtio_transport_read_skb,
 	},
 
@@ -123,6 +125,11 @@ static void vsock_loopback_work(struct work_struct *work)
 	spin_unlock_bh(&vsock->pkt_queue.lock);
 
 	while ((skb = __skb_dequeue(&pkts))) {
+		/* Decrement the bytes_sent counter without deallocating skb
+		 * It is freed by the receiver.
+		 */
+		virtio_transport_consume_skb_sent(skb, false);
+
 		virtio_transport_deliver_tap_pkt(skb);
 		virtio_transport_recv_pkt(&loopback_transport, skb);
 	}

-- 
2.45.2

