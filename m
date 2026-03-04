From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 04 Mar 2026 06:14:14 +0000
Subject: [PATCH v5 3/3] MAINTAINERS: Add an entry for Amlogic DMA driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260304-amlogic-dma-v5-3-aa453d14fd43@amlogic.com>
References: <20260304-amlogic-dma-v5-0-aa453d14fd43@amlogic.com>
In-Reply-To: <20260304-amlogic-dma-v5-0-aa453d14fd43@amlogic.com>
To: Vinod Koul <vkoul@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-amlogic@lists.infradead.org, dmaengine@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hardening@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772604853; l=791;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=3ILqFEE9mmDp095lkKeN49I2hs9aNRjaPs7y2SEtITs=;
 b=9USpP0n2vyKSR5Z5zHbVHWWUmK2A2p7Let4R9fnXZAezGITc++N1pXoFvcMlDUAjCTSoBm8s2
 ctANXVN1tv/CfTdMg2qDB1OiGzK7T56TIxFLGxUt40EQ0YiPopgKnIA
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Amlogic DMA controller entry to MAINTAINERS to clarify
the maintainers.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 MAINTAINERS | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 55af015174a5..e9c52dfba2df 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1316,6 +1316,13 @@ F:	Documentation/devicetree/bindings/perf/amlogic,g12-ddr-pmu.yaml
 F:	drivers/perf/amlogic/
 F:	include/soc/amlogic/
 
+AMLOGIC DMA DRIVER
+M:	Xianwei Zhao <xianwei.zhao@amlogic.com>
+L:	linux-amlogic@lists.infradead.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/dma/amlogic,a9-dma.yaml
+F:	drivers/dma/amlogic-dma.c
+
 AMLOGIC ISP DRIVER
 M:	Keke Li <keke.li@amlogic.com>
 L:	linux-media@vger.kernel.org

-- 
2.52.0

