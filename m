From: George Chan <gchan9527@gmail.com>
Date: Sun, 18 May 2025 19:16:19 +0800
Subject: [PATCH v3 2/3] mach-snapdragon: Enable workaround of ignoring
 androidboot addr
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250518-android-boot-v3-2-02c8768e131f@gmail.com>
References: <20250518-android-boot-v3-0-02c8768e131f@gmail.com>
In-Reply-To: <20250518-android-boot-v3-0-02c8768e131f@gmail.com>
To: Tom Rini <trini@konsulko.com>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Simon Glass <sjg@chromium.org>, Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, 
 George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747567000; l=697;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=V/nmnp/yBWPHuHu+12WLjQqWVlQARQn8Uo9PAXzdPD4=;
 b=fjn/bl6dHD5z+7X5pMPlY26oybhkCpJXruH9Z+mbmb3XDPN+urm1U0B/SjMBMvnne7Tjr5DJ6
 zO+JRyrLsWdCxaC0fq9kHt8YbhkWbUS531Dzm99C0+QQ7Y7hO/+LibW
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the workaround for whole snapdragon family.

Suggested-by: Casey Connolly <casey.connolly@linaro.org>
Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: George Chan <gchan9527@gmail.com>
---
 arch/arm/Kconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm/Kconfig b/arch/arm/Kconfig
index fedfdb21457..f6d903b4f1e 100644
--- a/arch/arm/Kconfig
+++ b/arch/arm/Kconfig
@@ -1124,6 +1124,7 @@ config ARCH_SNAPDRAGON
 	select LINUX_KERNEL_IMAGE_HEADER if !ENABLE_ARM_SOC_BOOT0_HOOK
 	select SYSRESET
 	select SYSRESET_PSCI
+	select ANDROID_BOOT_IMAGE_IGNORE_BLOB_ADDR
 	imply OF_UPSTREAM
 	imply CMD_DM
 	imply DM_USB_GADGET

-- 
2.43.0

