From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 09:39:05 +0200
Subject: [PATCH v2 6/6] rockchip: Allow compression of the FDT in the FIT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-binman-fit-fdt-compression-v2-6-d7e290847543@protonmail.com>
References: <20261017-b4-binman-fit-fdt-compression-v2-0-d7e290847543@protonmail.com>
In-Reply-To: <20261017-b4-binman-fit-fdt-compression-v2-0-d7e290847543@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Simon Glass <sjg@chromium.org>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, Tom Rini <trini@konsulko.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, Marek Vasut <marex@nabladev.com>, 
 Wojciech Dubowik <Wojciech.Dubowik@mt.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Philipp Tomsich <philipp.tomsich@vrull.eu>, 
 Kever Yang <kever.yang@rock-chips.com>, Jonas Karlman <jonas@kwiboo.se>, 
 Petr Pavlata <petr@acrux.cz>, David Heidelberg <david@ixit.cz>, 
 Alexey Charkov <alchark@flipper.net>, 
 James Hilliard <james.hilliard1@gmail.com>, 
 Aristo Chen <aristo.chen@canonical.com>, 
 Philippe Reynes <philippe.reynes@softathome.com>, 
 Daniel Golle <daniel@makrotopia.org>, Johan Jonker <jbx6244@gmail.com>, 
 Quentin Schulz <u-boot@0leil.net>, Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792222776; l=1504;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=FlQuXoK53s24j1p15W4V8i+V56MKTL/IXnwaSFm7F88=;
 b=227mYOyAh7ZzgX+0y0U8QgiecUpZ+O/BJxxFaicMrjOAMItj1LqEcdaHdioTNuEuG0MKWPa/8
 +3tamPutLuwBhfw3khU/SUJkc3ouJSfJZd3Bhb2FTpu7RaO7WGhqDQk
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Compressing the FDT shrinks the FIT at the cost of decompression time
in SPL.

Define FIT_FDT_COMP from the SPL_FIT_FDT_COMP choice and use it in the
@fdt-SEQ template via 'fit,compress'.

This has no effect on any current board as no in-tree Rockchip defconfig
selects a compression.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 arch/arm/dts/rockchip-u-boot.dtsi | 15 ++++++++++++++-
 1 file changed, 14 insertions(+), 1 deletion(-)

diff --git a/arch/arm/dts/rockchip-u-boot.dtsi b/arch/arm/dts/rockchip-u-boot.dtsi
index 4ba6a87e78a..3cb571ddddb 100644
--- a/arch/arm/dts/rockchip-u-boot.dtsi
+++ b/arch/arm/dts/rockchip-u-boot.dtsi
@@ -19,6 +19,19 @@
 #define FIT_UBOOT_COMP		"none"
 #endif
 
+/*
+ * The compression of the FDT is chosen by the SPL_FIT_FDT_COMP choice. It
+ * is independent of FIT_UBOOT_COMP so U-Boot may be gzip-compressed while the
+ * FDT is LZMA-compressed.
+ */
+#if defined(CONFIG_SPL_FIT_FDT_COMP_LZMA)
+#define FIT_FDT_COMP		"lzma"
+#elif defined(CONFIG_SPL_FIT_FDT_COMP_GZIP)
+#define FIT_FDT_COMP		"gzip"
+#else
+#define FIT_FDT_COMP		"none"
+#endif
+
 /*
  * SHA256 should be enabled in SPL when signature validation is involved,
  * CRC32 should only be used for basic checksum validation of FIT images.
@@ -136,7 +149,7 @@
 
 			@fdt-SEQ {
 				description = "fdt-NAME";
-				compression = "none";
+				fit,compress = FIT_FDT_COMP;
 				type = "flat_dt";
 #ifdef FIT_HASH_ALGO
 				hash {

-- 
2.55.0

