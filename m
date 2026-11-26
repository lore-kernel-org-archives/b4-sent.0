From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH net-next v3 0/3] Add Cortina Systems CS7542 MDIO controller
 support
Date: Thu, 26 Nov 2026 12:27:32 +0300
Message-Id: <20261126-b4-cs7542-mdio-v3-0-35739a0f3225@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NTQ7CIBhEr2JYi+G/jSvvYVy08NliLBhAUtP07
 lLcuNHlZOa9WVCEYCGi425BAbKN1rsS+H6H9Ni5AbA1JSNGmKKUcdwLrGMjBcOTsR6DFgIa2UD
 LBCrQI8DVzlV4Rg4SdjAndPk08dnfQKfNt21HG5MPr/qdaSV+3WSKCVZMGdIR4L0wp2Hq7P2g/
 VTlmf3HWcE5EUpCy2kr+Te+rusbNBsRNwcBAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795685252; l=4352;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=v4DtyEWM6eYR9iYKjGXdhR8kKtgwE4w8iV+oL7nK5eA=;
 b=k5okNZM1O0l1t82MvEdJICkqbAx5ePb28Uq98hkov9m7VT8S0FMbo6Tc16EpVTL8Tjp5FycTl
 3tGpku/3S5MBUMyJOh2qVTMTjLpRhPMUd6ac/ddjymX0NlAdUQfpHB7
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Clause 22 MDIO controller used by the CS7542 network engine.
The driver retains the MDC prescaler initialized by platform firmware and
uses bounded polling for each transaction. It is independent of the
pending Cortina platform series and COMPILE_TEST.

V2 followed Andrew Lunn's review: remove the pending-frame state and keep
one straightforward transaction/poll per read or write. No timeout was
observed at the normal firmware-selected MDC rate. The timeout mentioned
in v1 validation was deliberately induced only in a RAM test by slowing
the prescaler; it was not evidence of a normal bus failure. No clock-loss
recovery guarantee is provided by this driver.

Validation of v2:
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

The MDIO input clock is APB. On Almond+, temporarily selecting the vendor
600 MHz CPU mode changed APB from 150 to 100 MHz while AXI stayed at
150 MHz. With the same MDIO prescaler, the transaction took the same
number of APB timer ticks (median 66512 versus 66537), while CPU cycles
increased from 332326 to 399013, matching the CPU/APB ratio change from
5 to 6. Restoring the original mode restored the original measurements.
All 24 PHY-ID1 reads returned 004d. The original clock override and MDIO
configuration were restored, and the installed OpenWrt remained running.

Describe this input in the binding and allow the optional clock-frequency
property inherited from mdio.yaml. The accompanying peripheral DTS update
connects MDIO to the APB clock. The initial driver continues to retain the
firmware prescaler; this experiment does not establish the exact divisor
encoding and no programmable MDC calculation is introduced here.

---
Changes in v3:
- Use sleepable polling in the MDIO bus callbacks.
- Describe the hardware MDC prescaler and experimentally verified APB
  input clock; allow the inherited optional clock-frequency property.
- Remove the unused private mii_bus pointer.
- Link to v2: https://patch.msgid.link/20261123-b4-cs7542-mdio-v2-0-30465e831853@gmail.com

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

 .../bindings/net/cortina,cs7542-mdio.yaml          |  52 +++++++++
 MAINTAINERS                                        |   7 ++
 drivers/net/mdio/Kconfig                           |  12 +++
 drivers/net/mdio/Makefile                          |   1 +
 drivers/net/mdio/mdio-cs75xx.c                     | 116 +++++++++++++++++++++
 5 files changed, 188 insertions(+)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-b4-cs7542-mdio-ec44e757e824

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

