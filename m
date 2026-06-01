From: Sam Day <me@samcday.com>
Date: Mon, 01 Jun 2026 18:12:47 +1000
Subject: [PATCH RESEND 06/16] mach-snapdragon: introduce
 ARCH_SNAPDRAGON_ARM32
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-qcom-armv7-v1-6-05a08d87e476@samcday.com>
References: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
In-Reply-To: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Michal Simek <michal.simek@amd.com>, 
 Angelo Dureghello <angelo@kernel-space.org>, 
 Eugen Hristev <ehristev@kernel.org>, Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Yao Zi <me@ziyao.cc>, Simon Glass <sjg@chromium.org>, 
 Sughosh Ganu <sughosh.ganu@arm.com>, George Chan <gchan9527@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>, 
 Tien Fong Chee <tien.fong.chee@altera.com>, Peng Fan <peng.fan@nxp.com>, 
 Alif Zakuan Yuslaimi <alif.zakuan.yuslaimi@altera.com>, 
 Anshul Dalal <anshuld@ti.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Tingting Meng <tingting.meng@altera.com>, Alice Guo <alice.guo@nxp.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 David Wronek <david.wronek@mainlining.org>, 
 Danila Tikhonov <danila@jiaxyga.com>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>, 
 Lukasz Majewski <lukma@denx.de>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Jens Reidel <adrian@mainlining.org>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780301569; l=1775;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=CeQPeO7BRJn6Vqd3ZzjZhpN9ywFiQJrT8v1EeDohT0w=;
 b=JFpVi8NeqYEBoFlfy88EhE2INqOUNfzpB9nzTMtZo+gBxpqBaiVY6VdcBYTItUYzav6HqT6df
 8PynJM+l943BEwSY7xOnX0+zZ5uRieaB66gaLfoJvoIT5zj4xtcm5CK
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This config symbol lays the groundwork for arm32 support in the
Snapdragon board code.

Signed-off-by: Sam Day <me@samcday.com>
---
 arch/arm/Kconfig                 | 11 ++++++-----
 arch/arm/mach-snapdragon/Kconfig |  6 ++++++
 2 files changed, 12 insertions(+), 5 deletions(-)

diff --git a/arch/arm/Kconfig b/arch/arm/Kconfig
index 514bf2000b4..0847985a367 100644
--- a/arch/arm/Kconfig
+++ b/arch/arm/Kconfig
@@ -1134,7 +1134,8 @@ config ARCH_RENESAS
 
 config ARCH_SNAPDRAGON
 	bool "Qualcomm Snapdragon SoCs"
-	select ARM64
+	select ARM64 if !ARCH_SNAPDRAGON_ARM32
+	select CPU_V7A if ARCH_SNAPDRAGON_ARM32
 	select DM
 	select DM_GPIO
 	select DM_SERIAL
@@ -1148,11 +1149,11 @@ config ARCH_SNAPDRAGON
 	select BOARD_LATE_INIT
 	select OF_BOARD
 	select SAVE_PREV_BL_FDT_ADDR if !ENABLE_ARM_SOC_BOOT0_HOOK
-	select LINUX_KERNEL_IMAGE_HEADER if !ENABLE_ARM_SOC_BOOT0_HOOK
+	select LINUX_KERNEL_IMAGE_HEADER if ARM64 && !ENABLE_ARM_SOC_BOOT0_HOOK
 	select SYSRESET
-	select SYSRESET_PSCI
-	select ANDROID_BOOT_IMAGE_IGNORE_BLOB_ADDR
-	select MMU_PGPROT
+	select SYSRESET_PSCI if ARM64
+	select ANDROID_BOOT_IMAGE_IGNORE_BLOB_ADDR if ARM64
+	select MMU_PGPROT if ARM64
 	imply OF_UPSTREAM
 	imply CMD_DM
 	imply DM_USB_GADGET
diff --git a/arch/arm/mach-snapdragon/Kconfig b/arch/arm/mach-snapdragon/Kconfig
index d3de8693b5a..e663b0015c7 100644
--- a/arch/arm/mach-snapdragon/Kconfig
+++ b/arch/arm/mach-snapdragon/Kconfig
@@ -1,5 +1,11 @@
 if ARCH_SNAPDRAGON
 
+config ARCH_SNAPDRAGON_ARM32
+	bool "Build Snapdragon support for ARMv7-A SoCs"
+	help
+	  Enable this when building U-Boot for older 32-bit Snapdragon
+	  platforms, such as the MSM8960 family.
+
 config SYS_SOC
 	default "snapdragon"
 

-- 
2.54.0

