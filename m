From: Maud Spierings <maud_spierings@hotmail.com>
Date: Sat, 21 Feb 2026 16:04:17 +0100
Subject: [PATCH] RISC-V: dts: fix generation of dtbs-list
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260221-riscv_dtbs-v1-1-be58fc118bc2@hotmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDIyND3aLM4uSy+JSSpGLd1CSTNKNU4zTDxKQ0JaCGgqLUtMwKsGHRsbW
 1AC/b4gpcAAAA
X-Change-ID: 20260221-riscv_dtbs-eb4f2e3f1abf
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771686269; l=1339;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=Th7Qwm6hQnrq4gu3K2f3OhDRAPXeHmIvXWOPCaXz16A=;
 b=T0BIY/L3eAFKEItfifQ7QMsl2CthofU8BEzVlPQcFFkEjt+kIh5p812CeCMgLiChcJGR3o2L7
 sOvg3DTMAZlAnmOwv6WNQ7FThKwbj09pIhGmhXDcOB72dO+Fk+zEWO/
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For some reason pbl-$(CONFIG) results in dtbs-list being empty. This breaks
the generic fit image generation. Switch to lwl-$(CONFIG) like arm.

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
 arch/riscv/dts/Makefile | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/arch/riscv/dts/Makefile b/arch/riscv/dts/Makefile
index 841f86064ae1..92cff9b84fa6 100644
--- a/arch/riscv/dts/Makefile
+++ b/arch/riscv/dts/Makefile
@@ -4,11 +4,11 @@
 # created.
 obj- += dummy.o
 
-pbl-$(CONFIG_BOARD_ERIZO_GENERIC) += erizo-generic.dtb.o
-pbl-$(CONFIG_BOARD_HIFIVE) += hifive-unmatched-a00.dtb.o \
+lwl-$(CONFIG_BOARD_ERIZO_GENERIC) += erizo-generic.dtb.o
+lwl-$(CONFIG_BOARD_HIFIVE) += hifive-unmatched-a00.dtb.o \
                               hifive-unleashed-a00.dtb.o
-pbl-$(CONFIG_BOARD_BEAGLEV) += jh7100-beaglev-starlight.dtb.o
-pbl-$(CONFIG_BOARD_LITEX_LINUX) += litex-linux.dtb.o
+lwl-$(CONFIG_BOARD_BEAGLEV) += jh7100-beaglev-starlight.dtb.o
+lwl-$(CONFIG_BOARD_LITEX_LINUX) += litex-linux.dtb.o
 
 clean-files := *.dtb *.dtb.S .*.dtc .*.pre .*.dts *.dtb.z
 clean-files += *.dtbo *.dtbo.S .*.dtso

---
base-commit: 74393178faf08f8102c7c370ac310c29112e1137
change-id: 20260221-riscv_dtbs-eb4f2e3f1abf

Best regards,
-- 
Maud Spierings <maud_spierings@hotmail.com>

