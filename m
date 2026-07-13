From: Nikolai Burov <nikolai.burov@jolla.com>
Subject: [PATCH v2 0/3] pinctrl: mediatek: Add MT6858 support
Date: Mon, 13 Jul 2026 18:06:20 +0300
Message-Id: <20260713-mt6858-pinctrl-v2-0-1bd072e3206c@jolla.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOz+VGoC/12NQQ6DIBQFr2L+ujQfGgS76j0aF4hQMSoGqGljv
 HvRdtXlJPPmrRBNcCbCtVghmMVF56cM7FSA7tT0MMS1mYEhK1GgJGMqJZdkdpNOYSAVFaqtsBL
 ILpBHczDWvY7gvf5yfDa90Wmv7EbnYvLhfTwudPd+cYr/8YUSJFZw1XAuLbb21vthUGftR6i3b
 fsArly8vb4AAAA=
X-Change-ID: 20260708-mt6858-pinctrl-917ad9097023
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, Nikolai Burov <nikolai.burov@jolla.com>, 
 Nikolai Burov <nikolai.burov+review@abscue.de>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783955270; l=1879;
 i=nikolai.burov@jolla.com; s=20260707; h=from:subject:message-id;
 bh=JovwadXpz7CRGvxkNebvwnbtAdzmpWCiqaagy7z8tjw=;
 b=bWb23C26pN44n6mlmSAmuErea+0dtwrEaBlVVmyqLqqYDYMF6hqHYLznk/EUFEfNGhgqZrZSY
 qgwi96JaH/eDRNEKJ52VBzCwrmldS3UcW7B4GPGDJ7/wZmwMNsSo2wH
X-Developer-Key: i=nikolai.burov@jolla.com; a=ed25519;
 pk=yzpa+PD+ovHUFMIOBA9o2QqGwI110jM6hdGHLc7jtoQ=
X-Endpoint-Received: by B4 Relay for nikolai.burov@jolla.com/20260707 with auth_id=859
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for GPIO and pin configuration on the MT6858 (MediaTek
Dimensity 7100) SoC.

Signed-off-by: Nikolai Burov <nikolai.burov@jolla.com>
---
Changes in v2:
- dt-bindings: Change reg-names and descriptions as suggested by Angelo
- Remove incorrect slew rate field from register table
- Fix hole in the EINT table by including pins without EINT support
- Add missing pm_sleep_ptr() and /* sentinel */ comment
- Link to v1: https://patch.msgid.link/20260710-mt6858-pinctrl-v1-0-f75ab558f0df@jolla.com

To: Linus Walleij <linusw@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Matthias Brugger <matthias.bgg@gmail.com>
To: AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
To: Nikolai Burov <nikolai.burov@jolla.com>
To: Sean Wang <sean.wang@kernel.org>
Cc: linux-gpio@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-mediatek@lists.infradead.org

---
Nikolai Burov (3):
      dt-bindings: pinctrl: mediatek: Add MT6858
      pinctrl: mediatek: Add driver for MT6858
      arm64: dts: mediatek: mt6858: Add pinmux macro header file

 .../bindings/pinctrl/mediatek,mt6858-pinctrl.yaml  |  190 ++
 arch/arm64/boot/dts/mediatek/mt6858-pinfunc.h      | 1335 +++++++++++
 drivers/pinctrl/mediatek/Kconfig                   |   10 +
 drivers/pinctrl/mediatek/Makefile                  |    1 +
 drivers/pinctrl/mediatek/pinctrl-mt6858.c          | 1407 ++++++++++++
 drivers/pinctrl/mediatek/pinctrl-mtk-mt6858.h      | 2378 ++++++++++++++++++++
 6 files changed, 5321 insertions(+)
---
base-commit: bee763d5f341b99cf472afeb508d4988f62a6ca1
change-id: 20260708-mt6858-pinctrl-917ad9097023

Best regards,
--  
Nikolai Burov <nikolai.burov@jolla.com>

