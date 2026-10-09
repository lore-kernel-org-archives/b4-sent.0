From: Long Zhao <longzhao@ambarella.com>
Date: Fri, 09 Oct 2026 19:00:23 +0800
Subject: [PATCH 2/4] dt-bindings: mfd: syscon: add Ambarella CV75 secure
 scratchpad
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-cv75-soc-v1-2-808330e93ff1@ambarella.com>
References: <20261009-cv75-soc-v1-0-808330e93ff1@ambarella.com>
In-Reply-To: <20261009-cv75-soc-v1-0-808330e93ff1@ambarella.com>
To: Arnd Bergmann <arnd@arndb.de>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, soc@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Lee Jones <lee@kernel.org>, mfd@lists.linux.dev, devicetree@vger.kernel.org, 
 Long Zhao <longzhao@ambarella.com>, Long Zhao <zl020895@163.com>, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791543624; l=934;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=sWEDtsH7Lmq1R/x+RLJKvlPiYjtNzkc/ykiOxa9OBkU=;
 b=xgMXHFlE0r6oLPkI0VxxMrzReu67bf/gK3plkl0CEj768TtTEYtjOsPURVE1gRgEhf2/v/xva
 374waGNZlTvAtK3EkixRX13+RCtFZf5V8BR3t/09ZxPhruvoMXZtIvs
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow ambarella,cv75-sec-scratchpad as a syscon for the shared secure
scratchpad registers on CV75.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 Documentation/devicetree/bindings/mfd/syscon.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/mfd/syscon.yaml b/Documentation/devicetree/bindings/mfd/syscon.yaml
index fe882d3f828b..9ebf702c06f1 100644
--- a/Documentation/devicetree/bindings/mfd/syscon.yaml
+++ b/Documentation/devicetree/bindings/mfd/syscon.yaml
@@ -32,6 +32,7 @@ properties:
               - allwinner,sun50i-a64-system-controller
               - altr,l3regs
               - altr,sdr-ctl
+              - ambarella,cv75-sec-scratchpad
               - amd,pensando-elba-syscon
               - amlogic,meson-mx-assist
               - amlogic,meson-mx-bootrom

-- 
2.34.1

