From: Joseph Telaak <joseph@telaak.dev>
Subject: [PATCH net-next v2 0/2] net: dsa: mxl-gsw1xx: reset the switch
 through reset-gpios
Date: Sun, 08 Nov 2026 17:59:49 -0500
Message-Id: <20261108-mxl-gsw1xx-reset-v2-0-46c1da093893@telaak.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOb+8GoC/2WNwRKCIBRFf8V562gE0qhV/9G4QHwqpdgAEY3jv
 4fWruWde889Mzi0Gh2csxksBu30ZFJguwxUL02HRDcpA8tZSWnOyBgH0rkXjZFYdOgJP0oleFl
 z2iIk7GGx1XG7vIJJA4PRQ/Vt3LO+ofLr47rttfOTfW/2QDfiJzr8iwIlOSm44Ke6LZQQePE4S
 HnfNxigWpblA9vgvMPNAAAA
X-Change-ID: 20261102-mxl-gsw1xx-reset-37ac836b31fe
To: Hauke Mehrtens <hauke@hauke-m.de>, Andrew Lunn <andrew@lunn.ch>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Daniel Golle <daniel@makrotopia.org>, netdev@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794178811; l=2239;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=f7rumqhBXVUbXmTQZIshRAFnkK32CNzOSjjgSSKpiR8=;
 b=QPAUW8a6ugRpkrJXJB0dpgxYkTIc00FbTxffLAyGFvXNzMo0+oOzQN6D7pmH7oGNVdOW5byIQ
 9vzvn8KKZvODJte0VI1bitiTyaXrXpToT4D8bLxZliyOTdg7afkj0KT
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The GSW1xx driver never resets the switch, and the MDIO core does not
handle reset-gpios for non-PHY devices, so the driver works with whatever
the bootloader configured. On the GL.iNet GL-SFT1200 (Siflower SF19A2890 +
GSW150) the bootloader leaves the internal PHYs one MDIO address too high,
and the WAN port has no PHY.

Patch 1 allows reset-gpios in the binding for the standalone switches.
Patch 2 pulses it at probe.

This is separate from commit 82e2c7db0830 ("net: dsa: mxl-gsw1xx: force
internal PHYs into a known reset state"), which only programs the PHY
bits of RST_REQ. On this board that commit is applied, and the PHYs still
sit at the shifted addresses; only a hardware reset of the switch moves
them back.

Tested on a GL.iNet GL-SFT1200 (Intel GSW150 / PEB7084 at SMI address
0x1f, reset on an active-low SoC GPIO), on v7.4-rc1 with
CONFIG_RESET_GPIO=y: after a warm reboot and after a cold power-on, all
three ports find their PHYs at addresses 0 to 2 and link at 1 Gbit/s.
Without the patch, port 0 fails with -ENODEV after every boot.

There is no in-tree user yet: the GL-SFT1200's device tree is under
review on linux-mips without the switch, which follows once the SoC's
GMAC is supported.

---
Changes in v2:
- Use the reset controller API, so reset-gpios goes through reset-gpio,
  instead of driving the GPIO from the driver (Daniel).
- Use the vendor driver's reset timing, 250 ms asserted and 1 s before
  the first access. v1 gave 2 ms and 100 ms as the vendor's, which they
  are not.
- Patch 1: add Rob's Ack.
- Link to v1: https://patch.msgid.link/20261104-mxl-gsw1xx-reset-v1-0-53839bf5c88e@telaak.dev

---
Joseph Telaak (2):
      dt-bindings: net: dsa: lantiq,gswip: add reset-gpios
      net: dsa: mxl-gsw1xx: reset the switch through reset-gpios

 .../devicetree/bindings/net/dsa/lantiq,gswip.yaml  |  6 ++++++
 drivers/net/dsa/lantiq/mxl-gsw1xx.c                | 25 ++++++++++++++++++++++
 drivers/net/dsa/lantiq/mxl-gsw1xx.h                |  4 ++++
 3 files changed, 35 insertions(+)
---
base-commit: 4dd16e31135ea8437a720222df34e8745f385d6d
change-id: 20261102-mxl-gsw1xx-reset-37ac836b31fe

Best regards,
--  
Joseph Telaak <joseph@telaak.dev>

