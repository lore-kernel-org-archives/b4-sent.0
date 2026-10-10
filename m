From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 10 Oct 2026 16:24:48 +0200
Subject: [PATCH 4/4] rockchip: LZMA-compress the FDT image in the FIT based
 on FIT_FDT_COMP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-binman-fit-fdt-compression-v1-4-4465558758cc@protonmail.com>
References: <20261010-b4-binman-fit-fdt-compression-v1-0-4465558758cc@protonmail.com>
In-Reply-To: <20261010-b4-binman-fit-fdt-compression-v1-0-4465558758cc@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Simon Glass <sjg@chromium.org>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, Tom Rini <trini@konsulko.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, Marek Vasut <marex@nabladev.com>, 
 Wojciech Dubowik <Wojciech.Dubowik@mt.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Philipp Tomsich <philipp.tomsich@vrull.eu>, 
 Kever Yang <kever.yang@rock-chips.com>, Jonas Karlman <jonas@kwiboo.se>, 
 Petr Pavlata <petr@acrux.cz>, David Heidelberg <david@ixit.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791642291; l=1063;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=6QI+S+kJkoodlMS9OYGspm8o3lEQmxd0gwRkbK+j1rM=;
 b=VBvUyzfVswrH+Z1B5zHcLoVSGVGChm+LKZVYAFTR2LuvBSRAl4enL5D/BaqsqaFZceWHIN5ve
 ZUq7vGnq5m1DbPFCUqQaUCE2LunhxCb68Dp4KdAaWRn0D/WjQwku9N6
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds FIT_FDT_COMP alongside the existing FIT_UBOOT_COMP gated on
CONFIG_SPL_LZMA only. Applies it to the @fdt-SEQ template's compression
property.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 arch/arm/dts/rockchip-u-boot.dtsi | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/arch/arm/dts/rockchip-u-boot.dtsi b/arch/arm/dts/rockchip-u-boot.dtsi
index 4ba6a87e78a..ed082212446 100644
--- a/arch/arm/dts/rockchip-u-boot.dtsi
+++ b/arch/arm/dts/rockchip-u-boot.dtsi
@@ -19,6 +19,12 @@
 #define FIT_UBOOT_COMP		"none"
 #endif
 
+#if defined(CONFIG_SPL_LZMA)
+#define FIT_FDT_COMP		"lzma"
+#else
+#define FIT_FDT_COMP		"none"
+#endif
+
 /*
  * SHA256 should be enabled in SPL when signature validation is involved,
  * CRC32 should only be used for basic checksum validation of FIT images.
@@ -136,7 +142,7 @@
 
 			@fdt-SEQ {
 				description = "fdt-NAME";
-				compression = "none";
+				compression = FIT_FDT_COMP;
 				type = "flat_dt";
 #ifdef FIT_HASH_ALGO
 				hash {

-- 
2.55.0

