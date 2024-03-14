From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Subject: [PATCH 0/2] Set PHY address of MT7531 switch to 0x1f on MediaTek
 arm64 boards
Date: Thu, 14 Mar 2024 15:20:03 +0300
Message-Id: <20240314-for-mediatek-mt7531-phy-address-v1-0-52f58db01acd@arinc9.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAHPr8mUC/x3NTQqDMBBA4avIrDuQxBRpr1K6SDMTHYo/zIgo4
 t0buvw2751grMIGz+YE5U1M5qnC3xrIQ5p6RqFqCC5E1/qIZVYcmSSt/MVx7e6tx2U4MBEpm+G
 D3CfmwjkFD7WyKBfZ/4fX+7p+k3d7onEAAAA=
To: Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: mithat.guner@xeront.com, erkin.bozoglu@xeront.com, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1710418818; l=938;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=Lrp2iOUWubwRXDT8fn4ZYwC2hYGdTr2JrwFF4kKzDM8=;
 b=cZgt4TQjE+rDWx2SQqBS405Ixkn/oDpThaOqJKxN8BxUVkJNynIapl7jq/9Qm+A+fsgw7lThl
 P0tFBRvHLvjAa/EUuhPdhovNPfzqDO5V/Jc75hGFx9ZKfr0m5Gd/nXl
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello.

This is a small patch series setting the PHY address of MT7531 to 0x1f on
all boards that have the switch.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
Arınç ÜNAL (2):
      arm64: dts: mediatek: mt7622: set PHY address of MT7531 switch to 0x1f
      arm64: dts: mediatek: mt7986: set PHY address of MT7531 switch to 0x1f

 arch/arm64/boot/dts/mediatek/mt7622-bananapi-bpi-r64.dts | 4 ++--
 arch/arm64/boot/dts/mediatek/mt7622-rfb1.dts             | 4 ++--
 arch/arm64/boot/dts/mediatek/mt7986a-bananapi-bpi-r3.dts | 4 ++--
 arch/arm64/boot/dts/mediatek/mt7986a-rfb.dts             | 4 ++--
 arch/arm64/boot/dts/mediatek/mt7986b-rfb.dts             | 4 ++--
 5 files changed, 10 insertions(+), 10 deletions(-)
---
base-commit: ba90af39ba57b3fe3ecfdba0c87a80d20c7b788d
change-id: 20240314-for-mediatek-mt7531-phy-address-9d0b4cfeca21

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

