From: Joseph Telaak <joseph@telaak.dev>
Subject: [PATCH net-next 0/2] net: stmmac: Add the Siflower SF19A2890 glue
Date: Wed, 04 Nov 2026 02:22:23 -0500
Message-Id: <20261104-sf19a2890-gmac-v1-0-a15965a49574@telaak.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAC/d6moC/y2NwQqDMBBEf0X23IUkiCT9leIhphu7gmmbjSKI/
 9609jjMvDc7CGUmgWuzQ6aVhZ+pBn1pIDx8Ggn5XjMYZTqtlUGJ2nljncJx9gHbOLRW2Wg7F6B
 Cr0yRt5/wBokKJtoK9GcjyzBRKF/ff5vpvdTPcgL9cXwAoL3q7ZEAAAA=
X-Change-ID: 20261102-sf19a2890-gmac-4fb4808f869c
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Richard Cochran <richardcochran@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Giuseppe Cavallaro <peppe.cavallaro@st.com>, 
 Jose Abreu <joabreu@synopsys.com>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>
Cc: Chuanhong Guo <gch981213@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, linux-mips@vger.kernel.org, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793776955; l=2659;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=4aX1WuQkiEXgDzkE3OQjN92P69c1uJb0rksZC2QCI/c=;
 b=5W2C6p3JKlr/OYkYYzwVZ7Y5b/m53N4KDQeoxViOd9QSaRTx62D8T06k382412ER3M30amjJg
 EQ22G8hgj8LDsd9xPfExPXtkSI+BUGn7ruvO4K5Ikn+zcvgJNRsHte8
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Siflower SF19A2890, a MIPS SoC for home routers, has a DesignWare
GMAC 3.73a. Its interface type and RGMII clock delays are set in a
small configuration block next to its clock and reset manager. This
series adds a binding and the glue.

The glue is based on Chuanhong Guo's driver, which read the RGMII delays
from a factory flash cell in the delay line's own units and always
applied them. Here the delays come from rx-internal-delay-ps and
tx-internal-delay-ps and are applied only when those are present. The
interface type is set through set_phy_intf_sel.

The delay line's step is not documented, so I measured it: sweeping
each delay register over 0-255 with the link at 1000 Mb/s, the working
windows repeat every 145 steps (TX) and 144.5 steps (RX), which is one
8 ns period of the 125 MHz RGMII clock. So a step is about 55 ps. The
TX eye is about 3.1 ns wide and the RX eye about 1.75 ns; the delays the
bootloader programs, 17 and 10 steps (935 and 550 ps), sit inside both.

On the GL.iNet GL-SFT1200 the GMAC is the CPU port of a MaxLinear GSW150
switch over RGMII with no delays on the board; the GMAC adds both.

The MAINTAINERS entry that covers these files comes with the MIPS series
"MIPS: Add support for the Siflower SF19A2890"; this series applies on
its own. That entry is also why checkpatch's question about updating
MAINTAINERS for the new files is left unanswered here.

Tested on a GL-SFT1200 with the GSW150 driver:
- each of WAN, LAN 1 and LAN 2 links at 1000 Mb/s full duplex and
  passes iperf3 both ways (160-205 Mb/s out, 262-273 Mb/s in, well
  under line rate; I have not looked into where the limit is);
- 10 GB each way through LAN 1, after which every CRC, alignment,
  error, drop, overflow and underflow counter on eth0 and lan1 is 0;
- 50 link down/up cycles, after which the link and traffic recover;
- the MAC address from the factory partition, and ethtool reporting the
  link with no PCS workaround.

---
Joseph Telaak (2):
      dt-bindings: net: Add Siflower SF19A2890 GMAC
      net: stmmac: Add Siflower SF19A2890 glue

 .../bindings/net/siflower,sf19a2890-gmac.yaml      | 110 ++++++++++++++
 .../devicetree/bindings/net/snps,dwmac.yaml        |   1 +
 drivers/net/ethernet/stmicro/stmmac/Kconfig        |  11 ++
 drivers/net/ethernet/stmicro/stmmac/Makefile       |   1 +
 .../net/ethernet/stmicro/stmmac/dwmac-sf19a2890.c  | 158 +++++++++++++++++++++
 5 files changed, 281 insertions(+)
---
base-commit: 7b6ab4dbc156e2f96419715130b3d5738a306c93
change-id: 20261102-sf19a2890-gmac-4fb4808f869c

Best regards,
--  
Joseph Telaak <joseph@telaak.dev>

