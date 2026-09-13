From: Mark Amirkan <markdamirkan@gmail.com>
Date: Sun, 13 Sep 2026 10:28:08 +0000
Subject: [PATCH net] net/packet: clear RX owner on VNET header error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260913-b4-send-packet-vnet-v1-1-5545ffb528ae@gmail.com>
X-B4-Tracking: v=1; b=H4sIALh6pmoC/yWMwQqDMBBEf0Xm3AWNQbG/UnpI4tpuC6lkVQriv
 3fbXgbeMPN2KBdhxbnaUXgTlVc2aE4V0j3kG5OMxnC16+qhaSl6Us4jzSE9eaEtW7Qu+n7ofOj
 TBHvOhSd5/6wX2ADXf6lrfHBavj4cxwegs1g/fAAAAA==
X-Change-ID: 20260913-b4-send-packet-vnet-32b47964a7cf
To: Willem de Bruijn <willemdebruijn.kernel@gmail.com>, 
 netdev@vger.kernel.org
Cc: Paolo Abeni <pabeni@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, linux-kernel@vger.kernel.org, 
 Jakub Kicinski <kuba@kernel.org>, Jon Rosen <jrosen@cisco.com>, 
 Simon Horman <horms@kernel.org>, Eric Dumazet <edumazet@google.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789295303; l=1552;
 i=markdamirkan@gmail.com; s=pscsi-20260818; h=from:subject:message-id;
 bh=SpkUVWFs7UgiCwTRaWHfiD7eoNnej/IW1o2498FsgqQ=;
 b=PFXW4r/vjPDIxLlvD/wYPWPn7lQoJpU/6skFOK8D3zB9pvEu4uwHHa2q741VwUVdX3bjXuOuk
 FkLst3L+WbXCxAtAJx+ywUIIDKrdiyCjqbOFv6anzkZVNinY1hr8JZb
X-Developer-Key: i=markdamirkan@gmail.com; a=ed25519;
 pk=/wb49ibt4gZFDncmhFQBYtjPvzT1tfJtvK4Mqt1P2Wc=
X-Endpoint-Received: by B4 Relay for markdamirkan@gmail.com/pscsi-20260818 with auth_id=961
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 61fad6816fc1 ("net/packet: tpacket_rcv: avoid a producer race
condition") added rx_owner_map and made tpacket_rcv() claim a V1 or V2
ring slot before converting the virtio-net header.  If the conversion
fails, the drop path leaves the slot claimed.

With a one-frame TPACKET_V2 ring, an unsupported UDP GSO packet leaves
the only slot unavailable, so the ring also drops the next valid packet.

Clear the ownership bit on this error path.  TPACKET_V3 already clears
its block state here.

Fixes: 61fad6816fc1 ("net/packet: tpacket_rcv: avoid a producer race condition")
Cc: stable@vger.kernel.org
Assisted-by: Symbolic
Signed-off-by: Mark Amirkan <markdamirkan@gmail.com>
---
 net/packet/af_packet.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/net/packet/af_packet.c b/net/packet/af_packet.c
index 76bde7906d..50cae32ae2 100644
--- a/net/packet/af_packet.c
+++ b/net/packet/af_packet.c
@@ -2384,7 +2384,9 @@ static int tpacket_rcv(struct sk_buff *skb, struct net_device *dev,
 	    virtio_net_hdr_from_skb(skb, h.raw + macoff -
 				    sizeof(struct virtio_net_hdr),
 				    vio_le(), true, 0)) {
-		if (po->tp_version == TPACKET_V3)
+		if (po->tp_version <= TPACKET_V2)
+			__clear_bit(slot_id, po->rx_ring.rx_owner_map);
+		else
 			prb_clear_blk_fill_status(&po->rx_ring);
 		goto drop_n_account;
 	}

---
base-commit: e6b6078ea1731b05b3b552497b3bce4bf8b014ae
change-id: 20260913-b4-send-packet-vnet-32b47964a7cf

Best regards,
--  
Mark Amirkan <markdamirkan@gmail.com>

