From: Jia Wang <wangjia@ultrarisc.com>
Date: Thu, 16 Jul 2026 13:31:49 +0800
Subject: [PATCH 1/2] modpost: ignore generated GCOV and RISC-V local relocs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260716-modpost-v1-1-8eab36cc7310@ultrarisc.com>
References: <20260716-modpost-v1-0-8eab36cc7310@ultrarisc.com>
In-Reply-To: <20260716-modpost-v1-0-8eab36cc7310@ultrarisc.com>
To: Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nsc@kernel.org>, 
 Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-kbuild@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-riscv@lists.infradead.org, Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784179921; l=6237;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=Qmcrh0ELG719bfZpzSpb/gjTYnW7s0pXlwROWQGT5ys=;
 b=MjwTgun4996uhG+72Cge2Wt8gh9lXuzarMQqAKiDdWhEPqtokFnkCGZq1qwlRPlu0T5iJKfuJ
 TLL9keOWHMSDHujPLTMdvuryg9oHoTjpjuBC8JMCwKOGa5WVOaIjVXT
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

GCOV_PROFILE_ALL can make GCC emit constructor and metadata symbols
that reference init or exit sections. modpost may then report section
mismatches through generated symbols such as _sub_I_* and __gcov_.*,
even though those references do not describe a normal section lifetime
dependency in kernel code.

RISC-V also uses local branch and PC-relative relocation pairs that can
resolve through compiler local or mapping symbols near init or exit
code. Treating those local relocations as ordinary lifetime references
creates a large number of bogus section mismatch warnings.

Teach modpost to keep the raw target symbol for generated-symbol checks
and pass the relocation type into the mismatch filter. Ignore GCOV
constructor and metadata symbols, compiler mapping symbols, and RISC-V
local branch or PC-relative relocations when they target init or exit
sections.

This was seen with an rv32 randconfig using KCONFIG_SEED=277518 with
CONFIG_GCOV_PROFILE_ALL=y, CONFIG_KCOV_INSTRUMENT_ALL=y and
CONFIG_DEBUG_INFO_BTF=y, where modpost emitted a large number of bogus
.text to .init.text section mismatch warnings through generated GCOV
and local RISC-V symbols.

This keeps named symbol section mismatch diagnostics while avoiding the
warning flood from compiler-generated references.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 scripts/mod/modpost.c | 78 ++++++++++++++++++++++++++++++++++++++++++++++-----
 1 file changed, 71 insertions(+), 7 deletions(-)

diff --git a/scripts/mod/modpost.c b/scripts/mod/modpost.c
index a7b72a81d248..6869822446bd 100644
--- a/scripts/mod/modpost.c
+++ b/scripts/mod/modpost.c
@@ -951,8 +951,50 @@ static const struct sectioncheck *section_mismatch(
  *   refsymname = *.constprop.*
  *
  **/
+#ifndef R_RISCV_BRANCH
+#define R_RISCV_BRANCH		16
+#endif
+
+#ifndef R_RISCV_PCREL_HI20
+#define R_RISCV_PCREL_HI20	23
+#endif
+
+#ifndef R_RISCV_PCREL_LO12_I
+#define R_RISCV_PCREL_LO12_I	24
+#endif
+
+#ifndef R_RISCV_PCREL_LO12_S
+#define R_RISCV_PCREL_LO12_S	25
+#endif
+
+#ifndef R_RISCV_RVC_BRANCH
+#define R_RISCV_RVC_BRANCH	44
+#endif
+
+#ifndef R_RISCV_RVC_JUMP
+#define R_RISCV_RVC_JUMP	45
+#endif
+
+static bool is_gcov_generated_symbol(const char *sym)
+{
+	return strstarts(sym, "_sub_I_") ||
+	       strstarts(sym, "__gcov_.");
+}
+
+static bool is_riscv_local_reloc(unsigned int r_type)
+{
+	return r_type == R_RISCV_BRANCH ||
+	       r_type == R_RISCV_RVC_BRANCH ||
+	       r_type == R_RISCV_RVC_JUMP ||
+	       r_type == R_RISCV_PCREL_HI20 ||
+	       r_type == R_RISCV_PCREL_LO12_I ||
+	       r_type == R_RISCV_PCREL_LO12_S;
+}
+
 static int secref_whitelist(const char *fromsec, const char *fromsym,
-			    const char *tosec, const char *tosym)
+			    const char *tosec, const char *tosym,
+			    const char *raw_tosym, unsigned int r_type,
+			    unsigned int e_machine)
 {
 	/* Check for pattern 1 */
 	if (match(tosec, PATTERNS(ALL_INIT_DATA_SECTIONS)) &&
@@ -981,6 +1023,21 @@ static int secref_whitelist(const char *fromsec, const char *fromsym,
 	if (match(tosym, PATTERNS("__init_begin", "_sinittext", "_einittext")))
 		return 0;
 
+	/*
+	 * Compiler-generated local labels and GCOV constructors can produce
+	 * relocations that are later reported as section mismatches against
+	 * nearby init/exit symbols. Do not use those generated symbols as
+	 * evidence of a real section lifetime dependency.
+	 */
+	if (match(tosec, PATTERNS(ALL_INIT_SECTIONS, ALL_EXIT_SECTIONS)) &&
+	    (is_mapping_symbol(raw_tosym) || is_gcov_generated_symbol(fromsym)))
+		return 0;
+
+	if (e_machine == EM_RISCV &&
+	    is_riscv_local_reloc(r_type) &&
+	    match(tosec, PATTERNS(ALL_INIT_SECTIONS, ALL_EXIT_SECTIONS)))
+		return 0;
+
 	/* Check for pattern 5 */
 	if (match(fromsec, PATTERNS(ALL_TEXT_SECTIONS)) &&
 	    match(tosec, PATTERNS(ALL_INIT_SECTIONS)) &&
@@ -1025,21 +1082,25 @@ static void default_mismatch_handler(const char *modname, struct elf_info *elf,
 				     const struct sectioncheck* const mismatch,
 				     Elf_Sym *tsym,
 				     unsigned int fsecndx, const char *fromsec, Elf_Addr faddr,
-				     const char *tosec, Elf_Addr taddr)
+				     const char *tosec, Elf_Addr taddr,
+				     unsigned int r_type)
 {
 	Elf_Sym *from;
 	const char *tosym;
 	const char *fromsym;
 	char taddr_str[16];
+	const char *raw_tosym;
 
 	from = find_fromsym(elf, faddr, fsecndx);
 	fromsym = sym_name(elf, from);
 
+	raw_tosym = sym_name(elf, tsym);
 	tsym = find_tosym(elf, taddr, tsym);
 	tosym = sym_name(elf, tsym);
 
 	/* check whitelist - we may ignore it */
-	if (!secref_whitelist(fromsec, fromsym, tosec, tosym))
+	if (!secref_whitelist(fromsec, fromsym, tosec, tosym, raw_tosym,
+			      r_type, elf->hdr->e_machine))
 		return;
 
 	sec_mismatch_count++;
@@ -1152,7 +1213,8 @@ static void check_export_symbol(struct module *mod, struct elf_info *elf,
 static void check_section_mismatch(struct module *mod, struct elf_info *elf,
 				   Elf_Sym *sym,
 				   unsigned int fsecndx, const char *fromsec,
-				   Elf_Addr faddr, Elf_Addr taddr)
+				   Elf_Addr faddr, Elf_Addr taddr,
+				   unsigned int r_type)
 {
 	const char *tosec = sec_name(elf, get_secindex(elf, sym));
 	const struct sectioncheck *mismatch;
@@ -1168,7 +1230,7 @@ static void check_section_mismatch(struct module *mod, struct elf_info *elf,
 
 	default_mismatch_handler(mod->name, elf, mismatch, sym,
 				 fsecndx, fromsec, faddr,
-				 tosec, taddr);
+				 tosec, taddr, r_type);
 }
 
 static Elf_Addr addend_386_rel(uint32_t *location, unsigned int r_type)
@@ -1382,7 +1444,8 @@ static void section_rela(struct module *mod, struct elf_info *elf,
 		}
 
 		check_section_mismatch(mod, elf, tsym,
-				       fsecndx, fromsec, r_offset, taddr);
+				       fsecndx, fromsec, r_offset, taddr,
+				       r_type);
 	}
 }
 
@@ -1419,7 +1482,8 @@ static void section_rel(struct module *mod, struct elf_info *elf,
 		}
 
 		check_section_mismatch(mod, elf, tsym,
-				       fsecndx, fromsec, r_offset, taddr);
+				       fsecndx, fromsec, r_offset, taddr,
+				       r_type);
 	}
 }
 

-- 
2.34.1

