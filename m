From: Laika Price <laikabcprice@gmail.com>
Date: Sun, 14 Jun 2026 00:13:57 +0100
Subject: [PATCH net v3] ip_tunnel: drop stale dst from generated PMTU ICMP
 replies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260614-master-v3-1-9f5060ba1ed1@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM2wpAQBSF4VfRvjblLF5FLsZY2Mqh2UjJuxtcf
 vWvdZHAMoRK7yKLg4WX2SH2PTKDnnsobp0pCqIsyMJYTVo2WNXkSdF2GimMIRevFh2f31FV/5a
 9GWG2d033/QDp2htLagAAAA==
X-Change-ID: 20260613-master-b749dfae5ecc
To: David Ahern <dsahern@kernel.org>, Ido Schimmel <idosch@nvidia.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Laika Price <laikabcprice@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781392437; l=3515;
 i=laikabcprice@gmail.com; s=20260613; h=from:subject:message-id;
 bh=4R3bk96Acva4pjmtLVNfzqZPE4VBDyqBTO1OdJW0m54=;
 b=46a8YD2fqzTW1iLw1iw6oWYzRsLwrI0LRffoyWRfjrGozZINh2hNQsSyWlSEGSIjcQepVi19k
 9FYN5oBNvUsBnMA4PwpKjqTFmLEKTnzUSekvP4Zep10Umtl5XH91/Hv
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

This patch drops the stale dst after building the PMTU reply so that the
packet is routed using its new headers when it is reinjected.

The pmtu_ipv4_br_vxlan4_exception test generates PMTU exceptions by
pinging an IP on the other side of a tunnel. This was incorrect as it
would return upon the first ICMP Fragmentation Needed due to the -w flag
being used in conjunction with || return 1.

This patch updates pmtu_ipv4_br_vxlan4_exception to be in line with how
PMTU exceptions are generated in other tests such as in test_pmtu_ipvX

    run_cmd ${ns_a} ${ping} -q -M want -i 0.1 -w 1 -s 1800 ${dst1}
    run_cmd ${ns_a} ${ping} -q -M want -i 0.1 -w 1 -s 1800 ${dst2}

Signed-off-by: Laika Price <laikabcprice@gmail.com>
---
Changes in v3:
- Squashed the selftest update into the ip_tunnel fix so the patch remains
  bisectable.
- Link to v2: https://patch.msgid.link/20260613-master-v2-0-061b70fd45dd@gmail.com

Changes in v2:
- Fixed incorrect PMTU exception generation in the selftest.
- Link to v1: https://patch.msgid.link/20260613-master-v1-1-df796e8e2d74@gmail.com
---
 net/ipv4/ip_tunnel_core.c           | 2 ++
 tools/testing/selftests/net/pmtu.sh | 4 ++--
 2 files changed, 4 insertions(+), 2 deletions(-)

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
diff --git a/tools/testing/selftests/net/pmtu.sh b/tools/testing/selftests/net/pmtu.sh
index a3323c21f..9498d9f53 100755
--- a/tools/testing/selftests/net/pmtu.sh
+++ b/tools/testing/selftests/net/pmtu.sh
@@ -1456,8 +1456,8 @@ test_pmtu_ipvX_over_bridged_vxlanY_or_geneveY_exception() {
 	mtu "${ns_a}" ${type}_a $((${ll_mtu} + 1000))
 	mtu "${ns_b}" ${type}_b $((${ll_mtu} + 1000))
 
-	run_cmd ${ns_c} ${ping} -q -M want -i 0.1 -c 10 -s $((${ll_mtu} + 500)) ${dst} || return 1
-	run_cmd ${ns_a} ${ping} -q -M want -i 0.1 -w 1  -s $((${ll_mtu} + 500)) ${dst} || return 1
+	run_cmd ${ns_c} ${ping} -q -M want -i 0.1 -w 1 -s $((${ll_mtu} + 500)) ${dst}
+	run_cmd ${ns_a} ${ping} -q -M want -i 0.1 -w 1 -s $((${ll_mtu} + 500)) ${dst}
 
 	# Check that exceptions were created
 	pmtu="$(route_get_dst_pmtu_from_exception "${ns_c}" ${dst})"

---
base-commit: 2a2974b5145cdf2f4db134be1a2157e9ca4a1cf0
change-id: 20260613-master-b749dfae5ecc

Best regards,
--  
Laika Price <laikabcprice@gmail.com>

