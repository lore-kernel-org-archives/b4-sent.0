From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/3] Add Amlogic general DMA
Date: Tue, 16 Dec 2025 08:03:16 +0000
Message-Id: <20251216-amlogic-dma-v1-0-e289e57e96a7@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEQSQWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDI0NT3cTcnPz0zGTdlNxEXXNLE3PzFNPkFCMzEyWgjoKi1LTMCrBp0bG
 1tQAShWYnXQAAAA==
X-Change-ID: 20251215-amlogic-dma-79477d5cd264
To: Vinod Koul <vkoul@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-amlogic@lists.infradead.org, dmaengine@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hardening@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1765872198; l=826;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=5OeYvXMSFntRvGG5qfE6GBqZZ5Co1CPYfzo/K+UvU6w=;
 b=wWM4MMb1w1IBw2bhpp5tF6jlfbiSZWVDh/2dF4DWMbv9j6YXf0iFkErQOd59LS4px15OCDLq6
 r7c5aLSdljMBKVGwXcMBrmumCstimx/SqopZrkCoRZLQWYEzlw7Ci2p
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add DMA driver and bindigns for the Amlogic SoCs.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (3):
      dt-bindings: dma: Add Amlogic general DMA
      dma: amlogic: Add general DMA driver for SoCs
      MAINTAINERS: Add an entry for Amlogic DMA driver

 .../bindings/dma/amlogic,general-dma.yaml          |  70 +++
 MAINTAINERS                                        |   7 +
 drivers/dma/Kconfig                                |   8 +
 drivers/dma/Makefile                               |   1 +
 drivers/dma/amlogic-dma.c                          | 567 +++++++++++++++++++++
 5 files changed, 653 insertions(+)
---
base-commit: 8f0b4cce4481fb22653697cced8d0d04027cb1e8
change-id: 20251215-amlogic-dma-79477d5cd264

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

