From: Laika Price <laikabcprice@gmail.com>
Date: Sat, 13 Jun 2026 02:00:25 +0100
Subject: [PATCH net] ip_tunnel: drop stale dst from generated PMTU ICMP
 replies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260613-master-v1-1-df796e8e2d74@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSwqAMAxF0a1IxhbaCoG6FXFQa9QIfmhUBHHvV
 h0euO9dIBSZBMrsgkgHCy9zgskzCIOfe1LcJoPVFjWaQk1eNorKW+cMYuM0OkjxGqnj8zuq6t+
 yNyOF7V3DfT9ck/v8agAAAA==
X-Change-ID: 20260613-master-a299166b9069
To: David Ahern <dsahern@kernel.org>, Ido Schimmel <idosch@nvidia.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Laika Price <laikabcprice@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781312428; l=1673;
 i=laikabcprice@gmail.com; s=20260613; h=from:subject:message-id;
 bh=4DMd2b5yZeVwzvEhHqEHfg7CMqL/k52EB0m/TG6YOcw=;
 b=7amHt50uZ9UfatSs/+QnfsSKjejy7opjoU4KHdTOWwB+mXs1hRLzpmfmh5Q2+zIIoYNh6hLTo
 ejmz52W9TGyDwAdSZL0H09znmI/GeGLqCZfB8Zwhm9AoOKe/48S9uQH
X-Developer-Key: i=laikabcprice@gmail.com; a=ed25519;
 pk=mFSMw2odvyxt1H4QHAdwZVuwHduNzUMDKbWFOcwhDCg=
X-Endpoint-Received: by B4 Relay for laikabcprice@gmail.com/20260613 with auth_id=819
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

iptunnel_pmtud_build_icmp(...) and iptunnel_pmtud_build_icmpv6(...) take
in an sk_buff, modify it to create a PMTU ICMP error reply, and return it.
As part of these modifications, the source/destination ethernet and IP
addresses are swapped around which makes the sk_buff's current dst invalid.

If the stale dst is left, the packet can skip input routing and be
forwarded using the original output device. This was observed when sending
packets to a VXLAN over a WireGuard tunnel - the ICMP reply was generated
but it was sent over the VXLAN instead of to the WireGuard tunnel.

Drop the stale dst after building the PMTU reply so that the packet is
routed using its new headers when it is reinjected.

Signed-off-by: Laika Price <laikabcprice@gmail.com>
---
 net/ipv4/ip_tunnel_core.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/net/ipv4/ip_tunnel_core.c b/net/ipv4/ip_tunnel_core.c
index d3c677e9b..949150e43 100644
--- a/net/ipv4/ip_tunnel_core.c
+++ b/net/ipv4/ip_tunnel_core.c
@@ -267,6 +267,7 @@ static int iptunnel_pmtud_build_icmp(struct sk_buff *skb, int mtu)
 
 	eth_header(skb, skb->dev, ntohs(eh.h_proto), eh.h_source, eh.h_dest, 0);
 	skb_reset_mac_header(skb);
+	skb_dst_drop(skb);
 
 	return skb->len;
 }
@@ -370,6 +371,7 @@ static int iptunnel_pmtud_build_icmpv6(struct sk_buff *skb, int mtu)
 
 	eth_header(skb, skb->dev, ntohs(eh.h_proto), eh.h_source, eh.h_dest, 0);
 	skb_reset_mac_header(skb);
+	skb_dst_drop(skb);
 
 	return skb->len;
 }

---
base-commit: 2a2974b5145cdf2f4db134be1a2157e9ca4a1cf0
change-id: 20260613-master-a299166b9069

Best regards,
--  
Laika Price <laikabcprice@gmail.com>

