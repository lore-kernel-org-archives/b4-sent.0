From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 22 Oct 2026 21:48:35 -0500
Subject: [PATCH net 2/2] net/iucv: do not count the SHT frame against the
 receive window
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-b4-disp-b35a9153-v1-2-d74645876195@proton.me>
References: <20261022-b4-disp-b35a9153-v1-0-d74645876195@proton.me>
In-Reply-To: <20261022-b4-disp-b35a9153-v1-0-d74645876195@proton.me>
To: Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Paolo Abeni <pabeni@redhat.com>, 
 Alexandra Winter <wintera@linux.ibm.com>, 
 Thorsten Winkler <twinkler@linux.ibm.com>
Cc: Nagamani PV <nagamani@linux.ibm.com>, netdev@vger.kernel.org, 
 Hidayath Khan <hidayath@linux.ibm.com>, linux-s390@vger.kernel.org, 
 Simon Horman <horms@kernel.org>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792723713; l=4563;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=i2rbsTWNsPxkALKc4wo0Z3Yr7FRV6c4RAQqhDeB17Fg=;
 b=mtTCIJJNIr4U6qmCd9HEdKATkm3vkTAtKDAhWC9QPaWKqVydR4TUzQTZy2PJ9p7KtsGlMeFbV
 14eVT0k2IsVDYlsv7FgsDhwgJRgLeTYYvsjviZvVuBLaNdrU8uPAwio
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
logged. A zero-length data frame sets RCV_SHUTDOWN, after which
afiucv_hs_callback_rx() drops every later data frame uncounted; the one
slot this patch no longer credits for it is lost like the slots of the
frames dropped after it.

Fixes: 82492a355fac ("af_iucv: add shutdown for HS transport")
Fixes: 800c5eb7b5eb ("af_iucv: change net_device handling for HS transport")
Reported-by: Sashiko <netdev-bot+sashiko@kernel.org>
Closes: https://lore.kernel.org/netdev/179183431327.434549.446348148837850426@kernel.org/
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Reproduced on s390x under QEMU TCG (net-next 8df0638138d3 and net
f4377bf85887, same result) with an emulated HiperSockets adapter under
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
below the window the SYN advertised. Hidayath's test for that [1] runs
against the rework's backlog budget and passes on net-next, where the
update after every read keeps msg_recv low; measured here with
SO_RCVBUF at its minimum, so that frames wait in backlog_skb_q, the
same conforming peer reaches this check (net-next: WARN and -EFAULT
after two of eight messages; with this patch -EFAULT without the
WARN). The rework keeps the advertised window in a field of its own
for that, and this patch only takes the WARN out of its way. That
iucv_sock_shutdown() sends an SHT on every call is a sender-side oddity
left alone here; the receiver has to cope with any peer.

[1] https://lore.kernel.org/netdev/51a4a40a-f34b-4d41-b049-69aa53f4dcf5@linux.ibm.com/
---
 net/iucv/af_iucv.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index 501e758c5e68..a5142081bb6a 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -1317,10 +1317,13 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
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

-- 
2.56.0

