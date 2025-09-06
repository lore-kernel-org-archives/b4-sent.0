From: Sven Peter <sven@kernel.org>
Subject: [PATCH v2 00/22] Apple Silicon USB3 support
Date: Sat, 06 Sep 2025 15:43:13 +0000
Message-Id: <20250906-atcphy-6-17-v2-0-52c348623ef6@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJJWvGgC/1XMQQrDIBCF4auEWdeiU1qlq94jZKFmEqVFgwZpC
 N69NtBFV8M/8L4dMiVPGe7dDomKzz6GFnjqwDodZmJ+bA3I8coVcqZXu7iN3ZiQzEjSE14MCWm
 hLZZEk38fWj+0dj6vMW0HXsT3+3PEn1ME4+2ioVELhUY9npQCvc4xzTDUWj/mE1lwpwAAAA==
X-Change-ID: 20250820-atcphy-6-17-b7eaf23be17c
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Felipe Balbi <balbi@kernel.org>, 
 Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Frank Li <Frank.Li@nxp.com>, 
 Ran Wang <ran.wang_1@nxp.com>, Peter Chen <peter.chen@nxp.com>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 Sven Peter <sven@kernel.org>, stable@kernel.org, 
 Hector Martin <marcan@marcan.st>, R <rqou@berkeley.edu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=10497; i=sven@kernel.org;
 h=from:subject:message-id; bh=B2PmqO8jFsYcp9IfYjXmvUC+hdyx9Na0xGIpQfiCq3E=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8aesMlmluHV2zTUZB173myaePexf/uspYEqlw47XHrSw
 vPrRlxYRykLgxgHg6yYIsv2/famTx6+EVy66dJ7mDmsTCBDGLg4BWAiCVwM/3OWcm7WeaoboSbN
 OKvVIqXK+lNLnl6WXW/gfKs1EQeXXWb4w98TGXD49Mbirn5d2ecfD34x2D5z6zr52RvXl0qmxlo
 kMwAA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

With the dwc3 glue approach this is starting to look reasonable to me.

There's still one issue (SuperSpeed devices have a 5 second delay before
they come up; This has been known for ages and we haven't been able to
identify the root cause) but otherwise both host and device mode have
been working quite well across a number of different devices (usb3 only,
usb3+dp, dp-only, usb4, and the first two combined with a broken c-to-a
adapter that can trigger a lot of quick plug/unplug events ;)) for me.

With the dwc3 glue driver this series can now also be merged independently
once it's ready: Patches 1-4 can go through the dwc3 tree, 5-15 through
tipd, 16-18 should go together through the phy tree, and I'll take the
DTS changes through my tree. If everyone's happy with the overall
approach here I can also just send these as individual series.

A tree for testing is again available as apple-usb3-v2 at [5]. 

Changes in v2:
- Link to v1: https://lore.kernel.org/r/20250821-atcphy-6-17-v1-0-172beda182b8@kernel.org
- Fixed dt-binding warnings
- Extended the glue layer to allow control over mode switching
- Removed quirks added to dwc3 and implemented them as a glue
  driver instead as suggested by Thinh
- Dropped snps,dwc3 fallback compatible since this is neither compatible
  with the glue driver approach nor is this hardware truly compatible
  with snps,dwc3 unless the bootloader did a lot of heavy-lifting and
  left everything in just the right state
- Dropped atcphy dp-only compatible since this can be detected in other
  ways or just be driven from the dp controller once we upstream that
- Fixed duplicate #define in TIPD
- Use ioremap_np when required instead of just skipping
  dwc3_power_off_all_roothub_ports
- Dropped the change that added the USB role to typec_mux_state since
  the new glue driver approach no longer requires this.
- Cleaned up some leftover TODOs in atcphy and ran clang-format
- Reworked tunables.c to use a variable sized member and alloc the
  entire struct directly
- Shortened debug messages in atcphy
- Added DTS changes for t8112 and t600x
- Call typec_unregister_altmode unconditionally as it's NULL-safe
- Fixed arre -> arr typo in commit message
- Drop __func__ from cd321x_interrupt debug print
- Picked up Heikki's r-b tags

Original cover letter:

This series includes changes to dwc3, tipd and a new phy driver to enable
USB3 on these machines. There's also some preparations to eventually enable
DisplayPort AltMode and Thunderbolt but those need future work.
Overall, this entire setup is quite a mess and we've tried to make it work
for quite a while now and finally came up with this solution here.

The USB3 controller is a very special kind of broken: It never sees any port
plug/unplug events that should normally arrive directly at dwc3.
Additionally, it needs to go through a full hard reset for every new connection
and most mode change. Details on why this is required are in the commit
description.

On top of that we need to keep the Type-C PHY bringup and dwc3 bringup tightly
synchronized. If there's a race between the two systems at best the port stops
working until a system reboot and at worst there's a watchdog somewhere that
forcefully resets the entire SoC after ~5 seconds. I've only seen the latter
when bringing up thunderbolt so far but wouldn't be surprised if it happens
with just usb3 as well.

The entire bringup/bringup is orchestrated by a TIPD variant called CD321x
found on these machines. Unlike the original chips we however get no control
over which mode is negotiated or are even able to see the PDOs or VDOs. We only
get to know once the mode has been negotiated and have to act accordingly. I
even went as far as dumping the firmware from the chip to confirm this [1][2].

Hector wrote another summary of this early in January as well [3] and this
series is the only way we've been able to bring these ports up reliably.
It's not pretty in some places but I have no other idea how to implement this,
hence the RFC tag. Happy to discuss other approaches as well.

Both the PHY and the TIPD driver already include changes for DisplayPort
AltMode and USB4/Thunderbolt. These need additional work though but
since we can't control the mode devices end up in we can already merge
them now.

I used phy/qcom,sc8280xp-qmp-usb43dp-phy.yaml as a template for the dt-binding
for atcphy (especially the ports). That was the most recent binding I found for
a PHY with similar features.

In order to test this you need to run the latest m1n1 master [4] because the
1.5.0 release does not include the code that lifts the tunables from Apple's
device tree. A kernel tree for testing is also tagged as apple-usb3-v1 at [5].

If the overall approach here is fine and no one can think of a better way to
support this SoC I'll drop the RFC and include the dts changes for the other
M1 and M2 machines as well.

Best,

Sven

[1] https://social.treehouse.systems/@sven/111092587315536174
[2] https://social.treehouse.systems/@sven/111096589846468888
[3] https://lore.kernel.org/all/fda8b831-1ffc-4087-8e7b-d97779b3ecc5@marcan.st/
[4] https://github.com/AsahiLinux/m1n1
[5] https://git.kernel.org/pub/scm/linux/kernel/git/sven/linux.git

Signed-off-by: Sven Peter <sven@kernel.org>
---
To: Sven Peter <sven@kernel.org>
To: Janne Grunau <j@jannau.net>
To: Alyssa Rosenzweig <alyssa@rosenzweig.io>
To: Neal Gompa <neal@gompa.dev>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Thinh Nguyen <Thinh.Nguyen@synopsys.com>
To: Frank Li <Frank.Li@nxp.com>
To: Ran Wang <ran.wang_1@nxp.com>
To: Peter Chen <peter.chen@nxp.com>
To: Philipp Zabel <p.zabel@pengutronix.de>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>
To: Vinod Koul <vkoul@kernel.org>
To: Kishon Vijay Abraham I <kishon@kernel.org>
Cc: asahi@lists.linux.dev
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-usb@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-phy@lists.infradead.org

---
Hector Martin (5):
      usb: typec: tipd: Update partner identity when power status was updated
      usb: typec: tipd: Use read_power_status function in probe
      usb: typec: tipd: Read data status in probe and cache its value
      usb: typec: tipd: Handle mode transitions for CD321x
      arm64: dts: apple: t8103: Mark ATC USB AON domains as always-on

Janne Grunau (2):
      arm64: dts: apple: t8112: Add Apple Type-C PHY and dwc3 nodes
      arm64: dts: apple: t600x: Add Apple Type-C PHY and dwc3 nodes

Sven Peter (15):
      dt-bindings: usb: Add Apple dwc3
      usb: dwc3: dwc3_power_off_all_roothub_ports: Use ioremap_np when required
      usb: dwc3: glue: Allow more fine grained control over mode switches
      usb: dwc3: Add Apple Silicon DWC3 glue layer driver
      usb: typec: tipd: Clear interrupts first
      usb: typec: tipd: Move initial irq mask to tipd_data
      usb: typec: tipd: Move switch_power_state to tipd_data
      usb: typec: tipd: Trace data status for CD321x correctly
      usb: typec: tipd: Add cd321x struct with separate size
      usb: typec: tipd: Read USB4, Thunderbolt and DisplayPort status for cd321x
      usb: typec: tipd: Register DisplayPort and Thunderbolt altmodes for cd321x
      dt-bindings: phy: Add Apple Type-C PHY
      soc: apple: Add hardware tunable support
      phy: apple: Add Apple Type-C PHY
      arm64: dts: apple: t8103: Add Apple Type-C PHY and dwc3 nodes

 .../devicetree/bindings/phy/apple,atcphy.yaml      |  213 ++
 .../devicetree/bindings/usb/apple,dwc3.yaml        |   80 +
 MAINTAINERS                                        |    4 +
 arch/arm64/boot/dts/apple/t6001.dtsi               |    1 +
 arch/arm64/boot/dts/apple/t6002-j375d.dts          |  197 +-
 arch/arm64/boot/dts/apple/t6002.dtsi               |    1 +
 arch/arm64/boot/dts/apple/t600x-dieX.dtsi          |  212 ++
 arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi     |  236 +++
 arch/arm64/boot/dts/apple/t600x-j375.dtsi          |  275 +++
 arch/arm64/boot/dts/apple/t8103-j274.dts           |   12 +
 arch/arm64/boot/dts/apple/t8103-j293.dts           |   12 +
 arch/arm64/boot/dts/apple/t8103-j313.dts           |   12 +
 arch/arm64/boot/dts/apple/t8103-j456.dts           |   12 +
 arch/arm64/boot/dts/apple/t8103-j457.dts           |   12 +
 arch/arm64/boot/dts/apple/t8103-jxxx.dtsi          |  137 ++
 arch/arm64/boot/dts/apple/t8103-pmgr.dtsi          |    2 +
 arch/arm64/boot/dts/apple/t8103.dtsi               |  105 +
 arch/arm64/boot/dts/apple/t8112-j413.dts           |   12 +
 arch/arm64/boot/dts/apple/t8112-j473.dts           |   11 +
 arch/arm64/boot/dts/apple/t8112-j493.dts           |   12 +
 arch/arm64/boot/dts/apple/t8112-jxxx.dtsi          |  137 ++
 arch/arm64/boot/dts/apple/t8112.dtsi               |  105 +
 drivers/phy/Kconfig                                |    1 +
 drivers/phy/Makefile                               |    1 +
 drivers/phy/apple/Kconfig                          |   14 +
 drivers/phy/apple/Makefile                         |    4 +
 drivers/phy/apple/atc.c                            | 2214 ++++++++++++++++++++
 drivers/soc/apple/Kconfig                          |    4 +
 drivers/soc/apple/Makefile                         |    3 +
 drivers/soc/apple/tunable.c                        |   71 +
 drivers/usb/dwc3/Kconfig                           |   11 +
 drivers/usb/dwc3/Makefile                          |    1 +
 drivers/usb/dwc3/core.c                            |   16 +-
 drivers/usb/dwc3/dwc3-apple.c                      |  425 ++++
 drivers/usb/dwc3/gadget.c                          |    2 +
 drivers/usb/dwc3/glue.h                            |   14 +
 drivers/usb/dwc3/host.c                            |    7 +-
 drivers/usb/typec/tipd/core.c                      |  564 ++++-
 drivers/usb/typec/tipd/tps6598x.h                  |    5 +
 drivers/usb/typec/tipd/trace.h                     |   39 +
 include/linux/soc/apple/tunable.h                  |   60 +
 41 files changed, 5192 insertions(+), 64 deletions(-)
---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250820-atcphy-6-17-b7eaf23be17c

Best regards,
-- 
Sven Peter <sven@kernel.org>

