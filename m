From: George Chan <gchan9527@gmail.com>
Date: Sun, 18 May 2025 19:16:20 +0800
Subject: [PATCH v3 3/3] mach-snapdragon: Enhance android image handling
 memory footprint
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250518-android-boot-v3-3-02c8768e131f@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747567000; l=1406;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=5MqcY4oWRA3jIaJEq5nkPbwYGfD84Cne/Fh6c5pNYFE=;
 b=kM72fwbnxGSS+CWmwN35xxVHn79/0cZdm5Qx9v0mUjQRuuK5Q0s8xvdzV37FMnZ9lsyfgsDuJ
 VZ3EXYjZOcRAV3mApE/fcLZj+LZka7PR4yhSymp5wAO9Eo/DBhQbwiy
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In order to unzipped kernel from androidboot img, extra memory for
loadaddr is needed. So once fastboot is enabled fastboot memory also
share with loadaddr.

That can balance with memory constrain soc and android usecase.

Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: George Chan <gchan9527@gmail.com>
---
 arch/arm/mach-snapdragon/board.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/arch/arm/mach-snapdragon/board.c b/arch/arm/mach-snapdragon/board.c
index 3ab75f0fce0..e39973c62f6 100644
--- a/arch/arm/mach-snapdragon/board.c
+++ b/arch/arm/mach-snapdragon/board.c
@@ -499,8 +499,12 @@ int board_late_init(void)
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

