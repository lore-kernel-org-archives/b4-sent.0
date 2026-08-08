From: Esteban Alba <estebancalba@gmail.com>
Date: Fri, 07 Aug 2026 21:09:53 -0500
Subject: [PATCH] net: net6: validate IPv6 payload and UDP length on receive
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260807-net6-len-validation-v1-1-edff271cbf2c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPCPdmoC/yXMwQrDIBCE4VcJe86CyUHbvkrIwejYbgmmqJFCy
 LvXtscPZv6DMpIg0607KKFKli02DH1H7mHjHSy+mUY1anVRhiOK5hWRq13F29L27LwZEPxVWxO
 oPV8JQd6/6jT/nfflCVe+KTrPD4FKLfl3AAAA
X-Change-ID: 20260807-net6-len-validation-cd71efd96a7f
To: u-boot@lists.u-boot-project.org
Cc: Ramon Fried <rfried.dev@gmail.com>, 
 Jerome Forissier <jerome.forissier@arm.com>, Tom Rini <trini@konsulko.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786154992; l=2310;
 i=estebancalba@gmail.com; s=20260808; h=from:subject:message-id;
 bh=Noglsh+V1jbRhzRXFIKeYwjx9lELZ2FDIrdfAldKLjk=;
 b=mltVNCMlvJDST5IxyVGnqclfs/TqZZ03IQYrKdHH21v4nAjlYGxRjJP6exVh9mn8oz64j9gUM
 NDGwAIBToy8BxvruaKTQC++I9GBphp8OyTA+UvBFdcc6jJcacDnKVC9
X-Developer-Key: i=estebancalba@gmail.com; a=ed25519;
 pk=1BEuFs3cavGme7UfOyPkuXqt9/3FstTgVwsFSCXGO5o=
X-Endpoint-Received: by B4 Relay for estebancalba@gmail.com/20260808 with auth_id=927
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

net_ip6_handler() checks the received length only against IP6_HDR_SIZE
and then uses two length fields from the packet without checking them.
The checksum is computed over payload_len, but the length passed to the
UDP handler comes from udp_len. A sender can keep payload_len correct so
the checksum still validates and set udp_len larger than the frame. A
handler that trusts that length then reads or writes past the receive
buffer. The DHCPv6 client copies the declared number of bytes and can be
made to write past the packet buffer from a single link-local ADVERTISE.

The IPv4 path already reconciles these lengths in
net_process_received_packet(). Do the same here: reject a payload_len
that exceeds the received length and trim len to it, then reject a
udp_len smaller than the UDP header or larger than the payload before
calling the handler.

Fixes: 1feb697830ce ("net: ipv6: Add implementation of main IPv6 functions")
Signed-off-by: Esteban Alba <estebancalba@gmail.com>
Cc: Jerome Forissier <jerome.forissier@arm.com>
Cc: Tom Rini <trini@konsulko.com>
---
 net/net6.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/net/net6.c b/net/net6.c
index 4cff98df15..af2f484fad 100644
--- a/net/net6.c
+++ b/net/net6.c
@@ -392,6 +392,11 @@ int net_ip6_handler(struct ethernet_hdr *et, struct ip6_hdr *ip6, int len)
 	if (ip6->version != 6)
 		return -EINVAL;
 
+	/* Trim to the length declared in the header, as the IPv4 path does */
+	if (len < IP6_HDR_SIZE + ntohs(ip6->payload_len))
+		return -EINVAL;
+	len = IP6_HDR_SIZE + ntohs(ip6->payload_len);
+
 	switch (ip6->nexthdr) {
 	case PROT_ICMPV6:
 		icmp = (struct icmp6hdr *)(((uchar *)ip6) + IP6_HDR_SIZE);
@@ -433,6 +438,10 @@ int net_ip6_handler(struct ethernet_hdr *et, struct ip6_hdr *ip6, int len)
 		if (csum != udp->udp_xsum)
 			return -EINVAL;
 
+		if (ntohs(udp->udp_len) < UDP_HDR_SIZE ||
+		    ntohs(udp->udp_len) > len - IP6_HDR_SIZE)
+			return -EINVAL;
+
 		/* IP header OK. Pass the packet to the current handler. */
 		net_get_udp_handler()((uchar *)ip6 + IP6_HDR_SIZE +
 					UDP_HDR_SIZE,

---
base-commit: ece349ade2973e220f524ce59e59711cc919263f
change-id: 20260807-net6-len-validation-cd71efd96a7f

Best regards,
--  
Esteban Alba <estebancalba@gmail.com>

