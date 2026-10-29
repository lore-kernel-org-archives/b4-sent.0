From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Wed, 28 Oct 2026 23:46:22 -0500
Subject: [PATCH net v2 2/2] net/iucv: do not count the SHT frame against
 the receive window
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-b4-disp-dd3e4ebb-v2-2-3747658d59bd@proton.me>
References: <20261028-b4-disp-dd3e4ebb-v2-0-3747658d59bd@proton.me>
In-Reply-To: <20261028-b4-disp-dd3e4ebb-v2-0-3747658d59bd@proton.me>
To: Thorsten Winkler <twinkler@linux.ibm.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Alexandra Winter <wintera@linux.ibm.com>, 
 Eric Dumazet <edumazet@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-s390@vger.kernel.org, Nagamani PV <nagamani@linux.ibm.com>, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 Hidayath Khan <hidayath@linux.ibm.com>, Simon Horman <horms@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793249180; l=7444;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=5EMk432P/UMaeugCCbU0fxxarhsaJIaFUH4BOp7jRYk=;
 b=rutzQPSiZ8fsqEQv7zQDzPzZCwsALCPazPNLc8QqGWrKnU92E2h8rIK0pej/eyneIohSm5Znu
 BzLrcnW3sslCvbqQnsW5bg9EVAJaRrCEAtJ7yaW6Konhm3ZBuUUaLXJ
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

iucv_sock_recvmsg() counts every HiperSockets frame it consumes in
msg_recv, the SHT's empty one included, while the peer counts only what
sendmsg() sends against the window it was granted; the SHT goes out
through iucv_send_ctrl() uncounted, one per shutdown(SHUT_WR) call. The
next window update zeroes msg_recv and takes the surplus with it, but
recvmsg() sends none while frames wait in backlog_skb_q, and an SHT read
in that state pushes msg_recv past msglimit: WARN_ON(1) fires, the socket
is closed and the reader gets -EFAULT instead of EOF. A peer that sends
past its window reaches the same WARN from the network; with
panic_on_warn that is a remote panic. The SHT frame dates from
82492a355fac, the WARN and the close from 800c5eb7b5eb.

The SHT reaches recvmsg() as a zero-length frame, like a zero-length
data frame, so test the length: count only frames that still carry
data when the read consumes them (rlen; a partial SOCK_STREAM read
requeues above this point, so each data frame counts once), and close a
socket over the window without the WARN; -EFAULT is kept and nothing is
logged. A zero-length data frame that reaches recvmsg() sets
RCV_SHUTDOWN, after which afiucv_hs_callback_rx() drops every later
data frame uncounted; the one slot this patch no longer credits for it
is lost like the slots of the frames dropped after it.

The close over the window purges backlog_skb_q, not sk_receive_queue,
and nothing resets msg_recv; once empty frames are not counted, a read
of an empty frame from that queue after the close would skip the
-EFAULT branch and reach the window update, where iucv_send_ctrl()
sizes the skb through the cleared hs_dev. Send the update only while
the socket is connected.

Tested on s390x under QEMU TCG with a patched QEMU: an emulated
HiperSockets adapter under the real qeth and qdio drivers. An SHT read
with frames waiting in backlog_skb_q returns EOF instead of -EFAULT, and
a read after the close over the window attempts no window update.

Fixes: 82492a355fac ("af_iucv: add shutdown for HS transport")
Fixes: 800c5eb7b5eb ("af_iucv: change net_device handling for HS transport")
Reported-by: Sashiko <netdev-bot+sashiko@kernel.org>
Closes: https://lore.kernel.org/netdev/179183431327.434549.446348148837850426@kernel.org/
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
v2: the window update goes out only while the socket is connected. The
AI review of v1 found that, once empty frames are not counted, a read
from sk_receive_queue after the close over the window skips the -EFAULT
branch and reaches iucv_send_ctrl() with hs_dev NULL:
LL_RESERVED_SPACE() reads through the NULL pointer (lowcore on s390: no
fault on a default boot, an oops with a relocated lowcore),
afiucv_hs_send() fails with -ENODEV and recvmsg() moves the closed
socket to IUCV_DISCONN. Repro on the same machine with SO_MSGLIMIT 2 and
SO_RCVBUF 6144: the peer sends 1 byte twice (the window), then from a
tap on its interface one data frame over the window, its SHUT_WR for the
SHT, and 16 more data frames behind it, so that no read sends an update
before the close (a Linux peer blocks at the window; the overrun is
injected). The third read closes the socket, the fourth returns
-ECONNRESET, the fifth consumes the SHT, the sixth takes a data frame
behind it and closes again. On v1 the probe counts one iucv_send_ctrl()
entry after the close and the adapter sees no frame leave; with this
version there is none. The reads are the same on both (1, 1, -EFAULT,
-ECONNRESET, 0, -EFAULT), IOW nothing shows from user space on a default
boot; net without the patch reads -EFAULT at the SHT with its WARN.

Also in v2, the commit message now says "a zero-length data frame that
reaches recvmsg()": a zero-length send with a piggybacked credit is a
window update to afiucv_hs_rcv() and never reaches recvmsg(), so the
sentence did not hold for it.

Reproduced on s390x under QEMU TCG (net f4377bf85887 and net-next
8df0638138d3, same result) with an emulated HiperSockets adapter under
the real qeth and qdio drivers: the reader has SO_MSGLIMIT 2 and
SO_RCVBUF 2304 (the minimum); the peer sends 1 byte twice, which fills
the window, then calls shutdown(SHUT_WR) 32 times, one SHT each. The
reader starts once everything has arrived; the receive queue took two
frames, the rest wait in backlog_skb_q, and with that queue non-empty
recvmsg() sends no window update, so the first SHT read counts 3
against a limit of 2: WARN and -EFAULT without the patch, EOF with it.
With one SHT instead of 32 the queue drains, the update goes out after
the two reads, and both kernels read EOF.

Without the patch, the surplus a window update carries for a counted
SHT is credit the peer never spent, and it takes the peer's msg_sent
below zero; harmless, since a peer that sent an SHT has SEND_SHUTDOWN
and its sendmsg() returns -EPIPE. With the patch no SHT is counted, so
no update carries that surplus.

A HiperSockets socket stays in IUCV_BOUND from its SYN until the SYN|ACK
arrives, and SO_MSGLIMIT is accepted in that state, so msglimit can drop
below the window the SYN advertised. Hidayath's test for that [1],
written for the per-socket backlog budget of the socket-locking rework
[2], passes on bare net-next, where the update after every read keeps
msg_recv low; measured here with SO_RCVBUF at its minimum, so that
frames wait in backlog_skb_q, the same conforming peer reaches this
check (net-next: WARN and -EFAULT after two of eight messages; with this
patch -EFAULT without the WARN). The rework keeps the advertised window
in a field of its own for that, and this patch only takes the WARN out
of its way. That iucv_sock_shutdown() sends an SHT on every call is a
sender-side oddity left alone here; the receiver has to cope with any
peer.

[1] https://lore.kernel.org/netdev/51a4a40a-f34b-4d41-b049-69aa53f4dcf5@linux.ibm.com/
[2] https://lore.kernel.org/netdev/20261022-b4-disp-1d26b87a-v2-0-7ee1264d812a@proton.me/
---
 net/iucv/af_iucv.c | 13 ++++++++++---
 1 file changed, 10 insertions(+), 3 deletions(-)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index 5bab6aea910e..266563fb0e0c 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -1325,10 +1325,13 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 		}
 
 		consume_skb(skb);
-		if (iucv->transport == AF_IUCV_TRANS_HIPER) {
+		/* The peer counts only the data it sends against its window;
+		 * the SHT's empty frame is not among them. Over the window,
+		 * close without a WARN: a peer reaches this from the network.
+		 */
+		if (iucv->transport == AF_IUCV_TRANS_HIPER && rlen) {
 			atomic_inc(&iucv->msg_recv);
 			if (atomic_read(&iucv->msg_recv) > iucv->msglimit) {
-				WARN_ON(1);
 				iucv_sock_close(sk);
 				return -EFAULT;
 			}
@@ -1357,7 +1360,11 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 		}
 		spin_unlock_bh(&iucv->message_q.lock);
 
-		if (send_win) {
+		/* iucv_sock_close() clears hs_dev but leaves sk_receive_queue
+		 * readable: a frame read after the over-window close must not
+		 * send a window update.
+		 */
+		if (send_win && sk->sk_state == IUCV_CONNECTED) {
 			err = iucv_send_ctrl(sk, AF_IUCV_FLAG_WIN);
 			if (err) {
 				sk->sk_state = IUCV_DISCONN;

-- 
2.56.0

