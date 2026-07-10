From: Nikolai Burov <nikolai.burov@jolla.com>
Subject: [PATCH 0/3] pinctrl: mediatek: Add MT6858 support
Date: Fri, 10 Jul 2026 18:00:22 +0300
Message-Id: <20260710-mt6858-pinctrl-v1-0-f75ab558f0df@jolla.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAYJUWoC/yXMQQqDMBBA0avIrBsYI5rEqxQXGqd1RKMkUQTx7
 sZ2+Rb/nxDIMwWosxM87Rx4cQn5KwM7tO5LgvtkkCgrVKjFHCtdarGys9FPwuSq7Q0ahbKAFK2
 ePnz8hu/m77B1I9n4XOC6blrsz45yAAAA
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
 Nikolai Burov <nikolai.burov+review@abscue.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783695712; l=964;
 i=nikolai.burov@jolla.com; s=20260707; h=from:subject:message-id;
 bh=Zq0NKaJlpzYFMBprR7tFkC2cwEQusS6IE/2q5o6meCc=;
 b=dyxBquZP+GmdIg3f4UUg/xOOgljWgtNmiAwORqIKBamjDtTKI7DnD9sXCD3aVIz6d22P2zk0z
 EG7H7U+F8BLDZvN+uULFm22Jix5qv8l4sW25Lyq79NqY6FOX7UTUuvL
X-Developer-Key: i=nikolai.burov@jolla.com; a=ed25519;
 pk=yzpa+PD+ovHUFMIOBA9o2QqGwI110jM6hdGHLc7jtoQ=
X-Endpoint-Received: by B4 Relay for nikolai.burov@jolla.com/20260707 with auth_id=859
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for GPIO and pin configuration on the MT6858 (MediaTek
Dimensity 7100) SoC.

Signed-off-by: Nikolai Burov <nikolai.burov@jolla.com>
---
Nikolai Burov (3):
      dt-bindings: pinctrl: mediatek: Add MT6858
      pinctrl: mediatek: Add driver for MT6858
      arm64: dts: mediatek: mt6858: Add pinmux macro header file

 .../bindings/pinctrl/mediatek,mt6858-pinctrl.yaml  |  190 ++
 arch/arm64/boot/dts/mediatek/mt6858-pinfunc.h      | 1335 ++++++++++++
 drivers/pinctrl/mediatek/Kconfig                   |   10 +
 drivers/pinctrl/mediatek/Makefile                  |    1 +
 drivers/pinctrl/mediatek/pinctrl-mt6858.c          | 1408 ++++++++++++
 drivers/pinctrl/mediatek/pinctrl-mtk-mt6858.h      | 2301 ++++++++++++++++++++
 6 files changed, 5245 insertions(+)
---
base-commit: bee763d5f341b99cf472afeb508d4988f62a6ca1
change-id: 20260708-mt6858-pinctrl-917ad9097023

Best regards,
--  
Nikolai Burov <nikolai.burov@jolla.com>

