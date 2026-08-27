From: Charles Vosburgh <theminershive@gmail.com>
Date: Wed, 26 Aug 2026 21:01:30 -0400
Subject: [PATCH net] sctp: validate chunk length in the inqueue parser
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260826-sctp-zero-chunk-inqueue-v1-1-86769dcc7f8c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAGmMj2oC/yWMwQ6CMBAFf4Xs2U2wkUr8FeMBlqesJgW7LTES/
 t2qx5lkZiVDVBidqpUiFjWdQoH9riIZu3AD61CYXO183TrPJmnmN+LEMubwYA3PjAzuD8d2kK5
 pnHgq9Rxx1dfvfKaARJe/tNzfIen7pG37AMBtY+GAAAAA
X-Change-ID: 20260826-sctp-zero-chunk-inqueue-b478dca552c6
To: Marcelo Ricardo Leitner <marcelo.leitner@gmail.com>, 
 Xin Long <lucien.xin@gmail.com>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Vlad Yasevich <vladislav.yasevich@hp.com>
Cc: linux-sctp@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, security@kernel.org, 
 Charles Vosburgh <theminershive@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787792493; l=2767;
 i=theminershive@gmail.com; s=20260727; h=from:subject:message-id;
 bh=vMqw/cZjBCZMhglW7zLT3gwURYELJivbP13I5N01yIA=;
 b=AmMthM08XUQ5X5Ww1jjqDX9nET7jygzPCTaHbOa8fI2r79rQo6SpJ45SG3itooGWFrAhE2fma
 bP9tGswl6nJDoONJJV1u1R8Ugp+D1++c0DcsIn5EUbQuFbpRVESWpsN
X-Developer-Key: i=theminershive@gmail.com; a=ed25519;
 pk=kxCwp20gY82hL3ixb5IXlZ2N0X9TDxiKPCpjPcWqN3E=
X-Endpoint-Received: by B4 Relay for theminershive@gmail.com/20260727 with auth_id=977
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SCTP chunks always include a four-byte generic header, but
sctp_inq_pop() currently accepts shorter declared lengths. A zero-length
chunk leaves chunk_end at the current header.

When ASCONF is covered by the association's SCTP-AUTH policy,
sctp_assoc_bh_rcv() can continue before the state machine performs its
normal chunk-length check. sctp_inq_pop() then returns the same malformed
chunk repeatedly and the receive softirq can lock up.

A remote SCTP peer can trigger this after establishing an association on
a kernel built with CONFIG_IP_SCTP and configured with
net.sctp.addip_enable=1 and net.sctp.auth_enable=1. The reproducer did
not require application credentials, a shared SCTP AUTH key, or
net.sctp.addip_noauth_enable=1.

On commit f967455fb2a5 ("seg6: reset IP6CB after IPv6 decapsulation"),
one zero-length ASCONF caused repeated
watchdog soft-lockup reports in a two-vCPU KVM guest. All 3 pre-trigger
health probes succeeded, while 36 of 37 post-trigger probes failed. With
this change, all 37 post-trigger probes succeeded and no equivalent
soft-lockup signature appeared.

Reject chunks shorter than the generic SCTP header at the shared inqueue
parser boundary. Mark the packet for discard before either caller can
continue processing it, while preserving the four-byte generic minimum.
Declared-length 1 through 4 controls and kernel-generated ASCONF traffic
remained healthy. The patched sctp_hello selftest passed for IPv4 and
IPv6.

The complete private reproducer and validation evidence are available
directly to maintainers on request.

Fixes: bbd0d59809f9 ("[SCTP]: Implement the receive and verification of AUTH chunk")
Cc: stable@vger.kernel.org
Assisted-by: ChatGPT:GPT-5.6-Sol
Assisted-by: Vantix:claude-opus-5
Assisted-by: Codex:GPT-5
Signed-off-by: Charles Vosburgh <theminershive@gmail.com>
---
 net/sctp/inqueue.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/net/sctp/inqueue.c b/net/sctp/inqueue.c
index 5f988b3a8814..12a46868165a 100644
--- a/net/sctp/inqueue.c
+++ b/net/sctp/inqueue.c
@@ -212,6 +212,11 @@ struct sctp_chunk *sctp_inq_pop(struct sctp_inq *queue)
 	chunk->chunk_end = ((__u8 *)ch) + SCTP_PAD4(ntohs(ch->length));
 	skb_pull(chunk->skb, sizeof(*ch));
 	chunk->subh.v = NULL; /* Subheader is no longer valid.  */
+	if (unlikely(ntohs(ch->length) < sizeof(*ch))) {
+		chunk->pdiscard = 1;
+		chunk->chunk_end = chunk->skb->data;
+		return chunk;
+	}
 
 	if (chunk->chunk_end + sizeof(*ch) <= skb_tail_pointer(chunk->skb)) {
 		/* This is not a singleton */

---
base-commit: f967455fb2a5a2079b9eb5823e9ccf359174bf9f
change-id: 20260826-sctp-zero-chunk-inqueue-b478dca552c6

Best regards,
--  
Charles Vosburgh <theminershive@gmail.com>

