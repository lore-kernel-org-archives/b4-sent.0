From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Tue, 10 Nov 2026 23:44:30 -0500
Subject: [PATCH RFC net v3 5/7] net/iucv: serialize HiperSockets receive
 with the socket lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-b4-disp-2a6b4364-v3-5-35677b68e697@proton.me>
References: <20261110-b4-disp-2a6b4364-v3-0-35677b68e697@proton.me>
In-Reply-To: <20261110-b4-disp-2a6b4364-v3-0-35677b68e697@proton.me>
To: "David S. Miller" <davem@davemloft.net>, 
 Paolo Abeni <pabeni@redhat.com>, Jakub Kicinski <kuba@kernel.org>, 
 Eric Dumazet <edumazet@kernel.org>, 
 Alexandra Winter <wintera@linux.ibm.com>, 
 Hidayath Khan <hidayath@linux.ibm.com>
Cc: linux-kernel@vger.kernel.org, Thorsten Winkler <twinkler@linux.ibm.com>, 
 Nagamani PV <nagamani@linux.ibm.com>, Simon Horman <horms@kernel.org>, 
 netdev@vger.kernel.org, linux-s390@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794372266; l=24639;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=4O1SwvqM2U26YkSRw3kyw6kgIoT3NNR9yKiQo4nJ3Nk=;
 b=U/DIKTIwjtUijSPN775IP3/v9M/D1TzlIKr6/cebbF7qdYDU4cW9WRef4yuXZ4K7c29weOIVG
 XDdM8hAV0MtDdAX4y5eKUmSxCGx/xJMduTKQJMmWqJBDwg05aZb3Hhq
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HiperSockets receive callbacks change sk_state under bh_lock_sock()
without testing sock_owned_by_user(). A SYN|ACK, SYN|FIN or FIN that
arrives during a system call on the socket is applied under the task
that holds lock_sock(), which goes on with the state it read. A SYN is
answered for a listener that close() is emptying: the child is left on
the accept queue of a socket that is then freed, and nothing can close
it. It keeps the listener's name, so bind() to that name fails with
-EADDRINUSE from then on, and it keeps its reference on the net device.

Either needs only a frame from the peer at the wrong moment. No
memory-safety report is known.

Take bh_lock_sock() once in afiucv_hs_rcv(), for every frame that finds
a socket. While a task owns it:

- A SYN|ACK, SYN|FIN or FIN is recorded in the socket and applied by
  the owner from proto->release_cb. It is not queued: nothing resends a
  control frame, and the socket backlog can refuse one under memory
  pressure, since it does not take a pfmemalloc skb.
  connect() applies a recorded reply before it tests the state, so a
  non-blocking connect() still sees a reply that is already in.
- Data, SHT and WIN frames do not change sk_state and are handled on
  arrival, as before. They wait in the socket backlog only while the
  reply to our SYN is recorded and not applied yet, and behind frames
  that wait already, up to the window given to the peer plus one.
- A SYN for a listener waits in the backlog, cut to its header, up to
  the accept queue plus one. Past that, or if the listener closed or
  its queue filled meanwhile, it is refused without a child.

A frame that no state of the socket can use is freed in afiucv_hs_rcv()
and such a SYN refused there: a SYN|ACK or SYN|FIN outside IUCV_BOUND,
a FIN for a socket neither connected nor about to be, and data, SHT and
WIN frames behind a recorded FIN. A SYN for a socket that does not
listen was refused only after a child had been allocated for it, and
that child was never freed; it is now refused without one. A listener
whose accept queue is full still leaks the child when no task owns it,
as before.

Fixes: 3881ac441f64 ("af_iucv: add HiperSockets transport")
Suggested-by: Alexandra Winter <wintera@linux.ibm.com>
Link: https://lore.kernel.org/all/20260724222917.134769-1-hexlabsecurity@proton.me/
Cc: stable@vger.kernel.org # 6.18.x: f38bce9af9e2: net/iucv: take a private, writable frame before rewriting it in place
Cc: stable@vger.kernel.org # 6.18.x
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
v3:
- only the softirq side of the lock is left here; 1/7 to 4/7, 6/7 and
  7/7 took the rest, and the cover letter lists what was dropped. Up to
  this patch the parked reader still gets -ENOTCONN at the peer's FIN,
  as on net; 7/7 changes that
- afiucv_hs_stray() calls a FIN a stray unless the socket is
  IUCV_CONNECTED or a recorded SYN|ACK is about to connect it. v2
  recorded a FIN that reached a socket in IUCV_BOUND and applied it
  after the SYN|ACK (AI review of v2, first item)
- data, SHT and WIN frames behind a recorded FIN are strays too, as
  afiucv_hs_callback_rx() frees them once the FIN is applied. v2 handled
  them as connected (second item)
- connect() applies a recorded reply to its SYN before it tests the
  state. v1 and v2 left the reply for release_sock(): a non-blocking
  connect() returned -EAGAIN with the SYN|ACK, or the SYN|FIN, already
  in, where net returns 0 or -ECONNREFUSED
- kernel-doc on every function added, with its context; the comment on
  afiucv_hs_defer() is rewritten (the reason v2 gave there was stale),
  the one on afiucv_hs_backlog_add() says why frames are counted
- on net, with nothing under it
v2: https://lore.kernel.org/netdev/20261022-b4-disp-1d26b87a-v2-1-7ee1264d812a@proton.me/
v1: https://lore.kernel.org/netdev/20261011-b4-disp-410518f4-v1-1-753bf3258292@proton.me/

Repro of the listener in the message's first paragraph. The window is a
few instructions wide, between the last child taken off the accept
queue and the listener's IUCV_CLOSED, so the test kernels have an
mdelay(400) there and a SYN is sent 100 ms into the close(). net with
the delay: connect() returns 0, nothing ever accepts or closes the
child, one socket stays in use after both ends are closed, and a new
bind() to the listener's name fails with -EADDRINUSE. The series with
the same delay: the SYN waits in the listener's backlog, is refused
when the close is done, and connect() returns -ECONNREFUSED; nothing is
left and the name binds again. With the SYN sent before the close()
both kernels free the child. Not seen without the delay, and no KASAN
splat with it.

Strays are freed in afiucv_hs_rcv(): a FIN with consume_skb(), as
afiucv_hs_callback_fin() frees it on net, the rest as NO_SOCKET drops.
With the drop trace on, a second FIN for a socket the first one
disconnected leaves no kfree_skb event, on net and here; the series
with that FIN dropped like the other strays leaves one NO_SOCKET drop.
A data byte sent the same way is a drop on every kernel.

The SYN for a socket that does not listen, measured: 16 connect() calls
to a socket that is bound and does not listen, each refused. On net and
up to 4/7 they leave 16 sockets in use after everything is closed, from
this patch on none. The full accept queue is not fixed: 1056 SYNs
refused by a listener whose queue is full leave 1056 sockets in use, on
net and with the series.

The backlog's budget is the window of 1/7 plus one, so a socket
connected by a SYN|ACK without a SYN of its own counts against msglimit
there too. With the socket held, three one-byte messages behind such a
SYN|ACK are all read after the release. With the budget read from
msglimit_adv alone, one is read and two are SOCKET_BACKLOG drops.

The first two items of the AI review repro on v2 as sent and are gone
here. Both hold the socket with a task parked in setsockopt(), its
filter a userfaultfd page, and send it one forged frame over the
emulated adapter. First: the socket's SYN is held
back, so it is IUCV_BOUND and no SYN|ACK exists; a FIN arrives, then the
SYN is released and the SYN|ACK comes in. v2 connects and disconnects
at the release; v3 frees the FIN as it arrives and a byte goes each way
afterwards. With the FIN sent after the SYN|ACK instead, both apply it.
Second: the peer sends one byte and closes, then a forged data frame
arrives behind its FIN. v2 delivers the forged byte after the real one;
v3 frees it and the reader gets EOF. net and v1 behave as v3 in both.
v1 queued control frames and ran them in order, so both came in when v2
began to record them instead. With any FIN recorded again the first
test fails; with frames let through behind a recorded FIN, the second.

With any one of these pieces taken out, at least one test fails: the
release callback that applies what was recorded, the wait for the
owner, the reply to our SYN applied before the backlog runs, connect()
applying that reply, either half of afiucv_hs_stray()'s rule for a FIN,
its rule for frames behind one, the whole of afiucv_hs_stray(), the
budget read through the window helper, and the stray FIN consumed. Of
the 53 default tests the kernel with 1/7 to 5/7 fails six: the five in
the cover letter and the parked reader's -ENOTCONN, which 7/7 changes.

By inspection only, no repro: a pfmemalloc skb refused by the backlog,
the device reference a waiting SYN holds, and the SOCK_ZAPPED test in
afiucv_hs_apply().
---
 include/net/iucv/af_iucv.h |   5 +
 net/iucv/af_iucv.c         | 332 +++++++++++++++++++++++++++++++++++++++++----
 2 files changed, 314 insertions(+), 23 deletions(-)

diff --git a/include/net/iucv/af_iucv.h b/include/net/iucv/af_iucv.h
index 6decbb1f34b3..6b2cb6c41b9e 100644
--- a/include/net/iucv/af_iucv.h
+++ b/include/net/iucv/af_iucv.h
@@ -128,14 +128,19 @@ struct iucv_sock {
 	struct sock_msg_q	message_q;
 	unsigned int		send_tag;
 	u8			flags;
+	u8			hs_pending;	/* AF_IUCV_PEND_*, af_iucv.c */
 	u16			msglimit;
 	u16			msglimit_peer;
 	u16			msglimit_adv;	/* window given to the peer */
+	u16			hs_pending_window;
 	atomic_t		skbs_in_xmit;
 	atomic_t		msg_sent;
 	atomic_t		msg_recv;
 	atomic_t		pendings;
 	int			transport;
+	/* frames in sk_backlog since it was empty */
+	unsigned int		hs_backlog_data;
+	unsigned int		hs_backlog_syn;
 	void			(*sk_txnotify)(struct sock *sk,
 					       enum iucv_tx_notify n);
 };
diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index 1677cc65ad06..f31b037f28c1 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -44,7 +44,8 @@ static char iucv_userid[80];
  * @sk:		the socket, in IUCV_BOUND
  * @window:	the window in the SYN|ACK: the frames the peer takes from us
  *
- * Context: Softirq, under bh_lock_sock().
+ * Context: sk_lock.slock held: softirq with no task owning the socket, or
+ * the owner in afiucv_hs_apply().
  */
 static void afiucv_hs_synack(struct sock *sk, u16 window)
 {
@@ -77,10 +78,58 @@ static void afiucv_hs_fin(struct sock *sk)
 	sk->sk_state_change(sk);
 }
 
+/* iucv_sock.hs_pending: control frames recorded for the owner */
+#define AF_IUCV_PEND_SYNACK	0x01
+#define AF_IUCV_PEND_SYNFIN	0x02
+#define AF_IUCV_PEND_SYNREPLY	(AF_IUCV_PEND_SYNACK | AF_IUCV_PEND_SYNFIN)
+#define AF_IUCV_PEND_FIN	0x04
+#define AF_IUCV_PEND_ALL	(AF_IUCV_PEND_SYNREPLY | AF_IUCV_PEND_FIN)
+
+/**
+ * afiucv_hs_apply() - apply the control frames afiucv_hs_record() kept
+ * @sk:		the socket, owned by the caller
+ * @mask:	the AF_IUCV_PEND_* bits to apply
+ *
+ * A socket closed meanwhile takes none. The test is SOCK_ZAPPED, since
+ * __iucv_sock_close() leaves IUCV_BOUND as it is.
+ *
+ * Context: Process context, under sk_lock.slock.
+ */
+static void afiucv_hs_apply(struct sock *sk, u8 mask)
+{
+	struct iucv_sock *iucv = iucv_sk(sk);
+	u8 pending = iucv->hs_pending & mask;
+
+	iucv->hs_pending &= ~pending;
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
+/**
+ * afiucv_hs_release_cb() - proto->release_cb, apply what was recorded
+ * @sk:		the socket, still owned by the caller
+ *
+ * Runs after the backlog, so a recorded FIN follows the data before it.
+ *
+ * Context: Process context, under sk_lock.slock.
+ */
+static void afiucv_hs_release_cb(struct sock *sk)
+{
+	if (iucv_sk(sk)->hs_pending)
+		afiucv_hs_apply(sk, AF_IUCV_PEND_ALL);
+}
+
 static struct proto iucv_proto = {
 	.name		= "AF_IUCV",
 	.owner		= THIS_MODULE,
 	.obj_size	= sizeof(struct iucv_sock),
+	.release_cb	= afiucv_hs_release_cb,
 };
 
 static struct iucv_interface *pr_iucv;
@@ -131,6 +180,7 @@ static void iucv_sock_kill(struct sock *sk);
 static void __iucv_sock_close(struct sock *sk);
 
 static void afiucv_hs_callback_txnotify(struct sock *sk, enum iucv_tx_notify);
+static int afiucv_hs_backlog_rcv(struct sock *sk, struct sk_buff *skb);
 
 static struct iucv_sock_list iucv_sk_list = {
 	.lock = __RW_LOCK_UNLOCKED(iucv_sk_list.lock),
@@ -562,6 +612,8 @@ static struct sock *iucv_sock_alloc(struct socket *sock, int proto, gfp_t prio,
 		iucv->transport = AF_IUCV_TRANS_HIPER;
 
 	sk->sk_destruct = iucv_sock_destruct;
+	/* not from iucv_proto: sk_alloc() does not copy proto->backlog_rcv */
+	sk->sk_backlog_rcv = afiucv_hs_backlog_rcv;
 	sk->sk_sndtimeo = IUCV_CONN_TIMEOUT;
 
 	sock_reset_flag(sk, SOCK_ZAPPED);
@@ -836,6 +888,15 @@ static int iucv_sock_connect(struct socket *sock, struct sockaddr_unsized *addr,
 	if (err)
 		goto done;
 
+	/* The reply may be in already, recorded while we own the socket:
+	 * apply it, or a non-blocking connect() misses it.
+	 */
+	if (iucv->transport == AF_IUCV_TRANS_HIPER) {
+		spin_lock_bh(&sk->sk_lock.slock);
+		afiucv_hs_apply(sk, AF_IUCV_PEND_SYNREPLY);
+		spin_unlock_bh(&sk->sk_lock.slock);
+	}
+
 	if (sk->sk_state != IUCV_CONNECTED)
 		err = iucv_sock_wait(sk, iucv_sock_in_state(sk, IUCV_CONNECTED,
 							    IUCV_DISCONN),
@@ -1324,7 +1385,8 @@ static void iucv_process_message_q(struct sock *sk)
  * @err:	set when no skb is returned
  *
  * skb_recv_datagram() would sleep with the socket lock held. This sleeps in
- * sk_wait_event(), which drops it.
+ * sk_wait_event(), which drops it; a FIN recorded for the owner is applied
+ * then and ends the wait.
  *
  * Context: Process context, socket lock held; sleeps with it released.
  * Return: the skb, or NULL with @err set. At RCV_SHUTDOWN the caller
@@ -2018,7 +2080,6 @@ static int afiucv_hs_callback_syn(struct sock *sk, struct sk_buff *skb)
 	}
 
 	nsk = iucv_sock_alloc(NULL, sk->sk_protocol, GFP_ATOMIC, 0);
-	bh_lock_sock(sk);
 	if ((sk->sk_state != IUCV_LISTEN) ||
 	    sk_acceptq_is_full(sk) ||
 	    !nsk) {
@@ -2028,7 +2089,6 @@ static int afiucv_hs_callback_syn(struct sock *sk, struct sk_buff *skb)
 		err = dev_queue_xmit(skb);
 		if (nsk)
 			iucv_sock_kill(nsk);
-		bh_unlock_sock(sk);
 		goto out;
 	}
 
@@ -2059,7 +2119,6 @@ static int afiucv_hs_callback_syn(struct sock *sk, struct sk_buff *skb)
 		sk->sk_data_ready(sk);
 	} else
 		iucv_sock_kill(nsk);
-	bh_unlock_sock(sk);
 
 out:
 	return NET_RX_SUCCESS;
@@ -2075,9 +2134,7 @@ static int afiucv_hs_callback_synack(struct sock *sk, struct sk_buff *skb)
 		return NET_RX_SUCCESS;
 	}
 
-	bh_lock_sock(sk);
 	afiucv_hs_synack(sk, iucv_trans_hdr(skb)->window);
-	bh_unlock_sock(sk);
 	consume_skb(skb);
 	return NET_RX_SUCCESS;
 }
@@ -2092,9 +2149,7 @@ static int afiucv_hs_callback_synfin(struct sock *sk, struct sk_buff *skb)
 		return NET_RX_SUCCESS;
 	}
 
-	bh_lock_sock(sk);
 	afiucv_hs_synfin(sk);
-	bh_unlock_sock(sk);
 	consume_skb(skb);
 	return NET_RX_SUCCESS;
 }
@@ -2110,10 +2165,8 @@ static int afiucv_hs_callback_fin(struct sock *sk, struct sk_buff *skb)
 		return NET_RX_SUCCESS;
 	}
 
-	bh_lock_sock(sk);
 	if (sk->sk_state == IUCV_CONNECTED)
 		afiucv_hs_fin(sk);
-	bh_unlock_sock(sk);
 	consume_skb(skb);
 	return NET_RX_SUCCESS;
 }
@@ -2128,6 +2181,7 @@ static int afiucv_hs_callback_win(struct sock *sk, struct sk_buff *skb)
 	if (!iucv)
 		return NET_RX_SUCCESS;
 
+	/* also runs while a task owns the socket, see afiucv_hs_defer() */
 	if (sk->sk_state != IUCV_CONNECTED)
 		return NET_RX_SUCCESS;
 
@@ -2148,6 +2202,7 @@ static int afiucv_hs_callback_rx(struct sock *sk, struct sk_buff *skb)
 		return NET_RX_SUCCESS;
 	}
 
+	/* also runs while a task owns the socket, see afiucv_hs_defer() */
 	if (sk->sk_state != IUCV_CONNECTED) {
 		kfree_skb(skb);
 		return NET_RX_SUCCESS;
@@ -2180,12 +2235,171 @@ static int afiucv_hs_callback_rx(struct sock *sk, struct sk_buff *skb)
 	return NET_RX_SUCCESS;
 }
 
+/**
+ * afiucv_hs_stray() - test for a frame that no state of the socket can use
+ * @sk:		the socket the frame is for, under bh_lock_sock()
+ * @flags:	the flags of the frame
+ *
+ * A stray never waits for the owner. A SYN is one outside IUCV_LISTEN and a
+ * SYN|ACK or SYN|FIN outside IUCV_BOUND, the state tests of their
+ * callbacks; a full accept queue is not tested here. A FIN is one unless
+ * the socket is connected or a recorded SYN|ACK is about to connect it.
+ * Data, SHT and WIN are strays once the peer's FIN is recorded: the socket
+ * stays IUCV_CONNECTED until the owner applies it.
+ *
+ * Context: Softirq, under bh_lock_sock().
+ * Return: true if the frame is to be freed or, for a SYN, refused.
+ */
+static bool afiucv_hs_stray(struct sock *sk, u8 flags)
+{
+	struct iucv_sock *iucv = iucv_sk(sk);
+
+	switch (flags) {
+	case 0:
+	case AF_IUCV_FLAG_SHT:
+	case AF_IUCV_FLAG_WIN:
+		return iucv->hs_pending & AF_IUCV_PEND_FIN;
+	case AF_IUCV_FLAG_FIN:
+		return sk->sk_state != IUCV_CONNECTED &&
+		       !(iucv->hs_pending & AF_IUCV_PEND_SYNACK);
+	case AF_IUCV_FLAG_SYN:
+		return sk->sk_state != IUCV_LISTEN;
+	case AF_IUCV_FLAG_SYN | AF_IUCV_FLAG_ACK:
+	case AF_IUCV_FLAG_SYN | AF_IUCV_FLAG_FIN:
+		return sk->sk_state != IUCV_BOUND;
+	}
+	return true;
+}
+
+/**
+ * afiucv_hs_defer() - test whether a data, SHT or WIN frame has to wait
+ * @sk:		the socket, owned by a task, under bh_lock_sock()
+ *
+ * These frames do not change sk_state and are handled on arrival, also
+ * while a task owns the socket. They wait in the socket backlog only if:
+ *
+ * - the reply to our SYN is recorded and not applied yet: the socket is
+ *   still IUCV_BOUND, where data is freed and a WIN ignored;
+ * - frames wait already: a later one must not overtake them, and
+ *   sk_backlog.len stays non-zero until __release_sock() has run them all.
+ *
+ * Context: Softirq, under bh_lock_sock().
+ * Return: true if the frame has to wait in the backlog.
+ */
+static bool afiucv_hs_defer(struct sock *sk)
+{
+	return (iucv_sk(sk)->hs_pending & AF_IUCV_PEND_SYNREPLY) ||
+	       sk->sk_backlog.len != 0;
+}
+
+/**
+ * afiucv_hs_record() - keep a control frame for the task that owns the socket
+ * @sk:		the socket, owned by a task, under bh_lock_sock()
+ * @skb:	the frame, consumed here
+ * @flags:	the flags of the frame: SYN|ACK, SYN|FIN or FIN
+ *
+ * Not queued: nothing resends a control frame, and the socket backlog has
+ * to refuse a pfmemalloc skb. A bit in hs_pending is kept instead, and the
+ * window of a SYN|ACK. The first reply to our SYN decides; a FIN is applied
+ * after it.
+ *
+ * Context: Softirq, under bh_lock_sock().
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
+/**
+ * afiucv_hs_backlog_add() - make a frame wait for the task that owns the socket
+ * @sk:		the socket, owned by a task, under bh_lock_sock()
+ * @skb:	the frame
+ * @flags:	the flags of the frame: a SYN, or a data, SHT or WIN frame
+ *
+ * sk_add_backlog() is not used: its limit is in bytes and counts the
+ * receive queue too, while the window is in frames. So frames are counted:
+ *
+ * - data, SHT and WIN up to the window given to the peer plus one. They
+ *   wait only from the reply to our SYN until the owner has run them, and
+ *   a peer that keeps to its window sends at most that many data frames
+ *   and its SHT by then, and no WIN;
+ * - SYNs up to the accept queue plus the one sk_acceptq_is_full() admits.
+ *
+ * The counts restart only when __release_sock() has run every frame, so a
+ * peer cannot keep the owner in its loop. Past the limit a frame is
+ * dropped and a SYN refused; so is a pfmemalloc skb, on which
+ * __sk_backlog_rcv() BUG()s unless the socket is SOCK_MEMALLOC. A waiting
+ * SYN is cut to its header, all the reply needs, and holds its device:
+ * close() drops hs_dev before the release runs the SYN.
+ *
+ * Context: Softirq, under bh_lock_sock().
+ */
+static void afiucv_hs_backlog_add(struct sock *sk, struct sk_buff *skb,
+				  u8 flags)
+{
+	struct iucv_sock *iucv = iucv_sk(sk);
+	unsigned int *count;
+	unsigned int limit;
+
+	if (!sk->sk_backlog.len) {
+		iucv->hs_backlog_data = 0;
+		iucv->hs_backlog_syn = 0;
+	}
+	if (flags == AF_IUCV_FLAG_SYN) {
+		count = &iucv->hs_backlog_syn;
+		limit = sk->sk_max_ack_backlog + 1;
+	} else {
+		count = &iucv->hs_backlog_data;
+		limit = afiucv_hs_window(iucv) + 1;
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
+	/* a window of 65535 frames of 64K each would wrap the int */
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
 /**
  * afiucv_hs_dispatch() - run the callback of a frame
  * @sk:		the socket the frame is for, or NULL if there is none
  * @skb:	the frame
  *
- * Context: Softirq.
+ * Context: BH disabled. @sk is under bh_lock_sock(), or owned by the caller
+ * in afiucv_hs_backlog_rcv().
  * Return: NET_RX_SUCCESS.
  */
 static int afiucv_hs_dispatch(struct sock *sk, struct sk_buff *skb)
@@ -2231,6 +2445,71 @@ static int afiucv_hs_dispatch(struct sock *sk, struct sk_buff *skb)
 	return err;
 }
 
+/**
+ * afiucv_hs_backlog_rcv() - sk_backlog_rcv, run a frame that waited
+ * @sk:		the socket, owned by the caller
+ * @skb:	the frame
+ *
+ * Frames run in the order of arrival. The reply to our SYN came before any
+ * of them, so it is applied first. A SYN is refused if the listener was
+ * closed or its accept queue filled meanwhile.
+ *
+ * Context: Process context, socket owned by the caller, no sk_lock.slock.
+ * Return: 0.
+ */
+static int afiucv_hs_backlog_rcv(struct sock *sk, struct sk_buff *skb)
+{
+	struct net_device *dev = NULL;
+
+	spin_lock_bh(&sk->sk_lock.slock);
+	afiucv_hs_apply(sk, AF_IUCV_PEND_SYNREPLY);
+	spin_unlock_bh(&sk->sk_lock.slock);
+	if (iucv_trans_hdr(skb)->flags == AF_IUCV_FLAG_SYN) {
+		dev = skb->dev;		/* held by afiucv_hs_backlog_add() */
+		if (sk->sk_state != IUCV_LISTEN || sk_acceptq_is_full(sk)) {
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
+/**
+ * afiucv_hs_rcv_owned() - handle a frame while a task owns the socket
+ * @sk:		the socket, under bh_lock_sock()
+ * @skb:	the frame
+ * @flags:	the flags of the frame
+ *
+ * A SYN|ACK, SYN|FIN or FIN is recorded, a SYN waits in the backlog, and a
+ * data, SHT or WIN frame is handled now unless afiucv_hs_defer() says wait.
+ *
+ * Context: Softirq, under bh_lock_sock().
+ * Return: NET_RX_SUCCESS.
+ */
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
@@ -2302,18 +2581,25 @@ static int afiucv_hs_rcv(struct sk_buff *skb, struct net_device *dev,
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
+	/* no socket: a SYN is refused, anything else freed */
+	if (!sk)
+		return afiucv_hs_dispatch(NULL, skb);
 
-	err = afiucv_hs_dispatch(sk, skb);
-	if (sk)
-		sock_put(sk);
+	bh_lock_sock(sk);
+	if (afiucv_hs_stray(sk, trans_hdr->flags)) {
+		if (trans_hdr->flags == AF_IUCV_FLAG_SYN)
+			afiucv_hs_callback_syn(NULL, skb);
+		else if (trans_hdr->flags == AF_IUCV_FLAG_FIN)
+			consume_skb(skb);
+		else
+			kfree_skb_reason(skb, SKB_DROP_REASON_NO_SOCKET);
+	} else if (sock_owned_by_user(sk)) {
+		err = afiucv_hs_rcv_owned(sk, skb, trans_hdr->flags);
+	} else {
+		err = afiucv_hs_dispatch(sk, skb);
+	}
+	bh_unlock_sock(sk);
+	sock_put(sk);
 	return err;
 }
 

-- 
2.56.0

