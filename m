From: Jia Wang <wangjia@ultrarisc.com>
Date: Thu, 16 Jul 2026 13:31:50 +0800
Subject: [PATCH 2/2] modpost: handle RISC-V relative extable relocations
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260716-modpost-v1-2-8eab36cc7310@ultrarisc.com>
References: <20260716-modpost-v1-0-8eab36cc7310@ultrarisc.com>
In-Reply-To: <20260716-modpost-v1-0-8eab36cc7310@ultrarisc.com>
To: Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nsc@kernel.org>, 
 Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-kbuild@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-riscv@lists.infradead.org, Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784179921; l=4201;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=Q9Kl2WTnEgc/AGpok4mr/A3MQcvAYwsHz1JLGJEq9t8=;
 b=4mewT8X7Ur3HG+8XYP1s+yvdBIpVetFnR+mZb9M/hui6GV4SQChyjtuRkydw2zNCzqkB/hNOn
 7PnbxmgAboSAD7tJc/c2fQpxNPkIes31RxXlCDzvuxg5FJuYB4X18IN
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

RISC-V relative exception tables emit an R_RISCV_ADD32 and
R_RISCV_SUB32 relocation pair for each field. modpost already
ignores the SUB32 half, but still checks the ADD32 symbol section
directly.

After a relocatable link, that ADD32 symbol can name an unrelated
local debug symbol. This makes modpost report that __ex_table
references non-executable .debug* sections even though the original
exception table entry points at text.

Recognize the RISC-V ADD32/SUB32 pair for __ex_table. Ignore ADD32
entries that have been resolved to debug symbols, and otherwise
validate the resolved relative target address against executable
sections.

This was seen with an rv32 randconfig using KCONFIG_SEED=4721 with
CONFIG_MMU=y and CONFIG_DEBUG_INFO=y. The resulting vmlinux.o contains
R_RISCV_ADD32/R_RISCV_SUB32 relocation pairs in __ex_table, and the
fixed modpost run completes without the false .debug* section mismatch
diagnostics.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 scripts/mod/modpost.c | 79 +++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 79 insertions(+)

diff --git a/scripts/mod/modpost.c b/scripts/mod/modpost.c
index 6869822446bd..04a12eebb381 100644
--- a/scripts/mod/modpost.c
+++ b/scripts/mod/modpost.c
@@ -1356,6 +1356,10 @@ static Elf_Addr addend_mips_rel(uint32_t *location, unsigned int r_type)
 #define EM_RISCV		243
 #endif
 
+#ifndef R_RISCV_ADD32
+#define R_RISCV_ADD32		35
+#endif
+
 #ifndef R_RISCV_SUB32
 #define R_RISCV_SUB32		39
 #endif
@@ -1406,6 +1410,76 @@ static void get_rel_type_and_sym(struct elf_info *elf, uint64_t r_info,
 	*r_sym = ELF_R_SYM(r_info);
 }
 
+static bool section_contains_addr(struct elf_info *elf, unsigned int secndx,
+				  Elf_Addr addr)
+{
+	Elf_Shdr *sechdr;
+
+	if (secndx >= elf->num_sections)
+		return false;
+
+	sechdr = &elf->sechdrs[secndx];
+
+	return addr >= sechdr->sh_addr &&
+	       addr - sechdr->sh_addr < sechdr->sh_size;
+}
+
+static bool addr_is_executable(struct elf_info *elf, Elf_Addr addr)
+{
+	unsigned int i;
+
+	for (i = 1; i < elf->num_sections; i++) {
+		if ((elf->sechdrs[i].sh_flags & SHF_EXECINSTR) &&
+		    section_contains_addr(elf, i, addr))
+			return true;
+	}
+
+	return false;
+}
+
+static bool is_debug_section(const char *secname)
+{
+	return match(secname, PATTERNS(".debug*", ".zdebug*"));
+}
+
+static bool riscv_extable_rela_valid(struct elf_info *elf,
+				     const Elf_Rela *start,
+				     const Elf_Rela *stop,
+				     const Elf_Rela *rela,
+				     Elf_Addr r_offset,
+				     Elf_Sym *add_sym)
+{
+	Elf_Addr add_addr, sub_addr, target_addr;
+	unsigned int r_type, r_sym;
+	const Elf_Rela *pair;
+	Elf_Sym *sub_sym;
+
+	/*
+	 * RISC-V relative exception tables emit an ADD32/SUB32 pair for each
+	 * field. After ld -r, the ADD32 symbol may name an unrelated local
+	 * debug symbol. Otherwise, validate the resolved relative target.
+	 */
+	for (pair = start; pair < stop; pair++) {
+		get_rel_type_and_sym(elf, pair->r_info, &r_type, &r_sym);
+		if (TO_NATIVE(pair->r_offset) == r_offset &&
+		    r_type == R_RISCV_SUB32)
+			break;
+	}
+
+	if (pair == stop)
+		return false;
+
+	sub_sym = elf->symtab_start + r_sym;
+	if (is_debug_section(sec_name(elf, get_secindex(elf, add_sym))))
+		return true;
+
+	add_addr = add_sym->st_value + TO_NATIVE(rela->r_addend);
+	sub_addr = sub_sym->st_value + TO_NATIVE(pair->r_addend);
+	target_addr = r_offset + add_addr - sub_addr;
+
+	return addr_is_executable(elf, target_addr);
+}
+
 static void section_rela(struct module *mod, struct elf_info *elf,
 			 unsigned int fsecndx, const char *fromsec,
 			 const Elf_Rela *start, const Elf_Rela *stop)
@@ -1428,6 +1502,11 @@ static void section_rela(struct module *mod, struct elf_info *elf,
 			if (!strcmp("__ex_table", fromsec) &&
 			    r_type == R_RISCV_SUB32)
 				continue;
+			if (!strcmp("__ex_table", fromsec) &&
+			    r_type == R_RISCV_ADD32 &&
+			    riscv_extable_rela_valid(elf, start, stop, rela,
+						     r_offset, tsym))
+				continue;
 			break;
 		case EM_LOONGARCH:
 			switch (r_type) {

-- 
2.34.1

