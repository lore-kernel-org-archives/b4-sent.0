From: Luigi Leonardi <luigi.leonardi@outlook.com>
Date: Thu, 11 Jul 2024 16:58:47 +0200
Subject: [PATCH net-next v3 2/2] vsock/virtio: avoid queuing packets when
 work queue is empty
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240711-pinna-v3-2-697d4164fe80@outlook.com>
References: <20240711-pinna-v3-0-697d4164fe80@outlook.com>
In-Reply-To: <20240711-pinna-v3-0-697d4164fe80@outlook.com>
To: Stefan Hajnoczi <stefanha@redhat.com>, 
 Stefano Garzarella <sgarzare@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: kvm@vger.kernel.org, virtualization@lists.linux.dev, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Luigi Leonardi <luigi.leonardi@outlook.com>, 
 Marco Pinna <marco.pinn95@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720709936; l=3561;
 i=luigi.leonardi@outlook.com; s=20240626; h=from:subject:message-id;
 bh=l638VLzyzZ3I1aI8lPsDMG/usnFXIqhwGjTbGe9Tv7I=;
 b=DR4Cm+5TRSB/dUyBv/HfqjrwXGSLbFkVIM5oXx/s8ziijZhYilonRc84awoQ+U23YVu9pQHPf
 Un0RHiSrG5+B3/ldGuqDzy1+BxdPcB9LRw442gLcooE8+RNs10fdufs
X-Developer-Key: i=luigi.leonardi@outlook.com; a=ed25519;
 pk=RYXD8JyCxGnx/izNc/6b3g3pgpohJMAI0LJ7ynxXzi8=
X-Endpoint-Received: by B4 Relay for luigi.leonardi@outlook.com/20240626 with auth_id=177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce an optimization in virtio_transport_send_pkt:
when the work queue (send_pkt_queue) is empty the packet is
put directly in the virtqueue increasing the throughput.

In the following benchmark (pingpong mode) the host sends
a payload to the guest and waits for the same payload back.

All vCPUs pinned individually to pCPUs.
vhost process pinned to a pCPU
fio process pinned both inside the host and the guest system.

Host CPU: Intel i7-10700KF CPU @ 3.80GHz
Tool: Fio version 3.37-56
Env: Phys host + L1 Guest
Runtime-per-test: 50s
Mode: pingpong (h-g-h)
Test runs: 50
Type: SOCK_STREAM

Before: Linux 6.9.7

Payload 512B:

	1st perc.	overall		99th perc.
Before	370		810.15		8656		ns
After	374		780.29		8741		ns

Payload 4K:

	1st perc.	overall		99th perc.
Before	460		1720.23		42752		ns
After	460		1520.84		36096		ns

The performance improvement is related to this optimization,
I used ebpf to check that each packet was sent directly to the
virtqueue.

Throughput: iperf-vsock
The size represents the buffer length (-l) to read/write
P represents the number parallel streams

P=1
	4K	64K	128K
Before	6.87	29.3	29.5 Gb/s
After	10.5	39.4	39.9 Gb/s

P=2
	4K	64K	128K
Before	10.5	32.8	33.2 Gb/s
After	17.8	47.7	48.5 Gb/s

P=4
	4K	64K	128K
Before	12.7	33.6	34.2 Gb/s
After	16.9	48.1	50.5 Gb/s

Co-developed-by: Marco Pinna <marco.pinn95@gmail.com>
Signed-off-by: Marco Pinna <marco.pinn95@gmail.com>
Signed-off-by: Luigi Leonardi <luigi.leonardi@outlook.com>
---
 net/vmw_vsock/virtio_transport.c | 38 ++++++++++++++++++++++++++++++++++----
 1 file changed, 34 insertions(+), 4 deletions(-)

diff --git a/net/vmw_vsock/virtio_transport.c b/net/vmw_vsock/virtio_transport.c
index c4205c22f40b..d75727fdc35f 100644
--- a/net/vmw_vsock/virtio_transport.c
+++ b/net/vmw_vsock/virtio_transport.c
@@ -208,6 +208,29 @@ virtio_transport_send_pkt_work(struct work_struct *work)
 		queue_work(virtio_vsock_workqueue, &vsock->rx_work);
 }
 
+/* Caller need to hold RCU for vsock.
+ * Returns 0 if the packet is successfully put on the vq.
+ */
+static int virtio_transport_send_skb_fast_path(struct virtio_vsock *vsock, struct sk_buff *skb)
+{
+	struct virtqueue *vq = vsock->vqs[VSOCK_VQ_TX];
+	int ret;
+
+	/* Inside RCU, can't sleep! */
+	ret = mutex_trylock(&vsock->tx_lock);
+	if (unlikely(ret == 0))
+		return -EBUSY;
+
+	ret = virtio_transport_send_skb(skb, vq, vsock);
+
+	mutex_unlock(&vsock->tx_lock);
+
+	/* Kick if virtio_transport_send_skb succeeded */
+	if (ret == 0)
+		virtqueue_kick(vq);
+	return ret;
+}
+
 static int
 virtio_transport_send_pkt(struct sk_buff *skb)
 {
@@ -231,11 +254,18 @@ virtio_transport_send_pkt(struct sk_buff *skb)
 		goto out_rcu;
 	}
 
-	if (virtio_vsock_skb_reply(skb))
-		atomic_inc(&vsock->queued_replies);
+	/* If the workqueue (send_pkt_queue) is empty there is no need to enqueue the packet.
+	 * Just put it on the virtqueue using virtio_transport_send_skb_fast_path.
+	 */
 
-	virtio_vsock_skb_queue_tail(&vsock->send_pkt_queue, skb);
-	queue_work(virtio_vsock_workqueue, &vsock->send_pkt_work);
+	if (!skb_queue_empty_lockless(&vsock->send_pkt_queue) ||
+	    virtio_transport_send_skb_fast_path(vsock, skb)) {
+		/* Packet must be queued */
+		if (virtio_vsock_skb_reply(skb))
+			atomic_inc(&vsock->queued_replies);
+		virtio_vsock_skb_queue_tail(&vsock->send_pkt_queue, skb);
+		queue_work(virtio_vsock_workqueue, &vsock->send_pkt_work);
+	}
 
 out_rcu:
 	rcu_read_unlock();

-- 
2.45.2

