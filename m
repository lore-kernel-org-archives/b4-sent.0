From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH v2 0/3] nvmem: mtk-efuse: mt6572 support
Date: Fri, 24 Jul 2026 14:07:05 +0300
Message-Id: <20260724-6572-nvmem-v2-0-e58d16a29621@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/02NwQ6CMBAFf4Xs2Zq2BGo98R+GA5RV1tiWtNhoS
 P9dwJh4nGTevAUiBsII52KBgIkiebeCPBRgxs7dkNGwMkgua64EZ3WlJHPJomXY65NRnSrLSsA
 6mAJe6bXHLu2X47O/o5m3wmaMFGcf3vtbEpv3C1f/4SQYZ9qIsketB65UMwU/e2c7ehyNt9Dmn
 D/ddhBmuwAAAA==
X-Change-ID: 20260710-6572-nvmem-eb98c7a73351
To: Srinivas Kandagatla <srini@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Andrew-CT Chen <andrew-ct.chen@mediatek.com>, 
 Lala Lin <lala.lin@mediatek.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784892588; l=1693;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=uBSmUhci1EknRRqFtCBquW8bSNJi7MJ7/9rqReMYF50=;
 b=ZvXXV7SLUNHGIXtsurTciEl6g4gda5NqcmqNbWn7OcnAabRljAXBDZmB7seYQqARzvjmHW/aS
 0mFRT1i+yl2AunxizhOvo6Pg6moRWdHLwATTbeLWT9DTrY8J4eLEave
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds MediaTek mt6572 efuse support. Unlike newer SoCs,
its efuse controller doesn't work properly with 8-bit reads, leading to
invalid data with current mtk-efuse driver implementation.

This behavior can be observed with devmem (0x10009174 and 0x10009178 are
thermal calibration cells):
~ # devmem 0x10009174 32
0x00CDD4CD
~ # devmem 0x10009178 32
0x0F76865D
~ # devmem 0x10009174 8
0xCD
~ # devmem 0x10009175 8
0x00
~ # devmem 0x10009176 8
0x00
~ # devmem 0x10009177 8
0x00
~ # devmem 0x10009178 8
0x5D
~ # devmem 0x10009179 8
0x00
~ # devmem 0x1000917a 8
0x00
~ # devmem 0x1000917b 8
0x00

Patch 1 adds dt-bindings compatible for the mt6572,
Patch 2 adds platform data option to use aligned 32-bit reads instead
of plain readb().
Patch 3 adds platform data for mt6572 SoC.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
Changes in v2:
- dt-bindings: make mediatek,mt6572-efuse standalone compatible
- Driver: add 'mtk_reg_read_aligned' helper instead of modifying 'mtk_reg_read'
- Link to v1: https://patch.msgid.link/20260715-6572-nvmem-v1-0-9c13be99d077@protonmail.com

---
Roman Vivchar (3):
      dt-bindings: nvmem: mediatek: efuse: add mt6572
      nvmem: mtk-efuse: add support for 32-bit aligned reads
      nvmem: mtk-efuse: add mt6572 support

 .../devicetree/bindings/nvmem/mediatek,efuse.yaml  |  5 ++-
 drivers/nvmem/mtk-efuse.c                          | 41 +++++++++++++++++++++-
 2 files changed, 44 insertions(+), 2 deletions(-)
---
base-commit: 8cd9520d35a6c38db6567e97dd93b1f11f185dc6
change-id: 20260710-6572-nvmem-eb98c7a73351

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

