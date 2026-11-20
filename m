From: Ivan Pfarher <ipfarher@gmail.com>
Subject: [PATCH 0/4] arm64: dts: allwinner: h5: orangepi-zero-plus2: Fix
 Bluetooth and USB gadget
Date: Fri, 20 Nov 2026 12:40:44 +0100
Message-Id: <20261120-orangepi-zero-plus2-fixes-v1-0-ecd792189f27@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALwxAGsC/x2LSQqAMAwAvyI5G2gDCvoV8eASNSC2JCii+Herx
 5lhbjBWYYM6u0H5EJOwJfB5BsPSbTOjjImBHJXek8Ogn42CF2vAuO5GOMnJhhWN7KrB98VUQPq
 j8h/S3rTP8wIiTPS3awAAAA==
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, Ivan Pfarher <ipfarher@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795174845; l=2806;
 i=ipfarher@gmail.com; s=20261120; h=from:subject:message-id;
 bh=8NDP5ZNmJidSCuINYDzvhJHNJXi8K2RXS0VdGYiDgfo=;
 b=fwAfu0dfR2ngc4aIhPPXVyWR5bhlGxXAzqv3mF4h8OXYi1vICRCu30qqI8QT4BDRKtmUWBF/7
 EUWKft9RMhEDuGYa0/VJ1BF2zar9tVd2HX8K/l551LcaHvOq+8GH1eu
X-Developer-Key: i=ipfarher@gmail.com; a=ed25519;
 pk=3DMYyz/xl+KRAx2TNGJpheG+5QUm7lqHhKXFqVu2TmY=
X-Endpoint-Received: by B4 Relay for ipfarher@gmail.com/20261120 with auth_id=1582
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the Orange Pi Zero Plus2 (H5), neither the Bluetooth part of the
AP6212 module nor the micro USB port in peripheral mode work with the
current device tree. This series fixes both and adds MMC aliases:

1. The AP6212 needs the RTC 32.768 kHz clock (osc32k-out) as LPO. It
   is not referenced, so it gets disabled as unused, and the BT ROM
   then answers nothing but HCI_Reset.
2. Describe the Bluetooth controller on UART1 (BT_REG_ON on PA10), so
   hci_bcm can power it, load its firmware and use it at 1.5 Mbaud.
3. EHCI0/OHCI0 share USB PHY 0 with the MUSB controller. When they
   register, the USB core switches the PHY to host mode, so the
   peripheral-only micro USB port never enumerates as a gadget. Drop
   them, as the port cannot supply VBUS anyway.
4. Add MMC aliases so the microSD card and the eMMC keep fixed numbers.

About patch 3: the root cause is that phy-sun4i-usb accepts the
host-mode request from the HCD even though the PHY's dr_mode is fixed
to "peripheral". Changing the PHY driver would also cover other
boards, but that is a separate discussion; this series only fixes the
board DT. The H3 version of the board (sun8i-h3-orangepi-zero-plus2.dts)
has the same USB and AP6212 setup and very likely the same problems,
but it is not changed here because I could not test it.

Testing: all four changes were tested on an Orange Pi Zero Plus2 (H5)
running Linux 6.6.160 (Yocto scarthgap, meta-sunxi) with the same DT
changes: Bluetooth comes up with firmware loaded and scans, the g_cdc
gadget enumerates on a PC, and the board boots with the microSD card
as mmcblk0 and the eMMC as mmcblk1. Against current mainline the
series is build-tested only: dtc gives no new warnings and dt-validate
reports nothing for the resulting DTB.

The issues were found and the patches drafted with the help of an AI
coding assistant (Claude by Anthropic), which also ran the diagnostics
on the board (raw HCI commands over the UART, GPIO and clock
experiments, USB PHY state). I reviewed and tested the changes.

Signed-off-by: Ivan Pfarher <ipfarher@gmail.com>

Signed-off-by: Ivan Pfarher <ipfarher@gmail.com>
---
Ivan Pfarher (4):
      arm64: dts: allwinner: h5: orangepi-zero-plus2: Add LPO clock for AP6212
      arm64: dts: allwinner: h5: orangepi-zero-plus2: Add AP6212 Bluetooth
      arm64: dts: allwinner: h5: orangepi-zero-plus2: Fix USB peripheral mode
      arm64: dts: allwinner: h5: orangepi-zero-plus2: Add MMC aliases

 .../allwinner/sun50i-h5-orangepi-zero-plus2.dts    | 25 +++++++++++++++-------
 1 file changed, 17 insertions(+), 8 deletions(-)
---
base-commit: 65e4fd942f72a9dba0e4e257290c4fa1aa756854
change-id: 20261120-orangepi-zero-plus2-fixes-92de09c1b5f5

Best regards,
-- 
Ivan Pfarher <ipfarher@gmail.com>

