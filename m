From: George Chan <gchan9527@gmail.com>
Date: Sun, 27 Apr 2025 19:25:22 +0800
Subject: [PATCH 3/3] mach-snapdragon: Add support to append string to
 kernel cmdline
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250427-android-boot-v1-3-bb6b37c9c9f1@gmail.com>
References: <20250427-android-boot-v1-0-bb6b37c9c9f1@gmail.com>
In-Reply-To: <20250427-android-boot-v1-0-bb6b37c9c9f1@gmail.com>
To: Tom Rini <trini@konsulko.com>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Simon Glass <sjg@chromium.org>, Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, 
 George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745753127; l=4761;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=o7bGSV43vn8ZvzoBQQve0mT/ZvEW3snfpALQNmkOzQw=;
 b=XMDEfms/ZZVY36lxd8bUxhqfeFyfHPvEr0rKLJ9bHiLVm1G5wiP01BYLzpOsb4wzSJmXt8j2L
 4SellYvP8VfDZSL6k/JzYU4hxzro1IvJfYh9Inmr2rhT71etV+gdaoE
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for blindly appending string to bootargs env_param and let
boot process take care of it.

Signed-off-by: George Chan <gchan9527@gmail.com>
---
 arch/arm/mach-snapdragon/Kconfig | 11 +++++
 arch/arm/mach-snapdragon/board.c | 97 ++++++++++++++++++++++++++++++++++++++++
 2 files changed, 108 insertions(+)

diff --git a/arch/arm/mach-snapdragon/Kconfig b/arch/arm/mach-snapdragon/Kconfig
index 976c0e35fce..ee65bbd1313 100644
--- a/arch/arm/mach-snapdragon/Kconfig
+++ b/arch/arm/mach-snapdragon/Kconfig
@@ -45,4 +45,15 @@ config SYS_CONFIG_NAME
 	  Based on this option include/configs/<CONFIG_SYS_CONFIG_NAME>.h header
 	  will be used for board configuration.
 
+config SYS_BOARD_CMDLINE_APPEND
+        bool "Snapdragon SoCs based board cmdline append string"
+        help
+          Allows to specify the Snapdragon SoCs based board kernel cmdline override.
+          will be used as the custom board bootloader cmdline booting OS like Android.
+
+config SYS_BOARD_CMDLINE_APPEND_STRING
+	string "String to append"
+	default ""
+	depends on SYS_BOARD_CMDLINE_APPEND
+
 endif
diff --git a/arch/arm/mach-snapdragon/board.c b/arch/arm/mach-snapdragon/board.c
index deae4d32378..9b1dad8752d 100644
--- a/arch/arm/mach-snapdragon/board.c
+++ b/arch/arm/mach-snapdragon/board.c
@@ -46,6 +46,103 @@ static struct {
 	phys_size_t size;
 } prevbl_ddr_banks[CONFIG_NR_DRAM_BANKS] __section(".data") = { 0 };
 
+#ifdef CONFIG_SYS_BOARD_CMDLINE_APPEND
+/* (1) kernel cmdline support length is limited, which is (256..4096)
+ * (2) detain ref to COMMAND_LINE_SIZE of kernel header.
+ * (3) assumed null terminated.
+ * (4) Test shows that 1024 is working...
+ */
+#define COMMAND_LINE_SIZE_4_14		1024 /* ok make it default */
+static char bootargs[COMMAND_LINE_SIZE_4_14] = { 0 };
+const static char *soc_bootargs = CONFIG_SYS_BOARD_CMDLINE_APPEND_STRING;
+
+/* sort by importance to avoid some important value got wiped out */
+const static char *soc_bootargs_default = \
+" msm_drm.dsi_display0=dsi_nt36675_tianma_vid_display:" \
+" androidboot.lcmtype=dsi_nt36672c_tianma_fhd_video_display" \
+" androidboot.hwname=joyeuse" \
+" androidboot.secureboot=1" \
+" androidboot.keymaster=1"  \
+" androidboot.bootdevice=1d84000.ufshc" \
+" androidboot.boot_devices=soc/1d84000.ufshc" \
+" androidboot.verifiedbootstate=orange" \
+" androidboot.multisim_config=dsds" \
+" androidboot.cpuid=0xdc1467b8 " \
+" androidboot.dp=0x0 androidboot.baseband=msm" \
+" androidboot.fpsensor=fpc" \
+" androidboot.hwc=VDF_TWO" \
+" androidboot.hwlevel=MP" \
+" androidboot.AdcVol1=463 androidboot.AdcVol2=1306" \
+" androidboot.hwversion=4.90.0";
+
+/* fixups are put here:
+ * (1) androidboot.android_dt_dir this is to abuse the param to get rid of
+ * old fstab in device tree, and let search fail.
+ * (2) in case of fstab.qcom is in use but default boot.img have cmdline but
+ * do not specify the value, it will result expecting "fstab" instead of
+ * "fstab.qcom" and boot fail. so add a default value at last of cmd here.
+ */
+const static char *fix_bootargs = \
+" androidboot.android_dt_dir=/tmp/" \
+" androidboot.fstab_suffix=default" \
+" console=ramoops ";
+
+const char *get_board_support_bootargs(void)
+{
+        return soc_bootargs;
+}
+
+const char *get_board_support_bootargs_fixup(void)
+{
+        return fix_bootargs;
+}
+
+const char *board_fdt_chosen_bootargs(const struct fdt_property *fdt)
+{
+	int j;
+	char *env_prop = env_get("bootargs");
+	const char *soc_prop;
+	const char *fix_prop = fix_bootargs;
+	const char *fdt_prop;
+
+	soc_prop = (strlen(soc_bootargs) == 0) ? soc_bootargs_default : soc_bootargs;
+
+	fdt_prop = (fdt == NULL) ? "" : fdt->data;
+
+	if (env_prop == NULL)
+		env_prop = "";
+
+	debug("\n");
+	debug("fdt bootargs: %s\n", fdt_prop);
+	debug("env bootargs: %s\n", env_prop);
+	debug("soc bootargs: %s\n", soc_prop);
+	debug("fix bootargs: %s\n", fix_prop);
+
+	/* since android init parse androidboot property on a
+	 * first-come-first-serve manner so dtb valus come first and
+	 * then u-boot defaults and board specific fixups
+	 */
+	snprintf(bootargs, COMMAND_LINE_SIZE_4_14 - 2, "%s %s %s %s",
+		env_prop , fdt_prop, fix_prop, soc_prop);
+
+	/* remove all carriage return */
+	for (j = 0; j < COMMAND_LINE_SIZE_4_14; j++) {
+		if (bootargs[j] == '\0')
+			break;
+
+		if ((bootargs[j] == '\n') || (bootargs[j] == '\r'))
+			bootargs[j] = ' ';
+	}
+
+	/* trim to max length */
+	bootargs[COMMAND_LINE_SIZE_4_14 - 1] = '\0';
+
+	debug("out bootargs: %s\n", bootargs);
+	debug("total length: %d\n", j);
+	return bootargs;
+}
+#endif
+
 int dram_init(void)
 {
 	/*

-- 
2.43.0

