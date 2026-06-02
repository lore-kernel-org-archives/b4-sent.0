From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH 0/4] AUXADC driver for the MediaTek mt6323 PMIC
Date: Tue, 02 Jun 2026 15:46:53 +0300
Message-Id: <20260602-mt6323-adc-v1-0-68ec737508ee@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBBA4avIrDVhGl24iljodMpI/KRFJOLui
 uW3eO+CyEE4Qp1dEPiQKMucUOYZ0NDNPStxyYAFmqLCSk2b0ahV50hpy55YG7IeIQVrYC/nN2v
 a33G3I9P2HuC+H2I4g2luAAAA
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
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780404414; l=2643;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=7JSIVJME0qcwrQkDU0f3aTxdQOaohzA3I2n+ATF6Cqc=;
 b=0JbMx2y6tCQJ3dd9ZlUioB5ryHJQg5jI2blGOCtlbQ6SkPy7gHQ8050y5eQKPoicbwzx0Hnsg
 abvtLeSslqPAqYkIExaK3VblfKmPSMfXmth7sUz2Ec+Ybrc3QcZ880Z
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

The other parts (EFUSE and thermal) will probably be sent next week.

[1]: https://lore.kernel.org/linux-mediatek/20260504-mt6323-v1-0-799b58b355ff@protonmail.com/T/#med30fad67a090be35f549231336b2dec295233f6

Tested-by: Ben Grisdale <bengris32@protonmail.ch> # Amazon Echo Dot (2nd Generation)
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
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
 MAINTAINERS                                        |   8 +
 arch/arm/boot/dts/mediatek/mt6323.dtsi             |   5 +
 drivers/iio/adc/Kconfig                            |  11 +
 drivers/iio/adc/Makefile                           |   1 +
 drivers/iio/adc/mt6323-auxadc.c                    | 299 +++++++++++++++++++++
 drivers/mfd/mt6397-core.c                          |   3 +
 .../dt-bindings/iio/adc/mediatek,mt6323-auxadc.h   |  24 ++
 8 files changed, 353 insertions(+), 1 deletion(-)
---
base-commit: 028ef9c96e96197026887c0f092424679298aae8
change-id: 20260525-mt6323-adc-3befce36cbf2

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

