From: Quanye Yang <quanyeyang@proton.me>
Date: Fri, 04 Sep 2026 11:08:33 +0800
Subject: [PATCH mptcp-next] mptcp: shrink struct mptcp_options_received
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260904-mptcp-shrink-opt-rx-v1-1-2d87ab9505ff@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/y2OQW7DIBBFr2KxLhXYTGKiqOo9qixgGCc0AbtAL
 EtR7l7iePn15/15D5Ypecrs0DxYotlnP8Ya5EfD8GLimbh3NbNWtDuhheJhKjjxfEk+Xvk4FZ4
 WTkMPvRxkC25glZwSDX5ZV3/YG4i0FHZ6d/lufwnLa3a7TvR3r6/LhliTieMYgi9VRTjYO+wAU
 GsSe2mk7gkEKgDRWSStlHOAr6lAOZvV+dAcN+VuUw7ech9nc1utZ8kF75UB6BCgtbvvK6VIt88
 xnb/Y6fn8B9vGUFYaAQAA
X-Change-ID: 20260904-mptcp-shrink-opt-rx-ef8581f125df
To: MPTCP Linux <mptcp@lists.linux.dev>
Cc: Quanye Yang <quanyeyang@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788491322; l=2103;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=1B+1XumgR9LhmxTgiEsBwIPrCKh6bLV+MlAgeHF3ilY=;
 b=6maB2qmgVUN5tItUCYFpsStaBgnYO//ht5tuTdzUjbvIVH/T8fHdLScBmfaEBDy4FYCYgIjgC
 21XCdaUiOhCCZqKjdOL7fx3klf9xM5CNdeLDLbI8ral11A0a3fQdmKc
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

struct mptcp_options_received is allocated on the stack while parsing
incoming MPTCP options.

The sender key, MP_JOIN fields, ADD_ADDR fields and MP_FAIL sequence
number are mutually exclusive, as enforced by mptcp_parse_option().
Place them in an anonymous union while keeping the existing field
access unchanged.

This reduces the structure size from 136 to 88 bytes on x86_64.

Closes: https://github.com/multipath-tcp/mptcp_net-next/issues/625
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
 net/mptcp/protocol.h | 23 +++++++++++++++--------
 1 file changed, 15 insertions(+), 8 deletions(-)

diff --git a/net/mptcp/protocol.h b/net/mptcp/protocol.h
index 739f9006c1e1..6646c428dbdf 100644
--- a/net/mptcp/protocol.h
+++ b/net/mptcp/protocol.h
@@ -142,7 +142,6 @@ static inline bool before64(__u64 seq1, __u64 seq2)
 #define after64(seq2, seq1)	before64(seq1, seq2)
 
 struct mptcp_options_received {
-	u64	sndr_key;
 	u64	rcvr_key;
 	u64	data_ack;
 	u64	data_seq;
@@ -166,14 +165,22 @@ struct mptcp_options_received {
 		    __unused:1;
 	);
 	u8	join_id;
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
+		u64 sndr_key;
+		struct {
+			u32 token;
+			u32 nonce;
+			u64 thmac;
+			u8 hmac[MPTCPOPT_HMAC_LEN];
+		};
+		struct {
+			struct mptcp_addr_info addr;
+			u64 ahmac;
+		};
+		u64 fail_seq;
+	};
 };
 
 static inline __be32 mptcp_option(u8 subopt, u8 len, u8 nib, u8 field)

---
base-commit: 10d57dc355c99e071a198e50c45503bce944dd5c
change-id: 20260904-mptcp-shrink-opt-rx-ef8581f125df
prerequisite-message-id: <20260903-mptcp-mib-inval-opt-v1-0-84a553c552b6@kernel.org>
prerequisite-patch-id: 7f8decba16ce568283eaa86b23cd93b183aaa675
prerequisite-patch-id: c8fedc4ff2b5997f716dac0c30ec7620ecf11fc0
prerequisite-patch-id: 5abea779f2b0af347cd88d6b65bfc3b9eefff405

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

