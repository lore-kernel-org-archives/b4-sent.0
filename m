From: Jerome Mohm <jrmmhm.kernel@eldare.de>
Date: Tue, 29 Sep 2026 18:33:04 +0200
Subject: [PATCH net] vsock/bpf: release sock lock while waiting for data in
 recvmsg
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260929-kbh3-1-022-fix-v1-1-cc97cc95d269@eldare.de>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQrCMBAFf6W8swubjVjqr4iHtN3YVYiStCKU/
 nujHmdgZkXRbFpwblZkfVuxZ6rgDg2GKaSbko2VISwn7qSjRz95csQiFO1D/sgh+NhGbh1q9Mp
 a9W94QdIZ178sS3/XYf6usG07HflYVHcAAAA=
X-Change-ID: 20260929-kbh3-1-022-fix-340aa3f7f071
To: Stefano Garzarella <sgarzare@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, 
 Bobby Eshleman <bobby.eshleman@bytedance.com>, 
 "Michael S. Tsirkin" <mst@redhat.com>
Cc: virtualization@lists.linux.dev, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, bpf@vger.kernel.org, stable@vger.kernel.org, 
 Jerome Mohm <jrmmhm.kernel@eldare.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790699585; l=2593;
 i=jrmmhm.kernel@eldare.de; s=20260928; h=from:subject:message-id;
 bh=4IPBHLtgo8ghTbbKAwJ8yZ9NmPZQTYBQyUYCEEc51UE=;
 b=a5k/85Mme7ztf5MTcaik5O/66KyvJ3vqg/NckJwjUvqqNN5AX0f09Nk7mbJKtmd2bED+s22s3
 o2QNttsa+atCbSNoqOIKaMTU4xeuiPQ5/JHuHN5r0C3z65nhuT8jNyQ
X-Developer-Key: i=jrmmhm.kernel@eldare.de; a=ed25519;
 pk=xRCxNXbnNottaHpmvPDAOC9NuMJxqKo24abkehKRVlo=
X-Endpoint-Received: by B4 Relay for jrmmhm.kernel@eldare.de/20260928 with auth_id=1075
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vsock_bpf_recvmsg() takes lock_sock(sk) and holds it across the whole
receive loop, including vsock_msg_wait_data(), which sleeps in
wait_woken() without dropping the lock. When data arrives, the
transport's delivery context (the vsock-loopback worker, or the
virtio/vhost rx path) calls virtio_transport_recv_pkt() -> lock_sock()
on the same socket and blocks. That context is the only one that would
queue the skb and call sk_data_ready() to wake the reader, so neither
side makes progress. A blocking recv() hangs until a signal arrives (a
finite SO_RCVTIMEO also breaks it); while it lasts the shared delivery
worker is stalled, so all vsock rx on that transport stops, not only
the affected socket. The hung-task watchdog reports the worker blocked
in D state:

  INFO: task kworker/1:3:107 blocked for more than 5 seconds.
  task:kworker/1:3 state:D Workqueue: vsock-loopback vsock_loopback_work
  Call Trace:
   __schedule
   schedule
   __lock_sock
   lock_sock_nested
   virtio_transport_recv_pkt
   vsock_loopback_work

The reader holds the same sk_lock-AF_VSOCK it is waiting on, taken in
vsock_bpf_recvmsg().

This code is based on net/unix/unix_bpf.c, whose unix_msg_wait_data()
drops u->iolock around wait_woken() and re-takes it afterwards. The
vsock port substituted lock_sock() for that serialisation lock but
omitted the unlock and relock. tcp_bpf and the native
vsock_connectible_wait_data() both drop the lock across the wait;
vsock_bpf is the only one that does not.

Release the socket lock around the wait and re-acquire it before
re-checking for data, so the caller's locking is unchanged.

Fixes: 634f1a7110b4 ("vsock: support sockmap")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Jerome Mohm <jrmmhm.kernel@eldare.de>
---
 net/vmw_vsock/vsock_bpf.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/net/vmw_vsock/vsock_bpf.c b/net/vmw_vsock/vsock_bpf.c
index 9049d2648646..bb7d81a95baa 100644
--- a/net/vmw_vsock/vsock_bpf.c
+++ b/net/vmw_vsock/vsock_bpf.c
@@ -50,7 +50,9 @@ static bool vsock_msg_wait_data(struct sock *sk, struct sk_psock *psock, long ti
 	sk_set_bit(SOCKWQ_ASYNC_WAITDATA, sk);
 	ret = vsock_has_data(sk, psock);
 	if (!ret) {
+		release_sock(sk);
 		wait_woken(&wait, TASK_INTERRUPTIBLE, timeo);
+		lock_sock(sk);
 		ret = vsock_has_data(sk, psock);
 	}
 	sk_clear_bit(SOCKWQ_ASYNC_WAITDATA, sk);

---
base-commit: 72d3fcf802c45d00b300f25b848a93c3a2bd7c7e
change-id: 20260929-kbh3-1-022-fix-340aa3f7f071

Best regards,
--  
Jerome Mohm <jrmmhm.kernel@eldare.de>

