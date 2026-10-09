From: Arkadiusz Wadowski <wadowski.arkadiusz@gmail.com>
Date: Fri, 09 Oct 2026 22:13:17 +0200
Subject: [PATCH v2] board: qemu-arm: Add SPL support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-spl-for-quemu-arm-v2-1-460427488c17@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ6CMBBFr0Jm7Zi2KLauvIdhUXCAMZRiC0RDu
 LuAe5cvef/9GSIFpgjXZIZAE0f23QrqkEDZ2K4m5MfKoITKpBAGY99i5QO+RnIj2uBQnaQyF1P
 Ys0lh3fWBKn7vzXv+4zgWTyqHLbQZDcfBh89+OsnN+9efJErUZFMjMl1prW+1s9weS+8gX5blC
 xqr8ETEAAAA
X-Change-ID: 20261009-spl-for-quemu-arm-2412979ba593
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Tuomas Tynkkynen <tuomas.tynkkynen@iki.fi>, 
 Arkadiusz Wadowski <wadowski.arkadiusz@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791576832; l=4979;
 i=wadowski.arkadiusz@gmail.com; s=20261009; h=from:subject:message-id;
 bh=JDkQR1jI2dR/+MdscKbdpNDlzhyz0P3/TwaN7s3vVZ4=;
 b=j3UA4W8rEIyYREwUeSyNRITg2Xxycvn/9nLA6oDcUEAcCZ1Ccin5scumdFBSVlV97P9WmgwKp
 XdnmqLlz9+XDeOSYaFbT6iKfBGiCWI89yFdhxTPQIF8DPLiJ4Nbpu/9
X-Developer-Key: i=wadowski.arkadiusz@gmail.com; a=ed25519;
 pk=HKeMLZz72hO1HTxmFN3fZohsVyICtXJ2xUrbSalR0wQ=
X-Endpoint-Received: by B4 Relay for wadowski.arkadiusz@gmail.com/20261009 with auth_id=1144
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an optional SPL boot path for the QEMU ARM64 virt machine,
allowing the SPL-to-U-Boot boot flow to be explored without
physical hardware.

Use the existing NOR loader to load u-boot.img from flash into
RAM at 0x41000000. Generate u-boot-with-spl.bin with the payload
placed after SPL padding.

Signed-off-by: Arkadiusz Wadowski <wadowski.arkadiusz@gmail.com>
---
This patch adds an optional SPL boot path for the QEMU ARM64 virt
machine. It provides an emulated environment for exploring the
SPL-to-U-Boot boot flow without physical hardware.

SPL starts at flash address zero and uses the existing NOR loader
to load U-Boot proper into RAM at 0x41000000. The combined
u-boot-with-spl.bin image places u-boot.img at flash offset 0x100000.

QEMU provides initialized RAM at reset, so this boot path does
not require a DRAM initialization sequence.
---
Changes in v2:
- EDITME: describe what is new in this series revision.
- EDITME: use bulletpoints and terse descriptions.
- Link to v1: https://patch.msgid.link/20261009-spl-for-quemu-arm-v1-1-8ea39068f888@gmail.com
---
 Makefile                             |  2 +-
 arch/arm/mach-qemu/Kconfig           |  1 +
 board/emulation/qemu-arm/Kconfig     |  2 ++
 board/emulation/qemu-arm/Kconfig.spl | 40 ++++++++++++++++++++++++++++++++++++
 board/emulation/qemu-arm/qemu-arm.c  |  8 ++++++++
 include/configs/qemu-arm.h           |  4 ++++
 6 files changed, 56 insertions(+), 1 deletion(-)

diff --git a/Makefile b/Makefile
index 6303a0cca6a..49c1da0fb03 100644
--- a/Makefile
+++ b/Makefile
@@ -2458,7 +2458,7 @@ spl/u-boot-spl-dtb.bin: spl/u-boot-spl
 spl/u-boot-spl-dtb.hex: spl/u-boot-spl
 	@:
 
-spl/u-boot-spl: tools prepare $(if $(CONFIG_SPL_OF_CONTROL),dts/dt.dtb)
+spl/u-boot-spl: tools prepare $(if $(and $(CONFIG_SPL_OF_CONTROL),$(filter-out y,$(CONFIG_OF_OMIT_DTB))),dts/dt.dtb)
 	$(Q)$(MAKE) obj=spl -f $(srctree)/scripts/Makefile.xpl all
 
 spl/sunxi-spl.bin: spl/u-boot-spl
diff --git a/arch/arm/mach-qemu/Kconfig b/arch/arm/mach-qemu/Kconfig
index 9c06c6a3a5c..7e8aa62d38c 100644
--- a/arch/arm/mach-qemu/Kconfig
+++ b/arch/arm/mach-qemu/Kconfig
@@ -18,6 +18,7 @@ config TARGET_QEMU_ARM_64BIT
 	bool "ARMv8, 64bit"
 	select ARM64
 	select BOARD_LATE_INIT
+	select SUPPORT_SPL
 
 config TARGET_QEMU_ARM_SBSA
 	bool "SBSA Reference"
diff --git a/board/emulation/qemu-arm/Kconfig b/board/emulation/qemu-arm/Kconfig
index 447061b25cd..b66b260b292 100644
--- a/board/emulation/qemu-arm/Kconfig
+++ b/board/emulation/qemu-arm/Kconfig
@@ -1,3 +1,5 @@
+source "board/emulation/qemu-arm/Kconfig.spl"
+
 if TARGET_QEMU_ARM_32BIT || TARGET_QEMU_ARM_64BIT
 
 config TEXT_BASE
diff --git a/board/emulation/qemu-arm/Kconfig.spl b/board/emulation/qemu-arm/Kconfig.spl
new file mode 100644
index 00000000000..5dd7f478e82
--- /dev/null
+++ b/board/emulation/qemu-arm/Kconfig.spl
@@ -0,0 +1,40 @@
+# SPDX-License-Identifier: GPL-2.0+
+if TARGET_QEMU_ARM_64BIT && SPL
+
+config TEXT_BASE
+	range 0x41000000 0xffffffff
+	default 0x41000000
+
+config QEMU_ARM64_SPL
+	def_bool y
+	select SPL_LIBCOMMON_SUPPORT
+	select SPL_LIBGENERIC_SUPPORT
+	select SPL_HAS_BSS_LINKER_SECTION
+	select SPL_SEPARATE_BSS
+	select SPL_NOR_SUPPORT
+	select PANIC_HANG
+	select SPL_LEGACY_IMAGE_FORMAT
+	select SPL_DM
+	select SPL_OF_CONTROL
+	select SPL_SERIAL
+	select SPL_DM_SERIAL
+
+config SPL_PAYLOAD
+	default "u-boot.img"
+
+config SPL_TARGET
+	default "u-boot-with-spl.bin"
+
+config SPL_BLOBLIST
+	default n
+
+config SPL_MAX_SIZE
+	default 0x100000
+
+config SPL_BSS_START_ADDR
+	default 0x40400000
+
+config SPL_BSS_MAX_SIZE
+	default 0x100000
+
+endif
diff --git a/board/emulation/qemu-arm/qemu-arm.c b/board/emulation/qemu-arm/qemu-arm.c
index 38f0ec5f2fb..b0ab31ce793 100644
--- a/board/emulation/qemu-arm/qemu-arm.c
+++ b/board/emulation/qemu-arm/qemu-arm.c
@@ -11,6 +11,7 @@
 #include <fdtdec.h>
 #include <init.h>
 #include <log.h>
+#include <spl.h>
 #include <usb.h>
 #include <virtio_types.h>
 #include <virtio.h>
@@ -202,3 +203,10 @@ void flash_write32(u32 value, void *addr)
 {
 	asm("str %" __W "1, %0" : "=m"(*(u32 *)addr) : "r"(value));
 }
+
+#if defined(CONFIG_TARGET_QEMU_ARM_64BIT) && defined(CONFIG_SPL_BUILD)
+u32 spl_boot_device(void)
+{
+	return BOOT_DEVICE_NOR;
+}
+#endif
diff --git a/include/configs/qemu-arm.h b/include/configs/qemu-arm.h
index e296f398798..18939dd8fd5 100644
--- a/include/configs/qemu-arm.h
+++ b/include/configs/qemu-arm.h
@@ -11,4 +11,8 @@
 
 /* For timer, QEMU emulates an ARMv7/ARMv8 architected timer */
 
+#if defined(CONFIG_TARGET_QEMU_ARM_64BIT) && defined(CONFIG_SPL)
+#define CFG_SYS_UBOOT_BASE CONFIG_SPL_PAD_TO
+#endif
+
 #endif /* __CONFIG_H */

---
base-commit: 0a55b098d6f5f6bafa84fc2f18b433dd167bf729
change-id: 20261009-spl-for-quemu-arm-2412979ba593

Best regards,
--  
Arkadiusz Wadowski <wadowski.arkadiusz@gmail.com>

