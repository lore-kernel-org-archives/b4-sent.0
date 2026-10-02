From: Fredrik Nyberg <fredrik.nyberg@volvocars.com>
Date: Fri, 02 Oct 2026 14:28:57 +0200
Subject: [PATCH net] net: usb: ax88179_178a: fix rx frame length for
 non-last packets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261002-ax88179-rx-len-v1-1-f01a2a295079@volvocars.com>
X-B4-Tracking: v=1; b=H4sIAIijv2oC/yWMQQqDMBQFryJv3Q9JEE16ldKFid/2i6Ql0RIQ7
 97ULmdgZkfmJJxxbXYk/kiWV6ygLw3Cc4gPJhkrwyjTaaUMDcVa3TtKhRaOZH1oXavYWd+hRu/
 Ek5RzeEPkFfe/zJufOay/FY7jC2PISDp3AAAA
X-Change-ID: 20261002-ax88179-rx-len-8bc4940e98b6
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-usb@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Simon Horman <horms@kernel.org>, 
 Jose Alonso <joalonsof@gmail.com>, stable@vger.kernel.org, 
 Fredrik Nyberg <fredrik.nyberg@volvocars.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790944143; l=4935;
 i=fredrik.nyberg@volvocars.com; s=20261002; h=from:subject:message-id;
 bh=IRKcnIrPbqh8pcvFDSL7Xq7XQH9sQAAtncyR8eGC+EY=;
 b=yeLr4ykB1Bo2Pi9/VFxQzGmWnJCsZ/hSK5WU7sEibPp11igOTBJiDZswizNHZuEvBq8DCclLF
 D1dlfW5tiGbAp7XFUnT9rqx5nXF2ZYITnLYJmTBIxhvhCx3vFPtbkN0
X-Developer-Key: i=fredrik.nyberg@volvocars.com; a=ed25519;
 pk=qID6RVpkd1ixl+9o9DvizyEtYlu5k5KPZfGbD6OqhwI=
X-Endpoint-Received: by B4 Relay for fredrik.nyberg@volvocars.com/20261002 with auth_id=1100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 4ce62d5b2f7a ("net: usb: ax88179_178a: stop lying about
skb->truesize") replaced skb_clone() with a copy into a new skb for
every packet of a bulk-in transfer except the last one. The copy skips
the 2-byte IP alignment pseudo header but still copies pkt_len bytes,
and pkt_len includes that header. Each of these frames is therefore
delivered with two extra trailing bytes: the 0xeeee pseudo header of
the next slot when the frame ends on an 8-byte boundary, or slot
padding otherwise. The last packet is still trimmed to pkt_len - 2.

IPv4 and IPv6 trim the extra bytes, so most traffic is unaffected.
Anything that relies on the frame length is not. MACsec takes the ICV
from the last 16 bytes and drops every such frame as InPktsNotValid. In
our setup that was 0.2-1.2% of received MACsec frames, depending on how
many frames shared a transfer, including service discovery multicast.

Allocate and copy pkt_len - 2 bytes, like the last-packet path.

Fixes: 4ce62d5b2f7a ("net: usb: ax88179_178a: stop lying about skb->truesize")
Cc: stable@vger.kernel.org
Signed-off-by: Fredrik Nyberg <fredrik.nyberg@volvocars.com>
---
Found on Ubuntu 6.8.0-138-generic, whose ax88179_178a.ko carries this
change (it imports __netdev_alloc_skb and skb_put, not skb_clone), with
an ASIX AX88179 (0b95:1790, bcdDevice 1.00) on a USB 3.0 port and a
1000 Mb/s link. The code is unchanged in current mainline.

Bulk TCP from an embedded board (Linux 4.14, stmmac) into the AX88179,
captured with tcpdump on the sender's Ethernet interface and on the
receiver, and matched frame by frame:

  path            frames  +2 bytes  other differences  InPktsNotValid
  802.1Q 16 MB/s    5812      2665                  0               -
  MACsec  5 MB/s    6208        15                  0            +14*
  MACsec  5 MB/s    6112        32                  0            +31*

  * counter window slightly shorter than the capture

- No frame was lost or changed apart from the two extra bytes. RX
  checksum offload on or off made no difference.
- In the 802.1Q run every frame ended on an 8-byte slot boundary. Of the
  frames that were not the last in their transfer, 2662 of 2664 had the
  extra bytes, always ee ee; of the last frames, 3 of 3148 did. Transfer
  membership was inferred from receive timestamps, so a few frames are
  misclassified.
- A usbmon capture of 1393 bulk-in transfers showed that the device
  reported the correct length (pkt_len = frame length + 2) for all 2458
  IP frames and that every slot started with ee ee. For the 1061 aligned
  packets that were not last, copying pkt_len bytes from data + 2 takes
  exactly the next slot's ee ee, so the bytes are added by rx_fixup, not
  by the device.

To reproduce without MACsec: turn GRO off, receive a bulk TCP stream on
the adapter while running tcpdump, and count frames of 64 bytes or more
that are longer than their headers plus the IP total length. On an
affected kernel many of them end in ee ee. I can send the small script
I used.

Tested with this change applied to the 6.8.0-138 driver, built as a
module, back to back with the stock module on the same setup (8 MB per
path, matched frame by frame against the sender capture):

  driver   path    RX csum  frames  +2 bytes  InPktsNotValid  retrans
  stock    802.1Q  on         5792      2835               -        -
  stock    MACsec  on         6141        25             +23      +21
  patched  802.1Q  on         5818         0               -        -
  patched  MACsec  on         6299         0              +0       +0
  patched  802.1Q  off        5820         0               -        -
  patched  MACsec  off        6255         0              +0       +0

With the patch every received frame was identical to the sent one.
ax88179_rx_fixup() is the same in 6.8.0-138 and in net, and the patch
builds on net with W=1 without warnings.
---
 drivers/net/usb/ax88179_178a.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/net/usb/ax88179_178a.c b/drivers/net/usb/ax88179_178a.c
index 81d8412ce8..cba1dc95d3 100644
--- a/drivers/net/usb/ax88179_178a.c
+++ b/drivers/net/usb/ax88179_178a.c
@@ -1457,11 +1457,11 @@ static int ax88179_rx_fixup(struct usbnet *dev, struct sk_buff *skb)
 			return 1;
 		}
 
-		ax_skb = netdev_alloc_skb_ip_align(dev->net, pkt_len);
+		ax_skb = netdev_alloc_skb_ip_align(dev->net, pkt_len - 2);
 		if (!ax_skb)
 			return 0;
-		skb_put(ax_skb, pkt_len);
-		memcpy(ax_skb->data, skb->data + 2, pkt_len);
+		skb_put(ax_skb, pkt_len - 2);
+		memcpy(ax_skb->data, skb->data + 2, pkt_len - 2);
 
 		ax88179_rx_checksum(ax_skb, pkt_hdr);
 		usbnet_skb_return(dev, ax_skb);

---
base-commit: 71a77ab76e74131a101f4d2d2afb0dcbf81b4e3c
change-id: 20261002-ax88179-rx-len-8bc4940e98b6

Best regards,
--  
Fredrik Nyberg <fredrik.nyberg@volvocars.com>

