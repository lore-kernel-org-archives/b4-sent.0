From: Han Gao <gaohan@iscas.ac.cn>
Subject: [PATCH v2 0/4] pinctrl: sunxi: add support for the Allwinner V861
Date: Thu, 26 Nov 2026 21:41:08 +0800
Message-Id: <20261126-v861-pinctrl-v2-0-b1875a6a9bb8@iscas.ac.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQoCIRCA4VeROSc0I7jSq8Qe0sZ2Ikx0dwnEd
 8+243f4/waVi3CFi2pQeJcq7zRAJwVhuaUHa7kPA53JIpLVu7Oos6SwlpeOHl0k4yeDDCPJhaN
 8jt11/rtu/slh/T2g9y83ktIKcAAAAA==
X-Change-ID: 20261126-v861-pinctrl-fb18f23b731e
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Han Gao <rabenda.cn@gmail.com>, 
 Conor Dooley <conor.dooley@microchip.com>, Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795700469; l=1472;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=eQg1XPgM2OUF72cwOEwxs7jhBGy/qujAowmthq93fXs=;
 b=X2szDkYSIx12c7mpXlHG6VMgajFYM7aYhV70XDJf4UwJY+iyEn/kAIFYrjmi9qMV+u5Rq7Kha
 ZpbZtcqIjuGDRgRfDoJAqejLizBGcpNfcSe/5WNVhCDYyD8ZhkNpRZA
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the pin controller bindings and drivers for the Allwinner V861.

The vendor BSP code used as reference:
https://github.com/RevySR/linux/commit/bb06380bc2e5a02049cd01e0b10cb3c3c694b750

---
Changes in v2:
- Split out of the V861 series (Linus Walleij)
- Binding: explain the lowered minimums and keep the A523 and A733
  debounce limits (Conor)
- Drivers: drop mod_devicetable.h and fix the match table style (Uwe)
- Link the vendor BSP code (Jernej)
- Link to v1: https://lore.kernel.org/r/20261114-v861-v1-0-eb71ec3ee523@iscas.ac.cn

---
Han Gao (4):
      dt-bindings: pinctrl: add the Allwinner V861 pin controllers
      pinctrl: sunxi: allow a per-controller IRQ register base
      pinctrl: sunxi: add support for the Allwinner V861 PIO
      pinctrl: sunxi: add support for the Allwinner V861 R-PIO

 .../pinctrl/allwinner,sun55i-a523-pinctrl.yaml     | 36 ++++++++++++++--
 drivers/pinctrl/sunxi/Kconfig                      | 20 +++++++++
 drivers/pinctrl/sunxi/Makefile                     |  2 +
 drivers/pinctrl/sunxi/pinctrl-sun252i-v861-r.c     | 47 +++++++++++++++++++++
 drivers/pinctrl/sunxi/pinctrl-sun252i-v861.c       | 48 ++++++++++++++++++++++
 drivers/pinctrl/sunxi/pinctrl-sunxi.h              |  7 +++-
 6 files changed, 156 insertions(+), 4 deletions(-)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261126-v861-pinctrl-fb18f23b731e

Best regards,
--  
Han Gao <gaohan@iscas.ac.cn>

