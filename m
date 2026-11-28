From: Binoy Ravindran <binoy@vt.edu>
Date: Fri, 27 Nov 2026 20:26:09 -0500
Subject: [PATCH] objtool/klp: Copy constant pool entries for local labels
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-objtool-klp-cst-v1-1-dc19b08c8676@vt.edu>
X-B4-Tracking: v=1; b=H4sIALAtCmsC/yXMTQqDMBBA4avIrB1I4h/tVcRFTMc6KkYysRTEu
 zfW5bd47wChwCTwzA4I9GFhvyboPAM32vVNyK9kMMrUWpsGfT9F7xeclw2dRKwKa0pVNoOiB6R
 qCzTw939su9uy9xO5eG3gPH8AF2gMcwAAAA==
X-Change-ID: 20261127-objtool-klp-cst-53a24047f0e9
To: Josh Poimboeuf <jpoimboe@kernel.org>, 
 Peter Zijlstra <peterz@infradead.org>, Song Liu <song@kernel.org>
Cc: linux-kernel@vger.kernel.org, live-patching@vger.kernel.org, 
 Binoy Ravindran <binoy@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795829188; l=3839;
 i=binoy@vt.edu; s=20261123; h=from:subject:message-id;
 bh=g6HRbPb1IGu2InqS4C2jJUK6JDCQL7R1Kycv7BvVqMg=;
 b=S7QM5+ShXq94f+j5vazW2vbjBTc+Tw02491KJe6OG0xJF2Uqqmu9qme/pREbm6wCkIYrEwMvH
 TM70xkRCUVFCaFFT39mWLC/CaAcbxAnoZZHflRaWUrLE/TcKRNLDWdy
X-Developer-Key: i=binoy@vt.edu; a=ed25519;
 pk=4cNdKPHP0InmhK/9bb7Tm2ZMUXUvLGfw1pmVt5b98fA=
X-Endpoint-Received: by B4 Relay for binoy@vt.edu/20261123 with auth_id=1622
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The compiler refers to a constant in a .rodata.cst* pool through a local
label such as .LC32. The label has no size. Since commit 51e1dfce24c8
("objtool/klp: Don't correlate .rodata.cst* constant pool objects"),
klp-diff clones such a label together with its data. But
__clone_symbol() copies data only for a symbol with a nonzero length or
for a section symbol. For a .LC label it copies nothing and places the
label at the current end of the output section.

The patched function then reads whatever ends up at that place when the
module is linked. Building livepatches with klp-build for recent fixes
on v7.4-rc2 (x86-64, GCC 12), three of 54 modules read the wrong 2-byte
constant:

  fib_table_insert()          .LC32  expected 0x0000, reads 0x6e00
  ieee80211_rx_mgmt_beacon()  .LC68  expected 0x0000, reads 0x6e00
  cfg80211_inform_bss_data()  .LC9   expected 0x1000, reads 0x0000

In each case the bytes come from the end of an unrelated string in the
module's .rodata. The modules load and patch without any warning. We
confirmed this in a running kernel: with the first module loaded, the
patched fib_table_insert() loads 0x6e00.

A label in a SHF_MERGE constant pool names one entry of sh_entsize
bytes. Copy that entry when the label has no size. With this change, all
three modules hold the compiler's constants.

Fixes: 51e1dfce24c8 ("objtool/klp: Don't correlate .rodata.cst* constant pool objects")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Binoy Ravindran <binoy@vt.edu>
---
A small problem in __clone_symbol(): a .LC label in a .rodata.cst*
pool has no size, so its constant is never copied into the livepatch
module, and the patched function reads whatever bytes follow. Details
and the three affected modules are in the patch.

Tested on v7.4-rc2 (x86-64, GCC 12): with the fix, the three modules
hold the compiler's constants, and three unaffected modules are
unchanged. The patch applies to tip objtool/core and to mainline.
---
 tools/objtool/klp-diff.c | 15 +++++++++++++--
 1 file changed, 13 insertions(+), 2 deletions(-)

diff --git a/tools/objtool/klp-diff.c b/tools/objtool/klp-diff.c
index 95d0d86666d7..f8a638b29a26 100644
--- a/tools/objtool/klp-diff.c
+++ b/tools/objtool/klp-diff.c
@@ -923,6 +923,7 @@ static struct symbol *__clone_symbol(struct elf *elf, struct symbol *patched_sym
 
 	if (data_too && !is_undef_sym(patched_sym)) {
 		struct section *patched_sec = patched_sym->sec;
+		size_t len = patched_sym->len;
 
 		out_sec = find_section_by_name(elf, patched_sec->name);
 		if (!out_sec) {
@@ -946,7 +947,17 @@ static struct symbol *__clone_symbol(struct elf *elf, struct symbol *patched_sym
 		if (!is_sec_sym(patched_sym))
 			offset = ALIGN(sec_size(out_sec), out_sec->sh.sh_addralign);
 
-		if (patched_sym->len || is_sec_sym(patched_sym)) {
+		/*
+		 * A local label in a constant pool (.rodata.cst*) has no size,
+		 * but it names one entry of sh_entsize bytes.  Copy that entry,
+		 * or the label ends up pointing at whatever data follows it.
+		 */
+		if (!len && !is_sec_sym(patched_sym) &&
+		    (patched_sec->sh.sh_flags & SHF_MERGE) &&
+		    !is_string_sec(patched_sec) && patched_sec->sh.sh_entsize)
+			len = patched_sec->sh.sh_entsize;
+
+		if (len || is_sec_sym(patched_sym)) {
 			void *data = NULL;
 			size_t size;
 
@@ -957,7 +968,7 @@ static struct symbol *__clone_symbol(struct elf *elf, struct symbol *patched_sym
 			if (is_sec_sym(patched_sym))
 				size = sec_size(patched_sym->sec);
 			else
-				size = patched_sym->len;
+				size = len;
 
 			if (!elf_add_data(elf, out_sec, data, size))
 				return NULL;

---
base-commit: b99a5337da3c847db216476d645b69acd714c3ba
change-id: 20261127-objtool-klp-cst-53a24047f0e9

Best regards,
--  
Binoy Ravindran <binoy@vt.edu>

