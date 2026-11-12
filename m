From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v2 0/2] usb: core: Pair ports of different host controllers
 through their connector
Date: Thu, 12 Nov 2026 08:26:15 +0000
Message-Id: <20261112-usb-port-pairing-v2-0-45f5a1a29f1f@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ6CMBBFr0Jm7Zh2TGpw5T0MiwJTGCOUtEA0p
 HeX4t7lS95/f4PIQTjCrdgg8CpR/LgDnQpoejt2jNLuDKTIaK0VLrHGyYcZJytBxg6tU84Yp2x
 NDPtsCuzkfSQf1Y/jUj+5mXMnG73E2YfP8bnq7P3JrxoVlhd1ZSpb4pbu3WDldW78AFVK6QuDF
 Q0UwgAAAA==
X-Change-ID: 20261110-usb-port-pairing-af0f66f0ab2e
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Alan Stern <stern@rowland.harvard.edu>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mathias Nyman <mathias.nyman@intel.com>, Chen-Yu Tsai <wenst@chromium.org>, 
 Chen-Yu Tsai <wens@kernel.org>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794471975; l=7862;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=e2s8sooK67x7vmIoLwy9LZ4Ezlzfpkkf2yNAWvkHjzY=;
 b=V5kIsLgXO5t2Iud5BeBpSkGmnoh6KGzV5BybTjNJ/zjPpQX5LOUCNFdLgGhgxs39eLpHK8vbu
 QPGwDyGo6qtCWRXP3TPskmYJDkNfmuLZVi22rrlRyNrp2WzN1EyypdQ
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

The series lets the USB core use a description of the connector in
the device tree:

  1. usb: core: when a port's graph endpoint leads to a usb-{a,b,c}
     connector whose other half ends on a different hub or host
     controller, pair the two ports through the connector and keep them
     out of the default pairing. Connectors whose halves end on the same
     node (Type-C on a dwc3) are unchanged.
  2. usb: hub: when a SuperSpeed root hub whose ports are paired
     through a connector with USB 2.0 root hub ports of another host
     controller starts, reset a SuperSpeed-capable device (not a hub)
     that sits at high speed on the USB 2.0 peer, once, so that it can
     train its SuperSpeed link now that the host is up. Resume and reset
     of the root hub don't do this. A device that still does not train
     stays at high speed; there is no loop.

The Orange Pi 5/5B device tree that describes its Type-A USB 3
connector this way was patch 4 of v1; it now goes separately to the
Rockchip tree as "arm64: dts: rockchip: Describe the USB3 Type-A
connector on Orange Pi 5/5B". Other RK3588 boards with the same split
would need the same node.

That DT patch links an EHCI root hub port to the connector through a
"ports" node on the EHCI. v1 added that node to generic-ehci.yaml
in its patch 1; v2 relies instead on Chen-Yu Tsai's "dt-bindings:
usb: hcd: Add downstream USB ports", which adds "ports" to
usb-hcd.yaml for all host controllers [1]. It is not merged yet. The
two patches here don't need it to build or run; only the separate DT
patch needs it to pass dtbs_check.

Port numbers: patch 1 finds a root hub port in the graph by its root
hub port number, as usb_of_get_connect_type() does today, and not by
the xHCI port number. On an EHCI the two are the same. On the
SuperSpeed-only xHCI of the RK3588, a dwc3, the SuperSpeed root hub
port 1 is graph port@1, which is also where snps,dwc3-common.yaml puts
the SuperSpeed port today. Chen-Yu has said that the graph port of a
root hub port should be found by the xHCI port number
(usb_hcd_find_raw_port_number()) [2], and patch 2 of his series
renumbers the dwc3 ports to match. If that is the way to go, patch 1
has to translate the numbers on both sides of the pairing. I would
like to hear which numbering is wanted before I change it.

Honest limits: patch 2 only helps devices that retry SuperSpeed after
a USB 2.0 bus reset. A SanDisk Extreme does; a SanDisk Ultra Fit does
not and stays at high speed after the single reset. The hardware fix
(a switchable VBUS, cycled once the SuperSpeed host is up) is not
available on this board. The pairing itself (patch 1) also makes the
existing peer runtime-PM rules apply to such connectors.

v1 was tested on an Orange Pi 5 (RK3588S): with the series the EHCI
root hub port 1 and the xHCI SuperSpeed port 1 show each other as
"peer" in sysfs. A SanDisk Extreme present at boot enumerates at high
speed on the EHCI at ~3.2 s, "SuperSpeed peer port available,
resetting" is logged once, and it re-enumerates at 5 Gb/s on the xHCI
at ~3.8 s, on every boot; without the series (two different kernels)
it came up at 480 Mb/s on the EHCI on every boot and stayed there
until replugged. A SanDisk Ultra Fit that ignores the USB 2.0 reset
stays at high speed after the one reset. Hot-plug after boot (5 Gb/s),
the Type-C port (both halves on the same dwc3 node) and USB 2.0-only
devices in the port behave as before.

v2 was tested on the same Orange Pi 5 with the SanDisk Extreme in the
port: on 4 of 4 boots it ended at 5 Gb/s on the xHCI with the EHCI
port paired (3 of them logged the one peer reset), no WARN or BUG.
Root hubs runtime-suspend as without the series. 5 s2idle cycles with
the bus kept and 3 in which the root hubs lost power: no peer reset on
resume, no device lost. A logical replug, 2 xHCI unbind/bind cycles
and 10 unbind/bind races of the xHCI and of the hub driver at
different delays: no hang, no WARN, the device back at 5 Gb/s each
time. Not tested: an external USB 3 hub in the port (none at hand).
With Chen-Yu's binding patch applied, CHECK_DTBS for the Orange Pi 5
and 5B with the separate DT patch shows no new warnings.

All board tests ran on a v7.3 based kernel with these patches and the
DT patch applied. On v7.4-rc1 the series is build-tested only.

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit messages, and I reviewed and tested
every change as described above.

[1] https://lore.kernel.org/all/20261014082037.1774672-2-wenst@chromium.org/
[2] https://lore.kernel.org/all/CAGXv+5GdBUafk6niG-UMDx=z6LJQ6iHAWhDpm1Ly2ce6CQDaxg@mail.gmail.com/

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Changes in v2:
- Dropped v1 patch 1 "dt-bindings: usb: generic-ehci: Allow describing
  the root hub ports": Chen-Yu Tsai's "ports" binding in usb-hcd.yaml
  covers all host controllers, EHCI included, and Rob Herring's comment
  on it about the port numbers applied to ours too (Chen-Yu Tsai, Rob
  Herring). v1 patches 2 and 3 are now patches 1 and 2.
- Patch 2: reset the USB 2.0 peer only when the SuperSpeed root hub
  starts, not on its reset-resume or after a reset: a device that is
  suspended with the system can't be reset (Sashiko)
- Patch 2: never reset a hub, and only look at USB 2.0 root hub ports
  of another host controller: the USB 2.0 half of a USB 3 hub stays at
  high speed, and resetting it would disconnect its children (Sashiko)
- Patch 2: cancel the work in hub_quiesce() (Sashiko) and hold a
  runtime PM reference on the hub while it is queued (Sashiko); run it
  on the freezable hub_wq
- Patch 1 unchanged
- v1 patch 4 (Orange Pi 5/5B DTS) split out of the series; it goes to
  the Rockchip tree on its own (Krzysztof Kozlowski)
- Link to v1: https://patch.msgid.link/20261110-usb-port-pairing-v1-0-9307e29d2ed2@gmail.com

---
Arun Iyengar (2):
      usb: core: Pair ports of different hubs through their connector
      usb: hub: Retry SuperSpeed for a device stuck on its USB 2.0 peer

 drivers/usb/core/hub.c  | 113 ++++++++++++++++++++++++++++++++++++++++++++++++
 drivers/usb/core/hub.h  |   3 ++
 drivers/usb/core/of.c   | 101 +++++++++++++++++++++++++++++++++++++++++++
 drivers/usb/core/port.c |  54 +++++++++++++++++++++--
 include/linux/usb/of.h  |   9 ++++
 5 files changed, 276 insertions(+), 4 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261110-usb-port-pairing-af0f66f0ab2e

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

