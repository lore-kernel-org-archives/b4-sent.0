From: Mark Amirkan <markdamirkan@gmail.com>
Date: Sun, 13 Sep 2026 10:31:08 +0000
Subject: [PATCH net] net/packet: avoid truncating TPACKET_V3 private size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260913-b4-send-packet-private-v1-1-925eab2cd388@gmail.com>
X-B4-Tracking: v=1; b=H4sIAGx7pmoC/yWMzQrCMBAGX6Xs2YU01mJ9FekhP5+6CjFkYxFK3
 92oxxmYWUlRBEqnbqWCRVSeqUG/6yjcXLqCJTYma+xopn7PfmBFipxdeKByLrK4Ch6m6H00R2f
 HA7U4F1zk/RufKaHS/Jf68neE+l3Stn0A6apwK38AAAA=
X-Change-ID: 20260913-b4-send-packet-private-49dbbd08a265
To: Willem de Bruijn <willemdebruijn.kernel@gmail.com>, 
 netdev@vger.kernel.org
Cc: linux-kernel@vger.kernel.org, Paolo Abeni <pabeni@redhat.com>, 
 Eric Dumazet <edumazet@google.com>, Simon Horman <horms@kernel.org>, 
 Chetan Loke <loke.chetan@gmail.com>, Jakub Kicinski <kuba@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789295487; l=1549;
 i=markdamirkan@gmail.com; s=pscsi-20260818; h=from:subject:message-id;
 bh=Xrbgrj2e+0VtiEmFZJKiwvN6mF1r9zb2KOZmKfHcoEo=;
 b=ViISPkrNOzUErHhzk7g0veNyTTw2KwI8ocX+cBTB3PYd/mydDVg8fT9d6MYU0RCIejslPrWW8
 Rdbb50RwMGhARgPIOKVxfjIlFowy/+OU3YfRnddMS0s6UKzqsQffI0/
X-Developer-Key: i=markdamirkan@gmail.com; a=ed25519;
 pk=/wb49ibt4gZFDncmhFQBYtjPvzT1tfJtvK4Mqt1P2Wc=
X-Endpoint-Received: by B4 Relay for markdamirkan@gmail.com/pscsi-20260818 with auth_id=961
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tpacket_req3.tp_sizeof_priv is an unsigned int, and packet_set_ring()
validates the full value against the block size.  init_prb_bdqc() then
stores it in the unsigned short blk_sizeof_priv field.

Commit 2b6867c2ce76 ("net/packet: fix overflow in check for priv area
size") fixed the validation arithmetic, but an accepted value above
USHRT_MAX still narrows when it is stored.

For a 131072-byte block, tp_sizeof_priv=65536 is valid.  The narrowing
makes offset_to_first_pkt 48 instead of 65584, so packet records can be
placed in the private area that userspace asked the kernel to preserve.

blk_sizeof_priv is internal state, so widen it to hold the validated
UAPI value.

Fixes: f6fb8f100b80 ("af-packet: TPACKET_V3 flexible buffer implementation.")
Cc: stable@vger.kernel.org
Assisted-by: Symbolic
Signed-off-by: Mark Amirkan <markdamirkan@gmail.com>
---
 net/packet/internal.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/net/packet/internal.h b/net/packet/internal.h
index b76e645cd7..f5c8cd0eed 100644
--- a/net/packet/internal.h
+++ b/net/packet/internal.h
@@ -21,7 +21,7 @@ struct tpacket_kbdq_core {
 	unsigned int	hdrlen;
 	unsigned char	reset_pending_on_curr_blk;
 	unsigned short	kactive_blk_num;
-	unsigned short	blk_sizeof_priv;
+	unsigned int	blk_sizeof_priv;
 
 	unsigned short  version;
 

---
base-commit: e6b6078ea1731b05b3b552497b3bce4bf8b014ae
change-id: 20260913-b4-send-packet-private-49dbbd08a265

Best regards,
--  
Mark Amirkan <markdamirkan@gmail.com>

