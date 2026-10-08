From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 08 Oct 2026 01:12:42 -0500
Subject: [PATCH net v6 2/3] net/smc: bound the receive length to the RMB in
 smc_rx_recvmsg()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-b4-disp-f7cd3d96-v6-2-fba616c0920c@proton.me>
References: <20261008-b4-disp-f7cd3d96-v6-0-fba616c0920c@proton.me>
In-Reply-To: <20261008-b4-disp-f7cd3d96-v6-0-fba616c0920c@proton.me>
To: Sidraya Jayagond <sidraya@linux.ibm.com>, 
 "D. Wythe" <alibuda@linux.alibaba.com>, Eric Dumazet <edumazet@kernel.org>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Dust Li <dust.li@linux.alibaba.com>, 
 "David S. Miller" <davem@davemloft.net>, Paolo Abeni <pabeni@redhat.com>, 
 Jakub Kicinski <kuba@kernel.org>
Cc: Stefan Raspl <raspl@linux.ibm.com>, Tony Lu <tonylu@linux.alibaba.com>, 
 Hidayath Khan <hidayath@linux.ibm.com>, Ursula Braun <ubraun@linux.ibm.com>, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Simon Horman <horms@kernel.org>, linux-s390@vger.kernel.org, 
 linux-rdma@vger.kernel.org, Wen Gu <guwen@linux.alibaba.com>, 
 Wenjia Zhang <wenjia@linux.ibm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791439960; l=2562;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=8XnjAPiFNgdxFiS0DFFOhcMxeDcy1z+lQn/0VQ9GuIY=;
 b=7I7kwu5NazfzNT6J+sdQKH/rCbJKAYALX6Kh2/y9XgWtGogF+WOYCotdJ7zVI5v3xtQ9kdhGJ
 xTPyJKcNHT/CR0wSYh/fIIcDRG4C6f9qHCGOkz6v8ULmVAaqID7qj48
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

conn->bytes_to_rcv is accumulated in the receive tasklet from the peer's
wire-controlled producer cursor via smc_curs_diff(), whose
differing-wrap branch can exceed rmb_desc->len; a forged cursor drives
bytes_to_rcv past the RMB, and over many CDC messages overflows the
signed counter negative. smc_rx_recvmsg() reads it as the readable
length and does a wrap-around copy whose second chunk is not re-bounded
to rmb_desc->len, reading past the RMB into adjacent kernel memory and
returning it to the receiving process. The nearby readable >=
rmb_desc->len test only feeds SMC_STAT_RMB_RX_FULL on a separate earlier
read; it does not bound the copy.

Bound the readable length to rmb_desc->len at the consumer, treating a
negative (sign-overflowed) value as out of range too, so the copy can
never exceed the ring. This enforces the documented
0 <= bytes_to_rcv <= rmb_desc->len invariant where it is race-free
against the producer update in the tasklet; conforming peers are
unaffected.

Fixes: 952310ccf2d8 ("smc: receive data from RMBE")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
Reviewed-by: Dust Li <dust.li@linux.alibaba.com>
Reviewed-by: Sidraya Jayagond <sidraya@linux.ibm.com>
---
 net/smc/smc_rx.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/net/smc/smc_rx.c b/net/smc/smc_rx.c
index 197fddc6271f..f781d7229185 100644
--- a/net/smc/smc_rx.c
+++ b/net/smc/smc_rx.c
@@ -442,6 +442,18 @@ int smc_rx_recvmsg(struct smc_sock *smc, struct msghdr *msg,
 		/* initialize variables for 1st iteration of subsequent loop */
 		/* could be just 1 byte, even after waiting on data above */
 		readable = smc_rx_data_available(conn, peeked_bytes);
+		/* bytes_to_rcv is accumulated from the peer's wire-controlled
+		 * producer cursor; a forged cursor can drive it past the RMB,
+		 * or overflow the signed accumulator to a negative value across
+		 * many CDC messages (which a plain "> len" check would miss
+		 * before the size_t cast below turns it huge).  Bound it to the
+		 * RMB in either case so the wrap-around copy cannot run past
+		 * rmb_desc->len.  This enforces the documented
+		 * 0 <= bytes_to_rcv <= rmb_desc->len invariant at the consumer,
+		 * race-free against the producer update in the receive tasklet.
+		 */
+		if (readable < 0 || readable > conn->rmb_desc->len)
+			readable = conn->rmb_desc->len;
 		splbytes = atomic_read(&conn->splice_pending);
 		if (!readable || (msg && splbytes)) {
 			if (splbytes)

-- 
2.56.0

