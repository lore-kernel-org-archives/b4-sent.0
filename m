From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Tue, 10 Nov 2026 23:44:31 -0500
Subject: [PATCH RFC net v3 6/7] net/iucv: set RCV_SHUTDOWN under the socket
 spinlock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-b4-disp-2a6b4364-v3-6-35677b68e697@proton.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794372266; l=5238;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=Ep0RU8oUAggO7JaKWdU5cfb9fSG5mTAN7Flxu2cQnGk=;
 b=1uaZ4vEDcvq+y2324j8c33XJEQ5U5mcRtRVfyIYuZuG/2PE8C0GisaPntzRS3GumlH8UetPTB
 UGY+lo1ZDRCBeu0uOUeyrJ+tpx1fBhrqsftjUBy1GiJSxw741llz+35
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

shutdown(SHUT_RD) sets RCV_SHUTDOWN and purges the receive queue under
lock_sock() alone, and nothing orders that against a HiperSockets data
frame: a frame that tested RCV_SHUTDOWN before the bit was set is
queued after the purge, and recvmsg() returns its data after
shutdown(SHUT_RD) returned.

Since the previous patch such a frame is received under sk_lock.slock,
also while a task owns the socket; one that waited for the owner runs
when it releases the socket, which shutdown() does only after the purge.
On HiperSockets, set the bit and purge under that lock. recvmsg() sets
the same bit under lock_sock() only, when it reads a zero-length record,
which is how the peer's SHT arrives; that write and the frame's test are
marked WRITE_ONCE() and READ_ONCE(), and only a frame the peer sent
after that record can race with it. iucv_send_ctrl() still clears and
restores SEND_SHUTDOWN in that byte with plain writes. The z/VM branch
is unchanged, less a line that was commented out.

Without the previous patch this one changes nothing: the frame then
takes no lock that shutdown() could share with it.

Fixes: 82492a355fac ("af_iucv: add shutdown for HS transport")
Reported-by: Hidayath Khan <hidayath@linux.ibm.com>
Closes: https://lore.kernel.org/netdev/b3fea2ca-25ff-42c0-812c-f8cc6bb6667e@linux.ibm.com/
Cc: stable@vger.kernel.org # 6.18.x, with the previous patch only
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
New in v3 as a patch: the hunk was in the lock patch of v2.

This is the first of the two races KCSAN reported on v1 in the mail
the Closes: tag points at, afiucv_hs_callback_rx() against
iucv_sock_shutdown() on sk_shutdown. The second there, on hs_dev, is
fixed by 1/2 of the two fixes posted for net on 28 Oct ([7] in the
cover letter), which are not in this series.

In the emulated setup, 200 cycles a run and four runs a kernel (QEMU's
default slice and three seeded short ones): net, the kernel with 1/7
and 2/7 and the one with 1/7 to 3/7 read data after shutdown(SHUT_RD)
in 0 to 7 cycles of a run, 39 of 2400 in all. The series reads none.
Nor does the series minus this spinlock: since 5/7 only a frame that
takes sk_lock.slock between shutdown()'s lock_sock() and its write gets
through, and no run had one. With udelay(50) added after lock_sock() in
shutdown() and after the frame's test, the series minus this spinlock
reads late data in 10 to 28 of 200 cycles and the series in none.

On the hardware Hidayath could not get that window to fire with v1
either, and KCSAN cannot show it closed: shutdown()'s write is now
WRITE_ONCE(), which the readers that take no lock need, and that alone
silences the report. IOW only the udelay() kernels above show what the
spinlock does.

The z/VM branch is unchanged; what is open there is under "Seen while
reviewing v3" in the cover letter.
---
 net/iucv/af_iucv.c | 34 +++++++++++++++++++++++-----------
 1 file changed, 23 insertions(+), 11 deletions(-)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index f31b037f28c1..2118effc137f 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -1462,7 +1462,7 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 	rlen   = skb->len - offset;		/* real length of skb */
 	copied = min_t(unsigned int, rlen, len);
 	if (!rlen)
-		sk->sk_shutdown = sk->sk_shutdown | RCV_SHUTDOWN;
+		WRITE_ONCE(sk->sk_shutdown, sk->sk_shutdown | RCV_SHUTDOWN);
 
 	cskb = skb;
 	if (skb_copy_datagram_msg(cskb, offset, msg, copied)) {
@@ -1665,16 +1665,28 @@ static int iucv_sock_shutdown(struct socket *sock, int how)
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
+		/* Set the bit and purge under sk_lock.slock: a frame handled
+		 * on arrival tests RCV_SHUTDOWN under it, also while this
+		 * task owns the socket, and one that passed the test would
+		 * be queued after the purge. A frame that waited runs when
+		 * the owner releases the socket, not in between.
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
@@ -2208,7 +2220,7 @@ static int afiucv_hs_callback_rx(struct sock *sk, struct sk_buff *skb)
 		return NET_RX_SUCCESS;
 	}
 
-	if (sk->sk_shutdown & RCV_SHUTDOWN) {
+	if (READ_ONCE(sk->sk_shutdown) & RCV_SHUTDOWN) {
 		kfree_skb(skb);
 		return NET_RX_SUCCESS;
 	}

-- 
2.56.0

