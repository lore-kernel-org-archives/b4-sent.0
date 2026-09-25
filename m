From: Michael Reeves <michael.reeves077@gmail.com>
Subject: [PATCH v4 00/10] Add support for Apple Silicon DockChannel
 internal keyboards
Date: Fri, 25 Sep 2026 22:09:27 +1000
Message-Id: <20260925-apple-mtp-keyboard-final-v4-0-304c267518f4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6XPTWrDMBAF4KsErTtF/4mz6j1KFyN5FIvalpGMa
 Qi+e6VsGgothS4fzHxv5sYK5UiFnQ83lmmLJaa5Bv10YH7A+UIQ+5qZ5NJyKzvAZRkJpnWBd7q
 6hLmHEGccoRPeGbQh6OBZXV8yhfhxp1/fanZYCFzG2Q8NnLCslNtgyGmCdciED02K/9y0CeBgu
 O07ZVEc+fHlMmEcn32amjfEsqZ8vb+0iVb/T7Ndv8kvqBOnXyBZITTengwZ7iz/Dqm/QqpCpIz
 VVpM22j1C+75/AgCMxZW7AQAA
X-Change-ID: 20260629-apple-mtp-keyboard-final-91cb5a6ff4fc
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Jassi Brar <jassisinghbrar@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Hector Martin <marcan@marcan.st>, 
 Michael Reeves <michael.reeves077@gmail.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 iommu@lists.linux.dev, linux-input@vger.kernel.org, 
 Yureka Lilian <yureka@cyberchaos.dev>, Julian Braha <julianbraha@gmail.com>, 
 Sasha Finkelstein <k@chaosmail.tech>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790338174; l=6237;
 i=michael.reeves077@gmail.com; s=fedora-20260918; h=from:subject:message-id;
 bh=hxwPLIWGB9VFacGMzl96vn0a9gK+osjE6UJ2ESecD7k=;
 b=uwKlpt0ybpOmsl3B2L9VRnoEgdwRk9jnY9xtfDU/A0D8x94+c/0nzCxHWQAaeZSOaQWfP3lT1
 DbqhI7t8bwCBCjWU1MRHA66ylkuiWW04MDqGbh2aeQzxeBeU2iCzBbe
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=VJ0TvyQ9TvfzYZa908YSE9kpkjFLLD5luv0bERu+boc=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/fedora-20260918 with auth_id=1035
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series introduces support for the internal keyboards on Apple
Silicon M2 and M3 MacBook models.

On these platforms, built-in input devices are managed by a dedicated
coprocessor running an RTKit-based operating system. Communication
between this coprocessor and the main processor is carried out over a
low-latency hardware byte FIFO interface called DockChannel.

To support this input path, the series introduces a few new components:
- An apple-dockchannel mailbox driver to handle the low-level
  byte-stream FIFO.
- A DockChannel HID transport driver (apple-hid) that boots the
  coprocessor using the RTKit framework and encapsulates the HID
  protocol over the mailbox.
- Minor additions to the apple-rtkit and hid-apple drivers to support
  the TraceKit endpoint and integrate the keyboards into the existing
  input-quirks framework.
- Devicetree bindings and DTS updates to describe the nodes on M2 and
  M3 laptops.

The transport driver is based on an original out-of-tree implementation
by Hector Martin, but it has been significantly rewritten for upstream
inclusion to use the standard Linux mailbox framework and align better
with upstream HID design patterns and reduce reliance on hacks.

While the coprocessor manages both the keyboard and the trackpad, this
series only enables keyboard support. The keyboard can be initialised
without loading external firmware, whereas the trackpad requires
firmware. Trackpad support will be submitted in a subsequent series
once these base transport layers are established.

Tested on: MacBook Air M3 (J613).

Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>

Changes in v4:
- Link to v3: https://lore.kernel.org/all/20260918-apple-mtp-keyboard-final-v3-0-e356464e454b@gmail.com/
- Describe the DockChannel interrupt pair in DT (suggested by Yureka Lilian).
- Serialize command transactions and finish STM setup before signalling ready.
- Keep IRQ flag reads and acknowledgements under the controller lock.
- Clarify teardown synchronization and use the explicit-bounds HID API.
- Preserve interface-start errors and allow waiting again for delayed readiness.
- Simplify FIFO writes, IRQ startup and compatible matching.
- The command and IRQ changes address Sashiko feedback.

Changes in v3:
- Link to v2: https://lore.kernel.org/all/20260918-apple-mtp-keyboard-final-v2-0-a5c685e50b60@gmail.com/
- Fix failed-probe cleanup and interface publication ordering.
- Fix report lengths/types and reject replacement descriptors.
- Terminate serial replies and encode checksums as little endian.
- Honor HID_QUIRK_IGNORE_SPECIAL_DRIVER.
- Clarify the DockChannel TX byte register layout.
- All changes above address Sashiko feedback.

Changes in v2:
- Link to v1: https://lore.kernel.org/asahi/20260630-apple-mtp-keyboard-final-v1-0-506d936a1707@gmail.com/
- Rebase onto latest upstream and add M3 Pro/Max device-tree support.
- Use an optional STM node to decide whether to wait for device IDs
  (suggested by Yureka Lilian).
- Rename bindings to match the t8112 fallback (suggested by Conor Dooley).
- Fix FIFO MMIO write width (suggested by Yureka Lilian) and run mailbox
  interrupt handling in the IRQ thread.
- Remove the duplicate report fixup (suggested by Sasha Finkelstein)
  and redundant HID dependency (suggested by Julian Braha).
- Fix teardown and the missing HID stop callback; simplify interface lookup.

---
Michael Reeves (9):
      dt-bindings: mailbox: apple: Add M3 ASC mailbox compatibles
      dt-bindings: mailbox: apple: Add DockChannel mailbox
      dt-bindings: iommu: apple,dart: Add M3 compatibles
      dt-bindings: input: apple: Add DockChannel HID transport
      mailbox: apple: Add DockChannel FIFO controller
      HID: apple: Add support for DockChannel HID keyboards
      HID: apple: Add DockChannel HID transport driver
      arm64: dts: apple: Add MTP DockChannel HID nodes
      arm64: dts: apple: Enable DockChannel HID on M2 and M3 laptops

Sasha Finkelstein (1):
      soc: apple: rtkit: Add tracekit endpoint

 .../input/apple,t8112-dockchannel-hid.yaml         |  104 ++
 .../devicetree/bindings/iommu/apple,dart.yaml      |    6 +-
 .../devicetree/bindings/mailbox/apple,mailbox.yaml |    3 +
 .../bindings/mailbox/apple,t8112-dockchannel.yaml  |   88 ++
 MAINTAINERS                                        |    5 +
 arch/arm64/boot/dts/apple/t602x-die0.dtsi          |   47 +
 arch/arm64/boot/dts/apple/t602x-j414-j416.dtsi     |   29 +
 arch/arm64/boot/dts/apple/t6030.dtsi               |   47 +
 arch/arm64/boot/dts/apple/t6031-die0.dtsi          |   47 +
 arch/arm64/boot/dts/apple/t603x-j514-j516.dtsi     |   24 +
 arch/arm64/boot/dts/apple/t8112-j413.dts           |   24 +
 arch/arm64/boot/dts/apple/t8112-j415.dts           |   24 +
 arch/arm64/boot/dts/apple/t8112-j493.dts           |   26 +-
 arch/arm64/boot/dts/apple/t8112.dtsi               |   47 +
 arch/arm64/boot/dts/apple/t8122-j504.dts           |   26 +
 arch/arm64/boot/dts/apple/t8122-j613.dts           |   27 +
 arch/arm64/boot/dts/apple/t8122-j615.dts           |   27 +
 arch/arm64/boot/dts/apple/t8122.dtsi               |   48 +
 drivers/hid/Kconfig                                |    2 +
 drivers/hid/Makefile                               |    2 +
 drivers/hid/dockchannel/Kconfig                    |   14 +
 drivers/hid/dockchannel/Makefile                   |    3 +
 drivers/hid/dockchannel/apple-hid.c                | 1191 ++++++++++++++++++++
 drivers/hid/hid-apple.c                            |  118 +-
 drivers/mailbox/Kconfig                            |   12 +
 drivers/mailbox/Makefile                           |    2 +
 drivers/mailbox/apple-dockchannel.c                |  357 ++++++
 drivers/soc/apple/rtkit.c                          |    2 +
 include/linux/hid.h                                |    1 +
 include/linux/mailbox/apple-dockchannel.h          |   29 +
 30 files changed, 2334 insertions(+), 48 deletions(-)
---
base-commit: 5dd1818b15d98d4a20806cd00b1b40320b06004f
change-id: 20260629-apple-mtp-keyboard-final-91cb5a6ff4fc

Best regards,
-- 
Michael Reeves <michael.reeves077@gmail.com>

