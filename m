From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 14 Nov 2026 20:29:26 -0500
Subject: [PATCH RFC net v4 8/8] net/iucv: return EOF to a reader parked
 when the peer closes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-b4-disp-fc0634a3-v4-8-f96c506447ce@proton.me>
References: <20261114-b4-disp-fc0634a3-v4-0-f96c506447ce@proton.me>
In-Reply-To: <20261114-b4-disp-fc0634a3-v4-0-f96c506447ce@proton.me>
To: Jakub Kicinski <kuba@kernel.org>, 
 Alexandra Winter <wintera@linux.ibm.com>, Paolo Abeni <pabeni@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, 
 Hidayath Khan <hidayath@linux.ibm.com>, Eric Dumazet <edumazet@kernel.org>
Cc: Thorsten Winkler <twinkler@linux.ibm.com>, 
 Simon Horman <horms@kernel.org>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nagamani PV <nagamani@linux.ibm.com>, 
 linux-s390@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794706158; l=5822;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=yIOjUD35xIhM54ZE3C8FaqEc5HDffS6PKYKVECGLmR0=;
 b=rBymyfyUcyjG3Oy/edHNWS5TOMVZqtlJLWmeiT2AQgAwf81q7l+BFB/qg2J2WG1ice9jU8+xe
 qFNVikQcAUlBoV6I2VUR48fFWkc1ltzQmkrXTMuzozAacTGX0d1F6yC
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A recvmsg() that starts after the peer closed returns 0. One that was
already waiting returns -ENOTCONN: its wait ends on sk_state and does
not ask whether anything is left to read. In a z/VM guest over
HiperSockets that was every parked reader, 13627 of 13627 on net-next
[1]. poll() does not report EPOLLRDHUP for the close either.

Return EOF from the wait too when the socket is IUCV_DISCONN with
nothing left to read. As for a call that starts afterwards, it does not
matter how the socket got there: the peer's FIN, a severed z/VM path, a
transmit error, a window update that could not be sent or the device
going down. EOF does not say that all the peer sent was read: a severed
z/VM path drops the messages not yet received, for either call. Set
RCV_SHUTDOWN where the HiperSockets FIN is applied, as TCP does: poll()
then reports EPOLLRDHUP and EPOLLRDNORM for the close, and EPOLLHUP if
the socket had shut down its own sending. The other ways still report
none of the three.

Fixes: 561e036006dc ("[AF_IUCV]: Implementation of a skb backlog queue")
Fixes: 3881ac441f64 ("af_iucv: add HiperSockets transport")
Reported-by: Hidayath Khan <hidayath@linux.ibm.com>
Closes: https://lore.kernel.org/netdev/82691101-92d7-4838-b16e-2e41a83f65d0@linux.ibm.com/
Link: https://lore.kernel.org/netdev/51a4a40a-f34b-4d41-b049-69aa53f4dcf5@linux.ibm.com/ [1]
Cc: stable@vger.kernel.org # 6.18.x
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
v4: unchanged, was 7/7. The last paragraph of v3's note is gone: since
2/8 the NETDEV_GOING_DOWN notifier no longer writes sk_shutdown, so it
cannot lose the RCV_SHUTDOWN of a FIN.
v3: this was 2/2 of v2. The EOF in the receive wait, which v2 had in
the lock patch, is here now, so both halves of one change in behaviour
are in one patch: the wait returns EOF, and the FIN sets RCV_SHUTDOWN.
v3: https://lore.kernel.org/netdev/20261110-b4-disp-2a6b4364-v3-7-35677b68e697@proton.me/

Each half covers what the other does not. RCV_SHUTDOWN at the FIN gives
the parked reader EOF and poll() EPOLLRDHUP on HiperSockets, but a z/VM
path severed under a sleeping reader sets no RCV_SHUTDOWN; the test in
the wait covers the sever and gives poll() nothing.

In the emulated setup:

- the peer closes under a reader, 40 cycles, half with the reader
  parked and half with the close racing its recv(): -ENOTCONN in 29 on
  net, 35 with 1/8 to 3/8 and 29 with 1/8 to 7/8; EOF in all 40 with
  this patch
- poll() after the peer's close, 10 cycles of three cases (nothing
  queued, a message unread, the socket's own SHUT_WR first): on those
  three kernels no EPOLLRDHUP in any of the 30 and no EPOLLHUP in the
  10 with SHUT_WR; with this patch each case reports what an AF_UNIX
  socketpair reports on the same kernel. With RCV_SHUTDOWN at the FIN
  taken out again the reader still gets EOF, from the wait, and poll()
  reports as before the patch
- a reader parked while its own interface goes down, or while a send of
  its own fails in the adapter (SBALF15 0x10), and a z/VM reader whose
  path is severed (emulated CP): -ENOTCONN on those three kernels, and
  again with the EOF taken out of the wait; EOF with this patch

The interface going down and the TX error change sk_state with no
socket lock, so the test in the wait looks at the receive queue again.
A test kernel has an mdelay() that holds the reader between its look
at the queue and its look at the state; a byte arrives and the
interface goes down in that time. The reader's call returns -ENOTCONN
and its next two the byte and EOF. With the receive queue left out of
the test the first call returns 0 with the byte still queued. FWIW net
returns -ENOTCONN the same way when the skb lands between its own two
tests, a narrower window. The window update that could not be sent is
by inspection.

After 6/8 the FIN is applied under sk_lock.slock on every path, by the
softirq with no owner or by the owner from release_cb, and 7/8 has
shutdown() write the same field under that lock.
---
 net/iucv/af_iucv.c | 18 +++++++++++++++---
 1 file changed, 15 insertions(+), 3 deletions(-)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index 7a55bf884bc7..dda039bf5158 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -75,6 +75,8 @@ static void afiucv_hs_synfin(struct sock *sk)
 static void afiucv_hs_fin(struct sock *sk)
 {
 	sk->sk_state = IUCV_DISCONN;
+	/* as a TCP FIN: EOF for a reader, EPOLLRDHUP for poll() */
+	WRITE_ONCE(sk->sk_shutdown, sk->sk_shutdown | RCV_SHUTDOWN);
 	sk->sk_state_change(sk);
 }
 
@@ -1398,8 +1400,9 @@ static void iucv_process_message_q(struct sock *sk)
  * then and ends the wait.
  *
  * Context: Process context, socket lock held; sleeps with it released.
- * Return: the skb, or NULL with @err set. At RCV_SHUTDOWN the caller
- * returns EOF whatever @err is.
+ * Return: the skb, or NULL with @err set: 0 if the connection is gone with
+ * nothing left to read and the call could still wait. At RCV_SHUTDOWN the
+ * caller returns EOF whatever @err is.
  */
 static struct sk_buff *iucv_sock_recv_skb(struct sock *sk, int flags, int *err)
 {
@@ -1417,7 +1420,16 @@ static struct sk_buff *iucv_sock_recv_skb(struct sock *sk, int flags, int *err)
 		if (!timeo)
 			break;
 		if (sk->sk_state != IUCV_CONNECTED) {
-			*err = -ENOTCONN;
+			/* disconnected and nothing left to read: EOF, as at
+			 * the top of iucv_sock_recvmsg()
+			 */
+			if (sk->sk_state == IUCV_DISCONN &&
+			    skb_queue_empty(&iucv_sk(sk)->backlog_skb_q) &&
+			    skb_queue_empty(&sk->sk_receive_queue) &&
+			    list_empty(&iucv_sk(sk)->message_q.list))
+				*err = 0;
+			else
+				*err = -ENOTCONN;
 			break;
 		}
 		if (signal_pending(current)) {

-- 
2.56.0

