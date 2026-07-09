From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH v5 0/4] AUXADC driver for the MediaTek mt6323 PMIC
Date: Thu, 09 Jul 2026 13:52:46 +0300
Message-Id: <20260709-mt6323-adc-v5-0-d11b8332a735@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23NQW7DIBCF4atErEMEMwZDV71HlQXG44YqNhG4V
 qrIdy9ONkTJ8knz/XNjmVKgzD52N5ZoCTnEqQy13zF/ctM38dCXzUCAFgoUH2eNgNz1nmNHgyf
 UvhuAFXBJNITrPfZ1fOz82/2Qn7fCdnEKeY7p7/5tkdvdI6wF1OFFcsG1Id9iq4Qh+rykOMdpd
 OF88HFkW32B2tsnD8U7Z9EBoLCDfeux8lI/eSxeemi9MkYa1b/1TeULrH1TPFirjXA9Stu8+HV
 d/wF2cbq/ewEAAA==
X-Change-ID: 20260525-mt6323-adc-3befce36cbf2
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Lee Jones <lee@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, Ben Grisdale <bengris32@protonmail.ch>, 
 Roman Vivchar <rva333@protonmail.com>, 
 Conor Dooley <conor.dooley@microchip.com>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783594368; l=3957;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=W+zLO7+0D4YcJsgd55UMB8D9Ag99lffSIs84hIwj1wk=;
 b=vC7qT016llzBOmF+PEhK0ccwAPJrPTSdWmj97noZV+zvssERAiIuogUi8fbDoXTCwlN9Nzw+W
 wDASqDkMo1JCbvo0sksAKZM81Avhn0FcPJjXmPOBaU91ieF99V0i9wL
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the 15-bit AUXADC hardware block found on
the MediaTek mt6323 PMIC.

The previous version of the series for all AUXADC, EFUSE and thermal
drivers was split after Krzysztof's comment [1].

Tested on the MediaTek mt6572 and mt8163 SoCs (Ben), both paired with a
mt6323.

[1]: https://lore.kernel.org/linux-mediatek/20260504-mt6323-v1-0-799b58b355ff@protonmail.com/T/#med30fad67a090be35f549231336b2dec295233f6

Tested-by: Ben Grisdale <bengris32@protonmail.ch> # Amazon Echo Dot (2nd Generation)
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
Changes in v5:
- Rebase onto next-20260708
- Link to v4: https://patch.msgid.link/20260623-mt6323-adc-v4-0-299680ad3194@protonmail.com

Changes in v4:
- dt-bindings: Drop separate driver mention from the commit message (Conor)
- AUXADC driver: Break one more time 'regmap_read_poll_timeout' on logical boundaries (Andy)
- Link to v3: https://patch.msgid.link/20260616-mt6323-adc-v3-0-1c27c588185d@protonmail.com

Changes in v3:
- AUXADC driver:
    - Add comment for channels table about voltage and channel IDs (Jonathan)
    - Add comment for mutex in the 'mt6323_auxadc' struct (Jonathan)
    - Break 'regmap_read_poll_timeout' on logical boundaries (Andy)
    - Switch to 'guard' from 'scoped_guard' (Andy)
- Link to v2: https://patch.msgid.link/20260609-mt6323-adc-v2-0-aa93a22309f9@protonmail.com

Changes in v2:
- AUXADC driver:
    - Drop channel type from the MTK_PMIC_IIO_CHAN macro (Nuno)
    - Drop kerneldoc for the mt6323_auxadc struct (Nuno)
    - Add channel release to save power (Sashiko, Jonathan)
    - Drop 'reg' variable in the mt6323_auxadc_read (Jonathan)
    - Sort variables in the mt6323_auxadc_probe (Jonathan)
- Maintainers:
    - Drop linux-mediatek list (Andy)
    - Split between dt-bindings and driver to avoid missing file (Nuno)
- Link to v1: https://patch.msgid.link/20260602-mt6323-adc-v1-0-68ec737508ee@protonmail.com

Changes after split:
- dt-bindings: Change 'MT63xx' to 'MT6350 series and similar' (Jonathan)
- AUXADC driver:
    - Add missing headers (Andy)
    - Fix AUXADC_TRIM_CH* values (Andy)
    - Rename masks to include their register name (Jonathan)
    - Fix formatting (Andy, Jonathan)
    - Replace channel address with actual register value (Jonathan), align the table
    - Replace IIO_TEMP with IIO_VOLTAGE, since the actual output is still mV, not mC
    - Rename constants to match their registers (Jonathan)
    - Remove 'if/else if/else' in the mt6323_auxadc_read_raw (Andy)
    - Add comments for fsleep, ADC range and resolution (Andy, Jonathan)
    - Remove useless error messages (Andy)
- Maintainers:
    - Explicitly include mt6323 in the name (Jonathan)
    - Squash with AUXADC driver commit (Krzysztof)
    - Set status back to 'Maintained'
- Link to a previous series: https://patch.msgid.link/20260512-mt6323-v2-0-3efcba579e88@protonmail.com

---
Roman Vivchar (4):
      dt-bindings: iio: adc: mediatek,mt6359-auxadc: add mt6323 PMIC AUXADC
      iio: adc: mt6323-auxadc: add mt6323 PMIC AUXADC driver
      mfd: mt6397-core: add mt6323 AUXADC support
      ARM: dts: mediatek: mt6323: add AUXADC support

 .../bindings/iio/adc/mediatek,mt6359-auxadc.yaml   |   3 +-
 MAINTAINERS                                        |   7 +
 arch/arm/boot/dts/mediatek/mt6323.dtsi             |   5 +
 drivers/iio/adc/Kconfig                            |  11 +
 drivers/iio/adc/Makefile                           |   1 +
 drivers/iio/adc/mt6323-auxadc.c                    | 314 +++++++++++++++++++++
 drivers/mfd/mt6397-core.c                          |   3 +
 .../dt-bindings/iio/adc/mediatek,mt6323-auxadc.h   |  24 ++
 8 files changed, 367 insertions(+), 1 deletion(-)
---
base-commit: b9810cd75b9fb56a3425d391cba3f608502bd474
change-id: 20260525-mt6323-adc-3befce36cbf2

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

