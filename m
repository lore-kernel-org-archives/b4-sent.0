From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Wed, 25 Nov 2026 23:50:35 +0300
Subject: [PATCH RFC net-next 7/7] docs: networking: describe the CS7542
 flowtable RFC limits
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-almondplus-offload-rfc-v1-7-703175c6340c@gmail.com>
References: <20261125-almondplus-offload-rfc-v1-0-703175c6340c@gmail.com>
In-Reply-To: <20261125-almondplus-offload-rfc-v1-0-703175c6340c@gmail.com>
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Simon Horman <horms@kernel.org>, Pablo Neira Ayuso <pablo@netfilter.org>, 
 Florian Westphal <fw@strlen.de>, Phil Sutter <phil@nwl.cc>, 
 Hans Ulli Kroll <ulli.kroll@googlemail.com>, 
 Linus Walleij <linusw@kernel.org>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 Russell King <linux@armlinux.org.uk>, 
 Christian Marangi <ansuelsmth@gmail.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, netfilter-devel@vger.kernel.org, 
 coreteam@netfilter.org, linux-arm-kernel@lists.infradead.org, 
 linux-doc@vger.kernel.org, Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795639829; l=7601;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=/LLBgDu2W64JTNlAWpTpKMSB1T1Pf4WK5w8P8fK4qoU=;
 b=9pT84902ZU5MxLm8C/bMqb5Cm0U++CiHuoAF76UHN91JHgQgLR/IMTXkCWNXvt1L4mLae6csy
 DazXsyjCU5YDNQBsNdWPGV0pjCCA+Nqo8t5/3Yy9VrfP/TnRuIqBN1T
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Record the real LAN/WAN NAT qualification and its precise limits:
immutable result capacity, conservative sticky-HIT aging, module
lifetime restrictions and software fallback. Distinguish precursor
hardware results from execution of the new Linux composition. Extend the
existing network-engine file patterns.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 .../ethernet/cortina/cs7542-flowtable.rst          | 112 +++++++++++++++++++++
 MAINTAINERS                                        |   5 +
 2 files changed, 117 insertions(+)

diff --git a/Documentation/networking/device_drivers/ethernet/cortina/cs7542-flowtable.rst b/Documentation/networking/device_drivers/ethernet/cortina/cs7542-flowtable.rst
new file mode 100644
index 000000000..bedb825b6
--- /dev/null
+++ b/Documentation/networking/device_drivers/ethernet/cortina/cs7542-flowtable.rst
@@ -0,0 +1,112 @@
+.. SPDX-License-Identifier: GPL-2.0
+
+CS7542 hardware flowtable RFC
+============================
+
+This RFC connects the CS7542 forwarding engine to nftables hardware
+flowtables. The Ethernet driver remains the sole owner of packet DMA,
+indirect tables and network-engine reset. The forwarding algorithm and
+flowtable frontend are replaceable modules in this development version.
+They do not map hardware registers themselves.
+
+Supported path
+--------------
+
+The current path is wired IPv4 TCP/UDP NAT through a QCA8337 switch on the
+CS7542. It accepts physical user ports 1 through 5 on CPU port 0/GMAC1.
+Both ingress and egress must resolve to that conduit and to the initial
+network namespace. It checks the route, neighbor, bridge FDB, observed
+original Ethernet header, tag format and directional route MTU before
+publishing a lookup. Unsupported requests return to software processing.
+Wi-Fi and IPv6 are not accelerated.
+
+TCP admission additionally requires an established conntrack state. The
+flowtable supplies that state together with the route MTU. SYN, FIN,
+fragments, IP options, low TTL and packets outside the admitted length
+range remain on the CPU path. The driver does not infer a route MTU or an
+established connection from flower rewrite actions.
+
+The QCA four-byte CPU header puts an identifier ahead of the ordinary
+two-byte QCA metadata. This lets the CS7542 parser recognize the inner
+IPv4 header. CPU-port ``dsa-tag-protocol = "qca4"`` selects the format.
+Both configured CPU ports must agree. The default remains the ordinary
+two-byte QCA format. Ethernet management frames are not usable with this
+four-byte tagger, so switch register access stays on MDIO.
+
+Resource lifetime
+-----------------
+
+There are 16 admitted direction selectors and eight immutable result
+records in this implementation. A result includes every hardware-visible
+forwarding dependency. Identical results may be shared by independent
+selectors. A retired selector may be rebound only after invalidation and
+complete readback, with the original immutable result still present.
+Removing one selector does not retire another selector sharing its result.
+
+This is not general result reclamation. An incompatible result consumes
+another record. Eight different retained results exhaust this small
+allocation pool until a verified complete network-engine reset. Further
+flows fall back to software. A successful lookup withdrawal is not treated
+as proof that all in-flight hardware references have drained.
+
+Failed or ambiguous hardware transactions close admission and retain the
+state needed for isolation and recovery. The current replaceable modules
+remain pinned until the built-in manager completes checked detachment.
+Ordinary arbitrary module removal and suspend are not supported by this
+RFC. The Ethernet owner, switch and MDIO must be built in; forced module
+removal and power management are excluded by Kconfig. Consolidating this
+development interface into the Ethernet driver is an open design item.
+
+Activity accounting
+-------------------
+
+The hardware HIT bit is sticky. The driver only treats an observed
+zero-to-one transition as evidence of recent activity. It neither clears
+the bitmap without a proven drain protocol nor fabricates packet counters
+or fresh timestamps from repeated reads of the same set bit.
+
+Consequently an active connection can expire from the hardware flowtable
+at the normal Linux timeout and be learned again in software. On the
+tested OpenWrt configuration this produced one CPU packet in each direction
+at about 30-second intervals. This conservative refresh is a known limit,
+not evidence of uninterrupted hardware residency or accurate packet counts.
+
+Validation and provenance
+-------------------------
+
+The precursor on Almond+ OpenWrt 6.18.64 was tested with the standard LuCI
+hardware flow-offloading option and ordinary firewall4 NAT. LAN and WAN
+were separate physical switch ports. The client was 192.168.1.2; the WAN
+server was 10.42.0.1 and observed the translated router address 10.42.0.139.
+
+Byte-exact UDP exchanges covered IP lengths 512, 1400 and 1500 with DF
+set and clear. Both directions arrived with TTL 63. With flow offload
+disabled, the CPU capture contained all 72 marked packets. With hardware
+offload enabled it contained four of 212 packets: the two refresh pairs
+at 30 and 60 seconds. Capture reported no kernel drops. TCP exchanged
+2,293,760 verified bytes over 70 seconds; TCP and UDP conntrack entries
+retained HW_OFFLOAD at the 3, 35 and 69 second observations. TCP endpoints
+accepted the data; this is not an independent capture-based checksum
+audit of every accelerated TCP segment.
+
+A separate eight-connection test exercised 16 selectors sharing one result.
+Seven connections kept their original selectors and continued forwarding
+after the first connection was removed. These were correctness tests at a
+controlled rate, not throughput or maximum-capacity benchmarks.
+
+The Linux RFC changes the DSA selection interface, removes laboratory
+controls and adapts to current kernel APIs. Measurements of the precursor
+must not be represented as an execution of these exact Linux source bytes.
+Build and software-test results are recorded separately in the cover letter.
+
+Review questions
+----------------
+
+* Should directional route MTU and established TCP state be carried in the
+  flowtable's classifier request, or through a different common interface?
+* Is the standard DSA tag-selection property appropriate for this CPU
+  parser constraint and the two-conduit switch setup?
+* What hardware evidence would be sufficient to permit reclamation of
+  different result records and clearing the sticky HIT state safely?
+* Should the built-in owner and replaceable algorithm be consolidated
+  before a non-RFC submission?
diff --git a/MAINTAINERS b/MAINTAINERS
index d17acadaa..a70086354 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2966,7 +2966,12 @@ M:	Fil Dunsky <filipp.dunsky@gmail.com>
 L:	netdev@vger.kernel.org
 S:	Maintained
 F:	Documentation/devicetree/bindings/net/cortina,cs7542-ethernet.yaml
+F:	Documentation/networking/device_drivers/ethernet/cortina/cs7542-flowtable.rst
 F:	drivers/net/ethernet/cortina/cs752x_*
+F:	drivers/net/ethernet/cortina/cs7542*
+F:	drivers/net/ethernet/cortina/cs_fe_*
+F:	drivers/net/ethernet/cortina/flowtable/
+F:	include/linux/cs7542_*
 
 ARM/CORTINA SYSTEMS GEMINI ARM ARCHITECTURE
 M:	Hans Ulli Kroll <ulli.kroll@googlemail.com>

-- 
2.53.0

