From: Sam Day <me@samcday.com>
Date: Wed, 10 Jun 2026 11:27:47 +1000
Subject: [PATCH v3 09/10] arch: arm: exynos: add j7xelte binman config
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260610-android-binman-v3-9-710298a38fcc@samcday.com>
References: <20260610-android-binman-v3-0-710298a38fcc@samcday.com>
In-Reply-To: <20260610-android-binman-v3-0-710298a38fcc@samcday.com>
To: u-boot@lists.denx.de
Cc: Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, Bryan Brattlof <bb@ti.com>, 
 Yannic Moog <y.moog@phytec.de>, Wojciech Dubowik <Wojciech.Dubowik@mt.com>, 
 Yegor Yefremov <yegorslists@googlemail.com>, 
 Patrice Chotard <patrice.chotard@foss.st.com>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Rasmus Villemoes <ravi@prevas.dk>, Javier Tia <floss@jetm.me>, 
 Minkyu Kang <mk7.kang@samsung.com>, 
 Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Henrik Grimler <henrik@grimler.se>, yan wang <yan.wang@softathome.com>, 
 Marek Vasut <marex@nabladev.com>, Denis Mukhin <dmukhin@ford.com>, 
 Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781054859; l=1129;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=6N86e0nsPC791hYMDJuBq6vEcAt8DN6e0mfDXT4z8F0=;
 b=2qfRC2Sz84ILQ3AjBRog3eCXyVRF/2+ANcmE3Z03ekQTG3i4GjEc8Pj4P8bLi9H7MclrvH0Az
 BaBhcP9ooDkBHBRv2cGN8Cc83ZnaU2w0TDt0JLLMmRIlqJpIiNCexTm
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Note that, as of this commit, j7xelte does not yet exist in U-Boot's
upstream DTS tree. It was accepted into next so it should appear here
eventually.

Link: https://lore.kernel.org/all/177209522223.26390.6219893536178441080.b4-ty@kernel.org/
Signed-off-by: Sam Day <me@samcday.com>
---
 arch/arm/dts/exynos7870-j7xelte-u-boot.dtsi | 26 ++++++++++++++++++++++++++
 1 file changed, 26 insertions(+)

diff --git a/arch/arm/dts/exynos7870-j7xelte-u-boot.dtsi b/arch/arm/dts/exynos7870-j7xelte-u-boot.dtsi
new file mode 100644
index 00000000000..0cd4c12a2e4
--- /dev/null
+++ b/arch/arm/dts/exynos7870-j7xelte-u-boot.dtsi
@@ -0,0 +1,26 @@
+// SPDX-License-Identifier: GPL-2.0
+
+/ {
+	binman {
+		filename = "u-boot-samsung-j7xelte.img";
+
+		android-boot {
+			/* S-BOOT ignores offsets, so they are not provided here */
+			kernel {
+				u-boot-nodtb { };
+			};
+
+			vendor-dt {
+				dtbh {
+					dtb-0 {
+						model_info-chip = <7870>;
+						model_info-hw_rev = <0>;
+						model_info-hw_rev_end = <255>;
+
+						u-boot-dtb { };
+					};
+				};
+			};
+		};
+	};
+};

-- 
2.54.0

