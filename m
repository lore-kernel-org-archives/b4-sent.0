From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/4] usb: core: Pair ports of different host controllers
 through their connector
Date: Tue, 10 Nov 2026 07:20:05 +0000
Message-Id: <20261110-usb-port-pairing-v1-0-9307e29d2ed2@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMMQ7DIAxA0atEnmsJGBhylaoDUJO4A0F2qCJF3
 D00Hd/w/wlKwqQwTycIfVl5KwP2MUFaQ1kI+T0MzjhvrTXYNGLdZMcaWLgsGLLJ3mcToiMYWRX
 KfNzL5+tvbfFDaf99oPcLeeyAeXQAAAA=
X-Change-ID: 20261110-usb-port-pairing-af0f66f0ab2e
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Alan Stern <stern@rowland.harvard.edu>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295206; l=5057;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=5QKUfHPW3+xcVKyI0NDq5EzfqKIVMb0aDobvRO6Oo8U=;
 b=IcJ8AgVLByKYBVSrtphHEuo9ppLlzRjx+W1Sw0tObyGKPtuNlJmRNOcgsI0Fx9X2sFhjqNvK9
 Vu0pCcLz9j+AsupJpIXfO87sLsSnubzmbGgAAEin0iTqs8ZW6wfG09t
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The USB core pairs the USB 2.0 and SuperSpeed halves of a USB 3 port
only within one xHCI (shared_hcd, same port number) or through ACPI
location data. Some SoCs route the two halves of a connector to
different host controllers: on the Rockchip RK3588, USB 3.0 host 2 is
SuperSpeed-only (its own USB 2.0 root hub port is not wired to a PHY)
and the connector's USB 2.0 lines go to a separate EHCI/OHCI pair.
Today the SuperSpeed port is paired with the dead USB 2.0 port of its
own xHCI, and the EHCI port that really shares the connector has no
peer.

That is more than a cosmetic problem on boards where VBUS of such a
port is always on. On the Orange Pi 5 the Type-A USB 3 port has no
VBUS switch at all (no enable GPIO in the vendor or mainline device
tree; confirmed on the board), so a device that is plugged in across
power-up or a reboot is powered long before the kernel runs. It looks
for a SuperSpeed link while the xHCI is still down, gives up, and
connects at high speed to the EHCI, which starts ~10 ms before the
xHCI. It then stays at 480 Mb/s until it is unplugged: USB 3 devices
only look for a SuperSpeed link again after a VBUS cycle or a USB 2.0
bus reset.

The series describes the connector in the device tree and lets the
USB core use it:

  1. dt-bindings: allow a "ports" graph on generic-ehci (one port per
     root hub port, as usb-hub.yaml already has for hubs).
  2. usb: core: when a port's graph endpoint leads to a usb-{a,b,c}
     connector whose other half ends on a different hub or host
     controller, pair the two ports through the connector and keep them
     out of the default pairing. Connectors whose halves end on the same
     node (Type-C on a dwc3) are unchanged.
  3. usb: hub: when a SuperSpeed hub with connector-paired ports starts
     (or comes back from a reset / reset-resume), reset a
     SuperSpeed-capable device that sits at high speed on the USB 2.0
     peer, once, so that it can train its SuperSpeed link now that the
     host is up. A device that still does not train stays at high
     speed; there is no loop.
  4. arm64: dts: describe the Orange Pi 5/5B Type-A USB 3 connector.
     Other RK3588 boards with the same split would need the same node.

Honest limits: patch 3 only helps devices that retry SuperSpeed after
a USB 2.0 bus reset. A SanDisk Extreme does; a SanDisk Ultra Fit does
not and stays at high speed after the single reset. The hardware fix
(a switchable VBUS, cycled once the SuperSpeed host is up) is not
available on this board. The pairing itself (patch 2) also makes the
existing peer runtime-PM rules apply to such connectors.

Tested on an Orange Pi 5 (RK3588S): with the series the EHCI root hub
port 1 and the xHCI SuperSpeed port 1 show each other as "peer" in
sysfs. A SanDisk Extreme present at boot enumerates at high speed on
the EHCI at ~3.2 s, "SuperSpeed peer port available, resetting" is
logged once, and it re-enumerates at 5 Gb/s on the xHCI at ~3.8 s, on
every boot; without the series (two different kernels) it came up at
480 Mb/s on the EHCI on every boot and stayed there until replugged. A
SanDisk Ultra Fit that ignores the USB 2.0 reset stays at high speed
after the one reset. Hot-plug after boot (5 Gb/s), the Type-C port
(both halves on the same dwc3 node) and USB 2.0-only devices in the
port behave as before. dt_binding_check for generic-ehci and
CHECK_DTBS for the Orange Pi 5 and 5B are clean on this base.

Open point for the dwc3 binding: snps,dwc3-common.yaml describes
"ports" as used together with usb-role-switch; patch 4 uses port@1 of
a host-only dwc3 for the SuperSpeed lanes, as rk3588s-indiedroid-nova
and rk3588-lubancat-5io already do. I can send a wording update if
wanted.

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit messages, and I reviewed and tested
every change as described above.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (4):
      dt-bindings: usb: generic-ehci: Allow describing the root hub ports
      usb: core: Pair ports of different hubs through their connector
      usb: hub: Retry SuperSpeed for a device stuck on its USB 2.0 peer
      arm64: dts: rockchip: Describe the USB3 Type-A connector on Orange Pi 5/5B

 .../devicetree/bindings/usb/generic-ehci.yaml      |  13 +++
 .../boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi   |  60 ++++++++++++
 drivers/usb/core/hub.c                             |  88 ++++++++++++++++++
 drivers/usb/core/hub.h                             |   3 +
 drivers/usb/core/of.c                              | 101 +++++++++++++++++++++
 drivers/usb/core/port.c                            |  54 ++++++++++-
 include/linux/usb/of.h                             |   9 ++
 7 files changed, 324 insertions(+), 4 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261110-usb-port-pairing-af0f66f0ab2e

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

