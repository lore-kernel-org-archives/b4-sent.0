From: Michel Lind <michel@michel-slm.name>
Date: Tue, 30 Jan 2024 04:14:31 -0600
Subject: [PATCH] Fix building on x86_64 with binutils 2.41
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240130-fix-binutils-2-41-v1-1-99ee0fcfb5ce@michel-slm.name>
X-B4-Tracking: v=1; b=H4sIAAbMuGUC/x2MSQqAMAwAv1JyNtANBb8iHlqNGpAqjYog/t3ic
 WBmHhDKTAKteiDTxcJbKmAqBcMS0kzIY2Gw2nptnMaJb4yczoNXQYveYFN7G6KLNVEDpdszFel
 /dv37fthRuOBjAAAA
To: kexec@lists.infradead.org
Cc: Michel Lind <salimma@fedoraproject.org>, 
 Michel Lind <michel@michel-slm.name>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2666;
 i=michel@michel-slm.name; h=from:subject:message-id;
 bh=nOBIxomCd1NB/6X96cPgNNfdPJVIUS3lPhJ2O2YpA2Y=;
 b=owGbwMvMwCXWrTRXv+YMyyfG02pJDKk7znC+9whM9a5eyJgefDpPZq6L2qeuIzd2pOtyOfw+s
 ORbW8LcjlIWBjEuBlkxRZbYc3p1c6xl/l82PXgdZg4rE8gQBi5OAZjIY0+GfwZ3me5eMbn3yumC
 BePtIInHWWXLb0gFtaVGcawy+LHFsZKR4btbh3I0Y2gjy4+5Hkd8Oe/Pbbjgm1Cimsax6CjDzxk
 bOAA=
X-Developer-Key: i=michel@michel-slm.name; a=openpgp;
 fpr=5DCE2E7E9C3B1CFFD335C1D78B229D2F7CCC04F2
X-Endpoint-Received: by B4 Relay for michel@michel-slm.name/default with auth_id=119
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Michel Lind <salimma@fedoraproject.org>

Newer versions of the GNU assembler (observed with binutils 2.41) will
complain about the ".arch i386" in files assembled with "as --64",
with the message "Error: 64bit mode not supported on 'i386'".

Fix by moving ".arch i386" below the relevant ".code32" directive, so
that the assembler is no longer expecting 64-bit instructions to be used
by the time that the ".arch i386" directive is encountered.

Based on similar iPXE fix:
https://github.com/ipxe/ipxe/commit/6ca597eee

Signed-off-by: Michel Lind <michel@michel-slm.name>
---
 purgatory/arch/i386/entry32-16-debug.S | 2 +-
 purgatory/arch/i386/entry32-16.S       | 2 +-
 purgatory/arch/i386/entry32.S          | 2 +-
 purgatory/arch/i386/setup-x86.S        | 2 +-
 4 files changed, 4 insertions(+), 4 deletions(-)

diff --git a/purgatory/arch/i386/entry32-16-debug.S b/purgatory/arch/i386/entry32-16-debug.S
index 5167944..12e1164 100644
--- a/purgatory/arch/i386/entry32-16-debug.S
+++ b/purgatory/arch/i386/entry32-16-debug.S
@@ -25,10 +25,10 @@
 	.globl entry16_debug_pre32
 	.globl entry16_debug_first32
 	.globl entry16_debug_old_first32
-	.arch i386
 	.balign 16
 entry16_debug:
 	.code32
+	.arch i386
 	/* Compute where I am running at (assumes esp valid) */
 	call	1f
 1:	popl	%ebx
diff --git a/purgatory/arch/i386/entry32-16.S b/purgatory/arch/i386/entry32-16.S
index c051aab..eace095 100644
--- a/purgatory/arch/i386/entry32-16.S
+++ b/purgatory/arch/i386/entry32-16.S
@@ -20,10 +20,10 @@
 #undef i386	
 	.text
 	.globl entry16, entry16_regs
-	.arch i386
 	.balign 16
 entry16:
 	.code32
+	.arch i386
 	/* Compute where I am running at (assumes esp valid) */
 	call	1f
 1:	popl	%ebx
diff --git a/purgatory/arch/i386/entry32.S b/purgatory/arch/i386/entry32.S
index f7a494f..8ce9e31 100644
--- a/purgatory/arch/i386/entry32.S
+++ b/purgatory/arch/i386/entry32.S
@@ -20,10 +20,10 @@
 #undef i386
 
 	.text
-	.arch	i386
 	.globl entry32, entry32_regs
 entry32:
 	.code32
+	.arch	i386
 
 	/* Setup a gdt that should that is generally usefully */
 	lgdt	%cs:gdt
diff --git a/purgatory/arch/i386/setup-x86.S b/purgatory/arch/i386/setup-x86.S
index 201bb2c..a212eed 100644
--- a/purgatory/arch/i386/setup-x86.S
+++ b/purgatory/arch/i386/setup-x86.S
@@ -21,10 +21,10 @@
 #undef i386
 
 	.text
-	.arch	i386
 	.globl purgatory_start
 purgatory_start:
 	.code32
+	.arch	i386
 
 	/* Load a gdt so I know what the segment registers are */
 	lgdt	%cs:gdt

---
base-commit: 94fbe64fb22d61726ca0c0996987574b6c783c19
change-id: 20240130-fix-binutils-2-41-7642ab3b6ee7

Best regards,
-- 
Michel Lind <michel@michel-slm.name>

