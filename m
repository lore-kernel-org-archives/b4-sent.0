From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 22 Oct 2026 22:00:38 -0500
Subject: [PATCH RFC net-next v2 1/2] net/iucv: serialize HiperSockets
 receive with the socket lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-b4-disp-1d26b87a-v2-1-7ee1264d812a@proton.me>
References: <20261022-b4-disp-1d26b87a-v2-0-7ee1264d812a@proton.me>
In-Reply-To: <20261022-b4-disp-1d26b87a-v2-0-7ee1264d812a@proton.me>
To: Paolo Abeni <pabeni@redhat.com>, 
 Alexandra Winter <wintera@linux.ibm.com>, 
 Eric Dumazet <edumazet@kernel.org>, "David S. Miller" <davem@davemloft.net>, 
 Thorsten Winkler <twinkler@linux.ibm.com>, Jakub Kicinski <kuba@kernel.org>
Cc: Nagamani PV <nagamani@linux.ibm.com>, netdev@vger.kernel.org, 
 Simon Horman <horms@kernel.org>, linux-kernel@vger.kernel.org, 
 linux-s390@vger.kernel.org, Hidayath Khan <hidayath@linux.ibm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792724438; l=36528;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=ZaH2vVpIbUeU+kVxmT1m9T5E++H/KpD/zsEAvzrCsGY=;
 b=+Hx6Xko02EuaXT29yjfC6WKBsEtTLNVLSI4WW/yQhp7y9Dk+TyQhV1v9bB3RG9fisNVRUHS9f
 8eOC7gV3tdfBGisOFpsYPxCp0rhgahW9Hzog/JImnetW3/T6nXBn8q6
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HiperSockets receive callbacks change sk_state under bh_lock_sock()
without checking sock_owned_by_user(), so a FIN or SYN|ACK is applied
while a task owns the socket and acts on the state it read. recvmsg()
takes no socket lock and sends a due window update in any state, even
after the FIN; one that fails keeps its credit.

Take bh_lock_sock() once in afiucv_hs_rcv(). While a task owns the
socket, a SYN|ACK, SYN|FIN or FIN is recorded in the socket and applied
by the owner from proto->release_cb: nothing resends a control frame,
so none may be dropped, as the socket backlog drops a pfmemalloc skb.
Data, SHT and WIN frames do not change sk_state, so they go through
under sk_lock.slock, reading a state the owner may be changing: a data
frame queues or is dropped, a WIN credits the sender, and
iucv_sock_destruct() now purges backlog_skb_q for one that queued after
close(). They wait in the socket backlog while the reply to our SYN is
pending, and behind frames already waiting, counted in frames rather
than bytes, up to the window we gave the peer plus one, which a
conforming peer does not exceed; the reply is applied before them. A
listener's SYNs wait the same way, cut to their header, up to its
accept queue plus one; past that, or when the backlog cannot take the
skb, they are refused at once, without a child, and so is one the
listener cannot take when it is applied: closed, or its accept queue
full, meanwhile. A SYN|ACK or SYN|FIN no socket state can use is freed
in afiucv_hs_rcv(), a SYN for a socket that does not listen refused
there.

The window given to the peer is kept in msglimit_adv: the SYN carries
msglimit, and SO_MSGLIMIT may lower msglimit while the reply is
awaited. The backlog budget, the receive check in recvmsg() and the
window-update threshold read the window advertised, which a conforming
peer keeps to. recvmsg() runs under lock_sock() on both transports and
sleeps without it; a reader parked when the connection goes sees EOF
once nothing is left, as a fresh call does. A due window update goes
out only while connected, else the credit is dropped. shutdown() sets
RCV_SHUTDOWN and purges under the socket spinlock, where the data path
tests it. sendmsg() waits for memory without the lock and fails with
EPIPE once sending is shut down. Control frames go out after
shutdown(SHUT_WR) without clearing SEND_SHUTDOWN around their
allocation; the FIN and the first SHT go out past sk_sndbuf, as qeth
keeps sent skbs charged until TX completion.

Suggested-by: Alexandra Winter <wintera@linux.ibm.com>
Link: https://lore.kernel.org/all/20260724222917.134769-1-hexlabsecurity@proton.me/
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
v2:
- control frames that arrive while a task owns the socket (SYN|ACK,
  SYN|FIN, FIN) are recorded in iucv_sock (hs_pending, the SYN|ACK's
  window with it) and applied from iucv_proto.release_cb; the first
  reply to our SYN decides, a FIN applies after it. The backlog keeps
  data, SHT and WIN frames while the reply to our SYN is pending or
  behind frames already waiting, and a listener's SYNs; a SYN that
  waits is cut to its header and holds its device for the reply, and
  is refused without a child if the listener closed, or its accept
  queue filled, meanwhile.
  afiucv_hs_backlog_rcv() applies a pending reply before the frame it
  runs; a socket closed meanwhile applies nothing (__iucv_sock_close()
  leaves IUCV_BOUND as it is). The refusal test there repeats the one in
  afiucv_hs_callback_syn(), which still allocates the child before it
  tests; moving that allocation, and freeing the child on the refusal
  and transmit-failure paths, is the pre-existing leak Hidayath's fix
  covers, and this patch does not touch that path.
- the rework stays one patch: the lock in afiucv_hs_rcv(), the
  record/apply pair and the backlog budget each close a window the
  others open; msglimit_adv is the budget's window; recvmsg() under
  lock_sock() is what makes release_cb() the owner's point.
- iucv_sock_destruct() purges backlog_skb_q: a data frame that races
  __iucv_sock_close()'s purge under sk_lock.slock is freed with the
  socket instead of leaking (pre-existing; the bypass path makes it a
  question this patch has to answer)
- msglimit_adv records the window advertised in the SYN (on the
  listener's child, in the SYN|ACK); the data budget, the msg_recv
  check in recvmsg() and the window-update threshold read it. The
  WRITE_ONCE() on msglimit in setsockopt() is gone with it. (The AI
  review's item on v1; Hidayath's reproducer, SO_MSGLIMIT lowered in
  IUCV_BOUND, lost data on v1.)
- afiucv_hs_stray(): unknown flags, and a SYN|ACK or SYN|FIN for a
  socket not in IUCV_BOUND, are freed in afiucv_hs_rcv() as NO_SOCKET;
  a SYN for a socket that does not listen is refused there without
  allocating a child
- iucv_sock_shutdown() takes sk_lock.slock around the sk_shutdown set
  and the purge on HiperSockets; the z/VM branch is unchanged
- iucv_sock_recv_skb() returns EOF when the socket is IUCV_DISCONN with
  nothing queued, as the shortcut at the top of recvmsg() does
- afiucv_hs_dispatch() is defined before its callers; the declarations
  of afiucv_hs_backlog_rcv() and afiucv_hs_release_cb() stay, with the
  file's four: iucv_proto and iucv_sock_alloc() point at them, and they
  dispatch to the SYN handler, which allocates sockets. The old block
  comment on the no-socket case went with the move; the dispatcher's
  comment says what a NULL socket means
- the SHT accounting, the WARN_ON on the overrun path and the hs_dev
  ordering are fixes in net now; the commit message is shorter
v1: https://lore.kernel.org/netdev/20261011-b4-disp-410518f4-v1-1-753bf3258292@proton.me/

Tested on s390x under QEMU TCG (no Z here), net-next 8df0638138d3,
KASAN + PROVE_LOCKING + DEBUG_ATOMIC_SLEEP, as v1 was, with one change
in the setup: instead of lo and injected SYN|ACKs, the guest now has two
emulated HiperSockets adapters on one LAN under the real qeth and qdio
drivers, so every SYN, SYN|ACK, FIN and window update is a frame af_iucv
itself sent and received, and tx completion is the adapter's: at once,
late (QAOB), or parked while the peer has no receive buffer. The z/VM
transport runs against an emulated CP (IUCV CONNECT, SEND, SEVER as the
CP Programming Services book describes them). Two vCPUs under -icount
for all but one test, MTTCG at HZ=100 for that one. The emulation does
what the drivers expect; where they leave a choice, the choice is mine.

The default set is 53 tests. net-next fails 8 of them: data sent after
the socket's own SHT by a writer parked on the window, and a writer
that waits out SO_SNDTIMEO after that shutdown; -EFAULT instead of EOF
when the SHT's empty frame is counted past the window; a SHT and the
FIN of a device going down lost to a full send buffer; a window update
after the peer's FIN; -ECONNRESET for a stream the socket shut down
itself; a reader parked at the FIN woken to -ENOTCONN. v1 fails the
last one only. This series fails none, with no KASAN or
lockdep report. The opt-in tests: SO_MSGLIMIT lowered in IUCV_BOUND
(three forms: before the SYN|ACK, with the reader holding the socket,
with the minimum SO_RCVBUF), a stray SYN|ACK and junk ahead of the FIN,
a repeated SYN ahead of it, the SHT past the window, the leaked child
of a refused SYN, a reader blocked at the FIN and poll() after it,
shutdown(SHUT_RD) against a frame in flight under a probe that widens
the gap (udelay(50) on both sides), the z/VM group, and two readers at
once under MTTCG. With this series: all 8 messages arrive in the three
forms (v1 delivers 3 of 8 in two of them; net-next delivers 8 and
closes the socket with -EFAULT in the third); the FIN is applied in
both stray tests where v1 loses it; EOF for the SHT past the window
where net-next gives WARN and -EFAULT; the parked reader gets EOF and
poll() reports EPOLLRDHUP, -ENOTCONN and no RDHUP on net-next and v1;
0 reads of data after SHUT_RD in 200 under the probe over three seeds,
17 to 21 without the spinlock; the z/VM sever wakes the sleeping reader
with EOF, -ENOTCONN on net-next; net-next fails the two-reader test in
all three MTTCG runs, this series passes them. The refused SYN leaks
its child on every kernel, as Hidayath reported: 1056 refused leave
1056 sockets behind, and the control that accepts its 17 frees all 17.

10 kernels each remove or weaken one piece of this series. Nine fail a
test this series passes: the budget on the live SO_MSGLIMIT loses data
(3 of 8); release_cb() applying nothing leaves connect() waiting for a
SYN|ACK the socket recorded; the SYN reply applied only after the
backlog dispatches data in IUCV_BOUND and loses it; the SHT counted
gives -EFAULT where this series gives EOF; shutdown without the spinlock
gives the 17 to 21 late reads above, under the probe only; the wait
loop without EOF on IUCV_DISCONN gives -ENOTCONN at the z/VM sever; 1/2
without 2/2 gives EOF without RDHUP; the fixes of [3] alone fail
net-next's set minus the window refusal; and the kernel that defers
nothing (every frame dispatched under the owner, net-next's race) shows
data to poll() on a socket a task owns, in the window tests, and three
default tests log it as applying where this series defers. One passes
every test: the kernel without the stray filter in afiucv_hs_rcv()
records a stray control frame and applies it as a no-op on release
instead of freeing it, which only the probe sees. Two pre-existing z/VM
findings show on every kernel and are read as such.

Not covered: real hardware, KCSAN (your run is the witness for the
sk_shutdown race), and the z/VM callbacks' sk_state writes, which this
series does not touch. Logs on request.
---
 include/net/iucv/af_iucv.h |   5 +
 net/iucv/af_iucv.c         | 560 +++++++++++++++++++++++++++++++++++----------
 2 files changed, 440 insertions(+), 125 deletions(-)

diff --git a/include/net/iucv/af_iucv.h b/include/net/iucv/af_iucv.h
index df85d19fbf84..85b35cc88f0b 100644
--- a/include/net/iucv/af_iucv.h
+++ b/include/net/iucv/af_iucv.h
@@ -130,11 +130,16 @@ struct iucv_sock {
 	u8			flags;
 	u16			msglimit;
 	u16			msglimit_peer;
+	u16			msglimit_adv;	/* the window given to the peer */
+	u8			hs_pending;	/* control frames recorded for the owner */
+	u16			hs_pending_window;
 	atomic_t		skbs_in_xmit;
 	atomic_t		msg_sent;
 	atomic_t		msg_recv;
 	atomic_t		pendings;
 	int			transport;
+	unsigned int		hs_backlog_data;	/* frames waiting in sk_backlog */
+	unsigned int		hs_backlog_syn;
 	void			(*sk_txnotify)(struct sock *sk,
 					       enum iucv_tx_notify n);
 };
diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index 794a3cc8b79f..15ce99e90c5b 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -39,12 +39,6 @@
 
 static char iucv_userid[80];
 
-static struct proto iucv_proto = {
-	.name		= "AF_IUCV",
-	.owner		= THIS_MODULE,
-	.obj_size	= sizeof(struct iucv_sock),
-};
-
 static struct iucv_interface *pr_iucv;
 static struct iucv_handler af_iucv_handler;
 
@@ -93,6 +87,22 @@ static void iucv_sock_kill(struct sock *sk);
 static void __iucv_sock_close(struct sock *sk);
 
 static void afiucv_hs_callback_txnotify(struct sock *sk, enum iucv_tx_notify);
+static int afiucv_hs_backlog_rcv(struct sock *sk, struct sk_buff *skb);
+static void afiucv_hs_release_cb(struct sock *sk);
+
+static struct proto iucv_proto = {
+	.name		= "AF_IUCV",
+	.owner		= THIS_MODULE,
+	.obj_size	= sizeof(struct iucv_sock),
+	.release_cb	= afiucv_hs_release_cb,
+};
+
+/* control frames recorded in iucv_sock.hs_pending while a task owns the socket */
+#define AF_IUCV_PEND_SYNACK	0x01
+#define AF_IUCV_PEND_SYNFIN	0x02
+#define AF_IUCV_PEND_SYNREPLY	(AF_IUCV_PEND_SYNACK | AF_IUCV_PEND_SYNFIN)
+#define AF_IUCV_PEND_FIN	0x04
+#define AF_IUCV_PEND_ALL	(AF_IUCV_PEND_SYNREPLY | AF_IUCV_PEND_FIN)
 
 static struct iucv_sock_list iucv_sk_list = {
 	.lock = __RW_LOCK_UNLOCKED(iucv_sk_list.lock),
@@ -208,8 +218,11 @@ static int afiucv_hs_send(struct iucv_message *imsg, struct sock *sock,
 	phs_hdr->magic = ETH_P_AF_IUCV;
 	phs_hdr->version = 1;
 	phs_hdr->flags = flags;
-	if (flags == AF_IUCV_FLAG_SYN)
+	if (flags == AF_IUCV_FLAG_SYN) {
 		phs_hdr->window = iucv->msglimit;
+		/* what the peer may send us, whatever msglimit becomes */
+		iucv->msglimit_adv = iucv->msglimit;
+	}
 	memcpy(phs_hdr->destUserID, iucv->dst_user_id, 8);
 	memcpy(phs_hdr->destAppName, iucv->dst_name, 8);
 	memcpy(phs_hdr->srcUserID, iucv->src_user_id, 8);
@@ -283,6 +296,8 @@ static void iucv_sock_destruct(struct sock *sk)
 {
 	skb_queue_purge(&sk->sk_receive_queue);
 	skb_queue_purge(&sk->sk_error_queue);
+	/* a HiperSockets data frame that raced __iucv_sock_close()'s purge */
+	skb_queue_purge(&iucv_sk(sk)->backlog_skb_q);
 
 	if (!sock_flag(sk, SOCK_DEAD)) {
 		pr_err("Attempt to release alive iucv socket %p\n", sk);
@@ -374,26 +389,28 @@ static void iucv_sever_path(struct sock *sk, int with_user_data)
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
@@ -514,6 +531,8 @@ static struct sock *iucv_sock_alloc(struct socket *sock, int proto, gfp_t prio,
 		iucv->transport = AF_IUCV_TRANS_HIPER;
 
 	sk->sk_destruct = iucv_sock_destruct;
+	/* not from iucv_proto: sk_alloc() does not copy proto->backlog_rcv */
+	sk->sk_backlog_rcv = afiucv_hs_backlog_rcv;
 	sk->sk_sndtimeo = IUCV_CONN_TIMEOUT;
 
 	sock_reset_flag(sk, SOCK_ZAPPED);
@@ -819,7 +838,7 @@ static int iucv_sock_listen(struct socket *sock, int backlog)
 	if (sock->type != SOCK_STREAM && sock->type != SOCK_SEQPACKET)
 		goto done;
 
-	sk->sk_max_ack_backlog = backlog;
+	WRITE_ONCE(sk->sk_max_ack_backlog, backlog);
 	sk->sk_ack_backlog = 0;
 	sk->sk_state = IUCV_LISTEN;
 	err = 0;
@@ -1031,7 +1050,16 @@ static int iucv_sock_sendmsg(struct socket *sock, struct msghdr *msg,
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
@@ -1045,10 +1073,16 @@ static int iucv_sock_sendmsg(struct socket *sock, struct msghdr *msg,
 
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
@@ -1252,6 +1286,56 @@ static void iucv_process_message_q(struct sock *sk)
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
+			/* the connection is gone and nothing is left to read:
+			 * EOF, as a fresh call gets at the top of
+			 * iucv_sock_recvmsg()
+			 */
+			if (sk->sk_state == IUCV_DISCONN &&
+			    skb_queue_empty(&iucv_sk(sk)->backlog_skb_q) &&
+			    list_empty(&iucv_sk(sk)->message_q.list))
+				*err = 0;
+			else
+				*err = -ENOTCONN;
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
@@ -1263,31 +1347,32 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
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
 	rlen   = skb->len - offset;		/* real length of skb */
 	copied = min_t(unsigned int, rlen, len);
 	if (!rlen)
-		sk->sk_shutdown = sk->sk_shutdown | RCV_SHUTDOWN;
+		WRITE_ONCE(sk->sk_shutdown, sk->sk_shutdown | RCV_SHUTDOWN);
 
 	cskb = skb;
 	if (skb_copy_datagram_msg(cskb, offset, msg, copied)) {
@@ -1331,9 +1416,10 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 		 */
 		if (iucv->transport == AF_IUCV_TRANS_HIPER && rlen) {
 			atomic_inc(&iucv->msg_recv);
-			if (atomic_read(&iucv->msg_recv) > iucv->msglimit) {
-				iucv_sock_close(sk);
-				return -EFAULT;
+			if (atomic_read(&iucv->msg_recv) > iucv->msglimit_adv) {
+				__iucv_sock_close(sk);
+				err = -EFAULT;
+				goto out_err;
 			}
 		}
 
@@ -1355,18 +1441,23 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 				iucv_process_message_q(sk);
 			if (iucv->transport == AF_IUCV_TRANS_HIPER &&
 			    atomic_read(&iucv->msg_recv) >=
-							iucv->msglimit / 2)
+							iucv->msglimit_adv / 2)
 				send_win = true;
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
+		/* no window update went out: the peer, gone or going, takes
+		 * no credit. Drop it.
+		 */
+		if (send_win && sk->sk_state != IUCV_CONNECTED)
+			atomic_set(&iucv->msg_recv, 0);
 	}
 
 done:
@@ -1375,7 +1466,8 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 		copied = rlen;
 	if (flags & MSG_PEEK)
 		skb_unref(skb);
-
+out:
+	release_sock(sk);
 	return copied;
 
 err_out:
@@ -1383,7 +1475,8 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 		skb_queue_head(&sk->sk_receive_queue, skb);
 	else
 		skb_unref(skb);
-
+out_err:
+	release_sock(sk);
 	return err;
 }
 
@@ -1489,16 +1582,26 @@ static int iucv_sock_shutdown(struct socket *sock, int how)
 			iucv_send_ctrl(sk, AF_IUCV_FLAG_SHT);
 	}
 
-	sk->sk_shutdown |= how;
-	if (how == RCV_SHUTDOWN || how == SHUTDOWN_MASK) {
-		if ((iucv->transport == AF_IUCV_TRANS_IUCV) &&
-		    iucv->path) {
-			err = pr_iucv->path_quiesce(iucv->path, NULL);
-			if (err)
-				err = -ENOTCONN;
-/*			skb_queue_purge(&sk->sk_receive_queue); */
+	if (iucv->transport == AF_IUCV_TRANS_HIPER) {
+		/* a data frame tests RCV_SHUTDOWN under sk_lock.slock while this
+		 * task owns the socket (afiucv_hs_rcv()): set it and purge under
+		 * that spinlock, or the frame queues after the purge
+		 */
+		spin_lock_bh(&sk->sk_lock.slock);
+		WRITE_ONCE(sk->sk_shutdown, sk->sk_shutdown | how);
+		if (how == RCV_SHUTDOWN || how == SHUTDOWN_MASK)
+			skb_queue_purge(&sk->sk_receive_queue);
+		spin_unlock_bh(&sk->sk_lock.slock);
+	} else {
+		sk->sk_shutdown |= how;
+		if (how == RCV_SHUTDOWN || how == SHUTDOWN_MASK) {
+			if (iucv->path) {
+				err = pr_iucv->path_quiesce(iucv->path, NULL);
+				if (err)
+					err = -ENOTCONN;
+			}
+			skb_queue_purge(&sk->sk_receive_queue);
 		}
-		skb_queue_purge(&sk->sk_receive_queue);
 	}
 
 	/* Wake up anyone sleeping in poll */
@@ -1904,7 +2007,6 @@ static int afiucv_hs_callback_syn(struct sock *sk, struct sk_buff *skb)
 	}
 
 	nsk = iucv_sock_alloc(NULL, sk->sk_protocol, GFP_ATOMIC, 0);
-	bh_lock_sock(sk);
 	if ((sk->sk_state != IUCV_LISTEN) ||
 	    sk_acceptq_is_full(sk) ||
 	    !nsk) {
@@ -1914,7 +2016,6 @@ static int afiucv_hs_callback_syn(struct sock *sk, struct sk_buff *skb)
 		err = dev_queue_xmit(skb);
 		if (nsk)
 			iucv_sock_kill(nsk);
-		bh_unlock_sock(sk);
 		goto out;
 	}
 
@@ -1941,6 +2042,7 @@ static int afiucv_hs_callback_syn(struct sock *sk, struct sk_buff *skb)
 	afiucv_swap_src_dest(skb);
 	trans_hdr->flags = AF_IUCV_FLAG_SYN | AF_IUCV_FLAG_ACK;
 	trans_hdr->window = niucv->msglimit;
+	niucv->msglimit_adv = niucv->msglimit;
 	/* if receiver acks the xmit connection is established */
 	err = dev_queue_xmit(skb);
 	if (!err) {
@@ -1949,29 +2051,43 @@ static int afiucv_hs_callback_syn(struct sock *sk, struct sk_buff *skb)
 		sk->sk_data_ready(sk);
 	} else
 		iucv_sock_kill(nsk);
-	bh_unlock_sock(sk);
 
 out:
 	return NET_RX_SUCCESS;
 }
 
+/* the reply to our SYN, @sk IUCV_BOUND: a SYN|ACK connects, a SYN|FIN refuses */
+static void afiucv_hs_synack(struct sock *sk, u16 window)
+{
+	iucv_sk(sk)->msglimit_peer = window;
+	sk->sk_state = IUCV_CONNECTED;
+	sk->sk_state_change(sk);
+}
+
+static void afiucv_hs_synfin(struct sock *sk)
+{
+	sk->sk_state = IUCV_DISCONN;
+	sk->sk_state_change(sk);
+}
+
+/* the peer's FIN, @sk IUCV_CONNECTED */
+static void afiucv_hs_fin(struct sock *sk)
+{
+	sk->sk_state = IUCV_DISCONN;
+	sk->sk_state_change(sk);
+}
+
 /*
  * afiucv_hs_callback_synack() - react on received SYN-ACK
  */
 static int afiucv_hs_callback_synack(struct sock *sk, struct sk_buff *skb)
 {
-	struct iucv_sock *iucv = iucv_sk(sk);
-
-	if (!iucv || sk->sk_state != IUCV_BOUND) {
+	if (!sk || sk->sk_state != IUCV_BOUND) {
 		kfree_skb(skb);
 		return NET_RX_SUCCESS;
 	}
 
-	bh_lock_sock(sk);
-	iucv->msglimit_peer = iucv_trans_hdr(skb)->window;
-	sk->sk_state = IUCV_CONNECTED;
-	sk->sk_state_change(sk);
-	bh_unlock_sock(sk);
+	afiucv_hs_synack(sk, iucv_trans_hdr(skb)->window);
 	consume_skb(skb);
 	return NET_RX_SUCCESS;
 }
@@ -1981,17 +2097,12 @@ static int afiucv_hs_callback_synack(struct sock *sk, struct sk_buff *skb)
  */
 static int afiucv_hs_callback_synfin(struct sock *sk, struct sk_buff *skb)
 {
-	struct iucv_sock *iucv = iucv_sk(sk);
-
-	if (!iucv || sk->sk_state != IUCV_BOUND) {
+	if (!sk || sk->sk_state != IUCV_BOUND) {
 		kfree_skb(skb);
 		return NET_RX_SUCCESS;
 	}
 
-	bh_lock_sock(sk);
-	sk->sk_state = IUCV_DISCONN;
-	sk->sk_state_change(sk);
-	bh_unlock_sock(sk);
+	afiucv_hs_synfin(sk);
 	consume_skb(skb);
 	return NET_RX_SUCCESS;
 }
@@ -2001,20 +2112,14 @@ static int afiucv_hs_callback_synfin(struct sock *sk, struct sk_buff *skb)
  */
 static int afiucv_hs_callback_fin(struct sock *sk, struct sk_buff *skb)
 {
-	struct iucv_sock *iucv = iucv_sk(sk);
-
 	/* other end of connection closed */
-	if (!iucv) {
+	if (!sk) {
 		kfree_skb(skb);
 		return NET_RX_SUCCESS;
 	}
 
-	bh_lock_sock(sk);
-	if (sk->sk_state == IUCV_CONNECTED) {
-		sk->sk_state = IUCV_DISCONN;
-		sk->sk_state_change(sk);
-	}
-	bh_unlock_sock(sk);
+	if (sk->sk_state == IUCV_CONNECTED)
+		afiucv_hs_fin(sk);
 	consume_skb(skb);
 	return NET_RX_SUCCESS;
 }
@@ -2029,6 +2134,7 @@ static int afiucv_hs_callback_win(struct sock *sk, struct sk_buff *skb)
 	if (!iucv)
 		return NET_RX_SUCCESS;
 
+	/* also runs while the user owns the socket, see afiucv_hs_rcv() */
 	if (sk->sk_state != IUCV_CONNECTED)
 		return NET_RX_SUCCESS;
 
@@ -2049,12 +2155,13 @@ static int afiucv_hs_callback_rx(struct sock *sk, struct sk_buff *skb)
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
@@ -2081,6 +2188,240 @@ static int afiucv_hs_callback_rx(struct sock *sk, struct sk_buff *skb)
 	return NET_RX_SUCCESS;
 }
 
+/*
+ * A frame that changes sk_state waits while a task owns the socket. Data, SHT
+ * and WIN frames do not change it, so they go through: a reader holding the
+ * lock would otherwise wait for its own window. They wait while the reply to our
+ * SYN is pending, to be received connected, and never past frames already
+ * waiting: sk_backlog.len stays set until __release_sock() has run them all.
+ */
+static bool afiucv_hs_defer(struct sock *sk)
+{
+	return (iucv_sk(sk)->hs_pending & AF_IUCV_PEND_SYNREPLY) ||
+	       sk->sk_backlog.len != 0;
+}
+
+/*
+ * A SYN|ACK, SYN|FIN or FIN that arrives while a task owns the socket is
+ * recorded, not queued: nothing resends one, and the backlog may not keep an
+ * skb from the pfmemalloc reserves (see sk_add_backlog()). The first reply to
+ * our SYN decides, as on arrival; a FIN applies after it. Under sk_lock.slock.
+ */
+static void afiucv_hs_record(struct sock *sk, struct sk_buff *skb, u8 flags)
+{
+	struct iucv_sock *iucv = iucv_sk(sk);
+
+	switch (flags) {
+	case AF_IUCV_FLAG_SYN | AF_IUCV_FLAG_ACK:
+		if (!(iucv->hs_pending & AF_IUCV_PEND_SYNREPLY)) {
+			iucv->hs_pending_window = iucv_trans_hdr(skb)->window;
+			iucv->hs_pending |= AF_IUCV_PEND_SYNACK;
+		}
+		break;
+	case AF_IUCV_FLAG_SYN | AF_IUCV_FLAG_FIN:
+		if (!(iucv->hs_pending & AF_IUCV_PEND_SYNREPLY))
+			iucv->hs_pending |= AF_IUCV_PEND_SYNFIN;
+		break;
+	case AF_IUCV_FLAG_FIN:
+		iucv->hs_pending |= AF_IUCV_PEND_FIN;
+		break;
+	}
+	consume_skb(skb);
+}
+
+/* the owner applies what afiucv_hs_record() kept, under sk_lock.slock */
+static void afiucv_hs_apply(struct sock *sk, u8 mask)
+{
+	struct iucv_sock *iucv = iucv_sk(sk);
+	u8 pending = iucv->hs_pending & mask;
+
+	iucv->hs_pending &= ~pending;
+	/* closed meanwhile: __iucv_sock_close() leaves IUCV_BOUND as it is */
+	if (sock_flag(sk, SOCK_ZAPPED))
+		return;
+	if ((pending & AF_IUCV_PEND_SYNACK) && sk->sk_state == IUCV_BOUND)
+		afiucv_hs_synack(sk, iucv->hs_pending_window);
+	if ((pending & AF_IUCV_PEND_SYNFIN) && sk->sk_state == IUCV_BOUND)
+		afiucv_hs_synfin(sk);
+	if ((pending & AF_IUCV_PEND_FIN) && sk->sk_state == IUCV_CONNECTED)
+		afiucv_hs_fin(sk);
+}
+
+/* release_sock(), after the backlog: still the owner, under sk_lock.slock */
+static void afiucv_hs_release_cb(struct sock *sk)
+{
+	if (iucv_sk(sk)->hs_pending)
+		afiucv_hs_apply(sk, AF_IUCV_PEND_ALL);
+}
+
+/*
+ * Not sk_add_backlog(): its limit is in bytes, and nothing resends a frame it
+ * drops. Count frames instead. Data, SHT and WIN frames get the window we gave
+ * the peer plus one: before the reply to our SYN, a peer that keeps to it has
+ * at most that many data frames and one SHT waiting, and no WIN to send us. A
+ * listener's SYNs get its accept queue plus the one sk_acceptq_is_full()
+ * admits past it. Both counts restart only once __release_sock() has run
+ * every frame: a flood cannot keep the owner draining. A SYN the backlog does
+ * not take is refused at once; one that waits is cut to its header, which the
+ * reply reuses, and holds its device for it, as the listener may close, or
+ * fill its accept queue, meanwhile.
+ */
+static void afiucv_hs_backlog_add(struct sock *sk, struct sk_buff *skb,
+				  u8 flags)
+{
+	struct iucv_sock *iucv = iucv_sk(sk);
+	unsigned int *count, limit;
+
+	if (!sk->sk_backlog.len) {
+		iucv->hs_backlog_data = 0;
+		iucv->hs_backlog_syn = 0;
+	}
+	if (flags == AF_IUCV_FLAG_SYN) {
+		count = &iucv->hs_backlog_syn;
+		limit = READ_ONCE(sk->sk_max_ack_backlog) + 1;
+	} else {
+		count = &iucv->hs_backlog_data;
+		limit = iucv->msglimit_adv + 1;
+	}
+	if (*count >= limit ||
+	    (skb_pfmemalloc(skb) && !sock_flag(sk, SOCK_MEMALLOC)))
+		goto refuse;
+	if (flags == AF_IUCV_FLAG_SYN) {
+		if (pskb_trim(skb, sizeof(struct af_iucv_trans_hdr)))
+			goto refuse;
+		dev_hold(skb->dev);
+	}
+	__sk_add_backlog(sk, skb);
+	/* msglimit 65535 x 64K frames would wrap the int */
+	sk->sk_backlog.len = min_t(u32, sk->sk_backlog.len + skb->truesize,
+				   INT_MAX);
+	(*count)++;
+	return;
+
+refuse:
+	if (flags == AF_IUCV_FLAG_SYN) {
+		afiucv_hs_callback_syn(NULL, skb);
+	} else {
+		sk_drops_inc(sk);
+		kfree_skb_reason(skb, SKB_DROP_REASON_SOCKET_BACKLOG);
+	}
+}
+
+/*
+ * Frames the dispatcher would only free, and a SYN it would only refuse, do
+ * not wait for the owner.
+ */
+static bool afiucv_hs_stray(struct sock *sk, u8 flags)
+{
+	switch (flags) {
+	case 0:
+	case AF_IUCV_FLAG_SHT:
+	case AF_IUCV_FLAG_WIN:
+	case AF_IUCV_FLAG_FIN:
+		return false;
+	case AF_IUCV_FLAG_SYN:
+		return sk->sk_state != IUCV_LISTEN;
+	case AF_IUCV_FLAG_SYN | AF_IUCV_FLAG_ACK:
+	case AF_IUCV_FLAG_SYN | AF_IUCV_FLAG_FIN:
+		return sk->sk_state != IUCV_BOUND;
+	}
+	return true;
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
+	switch (trans_hdr->flags) {
+	case AF_IUCV_FLAG_SYN:
+		/* connect request */
+		err = afiucv_hs_callback_syn(sk, skb);
+		break;
+	case (AF_IUCV_FLAG_SYN | AF_IUCV_FLAG_ACK):
+		/* connect request confirmed */
+		err = afiucv_hs_callback_synack(sk, skb);
+		break;
+	case (AF_IUCV_FLAG_SYN | AF_IUCV_FLAG_FIN):
+		/* connect request refused */
+		err = afiucv_hs_callback_synfin(sk, skb);
+		break;
+	case (AF_IUCV_FLAG_FIN):
+		/* close request */
+		err = afiucv_hs_callback_fin(sk, skb);
+		break;
+	case (AF_IUCV_FLAG_WIN):
+		err = afiucv_hs_callback_win(sk, skb);
+		if (skb->len == sizeof(struct af_iucv_trans_hdr)) {
+			consume_skb(skb);
+			break;
+		}
+		fallthrough;	/* and receive non-zero length data */
+	case (AF_IUCV_FLAG_SHT):
+		/* shutdown request */
+		fallthrough;	/* and receive zero length data */
+	case 0:
+		/* plain data frame */
+		IUCV_SKB_CB(skb)->class = trans_hdr->iucv_hdr.class;
+		err = afiucv_hs_callback_rx(sk, skb);
+		break;
+	default:
+		kfree_skb(skb);
+	}
+	return err;
+}
+
+/* run by __release_sock() for each frame that waited; @sk is still owned */
+static int afiucv_hs_backlog_rcv(struct sock *sk, struct sk_buff *skb)
+{
+	struct net_device *dev = NULL;
+
+	/* the reply to our SYN came before any frame that waited */
+	spin_lock_bh(&sk->sk_lock.slock);
+	afiucv_hs_apply(sk, AF_IUCV_PEND_SYNREPLY);
+	spin_unlock_bh(&sk->sk_lock.slock);
+	if (iucv_trans_hdr(skb)->flags == AF_IUCV_FLAG_SYN) {
+		dev = skb->dev;		/* held by afiucv_hs_backlog_add() */
+		if (sk->sk_state != IUCV_LISTEN || sk_acceptq_is_full(sk)) {
+			/* closed, or its accept queue filled, while the SYN
+			 * waited: refused as a stray is, without a child
+			 */
+			afiucv_hs_callback_syn(NULL, skb);
+			dev_put(dev);
+			return 0;
+		}
+	}
+	/* BH off: the callbacks take message_q.lock with spin_lock() */
+	local_bh_disable();
+	afiucv_hs_dispatch(sk, skb);
+	local_bh_enable();
+	dev_put(dev);
+	return 0;
+}
+
+/* a task owns @sk, under bh_lock_sock(): what each frame does meanwhile */
+static int afiucv_hs_rcv_owned(struct sock *sk, struct sk_buff *skb, u8 flags)
+{
+	switch (flags) {
+	case AF_IUCV_FLAG_SYN | AF_IUCV_FLAG_ACK:
+	case AF_IUCV_FLAG_SYN | AF_IUCV_FLAG_FIN:
+	case AF_IUCV_FLAG_FIN:
+		afiucv_hs_record(sk, skb, flags);
+		return NET_RX_SUCCESS;
+	case AF_IUCV_FLAG_SYN:
+		break;
+	default:
+		if (!afiucv_hs_defer(sk))
+			return afiucv_hs_dispatch(sk, skb);
+	}
+	afiucv_hs_backlog_add(sk, skb, flags);
+	return NET_RX_SUCCESS;
+}
+
 /*
  * afiucv_hs_rcv() - base function for arriving data through HiperSockets
  *                   transport
@@ -2147,53 +2488,22 @@ static int afiucv_hs_rcv(struct sk_buff *skb, struct net_device *dev,
 	if (!iucv)
 		sk = NULL;
 
-	/* no sock
-	how should we send with no sock
-	1) send without sock no send rc checking?
-	2) introduce default sock to handle this cases
-
-	 SYN -> send SYN|ACK in good case, send SYN|FIN in bad case
-	 data -> send FIN
-	 SYN|ACK, SYN|FIN, FIN -> no action? */
+	if (!sk)
+		return afiucv_hs_dispatch(NULL, skb);
 
-	switch (trans_hdr->flags) {
-	case AF_IUCV_FLAG_SYN:
-		/* connect request */
-		err = afiucv_hs_callback_syn(sk, skb);
-		break;
-	case (AF_IUCV_FLAG_SYN | AF_IUCV_FLAG_ACK):
-		/* connect request confirmed */
-		err = afiucv_hs_callback_synack(sk, skb);
-		break;
-	case (AF_IUCV_FLAG_SYN | AF_IUCV_FLAG_FIN):
-		/* connect request refused */
-		err = afiucv_hs_callback_synfin(sk, skb);
-		break;
-	case (AF_IUCV_FLAG_FIN):
-		/* close request */
-		err = afiucv_hs_callback_fin(sk, skb);
-		break;
-	case (AF_IUCV_FLAG_WIN):
-		err = afiucv_hs_callback_win(sk, skb);
-		if (skb->len == sizeof(struct af_iucv_trans_hdr)) {
-			consume_skb(skb);
-			break;
-		}
-		fallthrough;	/* and receive non-zero length data */
-	case (AF_IUCV_FLAG_SHT):
-		/* shutdown request */
-		fallthrough;	/* and receive zero length data */
-	case 0:
-		/* plain data frame */
-		IUCV_SKB_CB(skb)->class = trans_hdr->iucv_hdr.class;
-		err = afiucv_hs_callback_rx(sk, skb);
-		break;
-	default:
-		kfree_skb(skb);
+	bh_lock_sock(sk);
+	if (afiucv_hs_stray(sk, trans_hdr->flags)) {
+		if (trans_hdr->flags == AF_IUCV_FLAG_SYN)
+			afiucv_hs_callback_syn(NULL, skb);
+		else
+			kfree_skb_reason(skb, SKB_DROP_REASON_NO_SOCKET);
+	} else if (sock_owned_by_user(sk)) {
+		err = afiucv_hs_rcv_owned(sk, skb, trans_hdr->flags);
+	} else {
+		err = afiucv_hs_dispatch(sk, skb);
 	}
-
-	if (sk)
-		sock_put(sk);
+	bh_unlock_sock(sk);
+	sock_put(sk);
 	return err;
 }
 

-- 
2.56.0

