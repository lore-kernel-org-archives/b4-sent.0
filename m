From: Quanye Yang <quanyeyang@proton.me>
Date: Thu, 17 Sep 2026 06:41:22 -0700
Subject: [PATCH net-next v4 1/2] tcp: annotate lockless access to
 sk->sk_err
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260917-mptcp-sk-err-net-v4-1-1f04f52f2561@proton.me>
References: <20260917-mptcp-sk-err-net-v4-0-1f04f52f2561@proton.me>
In-Reply-To: <20260917-mptcp-sk-err-net-v4-0-1f04f52f2561@proton.me>
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 "Matthieu Baerts (NGI0)" <matttbe@kernel.org>, 
 Geliang Tang <geliang@kernel.org>, Mat Martineau <martineau@kernel.org>, 
 Jiayuan Chen <jiayuan.chen@linux.dev>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789652484; l=5666;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=Ix5sfC38WPodAhwSsSWFlgULEhsUjMU6HvhZTqKvtI4=;
 b=XICKJEvnlVPQ+97Fkk7kzz2TXOIPC0u4SU70VxENFCg9mTMdpbvoYsgF5FrOno8iFMsUYDete
 ake6vNE06oVCZbStYS6bvYYM7bmUiWViNwMOvz5XsIi+QmJ4ddWptgV
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

BUG: KCSAN: data-race in do_recvmmsg / mptcp_recvmsg

read-write (marked) to 0xffff8880134d391c of 4 bytes by task 2619 on cpu 1:
 instrument_atomic_read_write include/linux/instrumented.h:113 [inline]
 sock_error include/net/sock.h:2565 [inline]
 do_recvmmsg+0x50c/0x580 net/socket.c:3049
 __sys_recvmmsg net/socket.c:3144 [inline]
 __do_sys_recvmmsg net/socket.c:3167 [inline]
 __se_sys_recvmmsg net/socket.c:3160 [inline]
 __x64_sys_recvmmsg+0x161/0x180 net/socket.c:3160
 x64_sys_call+0x19c7/0x1ca0 arch/x86/include/generated/asm/syscalls_64.h:300
 do_syscall_x64 arch/x86/entry/syscall_64.c:61 [inline]
 do_syscall_64+0xde/0x3d0 arch/x86/entry/syscall_64.c:84
 entry_SYSCALL_64_after_hwframe+0x77/0x7f

read to 0xffff8880134d391c of 4 bytes by task 2620 on cpu 0:
 tcp_recv_should_stop include/net/tcp.h:3086 [inline]
 mptcp_recvmsg+0x54d/0xd50 net/mptcp/protocol.c:2466
 inet_recvmsg+0x204/0x210 net/ipv4/af_inet.c:894
 sock_recvmsg_nosec net/socket.c:1151 [inline]
 sock_recvmsg+0x11a/0x140 net/socket.c:1173
 ____sys_recvmsg+0x14b/0x3c0 net/socket.c:2933
 ___sys_recvmsg+0x116/0x160 net/socket.c:2975
 __sys_recvmsg net/socket.c:3008 [inline]
 __do_sys_recvmsg net/socket.c:3014 [inline]
 __se_sys_recvmsg net/socket.c:3011 [inline]
 __x64_sys_recvmsg+0xeb/0x160 net/socket.c:3011
 x64_sys_call+0x1319/0x1ca0 arch/x86/include/generated/asm/syscalls_64.h:48
 do_syscall_x64 arch/x86/entry/syscall_64.c:61 [inline]
 do_syscall_64+0xde/0x3d0 arch/x86/entry/syscall_64.c:84
 entry_SYSCALL_64_after_hwframe+0x77/0x7f

value changed: 0x0000006b -> 0x00000000

Reported by Kernel Concurrency Sanitizer on:
CPU: 0 UID: 0 PID: 2620 Comm: syz.2.33 Not tainted 7.2.0-g39d4f32c5d53 #76 PREEMPT(full)
Hardware name: QEMU Ubuntu 26.04 PC (i440FX + PIIX, 1996), BIOS 1.17.0-debian-1.17.0-1ubuntu1 04/01/2014

do_recvmmsg() and getsockopt(SO_ERROR) call sock_error() without the
socket lock. sock_error() clears sk_err with xchg(), which races with
unmarked loads of the same field.

KCSAN reported the unmarked peek in tcp_recv_should_stop(). The same
lockless writer races with the other plain sk_err reads on the TCP
send, recv and splice paths.

Annotate those peeks with READ_ONCE(). No extra ordering is needed:
the value is only used to decide whether I/O should stop. This does
not consume sk_err; the check-then-sock_error() TOCTOU on the no-data
paths is a separate issue. MPTCP peeks are handled in the next patch.

Suggested-by: Jiayuan Chen <jiayuan.chen@linux.dev>
Link: https://lore.kernel.org/netdev/8bbee583-6f21-4817-bfeb-2d60057380a3@linux.dev/
Reported-by: Matthieu Baerts (NGI0) <matttbe@kernel.org>
Closes: https://github.com/multipath-tcp/mptcp_net-next/issues/632
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
 include/net/tcp.h  | 3 ++-
 net/core/stream.c  | 2 +-
 net/ipv4/tcp.c     | 6 +++---
 net/ipv4/tcp_bpf.c | 7 +++----
 4 files changed, 9 insertions(+), 9 deletions(-)

diff --git a/include/net/tcp.h b/include/net/tcp.h
index 5e5f5f9b89a3..6ee513bdb503 100644
--- a/include/net/tcp.h
+++ b/include/net/tcp.h
@@ -3093,7 +3093,8 @@ enum skb_drop_reason tcp_inbound_hash(struct sock *sk,
 
 static inline int tcp_recv_should_stop(struct sock *sk)
 {
-	return sk->sk_err ||
+	/* sk_err can be cleared locklessly by sock_error(). */
+	return READ_ONCE(sk->sk_err) ||
 	       sk->sk_state == TCP_CLOSE ||
 	       (sk->sk_shutdown & RCV_SHUTDOWN) ||
 	       signal_pending(current);
diff --git a/net/core/stream.c b/net/core/stream.c
index 2d748581862d..5c0adc3077f0 100644
--- a/net/core/stream.c
+++ b/net/core/stream.c
@@ -133,7 +133,7 @@ int sk_stream_wait_memory(struct sock *sk, long *timeo_p)
 	while (1) {
 		sk_set_bit(SOCKWQ_ASYNC_NOSPACE, sk);
 
-		if (sk->sk_err || (sk->sk_shutdown & SEND_SHUTDOWN))
+		if (READ_ONCE(sk->sk_err) || (sk->sk_shutdown & SEND_SHUTDOWN))
 			goto do_error;
 		if (!*timeo_p)
 			goto do_eagain;
diff --git a/net/ipv4/tcp.c b/net/ipv4/tcp.c
index 1c867a302444..9e7fa7e39726 100644
--- a/net/ipv4/tcp.c
+++ b/net/ipv4/tcp.c
@@ -843,7 +843,7 @@ ssize_t tcp_splice_read(struct socket *sock, loff_t *ppos,
 				break;
 			if (sock_flag(sk, SOCK_DONE))
 				break;
-			if (sk->sk_err) {
+			if (READ_ONCE(sk->sk_err)) {
 				ret = sock_error(sk);
 				break;
 			}
@@ -1228,7 +1228,7 @@ int tcp_sendmsg_locked(struct sock *sk, struct msghdr *msg, size_t size)
 	mss_now = tcp_send_mss(sk, &size_goal, flags);
 
 	err = -EPIPE;
-	if (sk->sk_err || (sk->sk_shutdown & SEND_SHUTDOWN))
+	if (READ_ONCE(sk->sk_err) || (sk->sk_shutdown & SEND_SHUTDOWN))
 		goto do_error;
 
 	while (msg_data_left(msg)) {
@@ -2760,7 +2760,7 @@ static int tcp_recvmsg_locked(struct sock *sk, struct msghdr *msg, size_t len,
 			if (sock_flag(sk, SOCK_DONE))
 				break;
 
-			if (sk->sk_err) {
+			if (READ_ONCE(sk->sk_err)) {
 				copied = sock_error(sk);
 				break;
 			}
diff --git a/net/ipv4/tcp_bpf.c b/net/ipv4/tcp_bpf.c
index 2e234d155b5e..a96323e65758 100644
--- a/net/ipv4/tcp_bpf.c
+++ b/net/ipv4/tcp_bpf.c
@@ -286,7 +286,7 @@ static int tcp_bpf_recvmsg_parser(struct sock *sk,
 		if (sock_flag(sk, SOCK_DONE))
 			goto out;
 
-		if (sk->sk_err) {
+		if (READ_ONCE(sk->sk_err)) {
 			copied = sock_error(sk);
 			goto out;
 		}
@@ -553,10 +553,9 @@ static int tcp_bpf_sendmsg(struct sock *sk, struct msghdr *msg, size_t size)
 		bool enospc = false;
 		u32 copy, osize;
 
-		if (sk->sk_err) {
-			err = -sk->sk_err;
+		err = -READ_ONCE(sk->sk_err);
+		if (err)
 			goto out_err;
-		}
 
 		copy = msg_data_left(msg);
 		if (!sk_stream_memory_free(sk))

-- 
2.55.0

