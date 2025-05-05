From: George Chan <gchan9527@gmail.com>
Date: Mon, 05 May 2025 17:17:13 +0800
Subject: [PATCH v2 5/5] mach-snapdragon: Enable workaround of ignoring
 androidboot addr
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250505-android-boot-v2-5-92dcb5bf59c8@gmail.com>
References: <20250505-android-boot-v2-0-92dcb5bf59c8@gmail.com>
In-Reply-To: <20250505-android-boot-v2-0-92dcb5bf59c8@gmail.com>
To: Tom Rini <trini@konsulko.com>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Simon Glass <sjg@chromium.org>, Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, 
 George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746436630; l=640;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=khgh6feuD1wxYZwtRfQW3mssUaZ3a8MPHiwC7OlndHU=;
 b=hZUzjlzexW6VblObDPHJD83/KQORJd66b46gLA0VWr3CzFhRYe4fwZk/zj3o5EILiziqAuOgz
 Zafk6yU1AlxC80VWgA7tYqcWu86gNl4HtfkeLoBQigmTlKomHLkX+By
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the workaround for whole snapdragon family.

Suggested-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: George Chan <gchan9527@gmail.com>
---
 arch/arm/Kconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm/Kconfig b/arch/arm/Kconfig
index df373d38a55..249bd4b5bf3 100644
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

