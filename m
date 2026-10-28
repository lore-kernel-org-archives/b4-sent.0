From: Jerome Mohm <jrmmhm.kernel@eldare.de>
Date: Wed, 28 Oct 2026 18:55:41 +0100
Subject: [PATCH net v3 2/2] vsock/bpf: fix zero-length, MSG_OOB and
 MSG_ERRQUEUE reads in recvmsg
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-kbh3-1-022-fix-v2-v3-2-bc0752b2d3db@eldare.de>
References: <20261028-kbh3-1-022-fix-v2-v3-0-bc0752b2d3db@eldare.de>
In-Reply-To: <20261028-kbh3-1-022-fix-v2-v3-0-bc0752b2d3db@eldare.de>
To: Stefano Garzarella <sgarzare@redhat.com>, 
 Bobby Eshleman <bobbyeshleman@meta.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, "Michael S. Tsirkin" <mst@redhat.com>
Cc: Michal Luczaj <mhal@rbox.co>, virtualization@lists.linux.dev, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, bpf@vger.kernel.org, 
 stable@vger.kernel.org, Jerome Mohm <jrmmhm.kernel@eldare.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793210158; l=3879;
 i=jrmmhm.kernel@eldare.de; s=20260928; h=from:subject:message-id;
 bh=Fv6wIyCvdPA88rsjL1PDN9TTHIaiEj+Jl/xpP9BfqoA=;
 b=vmSFC1mMOaV9MgLgItP9fekE1g5KX6bCdGA9DejGXaGzh/80o4zkGJivxjZZg76MZW4/2Kvhn
 Q+3bo60dXw8CHTUDk2ilW9hV1oPL9CmHR01g8x4AnIN03M/z+DgxcQ/
X-Developer-Key: i=jrmmhm.kernel@eldare.de; a=ed25519;
 pk=xRCxNXbnNottaHpmvPDAOC9NuMJxqKo24abkehKRVlo=
X-Endpoint-Received: by B4 Relay for jrmmhm.kernel@eldare.de/20260928 with auth_id=1075
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vsock_bpf_recvmsg() sends every read that cannot be served from the
transport's own queue through sk_msg_recvmsg() and its wait loop. Three
kinds of read do not fit that path:

 - len == 0: with data queued in the psock ingress queue (for example
   after an SK_PASS verdict), sk_msg_recvmsg() copies nothing and
   returns 0, and the wait reports data ready at once, so the loop spins
   with lock_sock() held. The vsock delivery worker then blocks on the
   same lock and all rx on the transport stops (hung-task).
   tcp_bpf, udp_bpf and unix_bpf return 0 early, and
   __vsock_connectible_recvmsg() handles len == 0 too.

 - MSG_ERRQUEUE: the read only reaches sock_recv_errqueue() when the
   native fallback happens to be taken. With empty queues a blocking
   recvmsg(MSG_ERRQUEUE) waits for stream data instead of returning
   -EAGAIN for an empty error queue. Route it to the native path first,
   as tcp_bpf does, so it is also not caught by the len == 0 check.

 - MSG_OOB: vsock has no out-of-band data and the native path returns
   -EOPNOTSUPP, but sk_msg_recvmsg() ignores the flag and consumes
   ordinary stream bytes; with empty queues the read waits for data.
   Reject it right after the MSG_ERRQUEUE route and, as
   unix_bpf_recvmsg() does, before the len == 0 check.

The len == 0 and MSG_OOB cases were reported by the netdev Sashiko AI
review of earlier, single-patch versions of this fix; the MSG_ERRQUEUE
case was found with the help of an LLM coding assistant (Anthropic's
Claude). Each reproducer is a C program run as root in the guest: it
adds one end of a vsock-loopback stream connection to a BPF sockmap
(CAP_BPF and CAP_NET_ADMIN), for the queued-byte cases with an SK_PASS
stream-verdict program, and issues the reads below. No kernel change or
error injection is needed. The reproducers are available on request.

Testing: on a private VM with a KASAN + lockdep kernel on net, with
reproducers over vsock-loopback. Before this patch: recv(fd, buf, 0, 0)
with a byte in the psock ingress queue spins and the delivery worker
hangs (hung-task); a zero-length recvmsg(MSG_ERRQUEUE) blocks; and
recv() with MSG_OOB waits for data or returns a queued ordinary byte,
which a following plain recv() then misses. After: a zero-length recv()
returns 0 and the next recv() returns the byte; MSG_ERRQUEUE returns
-EAGAIN from the empty error queue; MSG_OOB returns -EOPNOTSUPP at once
and consumes nothing. With both patches of this series applied, the
three single-VM tests of tools/testing/selftests/vsock/vmtest.sh
(vm_server_host_client, vm_client_host_server, vm_loopback; 44
vsock_test cases each) pass, as on net; on both kernels the host-side
runs skip the SO_INQ cases (SO_INQ not supported by the host kernel).
The ns_* tests of vmtest.sh were not run (they need root on the host).
The BPF test_progs sockmap_basic, sockmap_listen and sockmap_redir tests
pass (767 of 767 subtests, among them the three vsock subtests of
sockmap_basic and the 240 AF_VSOCK cases of sockmap_redir).

Fixes: 634f1a7110b4 ("vsock: support sockmap")
Cc: stable@vger.kernel.org
Signed-off-by: Jerome Mohm <jrmmhm.kernel@eldare.de>
---
 net/vmw_vsock/vsock_bpf.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/net/vmw_vsock/vsock_bpf.c b/net/vmw_vsock/vsock_bpf.c
index 5120911b8143..3edc01268c42 100644
--- a/net/vmw_vsock/vsock_bpf.c
+++ b/net/vmw_vsock/vsock_bpf.c
@@ -111,6 +111,15 @@ static int vsock_bpf_recvmsg(struct sock *sk, struct msghdr *msg,
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

