From: =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
Date: Mon, 12 Oct 2026 14:55:42 +0800
Subject: [PATCH 1/2] rockchip: rk3528: Split out common NanoPi u-boot.dtsi
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261012-nanopi-r28s-v1-1-042d62597829@proton.me>
References: <20261012-nanopi-r28s-v1-0-042d62597829@proton.me>
In-Reply-To: <20261012-nanopi-r28s-v1-0-042d62597829@proton.me>
To: u-boot@lists.u-boot-project.org
Cc: Kever Yang <kever.yang@rock-chips.com>, 
 Quentin Schulz <u-boot@0leil.net>, Jonas Karlman <jonas@kwiboo.se>, 
 Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2152;
 i=HystericalDragons@proton.me; h=from:subject:message-id;
 bh=OPgz28j3KtTUGlUgWj5O/HjkThPqN+JWbYP1nYWKvr4=;
 b=owGbwMvMwCUmepz3XUtTHjvjabUkhqwzLflCEwNWf+c5uP+M8uyEP5HG00JZduo93ju5KZ+1M
 Hrymx88HaUsDGJcDLJiiiyym6ojhVZFzyxikToOM4eVCWQIAxenAExERprhD0ffVrdr5ptPz18R
 pRjB/o2l59fWHavyzC/517OdXXG2XJORodllp8fzSbYhcSv+FRfvLq7fGq68Krw1+qntz4sMZ+T
 1GQE=
X-Developer-Key: i=HystericalDragons@proton.me; a=openpgp;
 fpr=1DB27B5912AA5B9972041AC715C70DEE84826E07
X-Endpoint-Received: by B4 Relay for HystericalDragons@proton.me/default with auth_id=1004
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Linux devicetree of the NanoPi Zero2 has been split into a common
rk3528-nanopi.dtsi, which the NanoPi R28S builds on. Both boards use
the same PWM regulators for vdd_arm and vdd_logic.

Move the U-Boot specific parts of the NanoPi Zero2 into a common
rk3528-nanopi-u-boot.dtsi in the same way, so that the NanoPi R28S can
include it instead of duplicating it. No functional change.

Signed-off-by: 安容 <HystericalDragons@proton.me>
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

