From: George Chan <gchan9527@gmail.com>
Date: Mon, 05 May 2025 17:17:10 +0800
Subject: [PATCH v2 2/5] mach-snapdragon: Enhance android image handling
 memory footprint
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250505-android-boot-v2-2-92dcb5bf59c8@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746436629; l=1349;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=hPXXw+rnIPfVlYotkqpo3tRExQpyYTqNNoYtAyejW30=;
 b=f5nSWTA9QujEEjvboolNlC2Z3mcVknzLAHa19Wy+2yf1kkfh5jzuKnGaoJ/M+PdonSr6iV7hk
 yIYLpGYuM1IBW0uhHjMHMMU47jSKNIesZK1trpy77fgeDhDQf9pE0iK
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In order to unzipped kernel from androidboot img, extra memory for
loadaddr is needed. So once fastboot is enabled fastboot memory also
share with loadaddr.

That can balance with memory constrain soc and android usecase.

Signed-off-by: George Chan <gchan9527@gmail.com>
---
 arch/arm/mach-snapdragon/board.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/arch/arm/mach-snapdragon/board.c b/arch/arm/mach-snapdragon/board.c
index deae4d32378..3ee0933d962 100644
--- a/arch/arm/mach-snapdragon/board.c
+++ b/arch/arm/mach-snapdragon/board.c
@@ -500,8 +500,12 @@ int board_late_init(void)
 	status |= env_set_hex("ramdisk_addr_r", addr_alloc(SZ_128M));
 	status |= env_set_hex("kernel_comp_addr_r", addr_alloc(KERNEL_COMP_SIZE));
 	status |= env_set_hex("kernel_comp_size", KERNEL_COMP_SIZE);
-	if (IS_ENABLED(CONFIG_FASTBOOT))
-		status |= env_set_hex("fastboot_addr_r", addr_alloc(FASTBOOT_BUF_SIZE));
+	if (IS_ENABLED(CONFIG_FASTBOOT)) {
+		addr = addr_alloc(FASTBOOT_BUF_SIZE);
+		status |= env_set_hex("fastboot_addr_r", addr);
+		/* override loadaddr for memory rich soc */
+		status |= env_set_hex("loadaddr", addr);
+	}
 	status |= env_set_hex("scriptaddr", addr_alloc(SZ_4M));
 	status |= env_set_hex("pxefile_addr_r", addr_alloc(SZ_4M));
 	addr = addr_alloc(SZ_2M);

-- 
2.43.0

