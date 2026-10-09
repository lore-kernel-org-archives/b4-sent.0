From: Long Zhao <longzhao@ambarella.com>
Subject: [PATCH 0/2] clk: add Ambarella CV75 RCT clock controller
Date: Fri, 09 Oct 2026 19:00:11 +0800
Message-Id: <20261009-cv75-clk-v1-0-6959b4da83c5@ambarella.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADvJyGoC/yXM0QpAMBTG8VfRubbaNBavIhczBwehDam1dzdc/
 ur/fR4cWkIHVeLB4kWOtjVCpAmYUa8DMuqiIeNZIThXzFwqZ2aZWa8kClnKXBUaYr5b7On+rur
 mtzvbCc3x7iGEBzbbpUJsAAAA
X-Change-ID: 20261007-cv75-clk-f74e1494576a
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, linux-clk@vger.kernel.org
Cc: Jerome Brunet <jbrunet@baylibre.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 Long Zhao <longzhao@ambarella.com>, Long Zhao <zl020895@163.com>, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791543615; l=2190;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=nEmNB/P7dMfDzlN97RLQsTVzEKL8hg1jn6EUL8ZG6dA=;
 b=Ccza4jQiFmnUVMomgE3ejHoZTGqwXkTT2Q/8/Zxd0/dF8iYXRd0cbXmE+p6pclf4tqY/HeQRl
 2r6oZaibcS1BwEF8KJlBKlurGpjzt+ZqaKK3KC/eqrxj5E07v3QyFdT
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Split from the combined CV75 bring-up series.

CLK_AMBARELLA_CV75 depends on ARCH_AMBARELLA || COMPILE_TEST, so the
driver still builds with COMPILE_TEST when the SoC symbol is absent.
The binding uses the ambarella vendor prefix, which is added by the
SoC series and is not in mainline yet; dt_binding_check needs that
prefix. The MAINTAINERS entry for these files is in the SoC series.

Changes since the patches in the combined v9:
- drop the redundant linux/math.h include (Andy)
- use for (unsigned int i = 0; ...) (Andy)
- initialize the spinlock after the allocation succeeds (Andy)
- group the ctrl, frac and ctrl2 offsets in struct cv75_pll_regs (Andy)

Link: https://patch.msgid.link/20261001-cv75-v5-v9-0-486cc289a4b8@ambarella.com

To: Michael Turquette <mturquette@baylibre.com>
To: Stephen Boyd <sboyd@kernel.org>
To: linux-clk@vger.kernel.org
Cc: Jerome Brunet <jbrunet@baylibre.com>
Cc: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Cc: Rob Herring <robh@kernel.org>
Cc: Krzysztof Kozlowski <krzk@kernel.org>
Cc: Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Cc: Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org
Cc: Long Zhao <longzhao@ambarella.com>
Cc: Long Zhao <zl020895@163.com>
Cc: linux-kernel@vger.kernel.org

Assisted-by: LLM
Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
Long Zhao (2):
      dt-bindings: clock: add Ambarella CV75 RCT
      clk: ambarella: add CV75 RCT clock controller

 .../bindings/clock/ambarella,cv75-rct.yaml         |  64 ++++
 drivers/clk/Kconfig                                |   1 +
 drivers/clk/Makefile                               |   1 +
 drivers/clk/ambarella/Kconfig                      |   9 +
 drivers/clk/ambarella/Makefile                     |   3 +
 drivers/clk/ambarella/clk-cv75.c                   | 361 +++++++++++++++++++++
 include/dt-bindings/clock/ambarella,cv75-rct.h     |  14 +
 7 files changed, 453 insertions(+)
---
base-commit: 34cf6dafc47441dfb6b356a095b89c3585a93714
change-id: 20261007-cv75-clk-f74e1494576a

Best regards,
--  
Long Zhao <longzhao@ambarella.com>

