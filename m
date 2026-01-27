From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v2 0/3] Add Amlogic general DMA
Date: Tue, 27 Jan 2026 03:27:51 +0000
Message-Id: <20260127-amlogic-dma-v2-0-4525d327d74d@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALgweGkC/1XMQQ7CIBCF4as0sxZTSAFx1XuYLgiM7SRSDBiia
 bi72OjC5T+T922QMRFmOHcbJCyUKa4txKEDt9h1Rka+NYheSC64ZDbc4kyO+WCZNoPWXjov1AB
 tcU94peeuXabWC+VHTK8dL/xz/Tnqzymc9QzFyaDUaJTV4/d7dDHAVGt9A/rhUiKoAAAA
X-Change-ID: 20251215-amlogic-dma-79477d5cd264
To: Vinod Koul <vkoul@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-amlogic@lists.infradead.org, dmaengine@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hardening@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769484476; l=1154;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=82UInUPaZAsuTnm7Eq2Rk6+iYxY2ts69JzilZc2OUsQ=;
 b=5pfGRD1ecIIB6hxFANgbOJ1NQmMd6kd+5Feseh7D/qlkLzwYFtI7HdbLloiExbeHw/v7Hsk5T
 EwCisl719kzCxW9iU3KyLM1/qj+3l2h1IAByGyQMcsZlhF09uAbbavS
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add DMA driver and bindigns for the Amlogic SoCs.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v2:
- Introduce what the DMA is used for in the A9 SoC.
- Some minor modifications were made according to Krzysztof's suggestions.
- Some modifications were made according to Neil's suggestions.
- Fix a build error.
- Link to v1: https://lore.kernel.org/r/20251216-amlogic-dma-v1-0-e289e57e96a7@amlogic.com

---
Xianwei Zhao (3):
      dt-bindings: dma: Add Amlogic A9 SoC DMA
      dma: amlogic: Add general DMA driver for A9
      MAINTAINERS: Add an entry for Amlogic DMA driver

 .../devicetree/bindings/dma/amlogic,a9-dma.yaml    |  70 +++
 MAINTAINERS                                        |   7 +
 drivers/dma/Kconfig                                |   9 +
 drivers/dma/Makefile                               |   1 +
 drivers/dma/amlogic-dma.c                          | 563 +++++++++++++++++++++
 5 files changed, 650 insertions(+)
---
base-commit: 3c8a86ed002ab8fb287ee4ec92f0fd6ac5b291d2
change-id: 20251215-amlogic-dma-79477d5cd264

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

