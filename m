From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH net-next v4 0/3] Add Cortina Systems CS7542 MDIO controller
 support
Date: Fri, 27 Nov 2026 13:14:21 +0300
Message-Id: <20261127-b4-cs7542-mdio-v4-0-0e37fc0c47d5@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NQQ6CMBAF0KuQrq1pZ9qCrryHcQHtADUChiLBE
 O4u4IZodPkz8/4fWaDWU2DHaGQt9T74pp6D2kXMlmldEPduzgwEGCkBeaa4DbFWwCvnG05WKYp
 1TAkoNqN7S7kf1sIzq6njNQ0du7wv4ZFdyXZL3/Jb+tA17XPd7uUqfs30kgtuwDiRCsJMuVNRp
 f62t021lvfwn8PMUSijKUGZaPzkuOXmi+PCdYyHVOQIoLd8mqYXMEeqkkYBAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795774461; l=4018;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=cL1FyNfM+w+TuBfusbsasQXCzAFXpIl+/zYfl/yh6WE=;
 b=XoT5tbTPB+u4Hl3bU23tP2j+OHoTf8/TOLp4E8sGdrfqBt1kaGwloPBGi4E3924nxFhBLvQPE
 Jit/TekuftRDUubP8lIB0YEcod3qJQqc/5vP73/R5nJmXAoW/Yamy+D
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the CS7542 Clause 22 MDIO controller with bounded, sleepable polling.
The driver is independent of the pending platform series and COMPILE_TEST.
It retains the firmware MDC prescaler while enabling software-initiated
transactions.

This revision acquires and enables the APB input required by the binding
before the first register access. The managed clock remains enabled until
the managed MDIO bus is unregistered. Clock lookup or enable failures,
including probe deferral, return before touching registers. No clock-rate
or MDC-divisor programming is added.

The APB source was established previously on Almond+ by changing APB from
150 to 100 MHz while AXI stayed at 150 MHz and comparing MDIO transaction
timing. The binding describes that source and allows clock-frequency from
mdio.yaml; the exact prescaler divisor encoding remains unestablished.

Validation for v4:
- The actual probe passes 10 allocation, map, clock, registration and
  cleanup-order cases with GCC/Clang ASan/UBSan. The pre-fix probe reproduces
  an MMIO access without an enabled clock under the same helpers.
- Native ARM driver=y object and exact Linux 6.18 driver=m module compile
  with W=1 and KCFLAGS=-Werror; existing configurations are unchanged.
- A read-only consumer probe on the running Almond+ obtained and enabled
  cs7542-apb at 150 MHz. MDIO CFG stayed 00200001; all references were dropped,
  the same OpenWrt boot continued and its watchdog/settings were preserved.
  This exercises the consumer/provider path, not a full live bus reprobe.

Earlier v2/v3 full independent builds, binding checks and RAM PHY read/write
results remain recorded. The transaction logic and firmware prescaler are
unchanged here; the old hardware matrix was not repeated.

---
Changes in v4:
- Enable the required APB input before accessing MDIO registers and keep it
  enabled through bus teardown.
- Clarify MANUAL transaction selection and preservation of the firmware
  MDC prescaler.
- Link to v3: https://lore.kernel.org/all/20261126-b4-cs7542-mdio-v3-0-35739a0f3225@gmail.com/

Changes in v3:
- Use sleepable polling in the MDIO bus callbacks.
- Describe the experimentally established APB input and allow the inherited
  optional clock-frequency property.
- Remove the unused private mii_bus pointer.
- Link to v2: https://lore.kernel.org/all/20261123-b4-cs7542-mdio-v2-0-30465e831853@gmail.com/

Changes in v2:
- Drop pending-frame state after Andrew Lunn's review.
- Sort Kconfig/Makefile entries and retain Andrew's Reviewed-by on the
  MAINTAINERS patch only.
- Link to v1: https://lore.kernel.org/all/20261123-b4-cs7542-mdio-v1-0-626d0a0e3b4d@gmail.com/

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

 .../bindings/net/cortina,cs7542-mdio.yaml          |  52 +++++++++
 MAINTAINERS                                        |   7 ++
 drivers/net/mdio/Kconfig                           |  12 ++
 drivers/net/mdio/Makefile                          |   1 +
 drivers/net/mdio/mdio-cs75xx.c                     | 126 +++++++++++++++++++++
 5 files changed, 198 insertions(+)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-b4-cs7542-mdio-ec44e757e824

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

