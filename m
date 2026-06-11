From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH 0/4] nvmem: add support for the MediaTek mt6323 PMIC
Date: Thu, 11 Jun 2026 13:20:28 +0300
Message-Id: <20260611-mt6323-nvmem-v1-0-b5e1b9ce51f2@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqAIBBA0avErBPUSqirRAuzsSbQQiuC6O5ZL
 d/i/wsiBsIITXZBwIMiLT5B5BmYSfsRGQ3JILlUXAnB3KYKWTB/OHSMm6rU3EqrawspWQNaOr9
 d2/2Oez+j2d4H3PcDKOQeZnAAAAA=
X-Change-ID: 20260611-mt6323-nvmem-0c54a0f2fa9f
To: Sen Chu <sen.chu@mediatek.com>, Sean Wang <sean.wang@mediatek.com>, 
 Macpaul Lin <macpaul.lin@mediatek.com>, Lee Jones <lee@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Srinivas Kandagatla <srini@kernel.org>, 
 Roman Vivchar <rva333@protonmail.com>
Cc: Andy Shevchenko <andy@kernel.org>, Jonathan Cameron <jic23@kernel.org>, 
 linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781173294; l=1828;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=Tvmqx4pYtJuxtoQ3R62SMg0IdP8UogvEPTr0AvaCegU=;
 b=r+iAeji7kO+0TGOzXiqhQcf+A5+3fkeYjjq9gerPbtOc6rQDDxklu44EumjyyX7+Qw++70LJk
 3kn+In2w6bUA0Kyok20FAN1TDGDf2JlVcLxmzPTL5uSJT28arb66KhH
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the EFUSE found on the MediaTek mt6323 PMIC.

The previous version of the series for all AUXADC, EFUSE and thermal
drivers was split after Krzysztof's comment [1].
    
Tested on the MediaTek mt6572 and mt8163 SoCs (Ben), both paired with a
mt6323.

[1]: https://lore.kernel.org/linux-mediatek/20260504-mt6323-v1-0-799b58b355ff@protonmail.com/T/#med30fad67a090be35f549231336b2dec295233f6

Tested-by: Ben Grisdale <bengris32@protonmail.ch> # Amazon Echo Dot (2nd Generation)
Signed-off-by: Roman Vivchar <rva333@protonmail.com>

---
Changes after split:
- EFUSE driver:
    - Remove 'linux/errno.h' header (Andy)
    - Remove explicit cast to u16 in the 'mt6323_efuse_read' (Andy)
    - Reword comment in the 'mt6323_efuse_read'
    - Capitalize MediaTek in the module description
- Link to a previous series: https://patch.msgid.link/20260512-mt6323-v2-0-3efcba579e88@protonmail.com

---
Roman Vivchar (4):
      dt-bindings: mfd: mediatek: mt6397: add mt6323 PMIC EFUSE
      nvmem: add mt6323 PMIC EFUSE driver
      mfd: mt6397-core: add mt6323 EFUSE support
      ARM: dts: mediatek: mt6323: add EFUSE support

 .../devicetree/bindings/mfd/mediatek,mt6397.yaml   | 21 ++++++
 MAINTAINERS                                        |  5 ++
 arch/arm/boot/dts/mediatek/mt6323.dtsi             |  4 +
 drivers/mfd/mt6397-core.c                          |  3 +
 drivers/nvmem/Kconfig                              | 11 +++
 drivers/nvmem/Makefile                             |  2 +
 drivers/nvmem/mt6323-efuse.c                       | 85 ++++++++++++++++++++++
 7 files changed, 131 insertions(+)
---
base-commit: 028ef9c96e96197026887c0f092424679298aae8
change-id: 20260611-mt6323-nvmem-0c54a0f2fa9f

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

