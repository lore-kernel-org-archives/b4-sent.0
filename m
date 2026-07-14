From: Nikolai Burov <nikolai.burov@jolla.com>
Subject: [PATCH 0/3] pmdomain: mediatek: Add MT6858 support
Date: Tue, 14 Jul 2026 16:43:05 +0300
Message-Id: <20260714-mt6858-pmdomain-v1-0-4f09bbb822e0@jolla.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOk8VmoC/yXMSwqEMBAA0atIrydggmk/VxlcmNhqC4mSqAji3
 Sejy7eouiBSYIrQZBcEOjjy4hPkJwM7dX4kwX0yqFxhXkol3IaVrsTq+sV17IWRptBoa8RSQ6r
 WQAOfz/Hbvo67mclu/w3c9w/7JHNicwAAAA==
X-Change-ID: 20260712-mt6858-pmdomain-b1b456c96675
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Ulf Hansson <ulfh@kernel.org>
Cc: Matthias Brugger <mbrugger@suse.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, linux-pm@vger.kernel.org, 
 Nikolai Burov <nikolai.burov@jolla.com>, 
 Nikolai Burov <nikolai.burov+review@abscue.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784036613; l=1329;
 i=nikolai.burov@jolla.com; s=20260707; h=from:subject:message-id;
 bh=B1dBuvMZZ+KcwFGP5V1ibOQf7yfUIHEhJB2HnHqSE8U=;
 b=7XYaBQR0BIJLfPGmhfDUR9Bs/0HhvM8dGolGPEg8QgVpXC8TT/QvkiyeLe93zS9DVUWcHPHR7
 2IE2UQgYK8lDxEVfgyemtphDYUBAviBuaFKS2F5E9OztEPHeythbnUF
X-Developer-Key: i=nikolai.burov@jolla.com; a=ed25519;
 pk=yzpa+PD+ovHUFMIOBA9o2QqGwI110jM6hdGHLc7jtoQ=
X-Endpoint-Received: by B4 Relay for nikolai.burov@jolla.com/20260707 with auth_id=859
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add power domain driver support for the MediaTek Dimensity 7100 (MT6858)
SoC. On this SoC, there are some new subsystem-specific bus protection
blocks, which are listed here in ascending address order:

- IMG_SUB0 at 0x1502f000
- CAM_SUB1 at 0x1a00c000
- CAM_SUB0 at 0x1a00d000
- IPE_SUB0 at 0x1b00e000

Additionally, implement the SMC-based power sequence required for
enabling the modem power domain on this SoC.

Signed-off-by: Nikolai Burov <nikolai.burov@jolla.com>
---
Nikolai Burov (3):
      dt-bindings: power: Add MediaTek MT6858 power domain controller
      pmdomain: mediatek: Add support for secure modem power domain control
      pmdomain: mediatek: Add support for MT6858 SoC

 .../bindings/power/mediatek,power-controller.yaml  |  21 +-
 drivers/pmdomain/mediatek/mt6858-pm-domains.h      | 462 +++++++++++++++++++++
 drivers/pmdomain/mediatek/mtk-pm-domains.c         |  59 ++-
 drivers/pmdomain/mediatek/mtk-pm-domains.h         |   6 +
 include/dt-bindings/power/mediatek,mt6858-power.h  |  23 +
 include/linux/soc/mediatek/mtk_sip_svc.h           |   3 +
 6 files changed, 568 insertions(+), 6 deletions(-)
---
base-commit: 49362394dad7df66c274c867a271394c10ca2bb8
change-id: 20260712-mt6858-pmdomain-b1b456c96675

Best regards,
--  
Nikolai Burov <nikolai.burov@jolla.com>

