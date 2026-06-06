From: Sam Day <me@samcday.com>
Date: Sat, 06 Jun 2026 10:52:38 +1000
Subject: [PATCH 04/13] qcom: arch: arm: qcom: sdm845-fajita binman configs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260606-android-binman-v1-4-c7a3c14b8a3d@samcday.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780707158; l=1083;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=mZxf+Q/EuryyhsgbBMWO83UoITzAa8GMxzUa+eg9aHg=;
 b=xuPEhbs5wlRRl3fnxwvPIH14+S1PB2ShzfVDRdwV4PRuRxWrFJlY6jIrdylddDmdNv7eAS9iT
 zhP4GK22upSDGUcSMNhwUrszNATw0WQDc9RLUscjTW8wN7bJbIg0pT8
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This binman configuration emits an Android v2 boot image that ABL will
accept. This platform accepts uncompressed kernel artifacts, and the
boot partition(s) are plenty big enough, so we opt for speed over size.

Signed-off-by: Sam Day <me@samcday.com>
---
 arch/arm/dts/sdm845-oneplus-fajita-u-boot.dtsi | 27 ++++++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/arch/arm/dts/sdm845-oneplus-fajita-u-boot.dtsi b/arch/arm/dts/sdm845-oneplus-fajita-u-boot.dtsi
new file mode 100644
index 00000000000..b88be5a502e
--- /dev/null
+++ b/arch/arm/dts/sdm845-oneplus-fajita-u-boot.dtsi
@@ -0,0 +1,27 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#include <config.h>
+
+#ifdef CONFIG_BINMAN
+/ {
+	binman {
+		filename = "u-boot-oneplus-fajita.img";
+
+		android-boot {
+			header-version = <2>;
+			page-size = <4096>;
+			base = <0x00000000>;
+			kernel-offset = <0x00008000>;
+			dtb-offset = <0x01f00000>;
+
+			kernel {
+				u-boot-nodtb {};
+			};
+
+			dtb {
+				u-boot-dtb {};
+			};
+		};
+	};
+};
+#endif

-- 
2.54.0

