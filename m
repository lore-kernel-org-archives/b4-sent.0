From: Quanye Yang <quanyeyang@proton.me>
Date: Wed, 09 Sep 2026 10:40:49 +0800
Subject: [PATCH mptcp-next v3 2/2] mptcp: shrink struct
 mptcp_options_received
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260909-mptcp-shrink-opt-rx-v2-v3-2-92bb3009a665@proton.me>
References: <20260909-mptcp-shrink-opt-rx-v2-v3-0-92bb3009a665@proton.me>
In-Reply-To: <20260909-mptcp-shrink-opt-rx-v2-v3-0-92bb3009a665@proton.me>
To: MPTCP Linux <mptcp@lists.linux.dev>
Cc: Quanye Yang <quanyeyang@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788921669; l=2657;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=YpW1YW98fTieQNQguyspktoCp+D2q9Bq/4Xz1WxldUA=;
 b=HNol1HmkDp8gGW2N0KttaORjzWENHxPvnAi8R3DT4y04QijGCQxeWd7+t0KmhwQdRXQ/gne9N
 P/gDDszp6hVDzgwSpP4eKzeGio+0KUc01mmtZ7i7MXljfdw2Cj0TD3E
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

struct mptcp_options_received is allocated on the stack while parsing
incoming MPTCP options. Several suboptions are mutually exclusive, as
enforced by mptcp_parse_option(), so their payloads can overlap.

Group fields by suboption and place the mutually exclusive payloads in
an anonymous union. Keep DSS and rm_list outside the union: they can
be combined with other suboptions. Move join_id into the MP_JOIN
group, and overlap token, thmac and hmac inside that group.

Further shrinking would require changing the parser so currently
coexisting fields (DSS mapping vs ACK, rm_list, status flags) can
overlap. That adds complexity for little gain, since the outer union is
already dominated by the MP_JOIN / ADD_ADDR members.

This reduces the structure size from 136 to 72 bytes on x86_64.

Closes: https://github.com/multipath-tcp/mptcp_net-next/issues/625
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
 net/mptcp/protocol.h | 45 ++++++++++++++++++++++++++++-----------------
 1 file changed, 28 insertions(+), 17 deletions(-)

diff --git a/net/mptcp/protocol.h b/net/mptcp/protocol.h
index 04e1180012b9..534d052ec007 100644
--- a/net/mptcp/protocol.h
+++ b/net/mptcp/protocol.h
@@ -145,16 +145,13 @@ static inline bool before64(__u64 seq1, __u64 seq2)
 #define after64(seq2, seq1)	before64(seq1, seq2)
 
 struct mptcp_options_received {
-	u64	sndr_key;
-	union {
-		u64	rcvr_key;
-		u64	fc_recv_key;
+	struct { /* DSS, also used by MP_CAPABLE with data */
+		u64	data_ack;
+		u64	data_seq;
+		u32	subflow_seq;
+		u16	data_len;
+		__sum16	csum;
 	};
-	u64	data_ack;
-	u64	data_seq;
-	u32	subflow_seq;
-	u16	data_len;
-	__sum16	csum;
 	struct_group(status,
 		u16 suboptions;
 		u16 use_map:1,
@@ -170,15 +167,29 @@ struct mptcp_options_received {
 		    deny_join_id0:1,
 		    __unused:2;
 	);
-	u8	join_id;
-	u32	token;
-	u32	nonce;
-	u64	thmac;
-	u8	hmac[MPTCPOPT_HMAC_LEN];
-	struct mptcp_addr_info addr;
 	struct mptcp_rm_list rm_list;
-	u64	ahmac;
-	u64	fail_seq;
+	/* Options below are mutually exclusive, see mptcp_parse_option() */
+	union {
+		struct { /* MP_CAPABLE */
+			u64	sndr_key;
+			u64	rcvr_key;
+		};
+		struct { /* MP_JOIN */
+			u32	nonce;
+			u8	join_id;
+			union {
+				u32	token;			/* SYN */
+				u64	thmac;			/* SYN + ACK */
+				u8	hmac[MPTCPOPT_HMAC_LEN];	/* ACK */
+			};
+		};
+		struct { /* ADD_ADDR */
+			struct mptcp_addr_info addr;
+			u64	ahmac;
+		};
+		u64	fail_seq;	/* MP_FAIL */
+		u64	fc_recv_key;	/* MP_FASTCLOSE */
+	};
 };
 
 static inline __be32 mptcp_option(u8 subopt, u8 len, u8 nib, u8 field)

-- 
2.55.0

