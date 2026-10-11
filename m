From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sun, 11 Oct 2026 14:08:17 -0500
Subject: [PATCH net-next] net/iucv: serialize HiperSockets receive with the
 socket lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-b4-disp-410518f4-v1-1-753bf3258292@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQ6CMBAAv0L27CbdpoL6FeOBli2sh0q6xZAQ/
 m6F42Qys4FyFlZ4NBtk/orKJ1WgSwNh6tPIKENlsMa2ZIjQOxxEZ3RkrnSLDu8cbei9pUAd1Gz
 OHGU9lk9IXDDxWuB1Gl38m0P5H2HffyguJKd+AAAA
X-Change-ID: 20261011-b4-disp-410518f4-9ef2cab21c17
To: Paolo Abeni <pabeni@redhat.com>, Jakub Kicinski <kuba@kernel.org>, 
 Thorsten Winkler <twinkler@linux.ibm.com>, 
 Eric Dumazet <edumazet@kernel.org>, 
 Alexandra Winter <wintera@linux.ibm.com>, 
 "David S. Miller" <davem@davemloft.net>
Cc: Nagamani PV <nagamani@linux.ibm.com>, 
 Hidayath Khan <hidayath@linux.ibm.com>, netdev@vger.kernel.org, 
 Simon Horman <horms@kernel.org>, linux-s390@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791745696; l=30175;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=KzNAYYctoVUU09T/3ktDVr/pcq82g9Nq41y4qSYppeg=;
 b=a2K+iSk8tlJSsSGur0hNN06uYvadqaJrQHDU3b5+UjaxPprbvJpWzv/DwyztUQBLvMSW4uHjj
 SuG2WgaTsb2CEN1uVX9l63EY597WB5YRkYHQ9Ae35bHLMnpQN8g1GGN
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HiperSockets receive callbacks change sk_state under bh_lock_sock()
without checking sock_owned_by_user(), so a FIN or SYN|ACK is applied
while a task owns the socket. recvmsg takes no socket lock and sends a
due window update in any state, even after the FIN; one that fails keeps
its credit, and reading the peer's SHT can then return -EFAULT.

Take bh_lock_sock() once in afiucv_hs_rcv() and, while the socket is
owned, defer frames to the socket backlog, handled by a per-socket
sk_backlog_rcv. Data, SHT and WIN frames leave sk_state alone and skip
the backlog while it is empty. Bound each run of the backlog in frames,
refusing a SYN past the bound. Run recvmsg under lock_sock(), with
__iucv_sock_close() on its msglimit path; send a due window update only
while connected, else drop the credit. As recvmsg now holds the lock,
let sendmsg wait for memory without it, and end both its waits with
EPIPE once sending is shut down. Send the FIN and the first SHT past
sk_sndbuf: qeth keeps sent HiperSockets skbs charged to the socket until
TX completion.

Suggested-by: Alexandra Winter <wintera@linux.ibm.com>
Link: https://lore.kernel.org/all/20260724222917.134769-1-hexlabsecurity@proton.me/
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Alexandra, this is stage 1 from the RFC thread [1]: the HiperSockets rx
path and recvmsg() under the socket lock, plus the sendmsg() and
iucv_send_ctrl() changes a locked recvmsg() needs; some of these also
fix bugs net-next has today. Through recvmsg() and sendmsg(), it changes
the z/VM transport too. It's for net-next because recvmsg()'s close goes
through __iucv_sock_close() from your aa5ec571b93f ("net/iucv: Add lock
nesting annotation in iucv_sock_close()"), which isn't in net; that
commit already covers item (a) of the RFC, the split close.

It differs from the plan you OK'd there in three places:

- afiucv_hs_backlog_rcv() is set per socket in iucv_sock_alloc(), not as
  iucv_proto.backlog_rcv: sk_alloc() doesn't copy proto->backlog_rcv
  (inet, inet6 and phonet do it themselves), so __release_sock() would
  call a NULL sk_backlog_rcv on the first deferred frame. tipc, x25 and
  vsock set it per socket too.

- Not every frame is deferred. Data, SHT and WIN frames don't touch
  sk_state, so they go straight through while the backlog is empty and
  wait behind it otherwise: the first data frame of a connection waits
  behind its SYN|ACK. Bypassing whenever the socket is connected would
  let a frame overtake those that __release_sock() is still draining.
  WIN goes with data because afiucv_hs_send() sets it on data frames.

- No sk_add_backlog(): its limit is in bytes, with sk_rmem_alloc counted
  in, and nothing resends a frame it drops. With the sk_rcvbuf limit
  that __sk_receive_skb() passes, most of a full window of MTU-sized
  frames (128 by default) behind a SYN|ACK is dropped, and so is a FIN
  behind them; a full receive queue alone costs the FIN. The backlog is
  bounded in frames instead, in two budgets: msglimit + 1 for data, SHT
  and WIN frames; sk_max_ack_backlog + 2 for the rest (a SYN|ACK and a
  FIN, as sk_max_ack_backlog is 0 unless the socket listens). Both
  budgets restart only once __release_sock() has run every frame, so a
  peer that ignores the window can't keep the owner draining. A SYN past
  its budget is refused with SYN|FIN, as a full accept queue refuses it.
  The comments on afiucv_hs_defer() and afiucv_hs_backlog_add() say why
  the budgets suffice. One gap remains: lowering SO_MSGLIMIT once
  connect() has sent its SYN shrinks the data budget below the window
  that SYN gave the peer, and a full window behind the SYN|ACK loses its
  tail. That takes a setsockopt() after connect() returns without the
  SYN|ACK (non-blocking, timed out or interrupted), or one from another
  thread while a blocking connect() waits.

Beyond the plan:

The IUCV_CONNECTED test you suggested before the window update, done
here under the lock, leaves the unsent credit in msg_recv; a SHT's
zero-length skb can then push it past msglimit, and recvmsg() takes the
msglimit path (WARN, close, -EFAULT) instead of returning EOF. So when
an update is due and the socket isn't connected, recvmsg() drops the
credit. That also fixes a bug net has today: once data sent but not yet
completed by qeth fills sk_sndbuf, the update fails and sets
IUCV_DISCONN, and reading the peer's SHT can then hit the WARN and
return -EFAULT. The fix sits in the block this patch rewrites, so it's
here rather than in a separate patch for net.

afiucv_hs_backlog_add() keeps sk_add_backlog()'s pfmemalloc check;
otherwise a frame from the reserves would hit the BUG_ON() in
__sk_backlog_rcv() if sk_memalloc_socks() is on when __release_sock()
runs it. The cost: a SYN, SYN|ACK, SYN|FIN or FIN from the reserves that
arrives while a task owns the socket is dropped (a SYN is refused) where
net-next applies it. A WIN frame from the reserves that has to wait is
dropped as well, credit included: net-next applies the credit of a WIN
on a data frame before sk_filter() drops the data. net-next drops data
and SHT frames from the reserves too.

sk_backlog.len saturates at INT_MAX, which msglimit (up to 65535)
MTU-sized frames can exceed. The data budget is the window the socket
grants its peer, and net-next already queues a window's worth in
backlog_skb_q once the receive queue is full.

afiucv_hs_backlog_rcv() drops frames whose socket was closed while they
waited, since by then nothing holds skb->dev. So a SYN that waited for a
listener being closed is dropped, not refused, and the peer's connect()
times out instead of failing with ECONNREFUSED.

With recvmsg() taking the lock, a writer asleep in
sock_alloc_send_pskb() would keep the reader out, and over z/VM, send
memory comes back only once the peer receives, which may wait for this
reader (a cycle I found with a hand-written model of af_iucv's locking
that enumerates interleavings). So sendmsg() now waits for send memory
with the lock released, as it already does for the window. Both waits
end once sending is shut down: sock_alloc_send_pskb() already does, and
the window wait now tests SEND_SHUTDOWN too. sendmsg() then fails with
EPIPE, checked before the connected state, as at its start. In net-next
a send() that races shutdown(SHUT_WR) can put its data on the wire after
the SHT (at the window wait), or wait out SO_SNDTIMEO for a window and
fail with EAGAIN.

In net-next, iucv_send_ctrl() allocates against sk_sndbuf, and a SHT or
FIN it can't allocate is lost without a trace: shutdown() and
afiucv_netdev_event() ignore the error, and close() only skips its wait
for tx completion. On HiperSockets, sent data stays charged to
sk_wmem_alloc until tx completion (qeth_xmit() orphans only non-IQD
skbs), so a shutdown() or close() right after a large send can find the
send buffer full, and the peer never sees EOF. The FIN and the first SHT
now go out past sk_sndbuf with sock_wmalloc(), as TCP forces its one
FIN; a repeated shutdown() still sends its SHT within sk_sndbuf or not
at all, so send memory stays bounded. The iucv_send_ctrl() change fixes
that single-threaded loss (send(), then shutdown() or close()), so it
could go to net on its own, with Fixes: 3881ac441f64 ("af_iucv: add
HiperSockets transport"), if you'd rather. It's here because a
shutdown() during the unlocked memory wait usually finds the send buffer
full, a second way to lose the SHT.

A close() that now gets its FIN out also waits for tx completion
(IUCV_DISCONN_TIMEOUT or SO_LINGER), as any close() with data in flight
does. SYN and WIN keep the sk_sndbuf test: as in net-next,
iucv_send_ctrl() returns -EAGAIN when the send buffer is full and arms
SIGIO for when there is room, and connect() passes the -EAGAIN up. A
window update that fails that way still sets IUCV_DISCONN, and the
credit drop above keeps it from turning into -EFAULT. sock_wmalloc()
doesn't test SEND_SHUTDOWN, so iucv_send_ctrl() no longer clears and
restores it, which also closes a race: afiucv_netdev_event() calls
iucv_send_ctrl() without the socket lock, so in net-next a concurrent
sendmsg() can find SEND_SHUTDOWN cleared.

Tested on s390x under QEMU TCG (no Z here), net-next 8df0638138d3,
KASAN + PROVE_LOCKING + DEBUG_ATOMIC_SLEEP. First over lo, on one CPU,
with real AF_IUCV sockets on the HiperSockets transport. lo can't return
af_iucv's own SYN|ACK to it, so the SYN|ACK is injected raw, as are
frames af_iucv never sends (data past the window, a SYN|FIN flood) and a
frame that has to arrive while __release_sock() is draining. lo orphans
skbs on xmit, so where a test needs send memory to stay charged, a plug
qdisc on lo holds sent frames (as qeth does until tx completion) or a
blocked writer holds a large skb.

I built 33 kernels that each remove or weaken one piece of this patch
and booted each twice, with the same result both times. Every one fails
a test this patch passes. On receive: a FIN applied while recvmsg() owns
the socket; a reader asleep until SO_RCVTIMEO after the FIN; a window
update after the FIN; -EFAULT instead of EOF. In the backlog: lost data;
a SHT or FIN lost there; a SYN refused with room in the accept queue, or
dropped instead of refused; an unbounded backlog; a NULL sk_backlog_rcv
call; the BUG_ON() in __sk_backlog_rcv() and a wrapped sk_backlog.len
(these two need test-only hooks: a pfmemalloc frame, sk_backlog.len set
to INT_MAX - 1). On send: a reader kept out by a writer waiting for
memory; a SHT or FIN lost to a full send buffer; data sent after the
socket's own SHT, or a writer that waits out SO_SNDTIMEO after it;
ECONNRESET for a stream the socket shut down itself; send memory past
sk_sndbuf on every shutdown(); ENOBUFS instead of EAGAIN from connect();
no SIGIO for an O_ASYNC socket when room comes back after that EAGAIN.
Besides these, a lockdep splat and a hang. This patch passes all of
these tests with no KASAN or lockdep report; the only splat is the
existing WARN_ON(1) on the msglimit path, which one test hits on
purpose. Every added line the compiler attributes code to (87) ran at
least once. MSG_OOB, a signal during recvmsg(), SHUT_RD and frames for a
socket that doesn't exist behave as before.

QEMU has no HiperSockets adapter and no z/VM, so I emulated both: the
adapter under the real qeth driver, tx completion included, and CP's
IUCV interface for the z/VM transport. The emulation does what the qeth,
qdio and iucv drivers expect; where they leave a choice, the choice is
mine. I ran the tests on two vCPUs under TCG with -icount, which runs
one vCPU at a time. The z/VM tests and a msglimit test ran with QEMU's
default slice only, the others also with seeded short ones. net-next
fails 7 HiperSockets tests (each a failure listed above) in each of five
runs, and one z/VM test: a writer waits out SO_SNDTIMEO after the peer
quiesces the path. This patch fails no test in those runs, with no KASAN
or lockdep report, and all 33 kernels are told apart from it: two only
by what a test logs; one only by the msglimit test, which runs alone;
and the rest by failing all five runs. Two extra kernels cover the two
changes that had no kernel on lo, each with a test of its own. One keeps
a closed socket's frames; with it, a SYN that waited for a listener
being closed is refused. The other clears and restores SEND_SHUTDOWN
again; with it, a send() after shutdown(SHUT_WR) can succeed while the
device goes down, and put data on the wire after the SHT, as in
net-next.

Two more tests, also under -icount. The freed-device test frees the
device that a closed socket's frames arrived on, while they wait. It
sends 600 SYNs to a listener being closed, and a test-only hook delays
each by 4 ms when __release_sock() runs it, so that unregister_netdev()
and free_netdev() finish while most still wait. This patch drops those
that waited, with no KASAN report; with the same hook and no drop, KASAN
reports a use-after-free in __dev_queue_xmit(). The ingress-device test
covers the check from your 80230a18c164 ("net/iucv: filter frames in
afiucv_hs_rcv() by ingress device"), since this patch changes
afiucv_hs_rcv() around it. On a second emulated LAN, where another of
the guest's adapters has the user ID of a socket connected on the first
LAN, a frame sent to that socket's names reaches no socket in net-next
or with this patch; with the check removed, it reaches that socket.

The same kernels, rebuilt with HZ=100, also ran under MTTCG, with the
two vCPUs at once (at HZ=1000, TCG falls behind the timer tick, and on
an idle host every boot livelocked). Each kernel got three runs of the
default tests (all HiperSockets), three of the z/VM tests and three of
the msglimit test. In each run of the default tests net-next fails the
same 7, and in each z/VM run the same z/VM test; this patch fails none,
with no KASAN or lockdep report. Of the 33 kernels, 30 fail all three
runs of the default tests and one all three runs of the msglimit test.
The other two pass every test but are told apart in each run of the
default tests by what a test logs: frames applied instead of deferred, a
SYN|FIN flood not dropped.

The two extra kernels' tests ran five times each on both of those
kernels and on this patch, and the two kernels are told apart in all
five: the one that clears and restores SEND_SHUTDOWN fails its test, and
the one that keeps a closed socket's frames passes its test but logs the
SYNs that waited as refused instead of dropped. The freed-device test
got five runs too, with the same result in each. With the hook, this
patch drops the frames with no KASAN report, and the kernel that keeps a
closed socket's frames gets the use-after-free. Without the hook, this
patch drops them all before the device is freed, and that kernel still
gets the use-after-free. The ingress-device test also got five runs,
each with the results it gives under -icount.

Not covered: real hardware. Memory ordering was checked only on the
locking model, exhaustively except for three cases that ran clean to
20,000,000 interleavings without finishing. You offered to run each
revision on real hardware; this one needs it for z/VM, HiperSockets and
SMP. Logs on request.

Still open: afiucv_hs_callback_txnotify(), afiucv_netdev_event()
(Nagamani's "net/iucv: fix races in afiucv_netdev_event()") and the z/VM
callbacks change sk_state without checking whether a task owns the
socket.

This patch and [2] ("net/iucv: take a private, writable frame before
rewriting it in place", sent to net) apply on top of each other in
either order, with offsets only.

Hidayath, Nagamani: sorry for the wait. This is the stage 1 your patches
were held for.

[1] https://lore.kernel.org/all/20260724222917.134769-1-hexlabsecurity@proton.me/
[2] https://lore.kernel.org/all/20261008-b4-disp-bf46f1ba-v2-1-46ff1ea9c40b@proton.me/
---
 include/net/iucv/af_iucv.h |   2 +
 net/iucv/af_iucv.c         | 251 ++++++++++++++++++++++++++++++++++++---------
 2 files changed, 206 insertions(+), 47 deletions(-)

diff --git a/include/net/iucv/af_iucv.h b/include/net/iucv/af_iucv.h
index df85d19fbf84..b5caf3e14faf 100644
--- a/include/net/iucv/af_iucv.h
+++ b/include/net/iucv/af_iucv.h
@@ -135,6 +135,8 @@ struct iucv_sock {
 	atomic_t		msg_recv;
 	atomic_t		pendings;
 	int			transport;
+	unsigned int		sk_backlog_data;
+	unsigned int		sk_backlog_ctrl;
 	void			(*sk_txnotify)(struct sock *sk,
 					       enum iucv_tx_notify n);
 };
diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index 5ba875798aa4..1fcb47a08755 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -39,6 +39,9 @@
 
 static char iucv_userid[80];
 
+static int afiucv_hs_backlog_rcv(struct sock *sk, struct sk_buff *skb);
+static int afiucv_hs_dispatch(struct sock *sk, struct sk_buff *skb);
+
 static struct proto iucv_proto = {
 	.name		= "AF_IUCV",
 	.owner		= THIS_MODULE,
@@ -374,26 +377,28 @@ static void iucv_sever_path(struct sock *sk, int with_user_data)
 static int iucv_send_ctrl(struct sock *sk, u8 flags)
 {
 	struct iucv_sock *iucv = iucv_sk(sk);
-	int err = 0;
 	int blen;
 	struct sk_buff *skb;
-	u8 shutdown = 0;
+	bool force;
 
 	blen = sizeof(struct af_iucv_trans_hdr) +
 	       LL_RESERVED_SPACE(iucv->hs_dev);
-	if (sk->sk_shutdown & SEND_SHUTDOWN) {
-		/* controlling flags should be sent anyway */
-		shutdown = sk->sk_shutdown;
-		sk->sk_shutdown &= RCV_SHUTDOWN;
-	}
-	skb = sock_alloc_send_skb(sk, blen, 1, &err);
-	if (skb) {
-		skb_reserve(skb, blen);
-		err = afiucv_hs_send(NULL, sk, skb, flags);
+	/* Control frames go out after a shutdown too. The FIN and the first SHT
+	 * end the stream and may exceed sk_sndbuf, like TCP's FIN; at sk_sndbuf
+	 * the others get -EAGAIN and arm SIGIO, as sock_alloc_send_skb() does.
+	 */
+	force = flags == AF_IUCV_FLAG_FIN ||
+		(flags == AF_IUCV_FLAG_SHT &&
+		 !(sk->sk_shutdown & SEND_SHUTDOWN));
+	if (!force && sk_wmem_alloc_get(sk) >= sk->sk_sndbuf) {
+		sk_set_bit(SOCKWQ_ASYNC_NOSPACE, sk);
+		return -EAGAIN;
 	}
-	if (shutdown)
-		sk->sk_shutdown = shutdown;
-	return err;
+	skb = sock_wmalloc(sk, blen, 1, sk->sk_allocation);
+	if (!skb)
+		return -ENOBUFS;
+	skb_reserve(skb, blen);
+	return afiucv_hs_send(NULL, sk, skb, flags);
 }
 
 /**
@@ -507,6 +512,8 @@ static struct sock *iucv_sock_alloc(struct socket *sock, int proto, gfp_t prio,
 		iucv->transport = AF_IUCV_TRANS_HIPER;
 
 	sk->sk_destruct = iucv_sock_destruct;
+	/* not from iucv_proto: sk_alloc() does not copy proto->backlog_rcv */
+	sk->sk_backlog_rcv = afiucv_hs_backlog_rcv;
 	sk->sk_sndtimeo = IUCV_CONN_TIMEOUT;
 
 	sock_reset_flag(sk, SOCK_ZAPPED);
@@ -812,7 +819,7 @@ static int iucv_sock_listen(struct socket *sock, int backlog)
 	if (sock->type != SOCK_STREAM && sock->type != SOCK_SEQPACKET)
 		goto done;
 
-	sk->sk_max_ack_backlog = backlog;
+	WRITE_ONCE(sk->sk_max_ack_backlog, backlog);
 	sk->sk_ack_backlog = 0;
 	sk->sk_state = IUCV_LISTEN;
 	err = 0;
@@ -1024,7 +1031,16 @@ static int iucv_sock_sendmsg(struct socket *sock, struct msghdr *msg,
 		}
 	}
 	skb = sock_alloc_send_pskb(sk, headroom + linear, len - linear,
-				   noblock, &err, 0);
+				   1, &err, 0);
+	if (!skb && err == -EAGAIN && !noblock) {
+		/* unlocked: over z/VM the room comes back only when the peer
+		 * receives, and that may wait for our own recvmsg()
+		 */
+		release_sock(sk);
+		skb = sock_alloc_send_pskb(sk, headroom + linear,
+					   len - linear, 0, &err, 0);
+		lock_sock(sk);
+	}
 	if (!skb)
 		goto out;
 	if (headroom)
@@ -1038,10 +1054,16 @@ static int iucv_sock_sendmsg(struct socket *sock, struct msghdr *msg,
 
 	/* wait if outstanding messages for iucv path has reached */
 	timeo = sock_sndtimeo(sk, noblock);
-	err = iucv_sock_wait(sk, iucv_below_msglim(sk), timeo);
+	err = iucv_sock_wait(sk, iucv_below_msglim(sk) ||
+			     (sk->sk_shutdown & SEND_SHUTDOWN), timeo);
 	if (err)
 		goto fail;
 
+	/* return -EPIPE if sending has been shut down meanwhile */
+	if (sk->sk_shutdown & SEND_SHUTDOWN) {
+		err = -EPIPE;
+		goto fail;
+	}
 	/* return -ECONNRESET if the socket is no longer connected */
 	if (sk->sk_state != IUCV_CONNECTED) {
 		err = -ECONNRESET;
@@ -1245,6 +1267,47 @@ static void iucv_process_message_q(struct sock *sk)
 	}
 }
 
+/*
+ * Like skb_recv_datagram(), but sleep with the socket lock released, so that
+ * release_sock() runs the backlog and a deferred FIN reaches the reader.
+ */
+static struct sk_buff *iucv_sock_recv_skb(struct sock *sk, int flags, int *err)
+{
+	long timeo = sock_rcvtimeo(sk, flags & MSG_DONTWAIT);
+	DEFINE_WAIT_FUNC(wait, woken_wake_function);
+	struct sk_buff *skb;
+
+	add_wait_queue(sk_sleep(sk), &wait);
+	for (;;) {
+		/* receive/dequeue next skb:
+		 * the function understands MSG_PEEK and, thus, does not
+		 * dequeue skb, only refcount is increased.
+		 */
+		skb = skb_recv_datagram(sk, flags | MSG_DONTWAIT, err);
+		if (skb || *err != -EAGAIN)
+			break;
+		if (sk->sk_shutdown & RCV_SHUTDOWN)
+			break;
+		if (!timeo)
+			break;
+		if (sk->sk_state != IUCV_CONNECTED) {
+			*err = -ENOTCONN;
+			break;
+		}
+		if (signal_pending(current)) {
+			*err = sock_intr_errno(timeo);
+			break;
+		}
+		sk_wait_event(sk, &timeo,
+			      !skb_queue_empty_lockless(&sk->sk_receive_queue) ||
+			      READ_ONCE(sk->sk_err) ||
+			      (READ_ONCE(sk->sk_shutdown) & RCV_SHUTDOWN) ||
+			      sk->sk_state != IUCV_CONNECTED, &wait);
+	}
+	remove_wait_queue(sk_sleep(sk), &wait);
+	return skb;
+}
+
 static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 			     size_t len, int flags)
 {
@@ -1256,24 +1319,25 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 	int err = 0;
 	u32 offset;
 
+	lock_sock(sk);
 	if ((sk->sk_state == IUCV_DISCONN) &&
 	    skb_queue_empty(&iucv->backlog_skb_q) &&
 	    skb_queue_empty(&sk->sk_receive_queue) &&
-	    list_empty(&iucv->message_q.list))
-		return 0;
+	    list_empty(&iucv->message_q.list)) {
+		copied = 0;
+		goto out;
+	}
 
-	if (flags & (MSG_OOB))
-		return -EOPNOTSUPP;
+	if (flags & (MSG_OOB)) {
+		err = -EOPNOTSUPP;
+		goto out_err;
+	}
 
-	/* receive/dequeue next skb:
-	 * the function understands MSG_PEEK and, thus, does not dequeue skb
-	 * only refcount is increased.
-	 */
-	skb = skb_recv_datagram(sk, flags, &err);
+	skb = iucv_sock_recv_skb(sk, flags, &err);
 	if (!skb) {
 		if (sk->sk_shutdown & RCV_SHUTDOWN)
-			return 0;
-		return err;
+			err = 0;
+		goto out_err;
 	}
 
 	offset = IUCV_SKB_CB(skb)->offset;
@@ -1322,8 +1386,9 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 			atomic_inc(&iucv->msg_recv);
 			if (atomic_read(&iucv->msg_recv) > iucv->msglimit) {
 				WARN_ON(1);
-				iucv_sock_close(sk);
-				return -EFAULT;
+				__iucv_sock_close(sk);
+				err = -EFAULT;
+				goto out_err;
 			}
 		}
 
@@ -1350,13 +1415,18 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 		}
 		spin_unlock_bh(&iucv->message_q.lock);
 
-		if (send_win) {
+		if (send_win && sk->sk_state == IUCV_CONNECTED) {
 			err = iucv_send_ctrl(sk, AF_IUCV_FLAG_WIN);
 			if (err) {
 				sk->sk_state = IUCV_DISCONN;
 				sk->sk_state_change(sk);
 			}
 		}
+		/* the peer won't take this credit: drop it, or a SHT's
+		 * zero-length skb counts past msglimit
+		 */
+		if (send_win && sk->sk_state != IUCV_CONNECTED)
+			atomic_set(&iucv->msg_recv, 0);
 	}
 
 done:
@@ -1365,7 +1435,8 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 		copied = rlen;
 	if (flags & MSG_PEEK)
 		skb_unref(skb);
-
+out:
+	release_sock(sk);
 	return copied;
 
 err_out:
@@ -1373,7 +1444,8 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 		skb_queue_head(&sk->sk_receive_queue, skb);
 	else
 		skb_unref(skb);
-
+out_err:
+	release_sock(sk);
 	return err;
 }
 
@@ -1549,7 +1621,7 @@ static int iucv_sock_setsockopt(struct socket *sock, int level, int optname,
 			if (val < 1 || val > U16_MAX)
 				rc = -EINVAL;
 			else
-				iucv->msglimit = val;
+				WRITE_ONCE(iucv->msglimit, val);
 			break;
 		default:
 			rc = -EINVAL;
@@ -1894,7 +1966,6 @@ static int afiucv_hs_callback_syn(struct sock *sk, struct sk_buff *skb)
 	}
 
 	nsk = iucv_sock_alloc(NULL, sk->sk_protocol, GFP_ATOMIC, 0);
-	bh_lock_sock(sk);
 	if ((sk->sk_state != IUCV_LISTEN) ||
 	    sk_acceptq_is_full(sk) ||
 	    !nsk) {
@@ -1904,7 +1975,6 @@ static int afiucv_hs_callback_syn(struct sock *sk, struct sk_buff *skb)
 		err = dev_queue_xmit(skb);
 		if (nsk)
 			iucv_sock_kill(nsk);
-		bh_unlock_sock(sk);
 		goto out;
 	}
 
@@ -1934,7 +2004,6 @@ static int afiucv_hs_callback_syn(struct sock *sk, struct sk_buff *skb)
 		sk->sk_data_ready(sk);
 	} else
 		iucv_sock_kill(nsk);
-	bh_unlock_sock(sk);
 
 out:
 	return NET_RX_SUCCESS;
@@ -1952,11 +2021,9 @@ static int afiucv_hs_callback_synack(struct sock *sk, struct sk_buff *skb)
 		return NET_RX_SUCCESS;
 	}
 
-	bh_lock_sock(sk);
 	iucv->msglimit_peer = iucv_trans_hdr(skb)->window;
 	sk->sk_state = IUCV_CONNECTED;
 	sk->sk_state_change(sk);
-	bh_unlock_sock(sk);
 	consume_skb(skb);
 	return NET_RX_SUCCESS;
 }
@@ -1973,10 +2040,8 @@ static int afiucv_hs_callback_synfin(struct sock *sk, struct sk_buff *skb)
 		return NET_RX_SUCCESS;
 	}
 
-	bh_lock_sock(sk);
 	sk->sk_state = IUCV_DISCONN;
 	sk->sk_state_change(sk);
-	bh_unlock_sock(sk);
 	consume_skb(skb);
 	return NET_RX_SUCCESS;
 }
@@ -1994,12 +2059,10 @@ static int afiucv_hs_callback_fin(struct sock *sk, struct sk_buff *skb)
 		return NET_RX_SUCCESS;
 	}
 
-	bh_lock_sock(sk);
 	if (sk->sk_state == IUCV_CONNECTED) {
 		sk->sk_state = IUCV_DISCONN;
 		sk->sk_state_change(sk);
 	}
-	bh_unlock_sock(sk);
 	consume_skb(skb);
 	return NET_RX_SUCCESS;
 }
@@ -2014,6 +2077,7 @@ static int afiucv_hs_callback_win(struct sock *sk, struct sk_buff *skb)
 	if (!iucv)
 		return NET_RX_SUCCESS;
 
+	/* also runs while the user owns the socket, see afiucv_hs_rcv() */
 	if (sk->sk_state != IUCV_CONNECTED)
 		return NET_RX_SUCCESS;
 
@@ -2034,12 +2098,13 @@ static int afiucv_hs_callback_rx(struct sock *sk, struct sk_buff *skb)
 		return NET_RX_SUCCESS;
 	}
 
+	/* also runs while the user owns the socket, see afiucv_hs_rcv() */
 	if (sk->sk_state != IUCV_CONNECTED) {
 		kfree_skb(skb);
 		return NET_RX_SUCCESS;
 	}
 
-	if (sk->sk_shutdown & RCV_SHUTDOWN) {
+	if (READ_ONCE(sk->sk_shutdown) & RCV_SHUTDOWN) {
 		kfree_skb(skb);
 		return NET_RX_SUCCESS;
 	}
@@ -2066,6 +2131,64 @@ static int afiucv_hs_callback_rx(struct sock *sk, struct sk_buff *skb)
 	return NET_RX_SUCCESS;
 }
 
+/* data, SHT and WIN frames: they leave sk_state alone */
+static bool afiucv_hs_is_data(u8 flags)
+{
+	return !flags || flags == AF_IUCV_FLAG_SHT || flags == AF_IUCV_FLAG_WIN;
+}
+
+/*
+ * Frames that change sk_state wait while the user owns the socket. Data, SHT
+ * and WIN frames go through, but never past waiting ones: sk_backlog.len stays
+ * set until __release_sock() has run them all. So they wait only behind a FIN,
+ * which voids them, or a SYN|ACK, when we have sent nothing for a WIN to ack.
+ */
+static bool afiucv_hs_defer(struct sock *sk, u8 flags)
+{
+	return !afiucv_hs_is_data(flags) || sk->sk_backlog.len != 0;
+}
+
+/*
+ * Not sk_add_backlog(): its limit is in bytes, and nothing resends a frame it
+ * drops. Count frames instead. Data, SHT and WIN frames get msglimit + 1: a
+ * peer that keeps to the window has at most msglimit data frames and one SHT
+ * waiting (a repeated one carries nothing); WINs need no room (see above). The
+ * rest get sk_max_ack_backlog + 2: a SYN|ACK and a FIN, or a listener's SYNs up
+ * to its accept queue and one more. Both counts restart only once
+ * __release_sock() has run every frame: a flood cannot keep the owner draining.
+ */
+static void afiucv_hs_backlog_add(struct sock *sk, struct sk_buff *skb,
+				  u8 flags)
+{
+	struct iucv_sock *iucv = iucv_sk(sk);
+	unsigned int *count, limit;
+
+	if (!sk->sk_backlog.len) {
+		iucv->sk_backlog_data = 0;
+		iucv->sk_backlog_ctrl = 0;
+	}
+	if (afiucv_hs_is_data(flags)) {
+		count = &iucv->sk_backlog_data;
+		limit = READ_ONCE(iucv->msglimit) + 1;
+	} else {
+		count = &iucv->sk_backlog_ctrl;
+		limit = READ_ONCE(sk->sk_max_ack_backlog) + 2;
+	}
+	if (*count < limit &&
+	    !(skb_pfmemalloc(skb) && !sock_flag(sk, SOCK_MEMALLOC))) {
+		__sk_add_backlog(sk, skb);
+		/* msglimit 65535 x 64K frames would wrap the int */
+		sk->sk_backlog.len = min_t(u32, sk->sk_backlog.len +
+					   skb->truesize, INT_MAX);
+		(*count)++;
+	} else if (flags == AF_IUCV_FLAG_SYN) {
+		afiucv_hs_callback_syn(NULL, skb);
+	} else {
+		sk_drops_inc(sk);
+		kfree_skb_reason(skb, SKB_DROP_REASON_SOCKET_BACKLOG);
+	}
+}
+
 /*
  * afiucv_hs_rcv() - base function for arriving data through HiperSockets
  *                   transport
@@ -2128,6 +2251,28 @@ static int afiucv_hs_rcv(struct sk_buff *skb, struct net_device *dev,
 	if (!iucv)
 		sk = NULL;
 
+	if (!sk)
+		return afiucv_hs_dispatch(NULL, skb);
+
+	bh_lock_sock(sk);
+	if (!sock_owned_by_user(sk) || !afiucv_hs_defer(sk, trans_hdr->flags))
+		err = afiucv_hs_dispatch(sk, skb);
+	else
+		afiucv_hs_backlog_add(sk, skb, trans_hdr->flags);
+	bh_unlock_sock(sk);
+	sock_put(sk);
+	return err;
+}
+
+/*
+ * @sk is NULL, or locked by the caller: bh_lock_sock() in afiucv_hs_rcv(),
+ * where the user may own it too, or user-owned in afiucv_hs_backlog_rcv().
+ */
+static int afiucv_hs_dispatch(struct sock *sk, struct sk_buff *skb)
+{
+	struct af_iucv_trans_hdr *trans_hdr = iucv_trans_hdr(skb);
+	int err = NET_RX_SUCCESS;
+
 	/* no sock
 	how should we send with no sock
 	1) send without sock no send rc checking?
@@ -2172,12 +2317,24 @@ static int afiucv_hs_rcv(struct sk_buff *skb, struct net_device *dev,
 	default:
 		kfree_skb(skb);
 	}
-
-	if (sk)
-		sock_put(sk);
 	return err;
 }
 
+/* run by __release_sock() for each frame that waited; @sk is still owned */
+static int afiucv_hs_backlog_rcv(struct sock *sk, struct sk_buff *skb)
+{
+	/* closed while the frame waited: nothing holds skb->dev any more */
+	if (!iucv_sk(sk)->hs_dev) {
+		kfree_skb(skb);
+		return 0;
+	}
+	/* BH off: the callbacks take message_q.lock with spin_lock() */
+	local_bh_disable();
+	afiucv_hs_dispatch(sk, skb);
+	local_bh_enable();
+	return 0;
+}
+
 /*
  * afiucv_hs_callback_txnotify() - handle send notifications from HiperSockets
  *                                 transport

---
base-commit: 8df0638138d3e0344fd1fb36cf2d1ca1cf5028f0
change-id: 20261011-b4-disp-410518f4-9ef2cab21c17

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

