From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Tue, 10 Nov 2026 23:44:28 -0500
Subject: [PATCH RFC net v3 3/7] net/iucv: run recvmsg() under the socket
 lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-b4-disp-2a6b4364-v3-3-35677b68e697@proton.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794372266; l=8262;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=l2qPWJX7A9pU8hsYefmLea43Ws4Vqj5D4r/jJtZd4uk=;
 b=7sGQPYEp78btGAOLd6+Rrle6sH45P5vvzyVP7KfdcE0C8wKsS4PopIg1uLCugIUuIg+xx1bKt
 Li1ZZ8yCyg8AxxO4wYfaP/ht4WT1heDdgmwLUKgWgJsSc9KO7JZ9fVW
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

recvmsg() takes no socket lock, on either transport:

- Two threads reading one socket get its data out of order.
- A read that races shutdown() can write back an older sk_shutdown and
  lose the bit shutdown() set, so a shutdown() that returned 0 has no
  effect.
- A MSG_PEEK read leaves its skb on the receive queue and holds a
  reference to it. When a second reader consumes the skb meanwhile,
  that reference is the last one and skb_unref() frees nothing: the skb
  and its receive memory leak, and iucv_sock_destruct() warns.

All three need only a second thread at the wrong moment. No
memory-safety report is known from any of them.

Take lock_sock() in recvmsg(). It sleeps for data without the lock, in
sk_wait_event(), so a reader with nothing to read keeps no other call
on the socket waiting.

sendmsg() now waits for send memory without the socket lock as well:
recvmsg() needs that lock, and over z/VM the memory comes back only when
the peer reads, which may wait for our own reader. That wait is one more
point at which shutdown(SHUT_WR) can find the send memory used up:
iucv_send_ctrl() then has no room for the SHT and the peer reads no EOF,
as before this patch whenever the memory is used up when shutdown()
runs.

Fixes: eac3731bd04c ("[S390]: Add AF_IUCV socket support")
Suggested-by: Alexandra Winter <wintera@linux.ibm.com>
Link: https://lore.kernel.org/all/20260724222917.134769-1-hexlabsecurity@proton.me/
Cc: stable@vger.kernel.org # 6.18.x: aa5ec571b93f: net/iucv: Add lock nesting annotation in iucv_sock_close()
Cc: stable@vger.kernel.org # 6.18.x
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
New in v3 as a patch of its own: the half of v2's lock patch that does
not touch the softirq side. Without 5/7 the softirq still changes
sk_state under a task that owns the socket, as on net.

In the emulated setup: two readers on one socket under MTTCG, three
runs of 838 messages each. On net and with 1/7 and 2/7 every run has
reads that go backwards, 9 to 18 of them; from 3/7 on there are none.

The lost bit: a task reads on a socket shut down for sending, with a
window of 2 so that nearly every read sends a window update, and
another calls shutdown(SHUT_RD). Over four runs of 200 cycles poll()
then shows no EPOLLRDHUP in 15 to 53 cycles of a run on net and with
1/7 and 2/7, and in none from 3/7 on.

Repro of the MSG_PEEK item: one process is parked in the copy of a
recv(MSG_PEEK), its buffer a userfaultfd page, and a second one reads
the same message. On net, and with 1/7 and 2/7, the second read returns
the byte while the first is still parked; once both are back the socket
has receive memory charged and nothing to read, and iucv_sock_destruct()
takes its WARN_ON() at close. From 3/7 on the second reader waits for
the first, then reads the byte, and nothing stays charged. With the two
reads one after the other every kernel is clean.

sendmsg()'s memory wait: with it left under the socket lock, a
non-blocking read is held up for as long as a writer waits for send
memory, 6 s in the test.

The prerequisite on the stable line, aa5ec571b93f, brings
__iucv_sock_close(), which recvmsg() now calls with the lock held where
it used to close the socket on a peer that overran its window.

By inspection: the memory wait now runs without the socket lock, so
iucv_send_ctrl() clearing SEND_SHUTDOWN around its allocation, e.g. for
recvmsg()'s window update, can make that wait miss the wake-up of a
shutdown(SHUT_WR). The writer then sleeps on until memory comes back,
where 2/7's test fails the call, or SO_SNDTIMEO runs out. No data goes
out after the SHT.

Hidayath's 19 KCSAN reports of recvmsg() against shutdown() on
net-next, and the 2 of iucv_send_ctrl() against shutdown(), are what
this patch should end.
---
 net/iucv/af_iucv.c | 94 ++++++++++++++++++++++++++++++++++++++++++++----------
 1 file changed, 78 insertions(+), 16 deletions(-)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index 133c1d1886b2..639725917f3f 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -1041,7 +1041,17 @@ static int iucv_sock_sendmsg(struct socket *sock, struct msghdr *msg,
 		}
 	}
 	skb = sock_alloc_send_pskb(sk, headroom + linear, len - linear,
-				   noblock, &err, 0);
+				   1, &err, 0);
+	if (!skb && err == -EAGAIN && !noblock) {
+		/* Wait without the socket lock: recvmsg() takes it, and over
+		 * z/VM the memory comes back only when the peer reads, which
+		 * may wait for our own reader.
+		 */
+		release_sock(sk);
+		skb = sock_alloc_send_pskb(sk, headroom + linear,
+					   len - linear, 0, &err, 0);
+		lock_sock(sk);
+	}
 	if (!skb)
 		goto out;
 	if (headroom)
@@ -1268,6 +1278,54 @@ static void iucv_process_message_q(struct sock *sk)
 	}
 }
 
+/**
+ * iucv_sock_recv_skb() - get the next skb for recvmsg(), waiting for one
+ * @sk:		the socket, locked by the caller
+ * @flags:	recvmsg() flags; MSG_PEEK leaves the skb queued and returns
+ *		it with a reference
+ * @err:	set when no skb is returned
+ *
+ * skb_recv_datagram() would sleep with the socket lock held. This sleeps in
+ * sk_wait_event(), which drops it.
+ *
+ * Context: Process context, socket lock held; sleeps with it released.
+ * Return: the skb, or NULL with @err set. At RCV_SHUTDOWN the caller
+ * returns EOF whatever @err is.
+ */
+static struct sk_buff *iucv_sock_recv_skb(struct sock *sk, int flags, int *err)
+{
+	long timeo = sock_rcvtimeo(sk, flags & MSG_DONTWAIT);
+	struct sk_buff_head *queue = &sk->sk_receive_queue;
+	DEFINE_WAIT_FUNC(wait, woken_wake_function);
+	struct sk_buff *skb;
+
+	for (;;) {
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
+		add_wait_queue(sk_sleep(sk), &wait);
+		sk_wait_event(sk, &timeo,
+			      !skb_queue_empty_lockless(queue) ||
+			      READ_ONCE(sk->sk_err) ||
+			      (READ_ONCE(sk->sk_shutdown) & RCV_SHUTDOWN) ||
+			      sk->sk_state != IUCV_CONNECTED, &wait);
+		remove_wait_queue(sk_sleep(sk), &wait);
+	}
+	return skb;
+}
+
 static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 			     size_t len, int flags)
 {
@@ -1279,24 +1337,25 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
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
+		goto unlock;
+	}
 
-	if (flags & (MSG_OOB))
-		return -EOPNOTSUPP;
+	if (flags & (MSG_OOB)) {
+		err = -EOPNOTSUPP;
+		goto err_unlock;
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
+		goto err_unlock;
 	}
 
 	offset = IUCV_SKB_CB(skb)->offset;
@@ -1346,8 +1405,9 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 			if (atomic_read(&iucv->msg_recv) >
 			    afiucv_hs_window(iucv)) {
 				WARN_ON(1);
-				iucv_sock_close(sk);
-				return -EFAULT;
+				__iucv_sock_close(sk);
+				err = -EFAULT;
+				goto err_unlock;
 			}
 		}
 
@@ -1389,7 +1449,8 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 		copied = rlen;
 	if (flags & MSG_PEEK)
 		skb_unref(skb);
-
+unlock:
+	release_sock(sk);
 	return copied;
 
 err_out:
@@ -1397,7 +1458,8 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 		skb_queue_head(&sk->sk_receive_queue, skb);
 	else
 		skb_unref(skb);
-
+err_unlock:
+	release_sock(sk);
 	return err;
 }
 

-- 
2.56.0

