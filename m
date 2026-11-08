From: Michael Reeves <michael.reeves077@gmail.com>
Subject: [PATCH v5 0/8] Add support for Apple Silicon DockChannel internal
 keyboards
Date: Sun, 08 Nov 2026 07:25:05 +0000
Message-Id: <20261108-b4-apple-mtp-keyboard-v5-0-e2c97b82669a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw6CMBBG4Vchs3aSDkGDvopx0Za/Ol6gacFoC
 O9O0eW3OGemjKTIdKpmSnhr1qEv2O8q8jfbX8HaFVNt6oOIadk1bGN8gl9j5Ae+brCp42MTxAf
 TIohQaWNC0M/ve778nSd3hx+3GS3LCrRNPvR5AAAA
X-Change-ID: 20261108-b4-apple-mtp-keyboard-94f1cf08ef11
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Jassi Brar <jassisinghbrar@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>, 
 Michael Reeves <michael.reeves077@gmail.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-input@vger.kernel.org, Yureka Lilian <yureka@cyberchaos.dev>, 
 Hector Martin <marcan@marcan.st>, Sasha Finkelstein <k@chaosmail.tech>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794122710; l=6706;
 i=michael.reeves077@gmail.com; s=20261107; h=from:subject:message-id;
 bh=oZ1mf4X7qkbYYE4msjSc6m28dHS86c7Eq0mA+YXb+hg=;
 b=v7ki5JFSQhh+Q4zMjzyf2zjxjqVKQX0Y8h+QJlST2dPie/6iR4/iewchJkfTySTilGaDN4KQ4
 S16otZvP0PnDkux1SbtRtTWJ/ZxNnuiFknjcJhC7w815itopmzU3QAf
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=ykwkLcuByJYb/cdLc2UuoYP03pIzwrscEZg30+4tJL8=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20261107 with auth_id=1442
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

Changes in v5:
- Link to v4: https://lore.kernel.org/all/20260925-apple-mtp-keyboard-final-v4-0-304c267518f4@gmail.com/
- Drop ASC mailbox and DART binding patches which were picked up and are in apple-soc/dt-7.5
- Simplify HID transport reg-names from coproc-asc/sram to asc/sram (suggested by Rob Herring).
- Replace the empty STM child node with the 'apple,has-stm' boolean property (suggested by Rob Herring).
- Drop the keyboard child node and move 'hid-country-code' to the parent node (suggested by Rob Herring).
- Simplify the transport driver to filter supported interfaces in C and drop fwnode handling.
- Collect Reviewed-by from Rob Herring on the DockChannel mailbox binding.
- Rebase on v7.4-rc1

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
Michael Reeves (7):
      dt-bindings: mailbox: apple: Add DockChannel mailbox
      dt-bindings: input: apple: Add DockChannel HID transport
      mailbox: apple: Add DockChannel FIFO controller
      HID: apple: Add support for DockChannel HID keyboards
      HID: apple: Add DockChannel HID transport driver
      arm64: dts: apple: Add MTP DockChannel HID nodes
      arm64: dts: apple: Enable DockChannel HID on M2 and M3 laptops

Sasha Finkelstein (1):
      soc: apple: rtkit: Add tracekit endpoint

 .../input/apple,t8112-dockchannel-hid.yaml         |   92 ++
 .../bindings/mailbox/apple,t8112-dockchannel.yaml  |   88 ++
 MAINTAINERS                                        |    5 +
 arch/arm64/boot/dts/apple/t602x-die0.dtsi          |   47 +
 arch/arm64/boot/dts/apple/t602x-j414-j416.dtsi     |   24 +
 arch/arm64/boot/dts/apple/t6030.dtsi               |   47 +
 arch/arm64/boot/dts/apple/t6031-die0.dtsi          |   47 +
 arch/arm64/boot/dts/apple/t603x-j514-j516.dtsi     |   19 +
 arch/arm64/boot/dts/apple/t8112-j413.dts           |   19 +
 arch/arm64/boot/dts/apple/t8112-j415.dts           |   19 +
 arch/arm64/boot/dts/apple/t8112-j493.dts           |   21 +-
 arch/arm64/boot/dts/apple/t8112.dtsi               |   47 +
 arch/arm64/boot/dts/apple/t8122-j504.dts           |   22 +
 arch/arm64/boot/dts/apple/t8122-j613.dts           |   22 +
 arch/arm64/boot/dts/apple/t8122-j615.dts           |   22 +
 arch/arm64/boot/dts/apple/t8122.dtsi               |   48 +
 drivers/hid/Kconfig                                |    2 +
 drivers/hid/Makefile                               |    2 +
 drivers/hid/dockchannel/Kconfig                    |   14 +
 drivers/hid/dockchannel/Makefile                   |    3 +
 drivers/hid/dockchannel/apple-hid.c                | 1167 ++++++++++++++++++++
 drivers/hid/hid-apple.c                            |  118 +-
 drivers/mailbox/Kconfig                            |   12 +
 drivers/mailbox/Makefile                           |    2 +
 drivers/mailbox/apple-dockchannel.c                |  357 ++++++
 drivers/soc/apple/rtkit.c                          |    2 +
 include/linux/hid.h                                |    1 +
 include/linux/mailbox/apple-dockchannel.h          |   29 +
 28 files changed, 2251 insertions(+), 47 deletions(-)
---
base-commit: 1d368e025d7c4fe63c8bf68ccb4bc3c9772ab75c
change-id: 20261108-b4-apple-mtp-keyboard-94f1cf08ef11

Best regards,
--  
Michael Reeves <michael.reeves077@gmail.com>

