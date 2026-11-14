From: Jerome Mohm <jrmmhm.kernel@eldare.de>
Date: Sat, 14 Nov 2026 12:59:14 +0100
Subject: [PATCH net v6 1/2] vsock/bpf: fix zero-length, MSG_OOB and
 MSG_ERRQUEUE reads
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-kbh3-1-022-fix-v2-v6-1-96b6029bbffa@eldare.de>
References: <20261114-kbh3-1-022-fix-v2-v6-0-96b6029bbffa@eldare.de>
In-Reply-To: <20261114-kbh3-1-022-fix-v2-v6-0-96b6029bbffa@eldare.de>
To: Stefano Garzarella <sgarzare@redhat.com>, 
 Bobby Eshleman <bobbyeshleman@meta.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, "Michael S. Tsirkin" <mst@redhat.com>, 
 Alexei Starovoitov <ast@kernel.org>
Cc: Michal Luczaj <mhal@rbox.co>, virtualization@lists.linux.dev, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, bpf@vger.kernel.org, 
 stable@vger.kernel.org, Jerome Mohm <jrmmhm.kernel@eldare.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794657554; l=2260;
 i=jrmmhm.kernel@eldare.de; s=20260928; h=from:subject:message-id;
 bh=HNk00rg3w34p5I+aJL5/O9foUQOvgErOJTc5nh/GqmQ=;
 b=swjcV4jiYBjHRD+LmXnkm4bBMz5vy4M5McoYob0jJlTaEfRXY+ad6xFFFFtcLe4OhoOT/wnJ0
 SohR0mWWn1DAy4oT/UEDBgfmmzhcdpCtcLvSj+7BIusfI3+jsD7ehrY
X-Developer-Key: i=jrmmhm.kernel@eldare.de; a=ed25519;
 pk=xRCxNXbnNottaHpmvPDAOC9NuMJxqKo24abkehKRVlo=
X-Endpoint-Received: by B4 Relay for jrmmhm.kernel@eldare.de/20260928 with auth_id=1075
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a vsock socket in a sockmap, vsock_bpf_recvmsg() sends zero-length,
MSG_OOB and MSG_ERRQUEUE reads down the sockmap path whenever the psock
queue has data or nothing is queued at all. That path copies from the
psock queue and waits for data, and it handles none of these reads:

 - a zero-length read with data in the psock queue spins with the
   socket lock held, and the delivery worker blocks on that lock;
 - MSG_ERRQUEUE consumes stream bytes from the psock queue, and the
   zero-length MSG_ERRQUEUE read that MSG_ZEROCOPY users make to collect
   completions gets -EAGAIN or blocks instead of reading the error
   queue;
 - MSG_OOB consumes ordinary stream bytes or waits for data, where a
   connected native socket returns -EOPNOTSUPP.

Hand these reads to __vsock_recvmsg(), the path of a socket outside a
sockmap, which does not wait for any of them. They now take one path,
so the order of the checks no longer matters.

The MSG_ERRQUEUE case was found with the help of Anthropic's Claude,
its stream-byte and MSG_ZEROCOPY parts by Stefano, and the zero-length
and MSG_OOB cases by the netdev Sashiko reviews. Each was reproduced in
a VM with a vsock-loopback socket in a sockmap, without kernel changes
or error injection. With this patch alone they behave as on a native
socket. The vsock vmtest.sh single-VM tests and the BPF sockmap
selftests pass with the series; I did not run them on this patch alone.

Fixes: 634f1a7110b4 ("vsock: support sockmap")
Suggested-by: Alexei Starovoitov <alexei.starovoitov@gmail.com>
Cc: stable@vger.kernel.org
Signed-off-by: Jerome Mohm <jrmmhm.kernel@eldare.de>
---
 net/vmw_vsock/vsock_bpf.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/net/vmw_vsock/vsock_bpf.c b/net/vmw_vsock/vsock_bpf.c
index 9049d2648646..c9b399f37720 100644
--- a/net/vmw_vsock/vsock_bpf.c
+++ b/net/vmw_vsock/vsock_bpf.c
@@ -80,6 +80,9 @@ static int vsock_bpf_recvmsg(struct sock *sk, struct msghdr *msg,
 	struct vsock_sock *vsk;
 	int copied;
 
+	if (unlikely(!len || (flags & (MSG_OOB | MSG_ERRQUEUE))))
+		return __vsock_recvmsg(sk, msg, len, flags);
+
 	psock = sk_psock_get(sk);
 	if (unlikely(!psock))
 		return __vsock_recvmsg(sk, msg, len, flags);

-- 
2.56.0

