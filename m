From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH v3 0/3] nvmem: add support for the MediaTek mt6323 PMIC
Date: Mon, 13 Jul 2026 13:11:34 +0300
Message-Id: <20260713-mt6323-nvmem-v3-0-205c39267a24@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XOTQ7CIBAF4Ks0rMXw02LqynsYFxQHixFoAImm6
 d2FujEaly95872ZUYRgIKJ9M6MA2UTjXQl80yA1SncBbM4lI0aYIIJSbJPgjGOXLVhMVNdKopm
 WvUblZAqgzWPljqd3jvfhCipVozZGE5MPz3Uv09r7Q2eKCR46oEOvoKOaHabgk3dWmttWeYuqn
 9mnsPsSWBFazQlwIcuX7Y+wLMsLAjaZiQEBAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783937511; l=2150;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=IH90joJ4tnRLkJPNr03igPwq+iiAzvjOkx7FuVR2LQo=;
 b=e72h5C0iNaVmwv4Y/8ukUwlKHV0J3jGG7YwkrI9fJAY3hbFhInt4LTTzIWRwBD+eA4nrrKCyJ
 v4b+mBvQsnSDumEwaC9CVp4OBK+J2/pJ3PklK3CCHhJJnfOQ8aMtO3S
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
 arch/arm/boot/dts/mediatek/mt6323.dtsi             |  4 +
 drivers/nvmem/Kconfig                              | 11 +++
 drivers/nvmem/Makefile                             |  2 +
 drivers/nvmem/mt6323-efuse.c                       | 85 ++++++++++++++++++++++
 6 files changed, 128 insertions(+)
---
base-commit: b9810cd75b9fb56a3425d391cba3f608502bd474
change-id: 20260611-mt6323-nvmem-0c54a0f2fa9f

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

