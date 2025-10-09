From: Dmitry Safonov <dima@arista.com>
Date: Thu, 09 Oct 2025 16:02:19 +0100
Subject: [PATCH v2] net/ip6_tunnel: Prevent perpetual tunnel growth
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251009-ip6_tunnel-headroom-v2-1-8e4dbd8f7e35@arista.com>
X-B4-Tracking: v=1; b=H4sIAHrO52gC/32OTQ7CIBBGr9KwFi3035X3MI2Z0lFICjRDJZqmd
 5f2AC7fJO99s7KAZDCwa7YywmiC8S6BPGVMaXAv5GZMzGQuK5HnDTdz/VjezuHENcJI3ls+QFe
 3IKErC2DJnAmf5nNU733iAQLygcApvbcWTxGmMVwshAVpN7QJ6fo93ohi9/4vRsEFV0K2TdkWU
 HXyBpQScFbesn7bth9CxeHO2QAAAA==
X-Change-ID: 20251007-ip6_tunnel-headroom-ba968a2a943a
To: "David S. Miller" <davem@davemloft.net>, 
 David Ahern <dsahern@kernel.org>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Tom Herbert <tom@herbertland.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Safonov <0x7f454c46@gmail.com>, Florian Westphal <fw@strlen.de>, 
 Francesco Ruggeri <fruggeri05@gmail.com>, Dmitry Safonov <dima@arista.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760022147; l=3753;
 i=dima@arista.com; s=20250521; h=from:subject:message-id;
 bh=QP0aw6XFbqBaKIxubuBQan+TnP0JhZPSMwD0ZXJHoWo=;
 b=0crxKtxxohvisEkl0rV59JpOcc/F2hdWJB8uSwEG9Z4igHS+nkyOlefV/5yUVqin7dbIzh1x7
 urEgRaoO7PvD1MUrRxcfd3DuhVFsf8qAXrJ8xhFDOG+Qx/UVqgzWV++
X-Developer-Key: i=dima@arista.com; a=ed25519;
 pk=/z94x2T59rICwjRqYvDsBe0MkpbkkdYrSW2J1G2gIcU=
X-Endpoint-Received: by B4 Relay for dima@arista.com/20250521 with auth_id=405
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Similarly to ipv4 tunnel, ipv6 version updates dev->needed_headroom, too.
While ipv4 tunnel headroom adjustment growth was limited in
commit 5ae1e9922bbd ("net: ip_tunnel: prevent perpetual headroom growth"),
ipv6 tunnel yet increases the headroom without any ceiling.

Reflect ipv4 tunnel headroom adjustment limit on ipv6 version.

Credits to Francesco Ruggeri, who was originally debugging this issue
and wrote local Arista-specific patch and a reproducer.

Fixes: 8eb30be0352d ("ipv6: Create ip6_tnl_xmit")
Cc: Florian Westphal <fw@strlen.de>
Cc: Francesco Ruggeri <fruggeri05@gmail.com>
Signed-off-by: Dmitry Safonov <dima@arista.com>
---
Changes in v2:
- Drop 'static' for local variable max_allowed (Jakub's nit)
- Link to v1: https://lore.kernel.org/r/20251007-ip6_tunnel-headroom-v1-1-c1287483a592@arista.com
---
 include/net/ip_tunnels.h | 15 +++++++++++++++
 net/ipv4/ip_tunnel.c     | 14 --------------
 net/ipv6/ip6_tunnel.c    |  3 +--
 3 files changed, 16 insertions(+), 16 deletions(-)

diff --git a/include/net/ip_tunnels.h b/include/net/ip_tunnels.h
index 4314a97702eae094f2defc65d914390864c21006..ecae35512b9b449fa061d96e66eb4533d1816bef 100644
--- a/include/net/ip_tunnels.h
+++ b/include/net/ip_tunnels.h
@@ -611,6 +611,21 @@ struct metadata_dst *iptunnel_metadata_reply(struct metadata_dst *md,
 int skb_tunnel_check_pmtu(struct sk_buff *skb, struct dst_entry *encap_dst,
 			  int headroom, bool reply);
 
+static inline void ip_tunnel_adj_headroom(struct net_device *dev,
+					  unsigned int headroom)
+{
+	/* we must cap headroom to some upperlimit, else pskb_expand_head
+	 * will overflow header offsets in skb_headers_offset_update().
+	 */
+	const unsigned int max_allowed = 512;
+
+	if (headroom > max_allowed)
+		headroom = max_allowed;
+
+	if (headroom > READ_ONCE(dev->needed_headroom))
+		WRITE_ONCE(dev->needed_headroom, headroom);
+}
+
 int iptunnel_handle_offloads(struct sk_buff *skb, int gso_type_mask);
 
 static inline int iptunnel_pull_offloads(struct sk_buff *skb)
diff --git a/net/ipv4/ip_tunnel.c b/net/ipv4/ip_tunnel.c
index aaeb5d16f0c9a46d90564dc2b6d7fd0a5b33d037..158a30ae7c5f2f1fa39eea7c3d64e36fb5f7551a 100644
--- a/net/ipv4/ip_tunnel.c
+++ b/net/ipv4/ip_tunnel.c
@@ -568,20 +568,6 @@ static int tnl_update_pmtu(struct net_device *dev, struct sk_buff *skb,
 	return 0;
 }
 
-static void ip_tunnel_adj_headroom(struct net_device *dev, unsigned int headroom)
-{
-	/* we must cap headroom to some upperlimit, else pskb_expand_head
-	 * will overflow header offsets in skb_headers_offset_update().
-	 */
-	static const unsigned int max_allowed = 512;
-
-	if (headroom > max_allowed)
-		headroom = max_allowed;
-
-	if (headroom > READ_ONCE(dev->needed_headroom))
-		WRITE_ONCE(dev->needed_headroom, headroom);
-}
-
 void ip_md_tunnel_xmit(struct sk_buff *skb, struct net_device *dev,
 		       u8 proto, int tunnel_hlen)
 {
diff --git a/net/ipv6/ip6_tunnel.c b/net/ipv6/ip6_tunnel.c
index 3262e81223dfc859a06b55087d5dac20f43e6c11..6405072050e0ef7521ca1fdddc4a0252e2159d2a 100644
--- a/net/ipv6/ip6_tunnel.c
+++ b/net/ipv6/ip6_tunnel.c
@@ -1257,8 +1257,7 @@ int ip6_tnl_xmit(struct sk_buff *skb, struct net_device *dev, __u8 dsfield,
 	 */
 	max_headroom = LL_RESERVED_SPACE(tdev) + sizeof(struct ipv6hdr)
 			+ dst->header_len + t->hlen;
-	if (max_headroom > READ_ONCE(dev->needed_headroom))
-		WRITE_ONCE(dev->needed_headroom, max_headroom);
+	ip_tunnel_adj_headroom(dev, max_headroom);
 
 	err = ip6_tnl_encap(skb, t, &proto, fl6);
 	if (err)

---
base-commit: ec714e371f22f716a04e6ecb2a24988c92b26911
change-id: 20251007-ip6_tunnel-headroom-ba968a2a943a

Best regards,
-- 
Dmitry Safonov <dima@arista.com>

