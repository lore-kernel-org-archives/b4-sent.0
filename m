From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH v2 0/3] usb: mtu3: add mt6595 support
Date: Tue, 22 Sep 2026 13:36:39 +0300
Message-Id: <20260922-6595-mtu3-v2-0-71203a362b36@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/02NSwqDMBQAryJv3ZQkxu+q9yguYnytr1QjSZQW8
 e41lkKXA8PMCh4doYc6WcHhQp7suIM8JWB6Pd6RUbczSC5zXgnF8qzK2BDmlJWyTbkqUQnUsPu
 Twxu9jta1+bKf2weaEAPR6MkH697HbBHR+3WLv+4iGGdatrowMuVdXl4mZ4MdB03Ps7EDNNu2f
 QD9ZHESuQAAAA==
X-Change-ID: 20260914-6595-mtu3-82b3048e41ea
To: Chunfeng Yun <chunfeng.yun@mediatek.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: linux-usb@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790073400; l=1822;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=XebCtYDXuoeTQItvr9tTkpbN8O4ztzoOG5eWaY6dSNg=;
 b=PVlzxA/nJQVDJMcS5/bXyZczb92MQbRfoA5S715QQ1oDDBYHcsuMEjsJ+VCAJFykdYysL9sP3
 F2x3PmMEdL3CoRinaUzEAqY2tym6VYl1ePfylSede39esbDYAeVtfXc
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

