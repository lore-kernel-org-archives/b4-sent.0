From: Quanye Yang <quanyeyang@proton.me>
Date: Thu, 15 Oct 2026 03:55:56 -0700
Subject: [PATCH mptcp-net] mptcp: annotate lockless access to
 msk->scaling_ratio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-t-mptcp-scaling-ratio-kcsan-v1-1-db146f55802e@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWM3QqDMAxGX0VyvYAtKGyvMnZRY6rZTyxNNwbiu
 6/Ty8P3nbOCcRY2uDQrZP6IyaIV3KkBmoNOjDJWBt/63rWuw4KvVCihUXiKTphDkQUfZEHx7OL
 gY9fX7wi1kDJH+e71KxyacoHbMdl7uDOVfx227QdsgdF2igAAAA==
X-Change-ID: 20261015-t-mptcp-scaling-ratio-kcsan-91fb2f56026d
To: MPTCP Linux <mptcp@lists.linux.dev>
Cc: "Matthieu Baerts (NGI0)" <matttbe@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792061772; l=4285;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=8/wCmek6QpqJ6/27La2REeAeeu9Zw7HssTgVJ+KVrtI=;
 b=DU3njxwwvsU0a5FOPuR/faxP9ksJ/JNq3OTaJbNN1420iRn3Se2LjG8Ep5kRaRMalaxWqHFQp
 wMxvhVd5+BEBUWbuT3DU81xIuwflLzsRTJ2G/A5bljnM4a7WWetSF3H
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mptcp_rcv_rtt_update() writes msk->scaling_ratio from BH while holding
the msk data lock (sk->sk_lock.slock). mptcp_cleanup_rbuf() reads the
same byte via mptcp_win_from_space() after mptcp_release_cb() drops
that lock, so it can run concurrently with the RX path.

KCSAN reports:

  BUG: KCSAN: data-race in mptcp_cleanup_rbuf / mptcp_data_ready

  write to 0xffff888014978790 of 1 bytes by interrupt on cpu 1:
   mptcp_rcv_rtt_update net/mptcp/protocol.c:1045 [inline]
   mptcp_data_ready+0x1c1/0x4d0 net/mptcp/protocol.c:1062
   subflow_data_ready+0x271/0x350 net/mptcp/subflow.c:1536
   tcp_data_ready+0x92/0x2c0 net/ipv4/tcp_input.c:5604
   tcp_data_queue+0x1236/0x26c0 net/ipv4/tcp_input.c:5694
   tcp_rcv_established+0x695/0x1fb0 net/ipv4/tcp_input.c:6689
   tcp_v4_do_rcv+0x356/0x6e0 net/ipv4/tcp_ipv4.c:1854
   tcp_v4_rcv+0x1b04/0x26b0 net/ipv4/tcp_ipv4.c:2248

  read to 0xffff888014978790 of 1 bytes by task 2624 on cpu 0:
   mptcp_win_from_space net/mptcp/protocol.h:421 [inline]
   __mptcp_space net/mptcp/protocol.h:431 [inline]
   mptcp_cleanup_rbuf+0x8a/0x380 net/mptcp/protocol.c:680
   mptcp_release_cb+0x375/0x900 net/mptcp/protocol.c:3889
   release_sock+0x100/0x150 net/core/sock.c:3866
   sk_wait_data+0x141/0x2f0 net/core/sock.c:3314
   mptcp_recvmsg+0x6cd/0xd50 net/mptcp/protocol.c:2496

  value changed: 0xd0 -> 0xd5

  Reported by Kernel Concurrency Sanitizer on:
  CPU: 0 UID: 0 PID: 2624 Comm: syz.7.22 Not tainted 7.3.0-rc1-gbaff4b3d06ef #77 PREEMPT(full)

The u8 EWMA is used only to convert sk_rcvbuf occupancy into an
advertised window. A slightly stale ratio is acceptable, so annotate
the lockless accesses with READ_ONCE()/WRITE_ONCE() instead of
widening the data lock. Do the same in mptcp_space_from_win(), which
reads the same field from DRS and SO_RCVLOWAT.

Fixes: d2000361e4dd ("mptcp: better mptcp-level RTT estimator")
Reported-by: Matthieu Baerts (NGI0) <matttbe@kernel.org>
Closes: https://github.com/multipath-tcp/mptcp_net-next/issues/634
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
 net/mptcp/protocol.c | 11 ++++++++---
 net/mptcp/protocol.h |  6 ++++--
 2 files changed, 12 insertions(+), 5 deletions(-)

diff --git a/net/mptcp/protocol.c b/net/mptcp/protocol.c
index 05c38564e8fd..ffd22849b719 100644
--- a/net/mptcp/protocol.c
+++ b/net/mptcp/protocol.c
@@ -988,6 +988,7 @@ static void mptcp_rcv_rtt_update(struct mptcp_sock *msk,
 {
 	const struct tcp_sock *tp = tcp_sk(subflow->tcp_sock);
 	u32 rtt_us = tp->rcv_rtt_est.rtt_us;
+	u8 scaling_ratio;
 	int id;
 
 	/* Update once per subflow per rcvwnd to avoid touching the msk
@@ -1004,9 +1005,13 @@ static void mptcp_rcv_rtt_update(struct mptcp_sock *msk,
 	if (++msk->rcv_rtt_est.next_sample == MPTCP_RTT_SAMPLES)
 		msk->rcv_rtt_est.next_sample = 0;
 
-	/* EWMA among the incoming subflows */
-	msk->scaling_ratio = ((msk->scaling_ratio << 3) - msk->scaling_ratio +
-			     tp->scaling_ratio) >> 3;
+	/* EWMA among the incoming subflows.
+	 * Pairs with READ_ONCE() in mptcp_win_from_space().
+	 */
+	scaling_ratio = READ_ONCE(msk->scaling_ratio);
+	WRITE_ONCE(msk->scaling_ratio,
+		   ((scaling_ratio << 3) - scaling_ratio +
+		    tp->scaling_ratio) >> 3);
 }
 
 void mptcp_data_ready(struct sock *sk, struct sock *ssk)
diff --git a/net/mptcp/protocol.h b/net/mptcp/protocol.h
index 4ed598febbf0..11e3c6db5e53 100644
--- a/net/mptcp/protocol.h
+++ b/net/mptcp/protocol.h
@@ -417,12 +417,14 @@ static inline void msk_owned_by_me(const struct mptcp_sock *msk)
 
 static inline int mptcp_win_from_space(const struct sock *sk, int space)
 {
-	return __tcp_win_from_space(mptcp_sk(sk)->scaling_ratio, space);
+	return __tcp_win_from_space(READ_ONCE(mptcp_sk(sk)->scaling_ratio),
+				    space);
 }
 
 static inline int mptcp_space_from_win(const struct sock *sk, int win)
 {
-	return __tcp_space_from_win(mptcp_sk(sk)->scaling_ratio, win);
+	return __tcp_space_from_win(READ_ONCE(mptcp_sk(sk)->scaling_ratio),
+				    win);
 }
 
 static inline int __mptcp_space(const struct sock *sk)

---
base-commit: a22035be824449c4921ec406f6383089016a628c
change-id: 20261015-t-mptcp-scaling-ratio-kcsan-91fb2f56026d

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

