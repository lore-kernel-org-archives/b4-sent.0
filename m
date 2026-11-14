From: Christian Zietz <czietz@gmx.net>
Date: Sat, 14 Nov 2026 10:15:49 +0100
Subject: [PATCH] m68k: Preserve fixups during dead code elimination
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-fix_deadcode_elimination_for_tt_ram-v1-1-a6aa8e7cb90c@gmx.net>
X-B4-Tracking: v=1; b=H4sIAMQm+GoC/x2OUQqDMBBEryL73UCTlqC9SilhTTZ1ocayCSKId
 +/az8fMPGaHSsJU4dHtILRy5aUo2EsHccLyJsNJGdzVeWvtzWTeQiJMcUkU6MMzF2w6CnmR0Fo
 QnI33bhhcb+999qCmESuZUbDE6XRp0xTa2hl9hdT4P/B8HccPTt9ER5AAAAA=
To: Geert Uytterhoeven <geert@linux-m68k.org>, 
 Sam Creasey <sammy@sammy.net>
Cc: linux-m68k@lists.linux-m68k.org, linux-kernel@vger.kernel.org, 
 Christian Zietz <czietz@gmx.net>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794647763; l=2837;
 i=czietz@gmx.net; s=20261113; h=from:subject:message-id;
 bh=UYLvKZBzNE+sBSp2JLnrfwCUbYDF4Z0Kocgxl/zojiw=;
 b=ewPMJ0lBlMkdQr2T23XANUpkboMvkGGSlqb+ofZhhS4Czu52r8eQtmR+d7nREuZEPYcsRtdDM
 RvvSgipjo6PC3z3h2JdA4cvtNhH3CkJCRJPazWTGFJuNquUnXTfD1Ug
X-Developer-Key: i=czietz@gmx.net; a=ed25519;
 pk=4CdkqAQq9wBZuj+KXG9PqH5ivA+edxVtP0VMbuoWu1c=
X-Endpoint-Received: by B4 Relay for czietz@gmx.net/20261113 with auth_id=1516
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A kernel built with CONFIG_LD_DEAD_CODE_DATA_ELIMINATION=y panics when
loaded into TT-RAM (starting at address 0x01000000) on Atari. This is
due to the .m68k_fixup section being removed by the linker's dead code
elimination. Thus, the kernel is not fixed up for the TT-RAM address.

KEEP() ensures the fixups are always kept in the kernel binary.

Tested on an Atari TT and under Hatari emulation.

Fixes: 4fbdd56edf1f ("m68k: Enable dead code elimination")
Signed-off-by: Christian Zietz <czietz@gmx.net>
---
For reference, here is the objdump output of a kernel built with
CONFIG_LD_DEAD_CODE_DATA_ELIMINATION=y that shows .m68k_fixup is
missing:

m68k-linux-gnu-objdump -s -j .m68k_fixup vmlinux

vmlinux:     file format elf32-m68k

m68k-linux-gnu-objdump: section '.m68k_fixup' mentioned in a -j option,
but not found in any input file

... versus after applying the patch:

m68k-linux-gnu-objdump -s -j .m68k_fixup vmlinux

vmlinux:     file format elf32-m68k

Contents of section .m68k_fixup:
 3c5a8c 00000000 003a8478 00000000 003aa6f8  .....:.x.....:..
 3c5a9c 00000000 003aaafe 00000000 0000b5ae  .....:..........
 3c5aac 00000000 003aaed4 00000000 003aaefa  .....:.......:..
 3c5abc 00000000 0000c5f6 00000000 0000c61c  ................
 [...]
---
 arch/m68k/kernel/vmlinux-nommu.lds | 2 +-
 arch/m68k/kernel/vmlinux-std.lds   | 2 +-
 arch/m68k/kernel/vmlinux-sun3.lds  | 2 +-
 3 files changed, 3 insertions(+), 3 deletions(-)

diff --git a/arch/m68k/kernel/vmlinux-nommu.lds b/arch/m68k/kernel/vmlinux-nommu.lds
index 45d7f4b01..485bbc24a 100644
--- a/arch/m68k/kernel/vmlinux-nommu.lds
+++ b/arch/m68k/kernel/vmlinux-nommu.lds
@@ -72,7 +72,7 @@ SECTIONS {
 	PERCPU_SECTION(16)
 	.m68k_fixup : {
 		__start_fixup = .;
-		*(.m68k_fixup)
+		KEEP(*(.m68k_fixup))
 		__stop_fixup = .;
 	}
 	.init.data : {
diff --git a/arch/m68k/kernel/vmlinux-std.lds b/arch/m68k/kernel/vmlinux-std.lds
index 7326586af..8783df430 100644
--- a/arch/m68k/kernel/vmlinux-std.lds
+++ b/arch/m68k/kernel/vmlinux-std.lds
@@ -45,7 +45,7 @@ SECTIONS
   INIT_DATA_SECTION(16)
   .m68k_fixup : {
 	__start_fixup = .;
-	*(.m68k_fixup)
+	KEEP(*(.m68k_fixup))
 	__stop_fixup = .;
   }
   .init_end : {
diff --git a/arch/m68k/kernel/vmlinux-sun3.lds b/arch/m68k/kernel/vmlinux-sun3.lds
index 1b19fef20..8be83d13d 100644
--- a/arch/m68k/kernel/vmlinux-sun3.lds
+++ b/arch/m68k/kernel/vmlinux-sun3.lds
@@ -40,7 +40,7 @@ __init_begin = .;
 	INIT_DATA_SECTION(16)
 	.m68k_fixup : {
 		__start_fixup = .;
-		*(.m68k_fixup)
+		KEEP(*(.m68k_fixup))
 		__stop_fixup = .;
 	}
 	. = ALIGN(PAGE_SIZE);

---
base-commit: 8c9ddebb300c719362a52a2d465f44e7d055778d
change-id: 20261113-fix_deadcode_elimination_for_tt_ram-6629928148f6

Best regards,
-- 
Christian Zietz <czietz@gmx.net>

