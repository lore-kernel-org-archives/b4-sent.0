From: Sam Day <me@samcday.com>
Date: Sat, 06 Jun 2026 10:52:46 +1000
Subject: [PATCH 12/13] arch: arm: exynos: add j7xelte binman config
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260606-android-binman-v1-12-c7a3c14b8a3d@samcday.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780707158; l=1641;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=hzM31luBfhFowNCNLsI3ruIRjk1FJsZ3zNEzn6DLuPs=;
 b=BTtUFmppJKh7IRNx/9XUZUpbbk1zxge3TYJMlz/TrxM72n1SS4YL8LLgD8DrbUyBFHP4HIUoF
 u+T/bLwNh5BB5JOUIr7KFJWCPcezeyjvuhoHReT7y0tufw8emNhWk3I
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Note that, as of this commit, j7xelte does not yet exist in U-Boot's
upstream DTS tree. It was accepted into next so it should appear here
eventually.

S-BOOT expects a DTBH with hw-rev == 6.

Link: https://lore.kernel.org/all/177209522223.26390.6219893536178441080.b4-ty@kernel.org/
Signed-off-by: Sam Day <me@samcday.com>
---
 arch/arm/dts/exynos7870-j7xelte-u-boot.dtsi    | 24 ++++++++++++++++++++++++
 arch/arm/dts/sdm845-oneplus-fajita-u-boot.dtsi |  2 --
 2 files changed, 24 insertions(+), 2 deletions(-)

diff --git a/arch/arm/dts/exynos7870-j7xelte-u-boot.dtsi b/arch/arm/dts/exynos7870-j7xelte-u-boot.dtsi
new file mode 100644
index 00000000000..90bf3b735d5
--- /dev/null
+++ b/arch/arm/dts/exynos7870-j7xelte-u-boot.dtsi
@@ -0,0 +1,24 @@
+// SPDX-License-Identifier: GPL-2.0
+
+/ {
+	/* These properties are required by S-BOOT. */
+	model_info-chip = <7870>;
+	model_info-hw_rev = <6>;
+	model_info-hw_rev_end = <6>;
+
+	binman {
+		filename = "u-boot-samsung-j7xelte.img";
+		android-boot {
+			kernel {
+				u-boot-nodtb {};
+			};
+			vendor-dt {
+				dtbh {
+					dtb-0 {
+						u-boot-dtb { };
+					};
+				};
+			};
+		};
+	};
+};
diff --git a/arch/arm/dts/sdm845-oneplus-fajita-u-boot.dtsi b/arch/arm/dts/sdm845-oneplus-fajita-u-boot.dtsi
index b88be5a502e..d0e0f64ae16 100644
--- a/arch/arm/dts/sdm845-oneplus-fajita-u-boot.dtsi
+++ b/arch/arm/dts/sdm845-oneplus-fajita-u-boot.dtsi
@@ -2,7 +2,6 @@
 
 #include <config.h>
 
-#ifdef CONFIG_BINMAN
 / {
 	binman {
 		filename = "u-boot-oneplus-fajita.img";
@@ -24,4 +23,3 @@
 		};
 	};
 };
-#endif

-- 
2.54.0

