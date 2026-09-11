From: Petr Hodina <petr.hodina@protonmail.com>
Date: Fri, 11 Sep 2026 20:18:50 +0200
Subject: [PATCH 4/4] arm: carry previous bootloader's bootargs into
 $bootargs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260911-b4-android-bootargs-carryover-v1-4-6ebb43da3df0@protonmail.com>
References: <20260911-b4-android-bootargs-carryover-v1-0-6ebb43da3df0@protonmail.com>
In-Reply-To: <20260911-b4-android-bootargs-carryover-v1-0-6ebb43da3df0@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Peng Fan <peng.fan@nxp.com>, 
 Simon Glass <sjg@chromium.org>, Kory Maincent <kory.maincent@bootlin.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Philip Molloy <philip.molloy@analog.com>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Markus Niebel <Markus.Niebel@ew.tq-group.com>, 
 Alexey Charkov <alchark@gmail.com>, Heiko Schocher <hs@nabladev.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Anshul Dalal <anshuld@ti.com>, Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 David Heidelberg <david@ixit.cz>, Petr Pavlata <petr@acrux.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789150739; l=2305;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=VbmVfaCKN9oCVXFuYc3390vt4fabre7I+6mi2MUK2Qs=;
 b=hS+XKBq4FxRJuDN5uOIiyex2j8Jzqfvc+9VvoLkTxcnfsuwNjYw10UuHZf8JAsGnjIcveVap8
 Y7IbCy7amaODAm8Rm9hrO7LNeUBtlWiZV6MssN6JH3VN0nVx8jfBoDq
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The existing SAVE_PREV_BL_FDT_ADDR / SAVE_PREV_BL_INITRAMFS_START_ADDR
options surface the chained FDT base and an initramfs pointer in env,
but the kernel command-line ABL had already prepared in
/chosen/bootargs is silently dropped the moment U-Boot starts.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 arch/arm/lib/save_prev_bl_data.c | 15 ++++++++++++++-
 boot/Kconfig                     |  8 ++++++++
 2 files changed, 22 insertions(+), 1 deletion(-)

diff --git a/arch/arm/lib/save_prev_bl_data.c b/arch/arm/lib/save_prev_bl_data.c
index 4357acaef6c..5ad607a6251 100644
--- a/arch/arm/lib/save_prev_bl_data.c
+++ b/arch/arm/lib/save_prev_bl_data.c
@@ -66,7 +66,9 @@ int save_prev_bl_data(void)
 
 	if (IS_ENABLED(CONFIG_SAVE_PREV_BL_FDT_ADDR))
 		env_set_addr("prevbl_fdt_addr", (void *)reg0);
-	if (!IS_ENABLED(CONFIG_SAVE_PREV_BL_INITRAMFS_START_ADDR))
+
+	if (!IS_ENABLED(CONFIG_SAVE_PREV_BL_INITRAMFS_START_ADDR) &&
+	    !IS_ENABLED(CONFIG_SAVE_PREV_BL_BOOTARGS))
 		return 0;
 
 	node = fdt_path_offset(fdt_blob, "/chosen");
@@ -75,6 +77,17 @@ int save_prev_bl_data(void)
 					__func__, reg0);
 		return -ENODATA;
 	}
+
+	if (IS_ENABLED(CONFIG_SAVE_PREV_BL_BOOTARGS)) {
+		const char *bootargs = fdt_getprop(fdt_blob, node, "bootargs",
+						   NULL);
+
+		if (bootargs && *bootargs)
+			env_set("bootargs", bootargs);
+	}
+
+	if (!IS_ENABLED(CONFIG_SAVE_PREV_BL_INITRAMFS_START_ADDR))
+		return 0;
 	/*
 	 * linux,initrd-start property might be either 64 or 32 bit,
 	 * depending on primary bootloader implementation.
diff --git a/boot/Kconfig b/boot/Kconfig
index ae6f09a6ede..92ecc89e06f 100644
--- a/boot/Kconfig
+++ b/boot/Kconfig
@@ -2036,6 +2036,14 @@ config SAVE_PREV_BL_INITRAMFS_START_ADDR
 	  If no initramfs was provided by previous bootloader, no env variables
 	  will be created.
 
+config SAVE_PREV_BL_BOOTARGS
+	depends on ARM
+	bool "Save /chosen/bootargs from the previous bootloader's FDT into $bootargs"
+	help
+	  When u-boot is chain-loaded from a primary bootloader that already
+	  populated /chosen/bootargs in the device tree it handed off (Android
+	  ABL) copy that string into U-Boot's bootargs environment variable.
+
 menu "Configuration editor"
 
 config CEDIT

-- 
2.55.0

