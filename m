From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH net-next v2 0/3] Add Cortina Systems CS7542 MDIO controller
 support
Date: Mon, 23 Nov 2026 23:40:37 +0300
Message-Id: <20261123-b4-cs7542-mdio-v2-0-30465e831853@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNwQ6CMBBEf4Xs2TVtKWA8+R+GA7QrrJGWtJVgC
 P8u4Nnjy8y8WSBSYIpwzRYINHFk7zZQpwxM37iOkO3GoIQqpVQ5thpNrAqtcLDskYzWVBUVXZS
 GbTQGevB8CO/gKKGjOUH9S+K7fZJJu2/v9hyTD5/je5LH4t/NJFFgqUorGkF5q+2tGxp+nY0fo
 F7X9QvVey6HyAAAAA==
X-Change-ID: 20261123-b4-cs7542-mdio-ec44e757e824
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Andrew Lunn <andrew+netdev@lunn.ch>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795466438; l=3043;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=2XRyBPIMRh1j+zYtAlcrPeywf0p5acJiOwhwhsnWEZw=;
 b=mIwMxphAuGSFzxUDwNw4M+d85hXwZXqjFAxuvk1bs6bmvGsfJ8ukAoR//oKgVXE+sbFzzWhlT
 E4qP9FegumEAdgbYHEiC0me+BI+N6rKcMfY96I/hhX7kFKgzrb3A6OQ
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Clause 22 MDIO controller used by the CS7542 network engine.
The driver retains the MDC prescaler initialized by platform firmware and
uses bounded polling for each transaction. It is independent of the
pending Cortina platform series and COMPILE_TEST.

V2 follows Andrew Lunn's review: remove the pending-frame state and keep
one straightforward transaction/poll per read or write. No timeout was
observed at the normal firmware-selected MDC rate. The timeout mentioned
in v1 validation was deliberately induced only in a RAM test by slowing
the prescaler; it was not evidence of a normal bus failure. No clock-loss
recovery guarantee is provided by this driver.

Validation:
- Full independent ARM vmlinux/modules builds with driver=y and=m,
  COMPILE_TEST=n, without the platform series.
- Actual driver read/write/wait functions: 5125 address, data and timeout
  cases under UBSan, including no data read after timeout.
- Binding and strict driver checks; b4 dependency/preflight checks.

V2 booted Linux 7.4 in RAM on Almond+: PHY IDs 004d:d036, the firmware
prescaler 00200001, and same-value advertisement write/readback passed.
A deliberately slowed MDC produced ETIMEDOUT at about 14ms; restoring the
prescaler returned the correct IDs. Final RAM result: failures=0 and
automatic return to installed OpenWrt. No NAND driver was loaded and no
flash writes were performed.

---
Changes in v2:
- Drop the pending-frame state as requested by Andrew Lunn.
- Sort Kconfig by prompt after MDIO_CAVIUM and sort the Makefile entry.
- Add Andrew's Reviewed-by to the MAINTAINERS patch only.
- Link to v1: https://patch.msgid.link/20261123-b4-cs7542-mdio-v1-0-626d0a0e3b4d@gmail.com

To: Fil Dunsky <filipp.dunsky@gmail.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>
To: "David S. Miller" <davem@davemloft.net>
To: Eric Dumazet <edumazet@kernel.org>
To: Jakub Kicinski <kuba@kernel.org>
To: Paolo Abeni <pabeni@redhat.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Andrew Lunn <andrew@lunn.ch>
To: Heiner Kallweit <hkallweit1@gmail.com>
To: Russell King <linux@armlinux.org.uk>
Cc: netdev@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Fil Dunsky (3):
      dt-bindings: net: Add Cortina CS7542 MDIO controller
      net: mdio: Add Cortina CS7542 bus controller
      MAINTAINERS: Add Cortina CS7542 MDIO controller entry

 .../bindings/net/cortina,cs7542-mdio.yaml          |  48 +++++++++
 MAINTAINERS                                        |   7 ++
 drivers/net/mdio/Kconfig                           |  12 +++
 drivers/net/mdio/Makefile                          |   1 +
 drivers/net/mdio/mdio-cs75xx.c                     | 119 +++++++++++++++++++++
 5 files changed, 187 insertions(+)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-b4-cs7542-mdio-ec44e757e824

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

