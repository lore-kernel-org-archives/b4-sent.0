From: Luigi Leonardi <luigi.leonardi@outlook.com>
Subject: [PATCH net-next v2 0/2] vsock: avoid queuing on workqueue if
 possible
Date: Mon, 01 Jul 2024 16:28:01 +0200
Message-Id: <20240701-pinna-v2-0-ac396d181f59@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPG8gmYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDIxMDcwND3YLMvLxEXTNDw1SLJLPklJREAyWg2oKi1LTMCrA50UoBjiHOHgp
 5qSW6eakVJUqxtbUAcKrvi2cAAAA=
To: Stefan Hajnoczi <stefanha@redhat.com>, 
 Stefano Garzarella <sgarzare@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: kvm@vger.kernel.org, virtualization@lists.linux.dev, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Luigi Leonardi <luigi.leonardi@outlook.com>, 
 Marco Pinna <marco.pinn95@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719844084; l=1421;
 i=luigi.leonardi@outlook.com; s=20240626; h=from:subject:message-id;
 bh=U2qxBsfXII2keV16dyH70ENv6wOvqN2WYE0+zRxOMF0=;
 b=esDzwhcl7yJuEVfUWxslORjydGrepc2F2GuDVExEB8Nakxvmi/MOSRBrVWHlWsGJIu8pPkZ/n
 w4JKJyQ4CbFApgzN4ddfo9bd/Qa4DXkDUPY6EnpQUF4z6hZ1mm30WMt
X-Developer-Key: i=luigi.leonardi@outlook.com; a=ed25519;
 pk=RYXD8JyCxGnx/izNc/6b3g3pgpohJMAI0LJ7ynxXzi8=
X-Endpoint-Received: by B4 Relay for luigi.leonardi@outlook.com/20240626 with auth_id=177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series introduces an optimization for vsock/virtio to reduce latency:
When the guest sends a packet to the host, and the workqueue is empty,
if there is enough space, the packet is put directly in the virtqueue.

In this v2 I replaced a mutex_lock with a mutex_trylock because it was inside
a RCU critical section. I also added a check on tx_run, so if the
module is being removed the packet is not queued. I'd like to thank Stefano
for reporting the tx_run issue.

v1->v2
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

Signed-off-by: Luigi Leonardi <luigi.leonardi@outlook.com>
---
Marco Pinna (2):
      vsock/virtio: refactor virtio_transport_send_pkt_work
      vsock/virtio: avoid enqueue packets when work queue is empty

 net/vmw_vsock/virtio_transport.c | 171 +++++++++++++++++++++++++--------------
 1 file changed, 109 insertions(+), 62 deletions(-)
---
base-commit: 2e7b471121b09e7fa8ffb437bfa0e59d13f96053
change-id: 20240701-pinna-611e8b6cdda0

Best regards,
-- 
Luigi Leonardi <luigi.leonardi@outlook.com>

