From: Luigi Leonardi <luigi.leonardi@outlook.com>
Subject: [PATCH net-next v3 0/2] vsock: avoid queuing on workqueue if
 possible
Date: Thu, 11 Jul 2024 16:58:45 +0200
Message-Id: <20240711-pinna-v3-0-697d4164fe80@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACXzj2YC/x3MQQqAIBBA0avErBPGEsKuEi20xprNJBoRiHdPW
 j74/AKZElOGuSuQ6OHMlzSMfQfb6eQgxXszDDgYnLRWkUWcMtYHdB6tRQutjYkCv/9nAaFbCb0
 3rLV+RekMaGEAAAA=
To: Stefan Hajnoczi <stefanha@redhat.com>, 
 Stefano Garzarella <sgarzare@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: kvm@vger.kernel.org, virtualization@lists.linux.dev, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Luigi Leonardi <luigi.leonardi@outlook.com>, 
 Marco Pinna <marco.pinn95@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720709936; l=2312;
 i=luigi.leonardi@outlook.com; s=20240626; h=from:subject:message-id;
 bh=4GyMZnbR7RiPhK1S6uAJ8PduAHpuNhc35bIXtjWWqbQ=;
 b=OKe8ArgWw5s3u221y8cYuzl/lSRKwV/KLQr+zKG2+UoJkwwYco3/h7ze8TQ2g7Tou2mH9sYna
 ymMojPaSHiSBhA1oKQ0WLMtDg4CnXUz90W6JcWVVr7GBamNlm0wr8C3
X-Developer-Key: i=luigi.leonardi@outlook.com; a=ed25519;
 pk=RYXD8JyCxGnx/izNc/6b3g3pgpohJMAI0LJ7ynxXzi8=
X-Endpoint-Received: by B4 Relay for luigi.leonardi@outlook.com/20240626 with auth_id=177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series introduces an optimization for vsock/virtio to reduce latency
and increase the throughput: When the guest sends a packet to the host, 
and the workqueue is empty, if there is enough space, the packet is put
directly in the virtqueue.

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

To: Stefan Hajnoczi <stefanha@redhat.com>
To: Stefano Garzarella <sgarzare@redhat.com>
To: David S. Miller <davem@davemloft.net>
To: Eric Dumazet <edumazet@google.com>
To: Jakub Kicinski <kuba@kernel.org>
To: Paolo Abeni <pabeni@redhat.com>
Cc: kvm@vger.kernel.org
Cc: virtualization@lists.linux.dev
Cc: netdev@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

Signed-off-by: Luigi Leonardi <luigi.leonardi@outlook.com>
---
Luigi Leonardi (1):
      vsock/virtio: avoid queuing packets when work queue is empty

Marco Pinna (1):
      vsock/virtio: refactor virtio_transport_send_pkt_work

 net/vmw_vsock/virtio_transport.c | 143 +++++++++++++++++++++++++--------------
 1 file changed, 93 insertions(+), 50 deletions(-)
---
base-commit: 58f9416d413aa2c20b2515233ce450a1607ef843
change-id: 20240711-pinna-49bf0ab09909

Best regards,
-- 
Luigi Leonardi <luigi.leonardi@outlook.com>

