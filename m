From: Kyle Hendry <khendry@reliablecontrols.com>
Subject: [PATCH 0/6] clk: renesas: r9a06g032: Add reset controller to clear
 resets for mii converter
Date: Thu, 19 Nov 2026 09:57:42 -0800
Message-Id: <20261119-rzn1-miic-resets-v1-0-feee2bb28bb4@reliablecontrols.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MPQqAMAxA4atIZgNtxR+8ijiUGjWDVRIRUXp3i
 +M3vPeCkjAp9MULQhcr7zHDlgWE1ceFkKdscMY11rgW5YkWN+aAQkqnYleZrra19y4YyNkhNPP
 9L4cxpQ8J1pusYgAAAA==
X-Change-ID: 20261027-rzn1-miic-resets-8308515aa2c0
To: Geert Uytterhoeven <geert+renesas@glider.be>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Magnus Damm <magnus.damm@gmail.com>, 
 Fabrizio Castro <fabrizio.castro.jz@renesas.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 =?utf-8?q?Cl=C3=A9ment_L=C3=A9ger?= <clement.leger@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Lad Prabhakar <prabhakar.mahadev-lad.rj@bp.renesas.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: linux-renesas-soc@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 netdev@vger.kernel.org, Kyle Hendry <khendry@reliablecontrols.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795111097; l=1387;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=VM7uW+z0dcnrH+6sPmftwId4Zj/tt42hzIKtv80ndFo=;
 b=GvGxRgU2SyYbnaJSMZVSGihx5MpcwtT4kKTRtaDimQphnNfLGkyHgS+5GojztchRAGRQ39I8e
 7tB0p5pLCPmAvajtZiL0DwjYQriMFSxEv2nIaf1tfdfSVhUgTsh6/TZ
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the rzn1, there are two resets for the mii converter in the system
controller. If they are not cleared by the bootloader then the kernel needs
to do it. 

To handle this, I've added a reset controller interface to the clock
driver so the miic driver can deassert them.

Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
Kyle Hendry (6):
      dt-bindings: clock: r9a06g032-sysctrl: Document reset cells
      clk: renesas: r9a06g032: Add reset controller
      ARM: dts: renesas: r9a06g032: Add #reset-cells to system controller node
      dt-bindings: net: pcs: renesas,rzn1-miic: Document rzn1 resets
      net: pcs: rzn1-miic: Add resets to rzn1 info structure
      ARM: dts: renesas: r9a06g032: Add resets to mii converter

 .../bindings/clock/renesas,r9a06g032-sysctrl.yaml  |  3 +
 .../bindings/net/pcs/renesas,rzn1-miic.yaml        | 36 ++++++++----
 arch/arm/boot/dts/renesas/r9a06g032.dtsi           |  4 ++
 drivers/clk/renesas/r9a06g032-clocks.c             | 64 ++++++++++++++++++++++
 drivers/net/pcs/pcs-rzn1-miic.c                    |  7 +++
 include/dt-bindings/clock/r9a06g032-sysctrl.h      |  3 +
 6 files changed, 106 insertions(+), 11 deletions(-)
---
base-commit: 662377fd1bb1d7cf4e97d312255fed868f56342d
change-id: 20261027-rzn1-miic-resets-8308515aa2c0

Best regards,
-- 
Kyle Hendry <khendry@reliablecontrols.com>

