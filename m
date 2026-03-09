From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v6 0/3] Add Amlogic general DMA
Date: Mon, 09 Mar 2026 06:33:51 +0000
Message-Id: <20260309-amlogic-dma-v6-0-63349d23bd4b@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAM9prmkC/23OwW7CMAwG4FdBOS9T4tjJwmnvgXYItQORKEXtV
 DGhvjsBgViB42/r++2TGqQvMqjl4qR6GctQun0N/mOhmm3ab0QXrlmBAbJgSad2121Ko7lNOkQ
 Mgalh8KiqOPSSy/HatvqpeVuG367/u5aP9jK99/hZz2i10QJfUShI9Cl837afTdeqS9MId+2Nh
 TDXUDUSEDsIHJBftXtoME+3XdXk8zpmisIArxr/6efbWHUGEvQWJa7ffE4P7QzONVWdEpJji5n
 RzfU0TWet487doAEAAA==
X-Change-ID: 20251215-amlogic-dma-79477d5cd264
To: Vinod Koul <vkoul@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Frank Li <Frank.Li@kernel.org>
Cc: linux-amlogic@lists.infradead.org, dmaengine@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hardening@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773038034; l=2225;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=+H1SBtc8kybh3elD3rirCxlwLPaSwRraLSvHJmDF8E4=;
 b=YsKRnRu9GAuuBEBSc4m+ypfeQJSwNrarLK8/8kRoxQMzCzeQ8HKTSpvBnCXBDQH5miFxSyfeM
 i558RIZKp0tBRE80pNH7tupBE5qDvzwlw0fM9WQB6gRa1bZXvOueFRM
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add DMA driver and bindigns for the Amlogic SoCs.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
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

 .../devicetree/bindings/dma/amlogic,a9-dma.yaml    |  65 +++
 MAINTAINERS                                        |   7 +
 drivers/dma/Kconfig                                |   9 +
 drivers/dma/Makefile                               |   1 +
 drivers/dma/amlogic-dma.c                          | 585 +++++++++++++++++++++
 include/dt-bindings/dma/amlogic,a9-dma.h           |   8 +
 6 files changed, 675 insertions(+)
---
base-commit: 3d2d1059cae3abab771576a7ee7f59d9627cfb8e
change-id: 20251215-amlogic-dma-79477d5cd264

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

