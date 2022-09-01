From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Thu, 01 Sep 2022 15:29:01 -0400
Subject: [PATCH v5 16/21] objtool: Disable CFI warnings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20220901-kcfi_support-v5-16-be2007d8da63@linuxfoundation.org>
References: <20220901-kcfi_support-v5-0-be2007d8da63@linuxfoundation.org>
In-Reply-To: <20220901-kcfi_support-v5-0-be2007d8da63@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-03aea
X-Developer-Signature: v=1; a=openpgp-sha256; l=1743;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=8U0LqN/pNuls3IF/m+5+L84TWapgLWeHQLZO2/xF8Ic=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJIF2X/XvbzssC7jIfud3QE/b7bZ90cXsRdsUNCbyCI6ba3a
 ErHojlIWBjEuBlkxRZayfbGbggofesil95jCzGFlAhnCwMUpABO5nMTwP6i20yO6QSP+WV3lMeVQHd
 Xr5zP2a2Us+fOhd8f5+yuNlzAyTLjwpGi2WEv/+46trx6s0p/R2r7cfNorU5/KfWa9tys0OAA=
X-Developer-Key: i=konstantin@linuxfoundation.org; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for konstantin@linuxfoundation.org/default with auth_id=3
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

From: Sami Tolvanen <samitolvanen@google.com>

The __cfi_ preambles contain a mov instruction that embeds the KCFI
type identifier in the following format:

  ; type preamble
  __cfi_function:
    mov <id>, %eax
  function:
    ...

While the preamble symbols are STT_FUNC and contain valid
instructions, they are never executed and always fall through. Skip
the warning for them.

.kcfi_traps sections point to CFI traps in text sections. Also skip
the warning about them referencing !ENDBR instructions.

Signed-off-by: Sami Tolvanen <samitolvanen@google.com>
Acked-by: Josh Poimboeuf <jpoimboe@kernel.org>
Reviewed-by: Kees Cook <keescook@chromium.org>
Tested-by: Kees Cook <keescook@chromium.org>

diff --git a/tools/objtool/check.c b/tools/objtool/check.c
index e55fdf952a3a..48e18737a2d1 100644
--- a/tools/objtool/check.c
+++ b/tools/objtool/check.c
@@ -3316,6 +3316,10 @@ static int validate_branch(struct objtool_file *file, struct symbol *func,
 		next_insn = next_insn_to_validate(file, insn);
 
 		if (func && insn->func && func != insn->func->pfunc) {
+			/* Ignore KCFI type preambles, which always fall through */
+			if (!strncmp(func->name, "__cfi_", 6))
+				return 0;
+
 			WARN("%s() falls through to next function %s()",
 			     func->name, insn->func->name);
 			return 1;
@@ -4113,7 +4117,8 @@ static int validate_ibt(struct objtool_file *file)
 		    !strcmp(sec->name, "__bug_table")			||
 		    !strcmp(sec->name, "__ex_table")			||
 		    !strcmp(sec->name, "__jump_table")			||
-		    !strcmp(sec->name, "__mcount_loc"))
+		    !strcmp(sec->name, "__mcount_loc")			||
+		    !strcmp(sec->name, ".kcfi_traps"))
 			continue;
 
 		list_for_each_entry(reloc, &sec->reloc->reloc_list, list)

-- 
b4 0.10.0-dev-03aea
