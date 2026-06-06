From: Sam Day <me@samcday.com>
Date: Sat, 06 Jun 2026 10:52:37 +1000
Subject: [PATCH 03/13] arch: arm: qcom: google-sargo binman config
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260606-android-binman-v1-3-c7a3c14b8a3d@samcday.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780707158; l=1036;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=x7PcMVoEJJF1L5LgC89yb2s092Ohj6g7/XUCPTRu96g=;
 b=XbbssfG97Eh7Atb99m55YWnn46VnWw+A4bdwnxHfIA8OuUA2Uor3sGdbtpgXwfU3Eo8a6zKVG
 EeHJv/TTFFUDB2KTNn5QfLUy1C1/2A2KbH06NAxO7Jj+dNhJUhcen8z
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This binman configuration emits an Android v2 boot image that ABL will
accept. Notably, this platform does not seem to accept uncompressed
kernel payloads, so it's gzipped.

Signed-off-by: Sam Day <me@samcday.com>
---
 arch/arm/dts/sdm670-google-sargo-u-boot.dtsi | 27 +++++++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/arch/arm/dts/sdm670-google-sargo-u-boot.dtsi b/arch/arm/dts/sdm670-google-sargo-u-boot.dtsi
new file mode 100644
index 00000000000..3257ef165cd
--- /dev/null
+++ b/arch/arm/dts/sdm670-google-sargo-u-boot.dtsi
@@ -0,0 +1,27 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#include <config.h>
+
+/ {
+	binman {
+		filename = "u-boot-google-sargo.img";
+
+		android-boot {
+			header-version = <2>;
+			page-size = <4096>;
+			base = <0x80000000>;
+			kernel-offset = <0x00008000>;
+			dtb-offset = <0x01f00000>;
+
+			kernel {
+				u-boot-nodtb {
+					compress = "gzip";
+				};
+			};
+
+			dtb {
+				u-boot-dtb {};
+			};
+		};
+	};
+};

-- 
2.54.0

