From: Sam Day <me@samcday.com>
Date: Sat, 06 Jun 2026 10:52:44 +1000
Subject: [PATCH 10/13] arch: arm: qcom: samsung-gt510 binman config
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260606-android-binman-v1-10-c7a3c14b8a3d@samcday.com>
References: <20260606-android-binman-v1-0-c7a3c14b8a3d@samcday.com>
In-Reply-To: <20260606-android-binman-v1-0-c7a3c14b8a3d@samcday.com>
To: u-boot@lists.denx.de, Sumit Garg <sumit.garg@kernel.org>, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, Bryan Brattlof <bb@ti.com>, 
 Yannic Moog <y.moog@phytec.de>, Wojciech Dubowik <Wojciech.Dubowik@mt.com>, 
 Yegor Yefremov <yegorslists@googlemail.com>, 
 Denis Mukhin <dmukhin@ford.com>, Rasmus Villemoes <ravi@prevas.dk>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, Javier Tia <floss@jetm.me>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Tien Fong Chee <tien.fong.chee@altera.com>, Peng Fan <peng.fan@nxp.com>, 
 Anshul Dalal <anshuld@ti.com>, 
 Alif Zakuan Yuslaimi <alif.zakuan.yuslaimi@altera.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Tingting Meng <tingting.meng@altera.com>, Alice Guo <alice.guo@nxp.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Minkyu Kang <mk7.kang@samsung.com>, 
 Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Henrik Grimler <henrik@grimler.se>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780707158; l=1137;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=q0SxIURCjc44eZjkjf69qGVfGy9ts/AdxjjhWGBBf3w=;
 b=ODaVhvaEro6AvAG3oquLYq9JiOVw1Ml2xrvmSokyAsoQtZPj5rtm34weXnWFGdFNStm8QIuV6
 AjCVIZv0BNAC2/x2weYr7H0hWNxyncbt8bB7ZJWLoG0K4Pum0NUcf6Y
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Emits an Android boot.img that runs U-Boot from the boot partition
(chained from aboot).

Signed-off-by: Sam Day <me@samcday.com>
---
 arch/arm/dts/msm8916-samsung-gt510-u-boot.dtsi | 39 ++++++++++++++++++++++++++
 1 file changed, 39 insertions(+)

diff --git a/arch/arm/dts/msm8916-samsung-gt510-u-boot.dtsi b/arch/arm/dts/msm8916-samsung-gt510-u-boot.dtsi
new file mode 100644
index 00000000000..53f301a2b79
--- /dev/null
+++ b/arch/arm/dts/msm8916-samsung-gt510-u-boot.dtsi
@@ -0,0 +1,39 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#include <dt-bindings/arm/qcom,ids.h>
+
+/ {
+	binman {
+		filename = "u-boot-samsung-gt510.img";
+
+		android-boot {
+			header-version = <0>;
+			page-size = <2048>;
+			base = <0x80000000>;
+			append-seandroid-enforce;
+
+			kernel {
+				u-boot {
+					no-expanded;
+				};
+			};
+
+			ramdisk {
+				fill {
+					size = <1>;
+				};
+			};
+
+			vendor-dt {
+				qcdt {
+					dtb-0 {
+						qcom,msm-id = <QCOM_ID_MSM8916 0>;
+						qcom,board-id = <0xce08ff01 7>;
+
+						u-boot-dtb {};
+					};
+				};
+			};
+		};
+	};
+};

-- 
2.54.0

