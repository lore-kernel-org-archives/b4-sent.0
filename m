From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 24 Feb 2024 01:12:30 +0800
Subject: [PATCH v5 3/6] arm64: dts: hisilicon: fix include path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240224-clk-mv200-v5-3-79f586d6e1a2@outlook.com>
References: <20240224-clk-mv200-v5-0-79f586d6e1a2@outlook.com>
In-Reply-To: <20240224-clk-mv200-v5-0-79f586d6e1a2@outlook.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: David Yang <mmyangfl@gmail.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708708351; l=950;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=zO+w8jqaXi8Ww2B8vF6SfS+3nCbKAcDggVh4EP/9jpU=;
 b=m/+S05itWlQ30Ap9od5dWXU+DhSNZmKJ1WRyKNIxWY8aZzeBGh8iEuz5CFPLRErVQqroK0K93
 whFgLijOMOACKC14GB9qTEIQ0N1aXHpPY4K1H56iVLGhKgFzGf7cNAJ
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The generic histb-clock.h header is now deprecated. Fix it by including
individual binding header files directly instead.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi b/arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi
index ed1b5a7a6067..1e6a8a8829b1 100644
--- a/arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi
+++ b/arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi
@@ -5,7 +5,8 @@
  * Copyright (c) 2016-2017 HiSilicon Technologies Co., Ltd.
  */
 
-#include <dt-bindings/clock/histb-clock.h>
+#include <dt-bindings/clock/hisilicon,hi3798cv200-crg.h>
+#include <dt-bindings/clock/hisilicon,hi3798cv200-sysctrl.h>
 #include <dt-bindings/gpio/gpio.h>
 #include <dt-bindings/interrupt-controller/arm-gic.h>
 #include <dt-bindings/phy/phy.h>

-- 
2.43.0

