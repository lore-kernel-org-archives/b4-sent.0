From: Dmitry Safonov <dima@arista.com>
Date: Mon, 26 Jan 2026 04:57:35 +0000
Subject: [PATCH] objtool: Print bfd_vma as unsigned long long on
 ia32-x86_64 cross build
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260126-objtool-ia32-v1-1-bb6feaf17566@arista.com>
X-B4-Tracking: v=1; b=H4sIAD70dmkC/x3MQQrCQAxA0auUrA22UUrxKuIi06Y2UjOSGWWg9
 O6OLt/i/w2SuEqCS7OBy0eTRqvoDg2MC9tdUKdqoJb6tqMeY3jkGFdUPhEO55kC0zAJMdTk5TJ
 r+e+ut+rASTA427j8Jqvau6BJyccnpywO+/4FegEfYoIAAAA=
X-Change-ID: 20260126-objtool-ia32-84f2ba28de2a
To: Josh Poimboeuf <jpoimboe@kernel.org>, 
 Peter Zijlstra <peterz@infradead.org>, 
 Alexandre Chartre <alexandre.chartre@oracle.com>
Cc: Dmitry Safonov <0x7f454c46@gmail.com>, linux-kernel@vger.kernel.org, 
 Dmitry Safonov <dima@arista.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769403458; l=3443;
 i=dima@arista.com; s=20250521; h=from:subject:message-id;
 bh=L+OyCJ+E74sD1H+mkrTXuuv+qHPrV/ngZ16iavL1m3s=;
 b=ObqIiox/jffAsupSuqKYIEIID1+AnArUvv3HHvsvuGE6FGaKlKB7YYdwDrOINTV4ErxqY2V+v
 TyO0iM1kzoqBohH89lj53ZfkDqEbNMTyrZRq4wsGqiMTt3uWUZIl85h
X-Developer-Key: i=dima@arista.com; a=ed25519;
 pk=/z94x2T59rICwjRqYvDsBe0MkpbkkdYrSW2J1G2gIcU=
X-Endpoint-Received: by B4 Relay for dima@arista.com/20250521 with auth_id=405
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When objtool is cross-compiled in ia32 container for x86_64 target it
fails with the following errors:

> disas.c: In function 'disas_print_addr_sym':
> disas.c:173:38: error: format '%lx' expects argument of type 'long unsigned int', but argument 3 has type 'bfd_vma' {aka 'long long unsigned int'} [-Werror=format=]
>   173 |                 DINFO_FPRINTF(dinfo, "0x%lx <%s>", addr, symstr);
>       |                                      ^~~~~~~~~~~~  ~~~~
>       |                                                    |
>       |                                                    bfd_vma {aka long long unsigned int}

Provide a correct printf-fmt depending on sizeof(bfd_vma).

Cc: Alexandre Chartre <alexandre.chartre@oracle.com>
Cc: Peter Zijlstra (Intel) <peterz@infradead.org>
Cc: Josh Poimboeuf <jpoimboe@kernel.org>
Fixes: 5d859dff266f ("objtool: Print symbol during disassembly")
Signed-off-by: Dmitry Safonov <dima@arista.com>
---
 tools/objtool/disas.c | 14 ++++++++------
 1 file changed, 8 insertions(+), 6 deletions(-)

diff --git a/tools/objtool/disas.c b/tools/objtool/disas.c
index 2b5059f55e40..26f08d41f2b1 100644
--- a/tools/objtool/disas.c
+++ b/tools/objtool/disas.c
@@ -108,6 +108,8 @@ static int sprint_name(char *str, const char *name, unsigned long offset)
 
 #define DINFO_FPRINTF(dinfo, ...)	\
 	((*(dinfo)->fprintf_func)((dinfo)->stream, __VA_ARGS__))
+#define bfd_vma_fmt			\
+	__builtin_choose_expr(sizeof(bfd_vma) == sizeof(unsigned long), "%#lx <%s>", "%#llx <%s>")
 
 static int disas_result_fprintf(struct disas_context *dctx,
 				const char *fmt, va_list ap)
@@ -170,10 +172,10 @@ static void disas_print_addr_sym(struct section *sec, struct symbol *sym,
 
 	if (sym) {
 		sprint_name(symstr, sym->name, addr - sym->offset);
-		DINFO_FPRINTF(dinfo, "0x%lx <%s>", addr, symstr);
+		DINFO_FPRINTF(dinfo, bfd_vma_fmt, addr, symstr);
 	} else {
 		str = offstr(sec, addr);
-		DINFO_FPRINTF(dinfo, "0x%lx <%s>", addr, str);
+		DINFO_FPRINTF(dinfo, bfd_vma_fmt, addr, str);
 		free(str);
 	}
 }
@@ -252,7 +254,7 @@ static void disas_print_addr_reloc(bfd_vma addr, struct disassemble_info *dinfo)
 		 * example: "lea 0x0(%rip),%rdi". The kernel can reference
 		 * the next IP with _THIS_IP_ macro.
 		 */
-		DINFO_FPRINTF(dinfo, "0x%lx <_THIS_IP_>", addr);
+		DINFO_FPRINTF(dinfo, bfd_vma_fmt, addr, "_THIS_IP_");
 		return;
 	}
 
@@ -264,11 +266,11 @@ static void disas_print_addr_reloc(bfd_vma addr, struct disassemble_info *dinfo)
 	 */
 	if (reloc->sym->type == STT_SECTION) {
 		str = offstr(reloc->sym->sec, reloc->sym->offset + offset);
-		DINFO_FPRINTF(dinfo, "0x%lx <%s>", addr, str);
+		DINFO_FPRINTF(dinfo, bfd_vma_fmt, addr, str);
 		free(str);
 	} else {
 		sprint_name(symstr, reloc->sym->name, offset);
-		DINFO_FPRINTF(dinfo, "0x%lx <%s>", addr, symstr);
+		DINFO_FPRINTF(dinfo, bfd_vma_fmt, addr, symstr);
 	}
 }
 
@@ -311,7 +313,7 @@ static void disas_print_address(bfd_vma addr, struct disassemble_info *dinfo)
 	 */
 	sym = insn_call_dest(insn);
 	if (sym && (sym->offset == addr || (sym->offset == 0 && is_reloc))) {
-		DINFO_FPRINTF(dinfo, "0x%lx <%s>", addr, sym->name);
+		DINFO_FPRINTF(dinfo, bfd_vma_fmt, addr, sym->name);
 		return;
 	}
 

---
base-commit: ca3a02fda4da8e2c1cb6baee5d72352e9e2cfaea
change-id: 20260126-objtool-ia32-84f2ba28de2a

Best regards,
-- 
Dmitry Safonov <dima@arista.com>

