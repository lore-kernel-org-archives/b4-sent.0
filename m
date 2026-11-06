From: Jerome Mohm <jrmmhm.kernel@eldare.de>
Date: Fri, 06 Nov 2026 22:57:21 +0100
Subject: [PATCH net v4 1/2] vsock/bpf: release sock lock while waiting for
 data in recvmsg
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-kbh3-1-022-fix-v2-v4-1-c7d36703814d@eldare.de>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794002242; l=4767;
 i=jrmmhm.kernel@eldare.de; s=20260928; h=from:subject:message-id;
 bh=tMncr/t2BZDCVu+DkSDka364ua2a05eGFszh7At9iJI=;
 b=AYg1/w4e3WXm2lKA1GWiOSiVmfBY81KRkcGtQraSUK/I77t97ELFZHMRkMqAmkZdyUrfpA9pF
 h8X5oc7IjtJDad5dcC3ygPR5QHkyl9yFm+Qqi4sswW66P7Mw3RnGoSq
X-Developer-Key: i=jrmmhm.kernel@eldare.de; a=ed25519;
 pk=xRCxNXbnNottaHpmvPDAOC9NuMJxqKo24abkehKRVlo=
X-Endpoint-Received: by B4 Relay for jrmmhm.kernel@eldare.de/20260928 with auth_id=1075
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vsock_bpf_recvmsg() holds lock_sock() while vsock_msg_wait_data() sleeps
in wait_woken(). The transport delivers data in
virtio_transport_recv_pkt(), which takes the same lock, so the reader
and the delivery worker deadlock: recv() hangs until a signal or
SO_RCVTIMEO, and all vsock rx handled by that worker stops.

Release the lock around wait_woken(), as unix_bpf and tcp_bpf release
theirs. That alone ends the deadlock but makes a blocking recv()
return -EAGAIN early: the reader is also woken without data, for
example by a credit update. So the wait also loops until data arrives
or one of the native exits applies: a socket error, a local or peer
shutdown, a socket that is no longer connected, the timeout or a
pending signal. The loop alone, with the lock still held, keeps the
deadlock, so the fix needs both halves and stays one patch.

For a non-blocking read, a socket error, a peer shutdown and a socket
that is not connected are now reported before -EAGAIN, as on the native
path. A blocking read interrupted by a signal returns sock_intr_errno()
instead of -EAGAIN. A recv() that starts after a virtio transport reset
returns -ECONNRESET until SO_ERROR has read the error, where the native
path returns -ENOTCONN.

The deadlock was found with the help of Anthropic's Claude; Sashiko
reviews of two earlier sockmap patches had already noted it as a
pre-existing issue. The other cases were reported by the netdev Sashiko
review. Each was reproduced in a VM with a vsock socket in a sockmap,
without kernel changes or error injection; the reset case unbinds the
guest's virtio-vsock device. With the series applied they behave as on
a native socket, except for the reset case above, and the vsock
vmtest.sh single-VM tests and the BPF sockmap test_progs pass.

Fixes: 634f1a7110b4 ("vsock: support sockmap")
Cc: stable@vger.kernel.org
Signed-off-by: Jerome Mohm <jrmmhm.kernel@eldare.de>
---
 net/vmw_vsock/vsock_bpf.c | 68 +++++++++++++++++++++++++++++++++++++----------
 1 file changed, 54 insertions(+), 14 deletions(-)

diff --git a/net/vmw_vsock/vsock_bpf.c b/net/vmw_vsock/vsock_bpf.c
index 9049d2648646..6d96ff03f28c 100644
--- a/net/vmw_vsock/vsock_bpf.c
+++ b/net/vmw_vsock/vsock_bpf.c
@@ -34,24 +34,63 @@ static bool vsock_has_data(struct sock *sk, struct sk_psock *psock)
 	return vsock_sk_has_data(sk, psock);
 }
 
-static bool vsock_msg_wait_data(struct sock *sk, struct sk_psock *psock, long timeo)
+/* Returns 1 if data is ready, 0 on EOF/shutdown, or a negative error. */
+static int vsock_msg_wait_data(struct sock *sk, struct sk_psock *psock, long timeo)
 {
-	bool ret;
+	struct vsock_sock *vsk = vsock_sk(sk);
+	int ret;
 
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
+	while (1) {
+		if (vsock_has_data(sk, psock)) {
+			ret = 1;
+			break;
+		}
+
+		/* Stop on a socket error, as vsock_connectible_wait_data()
+		 * does, so that recv() returns it; the checks below would
+		 * end the wait with 0 or -ENOTCONN instead.
+		 */
+		if (sk->sk_err) {
+			ret = -sk->sk_err;
+			break;
+		}
+
+		if ((sk->sk_shutdown & RCV_SHUTDOWN) ||
+		    (vsk->peer_shutdown & SEND_SHUTDOWN)) {
+			ret = 0;
+			break;
+		}
+
+		/* virtio_vsock_reset_sock() sets no shutdown bits, and
+		 * SO_ERROR clears sk_err: check the state the way
+		 * __vsock_connectible_recvmsg() does.
+		 */
+		if (sk->sk_state != TCP_ESTABLISHED) {
+			ret = sock_flag(sk, SOCK_DONE) ? 0 : -ENOTCONN;
+			break;
+		}
+
+		if (!timeo) {
+			ret = -EAGAIN;
+			break;
+		}
+
+		release_sock(sk);
+		timeo = wait_woken(&wait, TASK_INTERRUPTIBLE, timeo);
+		lock_sock(sk);
+
+		/* With a signal pending, wait_woken() returns at once, so
+		 * without this check the loop would spin until the timeout,
+		 * or forever without one.
+		 */
+		if (signal_pending(current)) {
+			ret = sock_intr_errno(timeo);
+			break;
+		}
 	}
 	sk_clear_bit(SOCKWQ_ASYNC_WAITDATA, sk);
 	remove_wait_queue(sk_sleep(sk), &wait);
@@ -101,9 +140,10 @@ static int vsock_bpf_recvmsg(struct sock *sk, struct msghdr *msg,
 	copied = sk_msg_recvmsg(sk, psock, msg, len, flags);
 	while (copied == 0) {
 		long timeo = sock_rcvtimeo(sk, flags & MSG_DONTWAIT);
+		int data = vsock_msg_wait_data(sk, psock, timeo);
 
-		if (!vsock_msg_wait_data(sk, psock, timeo)) {
-			copied = -EAGAIN;
+		if (data <= 0) {
+			copied = data;
 			break;
 		}
 

-- 
2.56.0

