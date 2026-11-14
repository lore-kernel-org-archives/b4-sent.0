From: Jerome Mohm <jrmmhm.kernel@eldare.de>
Date: Sat, 14 Nov 2026 12:59:15 +0100
Subject: [PATCH net v6 2/2] vsock/bpf: release sock lock while waiting for
 data in recvmsg
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-kbh3-1-022-fix-v2-v6-2-96b6029bbffa@eldare.de>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794657554; l=3876;
 i=jrmmhm.kernel@eldare.de; s=20260928; h=from:subject:message-id;
 bh=zKh/7Uqq17NlML/ztrwLxN7imFwo8STVIyMfCtn51P8=;
 b=ya6GopZ4hDKAtGvWAMvwpNAuKWBCDvuUjdlTBahAowEPw+GDQ4SNI7hi5ip0JOfTj+YGAEHBB
 8XJKYvXDWTtCn8mshSPblXKB0KPNxhgoBNRErigRPAZyJGhQWySzUWc
X-Developer-Key: i=jrmmhm.kernel@eldare.de; a=ed25519;
 pk=xRCxNXbnNottaHpmvPDAOC9NuMJxqKo24abkehKRVlo=
X-Endpoint-Received: by B4 Relay for jrmmhm.kernel@eldare.de/20260928 with auth_id=1075
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vsock_bpf_recvmsg() sleeps in vsock_msg_wait_data() with the socket lock
held, so the virtio delivery worker, which needs that lock, deadlocks
with the reader and all vsock rx on that worker stops.

Release the lock around the wait. The reader can then wake without
data, so the wait also has to loop; the fix needs both halves. The loop
ends on data, the timeout, a signal (the sleep returns at once while
one is pending), a lost transport after a failed connect(), or a state
in which __vsock_recvmsg() would not wait. Those states go to
__vsock_recvmsg(), so a non-blocking read now sees them before -EAGAIN.
A blocking read interrupted by a signal now gets -EINTR, or restarts,
instead of -EAGAIN. One tested difference remains: a reader asleep at a
virtio transport reset gets -ENOTCONN, where a native socket gets
-ECONNRESET (0 on seqpacket).

The deadlock was found with the help of Anthropic's Claude; the netdev
Sashiko reviews and Alexei found the wakeup, reset, shutdown and
lost-transport cases. Each was reproduced in a VM without kernel
changes or error injection (the resets unbind the guest's virtio-vsock
device), except the lost transport and a SHUT_RD with a pending socket
error, which were checked only in the code. With this patch the
reproduced cases behave as on a native socket, apart from the reset. I
ran the vsock vmtest.sh single-VM tests and the BPF sockmap selftests
with the series; they pass, though none of them sleeps in this wait.

Fixes: 634f1a7110b4 ("vsock: support sockmap")
Suggested-by: Alexei Starovoitov <alexei.starovoitov@gmail.com>
Cc: stable@vger.kernel.org
Signed-off-by: Jerome Mohm <jrmmhm.kernel@eldare.de>
---
 net/vmw_vsock/vsock_bpf.c | 42 +++++++++++++++++++++++++++---------------
 1 file changed, 27 insertions(+), 15 deletions(-)

diff --git a/net/vmw_vsock/vsock_bpf.c b/net/vmw_vsock/vsock_bpf.c
index c9b399f37720..41307759da99 100644
--- a/net/vmw_vsock/vsock_bpf.c
+++ b/net/vmw_vsock/vsock_bpf.c
@@ -34,24 +34,37 @@ static bool vsock_has_data(struct sock *sk, struct sk_psock *psock)
 	return vsock_sk_has_data(sk, psock);
 }
 
-static bool vsock_msg_wait_data(struct sock *sk, struct sk_psock *psock, long timeo)
+/* __vsock_recvmsg() doesn't wait in these states. */
+static bool vsock_rx_done(struct sock *sk)
 {
-	bool ret;
+	return sk->sk_err || sk->sk_state != TCP_ESTABLISHED ||
+	       (sk->sk_shutdown & RCV_SHUTDOWN) ||
+	       (vsock_sk(sk)->peer_shutdown & SEND_SHUTDOWN);
+}
+
+static int vsock_msg_wait_data(struct sock *sk, struct sk_psock *psock,
+			       long timeo)
+{
+	struct vsock_sock *vsk = vsock_sk(sk);
+	int ret = 0;
 
 	DEFINE_WAIT_FUNC(wait, woken_wake_function);
 
-	if (sk->sk_shutdown & RCV_SHUTDOWN)
-		return true;
-
-	if (!timeo)
-		return false;
-
 	add_wait_queue(sk_sleep(sk), &wait);
 	sk_set_bit(SOCKWQ_ASYNC_WAITDATA, sk);
-	ret = vsock_has_data(sk, psock);
-	if (!ret) {
-		wait_woken(&wait, TASK_INTERRUPTIBLE, timeo);
-		ret = vsock_has_data(sk, psock);
+	while (vsk->transport && !vsock_has_data(sk, psock) &&
+	       !vsock_rx_done(sk)) {
+		if (!timeo) {
+			ret = -EAGAIN;
+			break;
+		}
+		if (signal_pending(current)) {
+			ret = sock_intr_errno(timeo);
+			break;
+		}
+		release_sock(sk);
+		timeo = wait_woken(&wait, TASK_INTERRUPTIBLE, timeo);
+		lock_sock(sk);
 	}
 	sk_clear_bit(SOCKWQ_ASYNC_WAITDATA, sk);
 	remove_wait_queue(sk_sleep(sk), &wait);
@@ -105,10 +118,9 @@ static int vsock_bpf_recvmsg(struct sock *sk, struct msghdr *msg,
 	while (copied == 0) {
 		long timeo = sock_rcvtimeo(sk, flags & MSG_DONTWAIT);
 
-		if (!vsock_msg_wait_data(sk, psock, timeo)) {
-			copied = -EAGAIN;
+		copied = vsock_msg_wait_data(sk, psock, timeo);
+		if (copied)
 			break;
-		}
 
 		if (sk_psock_queue_empty(psock)) {
 			release_sock(sk);

-- 
2.56.0

