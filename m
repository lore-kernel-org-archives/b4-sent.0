From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 23 Jul 2026 19:23:28 -0500
Subject: [PATCH net v5 2/3] net/smc: bound the receive length to the RMB in
 smc_rx_recvmsg()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-b4-disp-0d07164f-v5-2-6a9e235dbc4e@proton.me>
References: <20260723-b4-disp-0d07164f-v5-0-6a9e235dbc4e@proton.me>
In-Reply-To: <20260723-b4-disp-0d07164f-v5-0-6a9e235dbc4e@proton.me>
To: Sidraya Jayagond <sidraya@linux.ibm.com>, 
 Jakub Kicinski <kuba@kernel.org>, "D. Wythe" <alibuda@linux.alibaba.com>, 
 "David S. Miller" <davem@davemloft.net>, Wen Gu <guwen@linux.alibaba.com>, 
 Wenjia Zhang <wenjia@linux.ibm.com>, Eric Dumazet <edumazet@google.com>, 
 Tony Lu <tonylu@linux.alibaba.com>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Dust Li <dust.li@linux.alibaba.com>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-s390@vger.kernel.org, linux-rdma@vger.kernel.org, 
 Ursula Braun <ubraun@linux.ibm.com>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Stefan Raspl <raspl@linux.ibm.com>, 
 Simon Horman <horms@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784852606; l=2495;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=zm+DwFi/hrFlsMaixwWDBBXKLevUgGKVa9KJqBjGNh8=;
 b=1jKt0ih0NXm8Ad9+veJJYvSZ2OkqjzWmQHosnqe+bTJKHQ2WmWBmNifIbvfTRWtCWE3fZQgP8
 mWwjS5BIA8kCL2hQWENk1XVnk/1MFhjx8IuilEXmGOS8QqRffLCF1Nm
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

conn->bytes_to_rcv is accumulated in the receive tasklet from the
peer's wire-controlled producer cursor via smc_curs_diff(), whose
differing-wrap branch can exceed rmb_desc->len; a forged cursor drives
bytes_to_rcv past the RMB, and over many CDC messages overflows the
signed counter negative. smc_rx_recvmsg() reads it as the readable
length and does a wrap-around copy whose second chunk is not re-bounded
to rmb_desc->len, reading past the RMB into adjacent kernel memory and
disclosing it to the peer. The nearby readable >= rmb_desc->len test
only feeds SMC_STAT_RMB_RX_FULL on a separate earlier read; it does not
bound the copy.

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
---
 net/smc/smc_rx.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/net/smc/smc_rx.c b/net/smc/smc_rx.c
index c1d9b923938d..f461cf10b085 100644
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
2.55.0

