From: Quanye Yang <quanyeyang@proton.me>
Date: Wed, 09 Sep 2026 10:40:48 +0800
Subject: [PATCH mptcp-next v3 1/2] mptcp: split FASTCLOSE key from rcvr_key
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260909-mptcp-shrink-opt-rx-v2-v3-1-92bb3009a665@proton.me>
References: <20260909-mptcp-shrink-opt-rx-v2-v3-0-92bb3009a665@proton.me>
In-Reply-To: <20260909-mptcp-shrink-opt-rx-v2-v3-0-92bb3009a665@proton.me>
To: MPTCP Linux <mptcp@lists.linux.dev>
Cc: Quanye Yang <quanyeyang@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788921669; l=1863;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=WgO2+QmzY+V2+nRfgV9IITy5E0MZHT50sASW65x//nA=;
 b=t4B3slwt+WfonG2ETHDAAIRxtRgS9VSCQp08CJbdUiAdIxq9XLYetnF0epjkLnrhDWjlBe1SI
 3W+XzB4T1E1AjrfUW2mpPMLA6gYdodrS0+EqHoOnfE2cl6KXlLnowHb
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MP_CAPABLE and MP_FASTCLOSE both stored their key in rcvr_key. Give
FASTCLOSE a dedicated fc_recv_key overlapped with rcvr_key in a union.

This helps shrink struct mptcp_options_received.

Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
 net/mptcp/options.c  | 6 +++---
 net/mptcp/protocol.h | 5 ++++-
 2 files changed, 7 insertions(+), 4 deletions(-)

diff --git a/net/mptcp/options.c b/net/mptcp/options.c
index f87707110c75..943b2b37eaae 100644
--- a/net/mptcp/options.c
+++ b/net/mptcp/options.c
@@ -374,10 +374,10 @@ static void mptcp_parse_option(const struct sk_buff *skb,
 			break;
 
 		ptr += 2;
-		mp_opt->rcvr_key = get_unaligned_be64(ptr);
+		mp_opt->fc_recv_key = get_unaligned_be64(ptr);
 		ptr += 8;
 		mp_opt->suboptions |= OPTION_MPTCP_FASTCLOSE;
-		pr_debug("MP_FASTCLOSE: recv_key=%llu\n", mp_opt->rcvr_key);
+		pr_debug("MP_FASTCLOSE: fc_recv_key=%llu\n", mp_opt->fc_recv_key);
 		break;
 
 	case MPTCPOPT_RST:
@@ -1259,7 +1259,7 @@ bool mptcp_incoming_options(struct sock *sk, struct sk_buff *skb)
 
 	if (unlikely(mp_opt.suboptions != OPTION_MPTCP_DSS)) {
 		if ((mp_opt.suboptions & OPTION_MPTCP_FASTCLOSE) &&
-		    READ_ONCE(msk->local_key) == mp_opt.rcvr_key) {
+		    READ_ONCE(msk->local_key) == mp_opt.fc_recv_key) {
 			WRITE_ONCE(msk->rcv_fastclose, true);
 			mptcp_schedule_work((struct sock *)msk);
 			MPTCP_INC_STATS(sock_net(sk), MPTCP_MIB_MPFASTCLOSERX);
diff --git a/net/mptcp/protocol.h b/net/mptcp/protocol.h
index b3121c8c766b..04e1180012b9 100644
--- a/net/mptcp/protocol.h
+++ b/net/mptcp/protocol.h
@@ -146,7 +146,10 @@ static inline bool before64(__u64 seq1, __u64 seq2)
 
 struct mptcp_options_received {
 	u64	sndr_key;
-	u64	rcvr_key;
+	union {
+		u64	rcvr_key;
+		u64	fc_recv_key;
+	};
 	u64	data_ack;
 	u64	data_seq;
 	u32	subflow_seq;

-- 
2.55.0

