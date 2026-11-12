From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH RFC 0/2] usb: dwc3: Let the Rockchip glue keep the host bus
 across suspend-to-idle
Date: Thu, 12 Nov 2026 08:35:54 +0000
Message-Id: <20261112-dwc3-s2idle-optin-v1-0-842e3f8413d0@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WOy2rDMBBFf8Vo3QnS2FZkU0qg0A/otmShxzhRa
 1uuZKeFkH+v4oRsOrs73DlnzixR9JRYW5xZpJNPPow5iKeC2aMeDwTe5cyQoxRCcHA/toSE3vU
 EYZr9CIJKjkI7I2vO8t0UqfO/K/ODvb+9sv1tmRbzSXa+0u61SN9LNs737kAp6dXYFs+rMHPBV
 BCD/bJHP93kj3ToF4KTUMBB8jyOl53VuLOh77UJUW9sGF6urn9k3mAj8ts1bpRsQADKGGbaHQb
 t+8eZ0Ykgh8HPbSElKtq6ykqDtVVOqE6UVU2lRu5QKGy0pi1VbH+5/AGHV0/IVwEAAA==
X-Change-ID: 20261110-dwc3-s2idle-optin-1e3021adb650
To: Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Heiko Stuebner <heiko@sntech.de>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Joonhoe Kim <26rote@gmail.com>, Vladyslav Tymoshchuk <tvlad744@gmail.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794472554; l=5505;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=r2pcT4ZGixdnFRH/sAK0mcOgo6siBSBMOfaZwbhbgmc=;
 b=rVIh1V5lwTlkLiqHtQdq4q9ZJDtAoCbQbe4v/9kI27BxqONQ6Q0GX51dJl52T8EBvbENMZE4q
 sMcrUL3prEPDmW0YX7jNPZXn3bYwAk2wZ3QQduTE5IMCq0tM0orrrQU
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In host mode, dwc3 tears the core down for system suspend unless the
controller is a wakeup source. On RK3588 that ends the power session of
every suspended USB device in suspend-to-idle: on an Orange Pi 5 a
SanDisk Extreme drive on the Type-A USB3 port and a card reader behind a
USB3 hub are disconnected and enumerated again after every resume, which
kills a filesystem mounted on them. With the bus kept suspended they
resume from U3 in milliseconds.

Patch 2 of v1 [1] kept the host core in suspend-to-idle for every dwc3
host. Sashiko found three ways in which that breaks other platforms, and
all three hold on usb-next:
- legacy glue drivers still act in their own suspend callbacks in
  suspend-to-idle (dwc3-of-simple asserts its resets on rk3399,
  dwc3-meson-g12a powers the PHYs off, dwc3-exynos switches its supplies
  off), so the core would skip the re-init on a reset controller;
- dwc3-google asserts its resets unless wakeup is enabled;
- genpd keeps a domain on for a device on the awake path only with
  GENPD_FLAG_ACTIVE_WAKEUP, which e.g. RK3568 PD_PIPE does not set.
  Vladyslav Tymoshchuk has since seen this one on hardware [2]: on
  SM8750 the USB GDSCs lack the flag, genpd powers them off in
  suspend-to-idle and the xHCI dies on resume, already on the existing
  wakeup path.
Commit c4a5153e87fd ("usb: dwc3: core: Power-off core/PHYs on
system_suspend in host mode") also made the teardown deliberate, so
that the PHYs can be powered off. Thanks to Sashiko for the review and
to Vladyslav for the test on SM8750.

This version makes it an opt-in instead: patch 1 adds
keep_host_bus_in_s2idle to dwc3_properties for the glue to set, and
patch 2 sets it in the Rockchip glue for RK3588 only, whose PD_USB has
GENPD_FLAG_ACTIVE_WAKEUP. Nothing changes for any other platform, nor
for suspend-to-RAM and hibernation.

It is an RFC because it depends on two postings that are not merged:
- Sebastian Reichel's Rockchip dwc3 glue driver, v18 [3]; patch 2 is on
  top of it.
- Joonhoe Kim's "usb: dwc3: tell xHCI that it lost its state when the
  core is powered off" [4]; patch 1 uses its xhci_power_lost flag to
  re-initialise the core on resume exactly when suspend tore it down.
  In host mode it does the same as patch 1 of v1 [1], which I withdrew
  in its favour.
The base is usb-next (v7.4-rc1) with [3] and [4] applied.

Tested on an Orange Pi 5 (RK3588S, no wakeup source) with the code of
this series on top of [3] and [4] in a v7.3-based kernel, 50
suspend-to-idle cycles through rtcwake. Both dwc3 controllers of the
board run on the Rockchip glue: USB3OTG2 (no power domain) with a
SanDisk Extreme drive on the Type-A port, and USB3OTG0 (in PD_USB) with
the USB 2.0 billboard device behind the Type-C port.
- Bus kept (this series), 40 of 40 cycles: the same USB bus and device
  numbers before and after resume; no "root hub lost power", no "xHC
  error in resume", no disconnect, re-enumeration or "reset
  SuperSpeed", no WARNING/BUG/Oops; the drive was readable after every
  resume (64 MiB direct read).
- Core torn down as without the opt-in (forced with a test-only module
  parameter that is not part of this series), 10 of 10 cycles: all
  root hubs reported "root hub lost power or was reset" (80 lines), no
  "xHC error in resume" thanks to [4], no WARNING/BUG/Oops; the drive
  was disconnected and enumerated again on every resume, which is what
  this series avoids.
Not tested: RK3576 (left unchanged), USB3OTG1 (not on the RK3588S),
suspend-to-RAM (not run with this series; the opt-in does not apply
there).

[1] https://lore.kernel.org/r/20261110-dwc3-s2idle-v1-0-2ef4cc3f8130@gmail.com
[2] https://lore.kernel.org/r/20261111121556.1871-1-tvlad744@gmail.com
[3] https://lore.kernel.org/r/20261021-b4-rockchip-dwc3-rockchip-glue-v18-0-60000d03fca2@collabora.com
[4] https://lore.kernel.org/r/20260929130252.869-1-26rote@gmail.com

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit messages, and I reviewed and tested it
as described above.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (2):
      usb: dwc3: Let the glue keep the host bus suspended across suspend-to-idle
      usb: dwc3: rockchip: Keep the host bus across suspend-to-idle on RK3588

 drivers/usb/dwc3/core.c          | 41 ++++++++++++++++++++++++++++++++++++----
 drivers/usb/dwc3/core.h          |  3 +++
 drivers/usb/dwc3/dwc3-rockchip.c | 10 ++++++++++
 drivers/usb/dwc3/glue.h          |  7 +++++++
 4 files changed, 57 insertions(+), 4 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261110-dwc3-s2idle-optin-1e3021adb650
prerequisite-message-id: <20261021-b4-rockchip-dwc3-rockchip-glue-v18-0-60000d03fca2@collabora.com>
prerequisite-patch-id: 4fa3aae8ccfa5383522070179c8777302411082c
prerequisite-patch-id: db09b4f5b0cffc1d5bf098fbdebb06b8be448fb7
prerequisite-patch-id: c2e1c453454a7589a691fe391dc79e86f09ca7b7
prerequisite-patch-id: dadeaf9e369e04d8b3329493a1a0756ddd6140f0
prerequisite-patch-id: aa0125edb604ecf704a69250cc0d693013a977c9
prerequisite-patch-id: 62b492b7b6e9957282f1029a02aaf258b63e990f
prerequisite-patch-id: fcc7dd5dcd583913f91bf9986b0137c2930d2200
prerequisite-message-id: <20260929130252.869-1-26rote@gmail.com>
prerequisite-patch-id: 34a5a2c638a729bde49c06a330bf0847bf17e5e9

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

