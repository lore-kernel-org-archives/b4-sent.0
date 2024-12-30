From: Junhui Liu <liujh2818@outlook.com>
Subject: [PATCH v2 0/8] usb: dwc2: Refactor and update USB DWC2 driver
Date: Mon, 30 Dec 2024 11:30:15 +0800
Message-Id: <20241230-dwc2-dev-v2-0-12cd9b8a2358@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMcTcmcC/x3Myw6CMBCF4Vchs7aEM7QRXfkehkVTRpiEi2kNa
 gjvbmX5n5x8GyWJKomuxUZRVk26zDn4VFAY/NyL0S43ccUWjMZ078Cmk9VcnAsM3wBoKN+fUR7
 6Oah7m3vQ9Fri95BX/NcDqRwzLNdAiXPtYGCS+DTIOAJcW+vcrZ+8jmVYJmr3ff8BwBhExKQAA
 AA=
X-Change-ID: 20241218-dwc2-dev-955c21a81118
To: Tom Rini <trini@konsulko.com>, Marek Vasut <marex@denx.de>, 
 Lukasz Majewski <lukma@denx.de>, 
 Mattijs Korpershoek <mkorpershoek@baylibre.com>
Cc: u-boot@lists.denx.de, Kongyang Liu <seashell11234455@gmail.com>, 
 Junhui Liu <liujh2818@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735529447; l=2593;
 i=liujh2818@outlook.com; s=20241030; h=from:subject:message-id;
 bh=CCYatxKTxRYELBIp9U83giTybP8U3Jv6Trfrr3zmKHY=;
 b=mUT1hHIZFohvjc5ywRf5CN56tysibFrFzU2yw4ChpKZDx1+A/exnDSw6/V6MsqnqOEmaxiBGF
 ddVSVk0iLwgD3fdi+34Z9rWxcX+6WNHUi0x6ataFsGLWFv/P8xubh4c
X-Developer-Key: i=liujh2818@outlook.com; a=ed25519;
 pk=ApYwI6KD3EjynMw61RqGa6c5BGbStQnKSrbNN+aQqT4=
X-Endpoint-Received: by B4 Relay for liujh2818@outlook.com/20241030 with auth_id=259
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series improves the USB DWC2 driver by extracting register
definitions into a common file for better readability and updating the
reset method to reflect changes in version 4.20a, including the new
GRSTCTL_CSFTRST_DONE bit for reset completion indication.

This series has been tested on two platforms:
- MK808 with RK3066 SoC and dwc2 v2.91a, tested with USB flash drive and
  connected the board to the PC through the rockusb command. Test log [1].
- K230-CanMV with K230 SoC [2] and dwc2 v4.30a, tested with the onboard
  rtl8152 USB to net chip and an external rtl8152 adapter connected to 
  the onboard USB-C interface via USB hub. Test log [3].

[1] https://gist.github.com/Judehahh/878ace2607d201dc49211f2c655f0fe0#file-mk808-md
[2] https://developer.canaan-creative.com/k230/en/dev/CanMV_K230_Tutorial.html
[3] https://gist.github.com/Judehahh/878ace2607d201dc49211f2c655f0fe0#file-k230-canmv-md

---
Changes in v2:
- Reorganized structures, renamed macros, and moved code for better
  clarity and maintainability.
- Added a fix for the incorrect ULPI_UTMI_SEL bit setting.
- Added a fix for incorrectly calculating HBstLen for external DMA mode.
- Extend the changes that replace uint32 with u32 to also include u8 and
  u16.
- Link to v1: https://lore.kernel.org/r/20240522142311.17351-1-seashell11234455@gmail.com

---
Junhui Liu (8):
      usb: dwc2: Extract register definitions to common header file
      usb: dwc2: Fix incorrect ULPI_UTMI_SEL bit setting
      USB: dwc2: Fix HBstLen setting for external DMA mode
      usb: dwc2: Clean up with bitfield macros
      usb: dwc2: Align macros with Linux kernel definitions
      usb: dwc2: Extract macro definitions to common header
      usb: dwc2: Unify flush and reset logic with v4.20a support
      usb: dwc2: Replace uint<x>_t types with u<x>

 drivers/usb/common/Makefile                |   2 +
 drivers/usb/common/dwc2_core.c             | 103 ++++
 drivers/usb/common/dwc2_core.h             | 560 +++++++++++++++++++++
 drivers/usb/gadget/dwc2_udc_otg.c          | 125 ++---
 drivers/usb/gadget/dwc2_udc_otg_regs.h     | 289 ++---------
 drivers/usb/gadget/dwc2_udc_otg_xfer_dma.c | 306 ++++++------
 drivers/usb/host/dwc2.c                    | 494 ++++++++-----------
 drivers/usb/host/dwc2.h                    | 750 +----------------------------
 8 files changed, 1123 insertions(+), 1506 deletions(-)
---
base-commit: cb7410257ac930a6fb05f1c63b291b7d399f19f2
change-id: 20241218-dwc2-dev-955c21a81118

Best regards,
-- 
Junhui Liu <liujh2818@outlook.com>

