From: Jerome Mohm <jrmmhm.kernel@eldare.de>
Date: Fri, 06 Nov 2026 22:57:22 +0100
Subject: [PATCH net v4 2/2] vsock/bpf: fix zero-length, MSG_OOB and
 MSG_ERRQUEUE reads in recvmsg
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-kbh3-1-022-fix-v2-v4-2-c7d36703814d@eldare.de>
References: <20261106-kbh3-1-022-fix-v2-v4-0-c7d36703814d@eldare.de>
In-Reply-To: <20261106-kbh3-1-022-fix-v2-v4-0-c7d36703814d@eldare.de>
To: Stefano Garzarella <sgarzare@redhat.com>, 
 Bobby Eshleman <bobbyeshleman@meta.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, "Michael S. Tsirkin" <mst@redhat.com>
Cc: Michal Luczaj <mhal@rbox.co>, virtualization@lists.linux.dev, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, bpf@vger.kernel.org, 
 stable@vger.kernel.org, Jerome Mohm <jrmmhm.kernel@eldare.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794002242; l=2197;
 i=jrmmhm.kernel@eldare.de; s=20260928; h=from:subject:message-id;
 bh=dwUGR/eCK7GtoK8H9bbKU0ilJyfRtgnQIrQ7vPni5kQ=;
 b=4nZ5slW3UfHVgJAEtqPZdz8lRe6LZIvhoXJrslECxOHSir4x5eu+lfl6KdZ04cTHPnrsnMHUi
 AqwPFJDB60RDKoWYhN1qCGgcwQVMb13vpu1lai55X4LjYu6QHfWu1sK
X-Developer-Key: i=jrmmhm.kernel@eldare.de; a=ed25519;
 pk=xRCxNXbnNottaHpmvPDAOC9NuMJxqKo24abkehKRVlo=
X-Endpoint-Received: by B4 Relay for jrmmhm.kernel@eldare.de/20260928 with auth_id=1075
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vsock_bpf_recvmsg() sends every read that the transport queue cannot
serve through sk_msg_recvmsg() and the sockmap wait, which handle
neither a zero length nor these flags:

 - with len == 0 and data in the psock ingress queue the loop spins with
   lock_sock() held, and the delivery worker blocks on the lock;
 - MSG_ERRQUEUE with data in the psock ingress queue consumes stream
   bytes, and a zero-length MSG_ERRQUEUE read, as MSG_ZEROCOPY users
   do, never reaches the error queue: it gets -EAGAIN, or waits for
   stream data if it blocks;
 - MSG_OOB consumes ordinary stream bytes or waits for data, where the
   native path returns -EOPNOTSUPP.

Handle them at the top of vsock_bpf_recvmsg(). The order matters:
MSG_ERRQUEUE goes to the native path first, as in tcp_bpf, or a
zero-length error-queue read would return 0; MSG_OOB comes before
len == 0, as in unix_bpf, so recv(fd, buf, 0, MSG_OOB) returns
-EOPNOTSUPP as on a connected native socket.

The MSG_ERRQUEUE case was found with the help of Anthropic's Claude, the
zero-length and MSG_OOB cases by the netdev Sashiko review. Each was
reproduced in a VM with a vsock-loopback socket in a sockmap, without
kernel changes or error injection. With the series applied the reads
behave as on a connected native socket, and the vsock vmtest.sh
single-VM tests and the BPF sockmap test_progs pass.

Fixes: 634f1a7110b4 ("vsock: support sockmap")
Cc: stable@vger.kernel.org
Signed-off-by: Jerome Mohm <jrmmhm.kernel@eldare.de>
---
 net/vmw_vsock/vsock_bpf.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/net/vmw_vsock/vsock_bpf.c b/net/vmw_vsock/vsock_bpf.c
index 6d96ff03f28c..58b32fbc1f4b 100644
--- a/net/vmw_vsock/vsock_bpf.c
+++ b/net/vmw_vsock/vsock_bpf.c
@@ -119,6 +119,15 @@ static int vsock_bpf_recvmsg(struct sock *sk, struct msghdr *msg,
 	struct vsock_sock *vsk;
 	int copied;
 
+	if (unlikely(flags & MSG_ERRQUEUE))
+		return __vsock_recvmsg(sk, msg, len, flags);
+
+	if (flags & MSG_OOB)
+		return -EOPNOTSUPP;
+
+	if (!len)
+		return 0;
+
 	psock = sk_psock_get(sk);
 	if (unlikely(!psock))
 		return __vsock_recvmsg(sk, msg, len, flags);

-- 
2.56.0

