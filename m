From: Ben Grisdale <bengris32@protonmail.ch>
Subject: [PATCH 0/2] soc: mediatek: pwrap: Add MT8163 support
Date: Tue, 17 Nov 2026 13:28:07 +0000
Message-Id: <20261117-mt8163-pwrap-support-v1-0-b00fa10035a5@protonmail.ch>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CQAxA0auQrm1CK6LxKsYFzBStidBMByUh3
 N1Rl2/x/wouScXhXK2Q5KWu01hAuwrCvRtvghqLgWtuieiIz3yido/2Tp2hz2ZTyhgic8915MP
 QQEktyaDLb3u5/u1z/5CQvy/Ytg87GfMaeAAAAA==
X-Change-ID: 20261117-mt8163-pwrap-support-cd22b20d25f4
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Flora Fu <flora.fu@mediatek.com>, Alexandre Mergnat <amergnat@baylibre.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794922196; l=935;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=H/UCJ2qAfxJA3SdM4D1y0mgjHFPRdqf+v5XoA4KVnSE=;
 b=W0fKT3k00Nmsp06bXskA6eG5czcF25ffOkNp0AHPQ5MNuJDV+/5yhMrFAPHpN1uFZ4TZQ6EmC
 09oK9XlsU8wA1UhSSRYGCSFuBvUVmpwz23XJ59d0O6lFyjjMolv/YjC
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a new device tree compatible and driver support
for the PMIC wrapper on the MediaTek MT8163 SoC.

All known MT8163 devices use the MT6323 PMIC, which is already
supported upstream. Due to the MT6323 pairing, MT8163 can share
the same reg clock init as MT2701.

An additional series will be sent in future to make the MT6323
device tree usable for arm64 boards.

Signed-off-by: Ben Grisdale <bengris32@protonmail.ch>
---
Ben Grisdale (2):
      dt-bindings: soc: mediatek: pwrap: Add MT8163
      soc: mediatek: pwrap: Add support for MT8163

 .../bindings/soc/mediatek/mediatek,pwrap.yaml           |  1 +
 drivers/soc/mediatek/mtk-pmic-wrap.c                    | 17 +++++++++++++++++
 2 files changed, 18 insertions(+)
---
base-commit: 749a4de370409464cf8501ec5b2451df45c84eb4
change-id: 20261117-mt8163-pwrap-support-cd22b20d25f4

Best regards,
--  
Ben Grisdale <bengris32@protonmail.ch>

