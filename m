From: =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
Date: Tue, 03 Nov 2026 18:37:09 +0800
Subject: [PATCH v3 4/6] rockchip: rk3528: Split out common NanoPi
 u-boot.dtsi
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261103-nanopi-r28s-v3-4-ae8664fd168f@proton.me>
References: <20261103-nanopi-r28s-v3-0-ae8664fd168f@proton.me>
In-Reply-To: <20261103-nanopi-r28s-v3-0-ae8664fd168f@proton.me>
To: u-boot@lists.u-boot-project.org
Cc: Kever Yang <kever.yang@rock-chips.com>, 
 Quentin Schulz <u-boot@0leil.net>, Jonas Karlman <jonas@kwiboo.se>, 
 Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>, 
 Quentin Schulz <quentin.schulz@cherry.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2208;
 i=HystericalDragons@proton.me; s=20261103; h=from:subject:message-id;
 bh=TIxtOopOrGmSkxCMfGEz85CWNxKpg64WHl+I8dZuAlU=;
 b=owGbwMvMwCU8Ldb53x4TtgLG02pJDFkvdwZ/PRjYkN6VyHC1u37he8F++yj2q7v+tbxgmfOG8
 yajq6NVxw4WBmEuBlkxRZZO6c8Tvzy+MP3rzUlZMHNYmUCGMHBxCsBE2CcxcTLK+afUVl47va/l
 bej6S+sXuGTJZFTXCp2cdSCu8YTgivzOWv6HbscvNS659oh9W9Jap8Llaqs2y12W+XTtG7d1jZL
 XuwYmjks16VNvf7jCEbs0fe/nsysdVyllF16WsYnVNuBoOzjleZmanAf7Zbe9Xrr/rv2atk7RMd
 P5yM3zyoblT3Xvpn7LK3ktCAA=
X-Developer-Key: i=HystericalDragons@proton.me; a=openpgp;
 fpr=5A3AC293DCEEAA41A8A3266A910205A0AEB09D84
X-Endpoint-Received: by B4 Relay for HystericalDragons@proton.me/20261103 with auth_id=1393
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Linux devicetree of the NanoPi Zero2 has been split into a common
rk3528-nanopi.dtsi, which the NanoPi R28S builds on. Both boards use
the same PWM regulators for vdd_arm and vdd_logic.

Move the U-Boot specific parts of the NanoPi Zero2 into a common
rk3528-nanopi-u-boot.dtsi in the same way, so that the NanoPi R28S can
include it instead of duplicating it. No functional change.

Signed-off-by: 安容 <HystericalDragons@proton.me>
Reviewed-by: Quentin Schulz <quentin.schulz@cherry.de>
---
 arch/arm/dts/rk3528-nanopi-u-boot.dtsi       | 11 +++++++++++
 arch/arm/dts/rk3528-nanopi-zero2-u-boot.dtsi | 10 +---------
 arch/arm/mach-rockchip/rk3528/MAINTAINERS    |  1 +
 3 files changed, 13 insertions(+), 9 deletions(-)

diff --git a/arch/arm/dts/rk3528-nanopi-u-boot.dtsi b/arch/arm/dts/rk3528-nanopi-u-boot.dtsi
new file mode 100644
index 00000000000..3e2fbd81da1
--- /dev/null
+++ b/arch/arm/dts/rk3528-nanopi-u-boot.dtsi
@@ -0,0 +1,11 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
+
+#include "rk3528-u-boot.dtsi"
+
+&vdd_arm {
+	regulator-init-microvolt = <953000>;
+};
+
+&vdd_logic {
+	regulator-init-microvolt = <900000>;
+};
diff --git a/arch/arm/dts/rk3528-nanopi-zero2-u-boot.dtsi b/arch/arm/dts/rk3528-nanopi-zero2-u-boot.dtsi
index 3e2fbd81da1..151f1872fed 100644
--- a/arch/arm/dts/rk3528-nanopi-zero2-u-boot.dtsi
+++ b/arch/arm/dts/rk3528-nanopi-zero2-u-boot.dtsi
@@ -1,11 +1,3 @@
 // SPDX-License-Identifier: (GPL-2.0+ OR MIT)
 
-#include "rk3528-u-boot.dtsi"
-
-&vdd_arm {
-	regulator-init-microvolt = <953000>;
-};
-
-&vdd_logic {
-	regulator-init-microvolt = <900000>;
-};
+#include "rk3528-nanopi-u-boot.dtsi"
diff --git a/arch/arm/mach-rockchip/rk3528/MAINTAINERS b/arch/arm/mach-rockchip/rk3528/MAINTAINERS
index 95543b40dd3..d1810fb0528 100644
--- a/arch/arm/mach-rockchip/rk3528/MAINTAINERS
+++ b/arch/arm/mach-rockchip/rk3528/MAINTAINERS
@@ -13,6 +13,7 @@ F:	configs/hinlink-h28k-rk3528_defconfig
 NANOPI-ZERO2-RK3528
 M:	Jonas Karlman <jonas@kwiboo.se>
 S:	Maintained
+F:	arch/arm/dts/rk3528-nanopi-u-boot.dtsi
 F:	arch/arm/dts/rk3528-nanopi-zero2*
 F:	configs/nanopi-zero2-rk3528_defconfig
 

-- 
2.56.0

