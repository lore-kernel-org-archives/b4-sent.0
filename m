From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH 0/2] arm64: dts: hi3798cv200: fix GICR size, add cache info
Date: Sun, 18 Feb 2024 17:40:29 +0800
Message-Id: <20240218-cache-v1-0-2c0a8a4472e7@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAI3Q0WUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDI0ML3eTE5IxUXUPDZIukNHNTM7NkIyWg2oKi1LTMCrA50bG1tQC79Mk
 MVwAAAA==
To: Wei Xu <xuwei5@hisilicon.com>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Jiancheng Xue <xuejiancheng@hisilicon.com>, Alex Elder <elder@linaro.org>, 
 Peter Griffin <peter.griffin@linaro.org>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708249233; l=1327;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=Y2yL2MQNl7y8iBg/28LLbPzlCYDMItit1WDiqTg7AR8=;
 b=EzwalVvQRDgmdAMHbQNlXT2iUSev7lM7NJ4H5zbxJQZQ6mLZu7IRNbdTgROodx4If5ifkW/Md
 +xhp0tJPbCaA4ajzfD5jG9+NTZnpZ+53fA3+S/6SrAMxiORlxl7NucD
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

They are tested on a hi3798mv200 board in fact. Though the 2 SoCs are
highly similar and the CPU should be the same. Still, Tested-by are
welcomed.

The patchset fixes some warnings reported by the kernel during boot.

The cache size info is from Processor_Datasheet_v2XX.pdf [1], Section
2.2.1 Master Processor.

The cache line size and the set-associative info are from Cortex-A53
Documentation [2]. Dts for other SoCs are also a good reference.

From the doc, we know L1 i-cache is 4-way assoc, L1 d-cache is 2-way
assoc and L2 cache is 16-way assoc. Fill the dts props accordingly.

Dear maintainers, maybe consider Cc to stable too?

[1]: https://github.com/96boards/documentation/blob/master/enterprise/poplar/hardware-docs/Processor_Datasheet_v2XX.pdf
[2]: https://developer.arm.com/documentation/ddi0500/j/Level-1-Memory-System

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Yang Xiwen (2):
      arm64: dts: hi3798cv200: Fix the size of GICR
      arm64: dts: hi3798cv200: add cache info

 arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi | 39 +++++++++++++++++++++++++-
 1 file changed, 38 insertions(+), 1 deletion(-)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240218-cache-11c8bf7566c2

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

