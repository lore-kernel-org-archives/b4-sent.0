From: Zakariya Hadrami <zkh@mailbox.org>
Subject: [PATCH v4 0/4] ARM: Basic support for Amazon ford tablet (MT8127)
Date: Wed, 09 Sep 2026 21:37:59 +0200
Message-Id: <20260909-mt8127-amazon-ford-basic-v4-0-e9af5c420ab1@mailbox.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43NywrCMBCF4VeRrI0kU5M0rnwPcZHLRAO2KUkpX
 ui7GwURBMXlf2C+uZGCOWIhm8WNZJxiiamvsV4uiDua/oA0+toEGEgmuaTd2HJQ1HTmmnoaUvb
 UmhId5YJpr5iAoJDU8yFjiOcnvdvXPsYypnx5fpr4Y32h6js6ccqoZ2A8F8Y1Qm+HnMbUrzokD
 3SCfyGokGyFRtCowLSfUPOGNGt/QE2FgltLG7iVzsK2M/Fk03mV8oHs53m+AwTj+CVUAQAA
X-Change-ID: 20260616-mt8127-amazon-ford-basic-1509d7052f7e
To: Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sean Wang <sean.wang@mediatek.com>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-watchdog@vger.kernel.org, zkh1@proton.me, 
 Zakariya Hadrami <zkh@mailbox.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788982689; l=1745;
 i=zkh@mailbox.org; s=20260908; h=from:subject:message-id;
 bh=pMj4eriQj048JYuAolqQ2BmBgq01CBfNFGOisnU/HrM=;
 b=3djYBaIYQoGZVRB5rjyMwbmJ3dsc+RI9A249z9PnHsJX2afhiZVx+YvyFZDoDdV5s4f0wekqe
 A6b+mtA2iwcAJdmhGNUWaZvDRibAwbWEcbKVqkshp9vHmgYwVxiA9wL
X-Developer-Key: i=zkh@mailbox.org; a=ed25519;
 pk=up24Xn4ScFKugfT4EJru/UQAS7JOIN+DSQqro+a05T4=
X-Endpoint-Received: by B4 Relay for zkh@mailbox.org/20260908 with auth_id=1015
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series of patches adds basic support for MT8127 SoC based Amazon ford
tablet.

Signed-off-by: Zakariya Hadrami <zkh@mailbox.org>
---
Changes in v4:
- Add chassis-type property to dts.
- Add missing #address-cells, #size-cells and ranges properties to dts
  (sashiko report).
- Link to v3: https://patch.msgid.link/20260908-mt8127-amazon-ford-basic-v3-0-fc46bf1b6cb2@mailbox.org

Changes in v3:
- Rebase onto v7.3-rc1.
- Drop [PATCH v2 3/5] as it was superseded by upstream changes.
- Link to v2: https://lore.kernel.org/r/20260617-mt8127-amazon-ford-basic-v2-0-6859e29e72a8@proton.me

Changes in v2:
- Move amazon ford compatible string to existing enum.
- Fix watchdog node not sorted in unit address ascending order (sashiko report).
- Move bindings documentation patches before patches implementing the bindings.
- Link to v1: https://lore.kernel.org/r/20260617-mt8127-amazon-ford-basic-v1-0-d02ad15ac359@proton.me

---
Zakariya Hadrami (4):
      dt-bindings: watchdog: mediatek: Add MT8127
      dt-bindings: arm: mediatek: Add MT8127 Amazon ford
      ARM: dts: mediatek: mt8127: Add watchdog support
      ARM: dts: mediatek: Add basic support for Amazon ford board

 .../devicetree/bindings/arm/mediatek.yaml          |  1 +
 .../bindings/watchdog/mediatek,mtk-wdt.yaml        |  1 +
 arch/arm/boot/dts/mediatek/Makefile                |  1 +
 arch/arm/boot/dts/mediatek/mt8127-amazon-ford.dts  | 54 ++++++++++++++++++++++
 arch/arm/boot/dts/mediatek/mt8127.dtsi             |  7 +++
 5 files changed, 64 insertions(+)
---
base-commit: cee9395acd8043be0644b25c34bfa86623f2b935
change-id: 20260616-mt8127-amazon-ford-basic-1509d7052f7e

Best regards,
--  
Zakariya Hadrami <zkh@mailbox.org>

