From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 02 Jan 2025 19:31:49 +0100
Subject: [PATCH 08/19] powerpc: boot: Enable FIT image generation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250102-mpc83xx-v1-8-86f78ba2a7af@posteo.net>
References: <20250102-mpc83xx-v1-0-86f78ba2a7af@posteo.net>
In-Reply-To: <20250102-mpc83xx-v1-0-86f78ba2a7af@posteo.net>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>, Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Frank Li <Frank.Li@nxp.com>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-gpio@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735842735; l=2597;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=gwgToc0kzqB+BXy5IXnLTTOxYYECLTdDBZaVu6gPiyM=;
 b=Zf345/Cls673vfLPBl8FI50FAUmAxpsp1Fvxct7loBav9XCC+T9a69RO9whzma99z7p8gIrp/
 E1AIylSmAzrBvcSfhIjrrIb6Bww/v+hPd4kyWILMBuuSU4x7NQybIIk
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Flat Image Tree (FIT) format combines a kernel, a set of
devicetrees, and optionally additional resources into a single file that
can be loaded by a bootloader such as U-Boot. Generating a FIT image as
part of the kernel build reduces the need for additional build scripts,
and produces a single boot image without falling back to one of the
many legacy methods implemented in arch/powerpc/boot/Makefile, which
would require additional changes for arch/powerpc/boot for each board.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---

Checkpatch warns:

  arch/powerpc/boot/Makefile:364: WARNING: Possible repeated word: 'Image'

for this line:

  image-y += Image image.fit

This is bogus and can be ignored.
---
 arch/powerpc/Makefile      |  3 ++-
 arch/powerpc/boot/Makefile | 11 +++++++++++
 2 files changed, 13 insertions(+), 1 deletion(-)

diff --git a/arch/powerpc/Makefile b/arch/powerpc/Makefile
index f3804103c56ccfdb16289468397ccaea71bf721e..693c82c06072fb0529288736efee460e375b2476 100644
--- a/arch/powerpc/Makefile
+++ b/arch/powerpc/Makefile
@@ -225,7 +225,7 @@ KBUILD_CFLAGS += $(cflags-y)
 all: zImage
 
 # With make 3.82 we cannot mix normal and wildcard targets
-BOOT_TARGETS1 := zImage zImage.initrd uImage
+BOOT_TARGETS1 := zImage zImage.initrd uImage image.fit
 BOOT_TARGETS2 := zImage% dtbImage% treeImage.% cuImage.% simpleImage.% uImage.%
 
 PHONY += $(BOOT_TARGETS1) $(BOOT_TARGETS2)
@@ -237,6 +237,7 @@ $(BOOT_TARGETS1): vmlinux
 $(BOOT_TARGETS2): vmlinux
 	$(Q)$(MAKE) $(build)=$(boot) $(patsubst %,$(boot)/%,$@)
 
+image.fit: dtbs
 
 PHONY += bootwrapper_install
 bootwrapper_install:
diff --git a/arch/powerpc/boot/Makefile b/arch/powerpc/boot/Makefile
index 1ff6ad4f6cd27755ea7bfe5b02af4a47ca33cea7..e0c62ab1cc5af99e43f6639be11bf1c64d352db8 100644
--- a/arch/powerpc/boot/Makefile
+++ b/arch/powerpc/boot/Makefile
@@ -360,6 +360,9 @@ ifdef CONFIG_PPC32
 image-$(CONFIG_PPC_PMAC)	+= zImage.coff zImage.miboot
 endif
 
+# FIT support (generic)
+image-y += Image image.fit
+
 # Allow extra targets to be added to the defconfig
 image-y	+= $(CONFIG_EXTRA_TARGETS)
 
@@ -398,6 +401,14 @@ $(obj)/dtbImage.%: vmlinux $(wrapperbits) $(obj)/dts/%.dtb FORCE
 $(obj)/vmlinux.strip: vmlinux
 	$(STRIP) -s -R .comment $< -o $@
 
+OBJCOPYFLAGS += -O binary
+
+$(obj)/Image: vmlinux FORCE
+	$(call if_changed,objcopy)
+
+$(obj)/image.fit: $(obj)/Image $(obj)/dts/dtbs-list FORCE
+	$(call if_changed,fit)
+
 $(obj)/uImage: vmlinux $(wrapperbits) FORCE
 	$(call if_changed,wrap,uboot)
 

-- 
2.45.2

