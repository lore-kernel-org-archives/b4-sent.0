From: Luigi Leonardi <luigi.leonardi@outlook.com>
Subject: [PATCH net-next v4 0/2] vsock: avoid queuing on intermediate queue
 if possible
Date: Tue, 30 Jul 2024 21:47:30 +0200
Message-Id: <20240730-pinna-v4-0-5c9179164db5@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFNDqWYC/x3MQQqAIBBA0avIrBNMg6KrRAu1qWYziUoI4t2Tl
 g8+v0LCSJhgFRUivpTo4Y5pEOBvyxdKOrpBKz2p2SgZiNnKwy3ej25xyszQ2xDxpPJ/NmDMkrF
 k2Fv7AFfDA9NhAAAA
To: Stefan Hajnoczi <stefanha@redhat.com>, 
 Stefano Garzarella <sgarzare@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: kvm@vger.kernel.org, virtualization@lists.linux.dev, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Marco Pinna <marco.pinn95@gmail.com>, 
 Luigi Leonardi <luigi.leonardi@outlook.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722368854; l=2569;
 i=luigi.leonardi@outlook.com; s=20240730; h=from:subject:message-id;
 bh=IKREFN+TIgBJvxWjZQPVCllveoHa06J0Ilw0xt1IXRc=;
 b=JLjB6D8toKe+KFeGH5/NYUNYcRfuWf3KVdRaY3LMIcqogFwa98x6njOM9A/V7AHeLl+y5UqFP
 vaj/3m7yjV8Ctc+o5bhG7weCTO2dUzzEIb20h5xrDH8Ae+lJGJhrr80
X-Developer-Key: i=luigi.leonardi@outlook.com; a=ed25519;
 pk=rejHGgcyJQFeByIJsRIz/gA6pOPZJ1I2fpxoFD/jris=
X-Endpoint-Received: by B4 Relay for luigi.leonardi@outlook.com/20240730 with auth_id=192
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series introduces an optimization for vsock/virtio to reduce latency
and increase the throughput: When the guest sends a packet to the host,
and the intermediate queue (send_pkt_queue) is empty, if there is enough
space, the packet is put directly in the virtqueue.

v3->v4
While running experiments on fio with 64B payload, I realized that there
was a mistake in my fio configuration, so I re-ran all the experiments
and now the latency numbers are indeed lower with the patch applied.
I also noticed that I was kicking the host without the lock.

- Fixed a configuration mistake on fio and re-ran all experiments.
- Fio latency measurement using 64B payload.
- virtio_transport_send_skb_fast_path sends kick with the tx_lock acquired
- Addressed all minor style changes requested by maintainer.
- Rebased on latest net-next
- Link to v3: https://lore.kernel.org/r/20240711-pinna-v3-0-697d4164fe80@outlook.com

v2->v3
- Performed more experiments using iperf3 using multiple streams
- Handling of reply packets removed from virtio_transport_send_skb,
  as is needed just by the worker.
- Removed atomic_inc/atomic_sub when queuing directly to the vq.
- Introduced virtio_transport_send_skb_fast_path that handles the
  steps for sending on the vq.
- Fixed a missing mutex_unlock in error path.
- Changed authorship of the second commit
- Rebased on latest net-next

v1->v2
In this v2 I replaced a mutex_lock with a mutex_trylock because it was
insidea RCU critical section. I also added a check on tx_run, so if the
module is being removed the packet is not queued. I'd like to thank Stefano
for reporting the tx_run issue.

Applied all Stefano's suggestions:
    - Minor code style changes
    - Minor commit text rewrite
Performed more experiments:
     - Check if all the packets go directly to the vq (Matias' suggestion)
     - Used iperf3 to see if there is any improvement in overall throughput
      from guest to host
     - Pinned the vhost process to a pCPU.
     - Run fio using 512B payload
Rebased on latest net-next

---
Luigi Leonardi (1):
      vsock/virtio: avoid queuing packets when intermediate queue is empty

Marco Pinna (1):
      vsock/virtio: refactor virtio_transport_send_pkt_work

 net/vmw_vsock/virtio_transport.c | 144 +++++++++++++++++++++++++--------------
 1 file changed, 94 insertions(+), 50 deletions(-)
---
base-commit: 1722389b0d863056d78287a120a1d6cadb8d4f7b
change-id: 20240730-pinna-db8cc1b8b037

Best regards,
-- 
Luigi Leonardi <luigi.leonardi@outlook.com>

