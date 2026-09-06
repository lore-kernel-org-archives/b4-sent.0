From: Sven Peter <sven@kernel.org>
Subject: [PATCH v2 00/22] Initial USB4/Thunderbolt support for Apple
 M1/M2/M3 SoCs
Date: Sun, 06 Sep 2026 20:36:23 +0200
Message-Id: <20260906-b4-apple-soc-tbt-v2-0-1f80085f93fb@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WOQQ6CMBBFr0K6dkxtKxZX3sOwaMsIVUKxLURDu
 LsFSVy4fJP//5uJBPQWAzlnE/E42mBdl4DtMmIa1dUItkpMGGU5lawALUD1fYsQnIGoIyhKUZ6
 4OrJKk1TrPd7sa528ll8Og76jicvOlvD4HJIr/mKNDdH59/rIeFium5PTf+d4AApCaFNwIXPJz
 eWBvsN273xNynmeP94g8K7YAAAA
X-Change-ID: 20260829-b4-apple-soc-tbt-a00e873a52db
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Konrad Dybcio <konradybcio@kernel.org>, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Sven Peter <sven@kernel.org>, Joshua Peisach <jpeisach@ubuntu.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=9734; i=sven@kernel.org;
 h=from:subject:message-id; bh=ctP7tFAUzmbrQ//d68YH++TkcYEnYEQHDv78Hba+RxY=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9bcTet62P+LfRQ0ObU86dLJuSwGjWzVnOwCVy3qtlgxf
 Kn7/dmoo5SFQYyLQVZMkWX7fnvTJw/fCC7ddOk9zBxWJpAhDFycAjCRg6cZ/vDZ6MTlulx85/xg
 YqCg6KbrIfrhPUu+zdvt9uPEh1Yjt0SG/4mPGitfNfZx655rCJ5VsfXR89BHe6a2bqthue86/4t
 2EA8A
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series adds initial USB4/Thunderbolt support for Apple Silicon
M1, M2 and M3 SoCs. Each USB4 capable Type-C port comes with an ACIO
("Apple Converged I/O") block which contains a Cortex-M3 co-processor
and the hardware implementing the USB4 router.

The NHI and DART IOMMU are part of this ACIO block as well. Instead of
being exposed as independent always-accessible devices the main SoC bus
only gets a 16 MiB window into ACIO's MMIO space while its co-processor
is running. It is not entirely clear whether this is ACIO's own address
space or a window into the co-processor's address space.

This is why the device tree represents the NHI and DART as children of
ACIO with addresses relative to that window. The driver only populates
these children after booting the co-processor and removes them again
before powering ACIO down. This setup is slightly unusual but matches
both the MMIO layout and the lifetime of the devices.

ACIO also has rather strict ordering requirements: it can only be
started after the Type-C PHY has been configured for USB4/Thunderbolt
(and ideally has to be stopped again before the PHY is powered down but
this doesn't break anything unlike getting startup wrong). It also
needs cable details which are only known to the Type-C port controller.

The first two patches add synchronous Type-C alternate mode state
notifiers and support for representing USB4 connections on the Type-C
bus. USB4 uses Enter_USB instead of Enter Mode and has no SVID, so it
gets its own mode kind and stores the negotiated EUDO directly.
The next two patches register a USB4 port mode and publish
the negotiated Thunderbolt and USB4 partner modes on the Type-C bus,
along with the Thunderbolt cable mode. These modes are marked active
after the mux has been configured and deactivated before it is switched
back to its safe state.

The following two patches add the bindings for the NHI and ACIO. The
Thunderbolt core patches prepare for the different NHI register layout
and interrupt handling, read the USB4 router DROM from the device tree,
unlock the host router ports and find the Apple VSE capability. They
also add a hook for device links to tunneled native ports, a quirk for
USB3 bandwidth allocation not implemented by the Apple hardware and
the symbol exports needed by the driver.

The main driver registers the newly introduced notifications for the
negotiated Type-C modes, powers up ACIO, boots the co-processor,
populates the DART and NHI children once their MMIO regions are
accessible and registers the NHI with the software connection
manager. The last three patches add the device tree nodes
for the M1 and M2. M3 nodes will follow once the rest of the stack is
upstream, but the current Thunderbolt/USB4 code has already been
successfully tested on those.

Right now only XDomain connections and USB3-via-USB4 tunnels are
supported. Both PCIe and DisplayPort tunnels will come later since those
require additional work and reverse engineering that is not done yet.
Suspend is also not supported yet and we actually have to prevent
suspending whenever an active connection is present because we would
otherwise resume into an SError.

This series depends on the Apple CIO reset controller [1], the ATCPHY
USB3-via-4 pipehandler support [2], support for specifying the DART DMA
aperture in the device tree [3], a fix for CD321x Thunderbolt
altmode VDOs [4], and fixes for making the DPTX capabilities read fail
gracefully [5]. I couldn't split it any further since the remaining
patches now directly depend upon each other.
Except for the dts changes the series applies cleanly without these
dependencies though.

For merging we'll probably need an immutable brach with the first two
commits after they've been reviewed which is then merged in both the usb
and thunderbolt tree sincethere are other tipd changes in flight as well.

Happy to split this series in two as well if you prefer that.

Best,

Sven

[1] https://patch.msgid.link/20260821-b4-cio-reset-v2-0-2d045f80a424@kernel.org
[2] https://patch.msgid.link/20260821-b4-atcphy-usb4-v1-0-45c0b741e0c0@kernel.org
[3] https://patch.msgid.link/20260819-iommu-apple-dart-aperture-v1-0-252703f381aa@jannau.net
[4] https://patch.msgid.link/20260813-b4-tipd-vdo-fix-v1-1-70317f2cd554@kernel.org
[5] https://patch.msgid.link/20260829-b4-tbt-fixes-v3-0-e1fab6ac54fe@kernel.org

---
Changes in v2:
- Dropped thunderbolt switch in favor of the typec bus and an additional
  notifer
- Add USB4 to the Type-C bus with its own mode kind instead of an SVID
- Register port/partner altmodes for CD321x
- Replaced the struct with ring MMIO offsets with two callbacks insid
  tb_nhi_ops
- Moved port unlock sequence and finding the Apple VSE capability into
  core tb code
- Added device links for USB3 tunnels
- Move the USB3 BW quirk from an NHI quirk to a router quirk
- Added Joshua's rb to patches which didn't change
- Link to v1: https://patch.msgid.link/20260830-b4-apple-soc-tbt-v1-0-44bc9348683c@kernel.org

To: Heikki Krogerus <heikki.krogerus@linux.intel.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Janne Grunau <j@jannau.net>
To: Neal Gompa <neal@gompa.dev>
To: Andreas Noever <andreas.noever@gmail.com>
To: Mika Westerberg <westeri@kernel.org>
To: Yehezkel Bernat <YehezkelShB@gmail.com>
To: Philipp Zabel <p.zabel@pengutronix.de>
Cc: Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-usb@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: asahi@lists.linux.dev
Cc: linux-arm-kernel@lists.infradead.org
Signed-off-by: Sven Peter <sven@kernel.org>

---
Sven Peter (22):
      usb: typec: Add alternate mode state notifiers
      usb: typec: Represent USB4 on the Type-C bus
      usb: typec: tipd: Register a USB4 port mode for CD321x
      usb: typec: tipd: Publish CD321x partner alternate modes
      dt-bindings: thunderbolt: Add Apple USB4/Thunderbolt NHI
      dt-bindings: thunderbolt: Add Apple USB4/Thunderbolt ACIO block
      thunderbolt: Try reading host DROM from device tree first
      thunderbolt: Don't read the UID if we already know it
      thunderbolt: Allocate ring HopID before requesting the ring interrupt
      thunderbolt: Unlock host router ports during startup
      thunderbolt: Find Apple VSE capability during startup
      thunderbolt: Add ring_interrupt_active to tb_nhi_ops
      thunderbolt: Add ring register accessors to tb_nhi_ops
      thunderbolt: Add ring_interrupt_mask to tb_nhi_ops
      thunderbolt: Add ring_configure to tb_nhi_ops
      thunderbolt: Add add_links to tb_nhi_ops
      thunderbolt: Add QUIRK_NO_USB3_BW_ALLOC
      thunderbolt: Export symbols required by the Apple Silicon driver
      thunderbolt: Add Apple Silicon support
      arm64: dts: apple: t8103: Add USB4 ACIO and NHI
      arm64: dts: apple: t8112: Add USB4 ACIO and NHI
      arm64: dts: apple: t60xx: Add USB4 ACIO and NHI

 Documentation/ABI/testing/sysfs-bus-typec          |   36 +
 .../thunderbolt/apple,t8103-usb4-acio.yaml         |  213 ++++
 .../bindings/thunderbolt/apple,t8103-usb4-nhi.yaml |  151 +++
 MAINTAINERS                                        |    4 +
 arch/arm64/boot/dts/apple/t6002-j375d.dts          |  101 +-
 arch/arm64/boot/dts/apple/t600x-dieX.dtsi          |  376 ++++++
 arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi     |  158 ++-
 arch/arm64/boot/dts/apple/t600x-j375.dtsi          |  205 +++-
 arch/arm64/boot/dts/apple/t6022-j180d.dts          |  304 ++++-
 arch/arm64/boot/dts/apple/t6022-j475d.dts          |   10 +
 arch/arm64/boot/dts/apple/t6022-jxxxd.dtsi         |   91 +-
 arch/arm64/boot/dts/apple/t602x-dieX.dtsi          |  376 ++++++
 arch/arm64/boot/dts/apple/t8103-jxxx.dtsi          |   95 +-
 arch/arm64/boot/dts/apple/t8103.dtsi               |  184 +++
 arch/arm64/boot/dts/apple/t8112-jxxx.dtsi          |   95 +-
 arch/arm64/boot/dts/apple/t8112.dtsi               |  186 +++
 drivers/thunderbolt/Kconfig                        |   13 +
 drivers/thunderbolt/Makefile                       |    3 +
 drivers/thunderbolt/apple.c                        | 1277 ++++++++++++++++++++
 drivers/thunderbolt/ctl.c                          |    2 +
 drivers/thunderbolt/domain.c                       |    2 +
 drivers/thunderbolt/eeprom.c                       |   27 +-
 drivers/thunderbolt/nhi.c                          |  127 +-
 drivers/thunderbolt/nhi.h                          |   20 +
 drivers/thunderbolt/quirks.c                       |    9 +
 drivers/thunderbolt/switch.c                       |    8 +-
 drivers/thunderbolt/tb.c                           |   18 +-
 drivers/thunderbolt/tb.h                           |    4 +
 drivers/thunderbolt/tb_regs.h                      |    1 +
 drivers/thunderbolt/tunnel.c                       |   60 +-
 drivers/usb/typec/bus.c                            |   67 +-
 drivers/usb/typec/bus.h                            |    6 +
 drivers/usb/typec/class.c                          |  142 ++-
 drivers/usb/typec/mode_selection.c                 |    6 +-
 drivers/usb/typec/tipd/core.c                      |  241 +++-
 include/linux/usb/typec.h                          |   36 +-
 include/linux/usb/typec_altmode.h                  |   10 +-
 37 files changed, 4533 insertions(+), 131 deletions(-)
---
base-commit: 19998fc5177866e77a3be488644438a2227ff370
change-id: 20260829-b4-apple-soc-tbt-a00e873a52db

Best regards,
--  
Sven Peter <sven@kernel.org>

