From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH v3 0/3] usb: mtu3: add mt6595 support
Date: Sat, 07 Nov 2026 16:54:41 +0200
Message-Id: <20261107-6595-mtu3-v3-0-f36bc569cb47@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WOQQ6CMBBFr0K6tqadQgFX3sO4KDBKjVDSlkZDu
 LstxoTE5U/eezMLcWg1OnLKFmIxaKfNGIc4ZKTt1XhHqru4CTCQrOY5lUVd0MHPglbQCJZXmHN
 UJPKTxZt+ba3L9bvd3Dyw9SmQiF47b+x7OxZ44n7dctcNnDKqoFFlC4J1sjpP1ngzDko/j60ZS
 IoH2OkAex2iXnJgQgkZX5R/+rquH5EGntv4AAAA
X-Change-ID: 20260914-6595-mtu3-82b3048e41ea
To: Chunfeng Yun <chunfeng.yun@mediatek.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: linux-usb@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Roman Vivchar <rva333@protonmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794063282; l=1956;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=2Sh8YO03rPQWohGdbHMukgtcPFDJ9M5hUrRVkx1RGnA=;
 b=Qk9pSav8KEL83b7n34Cn7Yb6sSrZhCOT0mD42L5dFoOLGDcDOn28R/KJBzqcf8MoOsQ2bkDNH
 VsGg++rTWMYAKcnwDCI4pdau81yyM3IO2evOYn3wEBvSu1ulsOfrfyr
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds mt6595 SoC support to the mtu3 driver.

Unlike the mt8173 and newer controllers, the 6595 uses older IP revision
that can handle only one FIFO slot. Without this series, the current
driver implementation results in 2 to 4 lost bytes on USB transfers.

In mediatek sources, mt6595 is sometimes called 6795. Most of their
clocks/pins are also compatible. It's not clear if 6795 has the same
issue or simply lacks T-PHY patch. Other (rare) mobile SoCs with mtu3,
like mt6757 or 6771, don't need this series.

Another thing worth mentioning, this series is not enough for the USB on
6595. The other T-PHY patch is required to get the link up. This issue
has been observed on some 65xx and most 67xx SoCs. Though this is a
subject for the separate discussion.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
Changes in v3:
- Pick up tags, resend
- Link to v2: https://patch.msgid.link/20260922-6595-mtu3-v2-0-71203a362b36@protonmail.com

Changes in v2:
- Reword patch 2 commit title
- single_slot -> fifo_single_slot naming
- Drop redundant platform data check
- Link to v1: https://patch.msgid.link/20260917-6595-mtu3-v1-0-a2ba7c230d68@protonmail.com

---
Roman Vivchar (3):
      dt-bindings: usb: mtu3: add mt6595
      usb: mtu3: add SoC platform data for FIFO quirk handling
      usb: mtu3: add mt6595 support

 Documentation/devicetree/bindings/usb/mediatek,mtu3.yaml |  1 +
 drivers/usb/mtu3/mtu3.h                                  |  9 +++++++++
 drivers/usb/mtu3/mtu3_core.c                             |  3 +++
 drivers/usb/mtu3/mtu3_gadget.c                           |  8 ++++++--
 drivers/usb/mtu3/mtu3_plat.c                             | 13 +++++++++++--
 5 files changed, 30 insertions(+), 4 deletions(-)
---
base-commit: 8d3ae59288f1e7d58d76558a6ee96d533bc5019f
change-id: 20260914-6595-mtu3-82b3048e41ea

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

