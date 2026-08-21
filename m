From: Esteban Alba <estebancalba@gmail.com>
Date: Fri, 21 Aug 2026 02:07:43 -0500
Subject: [PATCH v2] net: net6: validate IPv6 payload and transport lengths
 on receive
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-net6-len-validation-v2-1-29bd39f946e0@gmail.com>
X-B4-Tracking: v=1; b=H4sIAD75h2oC/32NQQ6CMBBFr0Jm7RjaBVVX3sOwKO0UxkAxbWk0h
 LtbcO/yJe+/v0KkwBThVq0QKHPk2ReQpwrMoH1PyLYwyFo29aVW6Ck1OJLHrEe2OhUfjVWCnL0
 2Wjkoy1cgx++j+mh/HJfuSSbtqd0YOKY5fI7bLHbv/0MWKJCsc1IJ0zlp7v2keTybeYJ227YvT
 hucFMgAAAA=
X-Change-ID: 20260807-net6-len-validation-cd71efd96a7f
In-Reply-To: <20260807-net6-len-validation-v1-1-edff271cbf2c@gmail.com>
References: <20260807-net6-len-validation-v1-1-edff271cbf2c@gmail.com>
To: u-boot@lists.u-boot-project.org
Cc: trini@konsulko.com, rfried.dev@gmail.com, v.v.mitrofanov@yadro.com, 
 jerome.forissier@arm.com, sjg@chromium.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787296063; l=3321;
 i=estebancalba@gmail.com; s=20260808; h=from:subject:message-id;
 bh=B1o1ST4jOJ2e8Snq5dgcEV+I6sEAaDIE46Qusbt0PFs=;
 b=6sYAvn5Kxrtlk6o/HubL+tUHtLDjcHnP24BTi8BOwCc+cRccUZxFBf0oh4uDTwDY4QR1XAoh2
 Of9Shub8xIQCWmRmXSFuririKiM063yLb3Fq4rVNjcP4+Qap5r+q4EX
X-Developer-Key: i=estebancalba@gmail.com; a=ed25519;
 pk=1BEuFs3cavGme7UfOyPkuXqt9/3FstTgVwsFSCXGO5o=
X-Endpoint-Received: by B4 Relay for estebancalba@gmail.com/20260808 with auth_id=927
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

net_ip6_handler() checks the received length only against IP6_HDR_SIZE and
then uses length fields from the packet without checking them. The checksum
is computed over payload_len, but the UDP handler length comes from
udp_len. A sender can keep payload_len correct so the checksum still
validates and set udp_len larger than the frame. A handler that trusts that
length then reads or writes past the receive buffer. The DHCPv6 client
copies the declared number of bytes and can be made to write past the
packet buffer from a single link-local ADVERTISE.

Validate payload_len against the received length and trim len to it before
protocol dispatch. Validate the ICMPv6 and UDP header sizes before either
header is dereferenced, and validate udp_len before reading udp_xsum or
calling the UDP handler.

Fixes: 1feb697830ce ("net: ipv6: Add implementation of main IPv6 functions")
Suggested-by: Jerome Forissier <jerome.forissier@arm.com>
Signed-off-by: Esteban Alba <estebancalba@gmail.com>
---
Validate the IPv6 payload length against the received frame before protocol
dispatch, then validate the ICMPv6 and UDP transport header sizes and
udp_len before either header is dereferenced or the UDP handler is called.
---
Changes in v2:
- Move payload_len reconciliation before protocol dispatch.
- Validate ICMPv6 and UDP header sizes before dereferencing their headers.
- Validate udp_len before reading udp_xsum or dispatching to the UDP handler.
- Link to v1: https://patch.msgid.link/20260807-net6-len-validation-v1-1-edff271cbf2c@gmail.com

To: u-boot@lists.u-boot-project.org
Cc: Ramon Fried <rfried.dev@gmail.com>
Cc: Jerome Forissier <jerome.forissier@arm.com>
Cc: Tom Rini <trini@konsulko.com>
Cc: Viacheslav Mitrofanov <v.v.mitrofanov@yadro.com>
Cc: Simon Glass <sjg@chromium.org>
---
 net/net6.c | 18 ++++++++++++++++--
 1 file changed, 16 insertions(+), 2 deletions(-)

diff --git a/net/net6.c b/net/net6.c
index 4cff98df15..e1a455748e 100644
--- a/net/net6.c
+++ b/net/net6.c
@@ -392,11 +392,19 @@ int net_ip6_handler(struct ethernet_hdr *et, struct ip6_hdr *ip6, int len)
 	if (ip6->version != 6)
 		return -EINVAL;
 
+	hlen = ntohs(ip6->payload_len);
+
+	if (len < IP6_HDR_SIZE + hlen)
+		return -EINVAL;
+	len = IP6_HDR_SIZE + hlen;
+
 	switch (ip6->nexthdr) {
 	case PROT_ICMPV6:
+		if (hlen < sizeof(struct icmp6hdr))
+			return -EINVAL;
+
 		icmp = (struct icmp6hdr *)(((uchar *)ip6) + IP6_HDR_SIZE);
 		csum = icmp->icmp6_cksum;
-		hlen = ntohs(ip6->payload_len);
 		icmp->icmp6_cksum = 0;
 		/* checksum */
 		csum_p = csum_partial((u8 *)icmp, hlen, 0);
@@ -421,9 +429,15 @@ int net_ip6_handler(struct ethernet_hdr *et, struct ip6_hdr *ip6, int len)
 		}
 		break;
 	case IPPROTO_UDP:
+		if (hlen < UDP_HDR_SIZE)
+			return -EINVAL;
+
 		udp = (struct udp_hdr *)(((uchar *)ip6) + IP6_HDR_SIZE);
+		if (ntohs(udp->udp_len) < UDP_HDR_SIZE ||
+		    ntohs(udp->udp_len) > hlen)
+			return -EINVAL;
+
 		csum = udp->udp_xsum;
-		hlen = ntohs(ip6->payload_len);
 		udp->udp_xsum = 0;
 		/* checksum */
 		csum_p = csum_partial((u8 *)udp, hlen, 0);

---
base-commit: ece349ade2973e220f524ce59e59711cc919263f
change-id: 20260807-net6-len-validation-cd71efd96a7f

Best regards,
--  
Esteban Alba <estebancalba@gmail.com>

