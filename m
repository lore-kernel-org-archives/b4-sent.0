From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH v5 0/3] nvmem: add support for the MediaTek mt6323 PMIC
Date: Mon, 21 Sep 2026 10:50:01 +0300
Message-Id: <20260921-mt6323-nvmem-v5-0-2f5d308369f0@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XPwW7DIAwG4FepOI8KbCDKTnuPaQdCzEpVQgUZa
 lXl3Ue6Q6u2O/7S78/2hRXKgQp731xYphpKSFML+m3D3M5O38TD2DIDAUYYKXmcDQLyqUaKXDi
 trPDgbe9ZGzlm8uF05T6//nL5Gfbk5tVYG7tQ5pTP131Vrr1/6Cq54IMmOfSOtPTwccxpTlO04
 bB1KbLVr3AvdA8CNEF5FITGtivVSwFvQifxQcAmgNAOezCdhdeCugn90xeqCQbMOMpOoxzdk7A
 syy9+Vg4WhQEAAA==
X-Change-ID: 20260611-mt6323-nvmem-0c54a0f2fa9f
To: Sen Chu <sen.chu@mediatek.com>, Sean Wang <sean.wang@mediatek.com>, 
 Macpaul Lin <macpaul.lin@mediatek.com>, Lee Jones <lee@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Srinivas Kandagatla <srini@kernel.org>, 
 Roman Vivchar <rva333@protonmail.com>
Cc: Andy Shevchenko <andy@kernel.org>, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Ben Grisdale <bengris32@protonmail.ch>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789977026; l=2403;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=MN6wjM73jwFJE0BBGgrZ2DP1kz/GNI2gsTbQ6k5QYKg=;
 b=WfuNkR0MZFTaJPn5Cgdqk4A6l9M4n4AssM/47amKmWilCckA8bhc+0ZqCnazyL3HtApVK61Vh
 bJCgtxCUZ28Abj0eGsH68mAgfNWjTroT7j4ofNoF8QSt1nNO8OXiuad
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the EFUSE found on the MediaTek mt6323 PMIC.

Tested on the MediaTek mt6572 and mt8163 SoCs (Ben), both paired with a
mt6323.

Tested-by: Ben Grisdale <bengris32@protonmail.ch> # Amazon Echo Dot (2nd Generation)
Signed-off-by: Roman Vivchar <rva333@protonmail.com>

---
Changes in v5:
- Reorder Makefile entries
- Use mt6323_regulators driver pattern for regmap instead of dev->parent->parent
- Link to v4: https://patch.msgid.link/20260911-mt6323-nvmem-v4-0-626dd17531dc@protonmail.com

Changes in v4:
- Rebase onto nvmem/for-next (8f596c13b6b7 ("dt-bindings: nvmem: qfprom: Add compatible for Qualcomm Maili"))
- Drop device-id/of.h header (Andy)
- Mediatek -> MediaTek in Kconfig
- Link to v3: https://patch.msgid.link/20260713-mt6323-nvmem-v3-0-205c39267a24@protonmail.com

Changes in v3:
- Rebase onto next-20260708
- EFUSE driver: Replace 'mod_devicetable.h' with explicit 'device-id/of.h'
- Drop MFD patch since it's applied
- Link to v2: https://patch.msgid.link/20260617-mt6323-nvmem-v2-0-4f30e36aa0f4@protonmail.com

Changes in v2:
- EFUSE driver: Sort variables in the mt6323_efuse_read (Andy)
- Link to v1: https://patch.msgid.link/20260611-mt6323-nvmem-v1-0-b5e1b9ce51f2@protonmail.com

Changes after split:
- EFUSE driver:
    - Remove 'linux/errno.h' header (Andy)
    - Remove explicit cast to u16 in the 'mt6323_efuse_read' (Andy)
    - Reword comment in the 'mt6323_efuse_read'
    - Capitalize MediaTek in the module description
- Link to a previous series: https://patch.msgid.link/20260512-mt6323-v2-0-3efcba579e88@protonmail.com

---
Roman Vivchar (3):
      dt-bindings: mfd: mediatek: mt6397: add mt6323 PMIC EFUSE
      nvmem: add mt6323 PMIC EFUSE driver
      ARM: dts: mediatek: mt6323: add EFUSE support

 .../devicetree/bindings/mfd/mediatek,mt6397.yaml   | 21 ++++++
 MAINTAINERS                                        |  5 ++
 arch/arm/boot/dts/mediatek/mt6323.dtsi             |  4 ++
 drivers/nvmem/Kconfig                              | 11 +++
 drivers/nvmem/Makefile                             |  2 +
 drivers/nvmem/mt6323-efuse.c                       | 83 ++++++++++++++++++++++
 6 files changed, 126 insertions(+)
---
base-commit: 8f596c13b6b7fa9fa35091273c37f9b6e3fc2d0f
change-id: 20260611-mt6323-nvmem-0c54a0f2fa9f

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

