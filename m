From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v9 0/3] Add Amlogic general DMA
Date: Fri, 26 Jun 2026 05:39:32 +0000
Message-Id: <20260626-amlogic-dma-v9-0-558d672c4a95@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJQQPmoC/23QTU7EMAwF4KuMsqaoduykYcU9EIs0cWci0SlqU
 QUa9e6kI0b9Y/kSfc+Wb2qQPsmgXk431cuYhtRdc3BPJxUu/nqWIsWcFZbIgMCFbz+6cwpFbH1
 hHVkbOUQ0pLL47KVJ3/e2t/ecL2n46vqfe/kI8+ujx2x6RijKQrBywlac8fb17/c5dK2am0Z8a
 FMC2q3GrImRo0YbLcWj1ovGcjdbZ82mqV3DTiLiUdNK72dT1g2ykAESV/+zOS9al7TVnLX3xDo
 CNZH0UZu1dlttsjZak4uo60j1UduVxt1sO29e1Q5EwGGAo64WzQhbXWVdmRAwiCOg3dWmafoFE
 uGPSloCAAA=
X-Change-ID: 20251215-amlogic-dma-79477d5cd264
To: Vinod Koul <vkoul@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Frank Li <Frank.Li@kernel.org>
Cc: linux-amlogic@lists.infradead.org, dmaengine@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hardening@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782452375; l=2825;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=g+qv6yDnSKfM5Y35nL+/IDMuJ04Lv9xK2LZVXVlDSpQ=;
 b=mDnEzc5cmYQ9D1pqlFBAkvAS8wOrutsoF7kY2et9MK1iAJabMWCZVNZIbjhzSpi3V8fp5/MLV
 jKtI/Okrw1uAvN0i5dlShGgHVXY9ex4goTEgkU2w1tnPkjaRGLq1/2K
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add DMA driver and bindigns for the Amlogic SoCs.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v9:
- Use each transmission request sg_link mem instead of the loop mem get.
- Fix some hidden issues which reviewed by ai robot.
- Link to v8: https://lore.kernel.org/r/20260521-amlogic-dma-v8-0-86cc2ce94142@amlogic.com

Changes in v8:
- Use kzalloc instead of kmalloc.
- Initialize the temporary variable and fix a spelling mistake.
- Link to v7: https://lore.kernel.org/r/20260324-amlogic-dma-v7-0-f8b91ee192c1@amlogic.com

Changes in v7:
- Take use vchan to support mltiple txns.
- Link to v6: https://lore.kernel.org/r/20260309-amlogic-dma-v6-0-63349d23bd4b@amlogic.com

Changes in v6:
- Some minor modifications according to Frank's suggestion.
- Link to v5: https://lore.kernel.org/r/20260304-amlogic-dma-v5-0-aa453d14fd43@amlogic.com

Changes in v5:
- Rename head file and rename macro definition.
- Rename the subject in [2/3] from "dma" to "dmaengine".
- Link to v4: https://lore.kernel.org/r/20260227-amlogic-dma-v4-0-f25e4614e9b7@amlogic.com

Changes in v4:
- Support split transfer when data len > MAX_LEN.
- When a module fails or exits, perform de-initialization.
- Some other minor modifications.
- Link to v3: https://lore.kernel.org/r/20260206-amlogic-dma-v3-0-56fb9f59ed22@amlogic.com

Changes in v3:
- Adjust the format of binding according to Frank's suggestion.
- Some code format modified according to Frank's suggestion.
- Support one prep_sg and one submit, drop multi prep_sg and one submit.
- Keep pre state when resume from pause status.
- Link to v2: https://lore.kernel.org/r/20260127-amlogic-dma-v2-0-4525d327d74d@amlogic.com

Changes in v2:
- Introduce what the DMA is used for in the A9 SoC.
- Some minor modifications were made according to Krzysztof's suggestions.
- Some modifications were made according to Neil's suggestions.
- Fix a build error.
- Link to v1: https://lore.kernel.org/r/20251216-amlogic-dma-v1-0-e289e57e96a7@amlogic.com

---
Xianwei Zhao (3):
      dt-bindings: dma: Add Amlogic A9 SoC DMA
      dmaengine: amlogic: Add general DMA driver for A9
      MAINTAINERS: Add an entry for Amlogic DMA driver

 .../devicetree/bindings/dma/amlogic,a9-dma.yaml    |  65 ++
 MAINTAINERS                                        |   7 +
 drivers/dma/Kconfig                                |  10 +
 drivers/dma/Makefile                               |   1 +
 drivers/dma/amlogic-dma.c                          | 708 +++++++++++++++++++++
 include/dt-bindings/dma/amlogic,a9-dma.h           |   8 +
 6 files changed, 799 insertions(+)
---
base-commit: 4e01d2f7809240ed63a44889386635921c0627b1
change-id: 20251215-amlogic-dma-79477d5cd264

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

