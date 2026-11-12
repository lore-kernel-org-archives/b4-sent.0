From: Hang Zhengyang <hang.zhengyang1010@gmail.com>
Date: Thu, 12 Nov 2026 13:26:18 +0800
Subject: [PATCH] uprobes/x86: Emulate ENDBR as a NOP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-uprobe-endbr-v1-1-284a47a5ae3e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MPQqAMAxA4atIZgumg0WvIg79iZqlLSmKUHp3i
 +M3vFehkDAVWIcKQg8XTrEDxwH8ZeNJikM36EnPiKjVnSU5UhSDE2W8sQ6dtbgg9CQLHfz+u21
 v7QN5bbihXgAAAA==
X-Change-ID: 20261112-uprobe-endbr-7c7ab1baa191
To: Masami Hiramatsu <mhiramat@kernel.org>, Oleg Nesterov <oleg@redhat.com>, 
 Peter Zijlstra <peterz@infradead.org>, Thomas Gleixner <tglx@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, x86@kernel.org, 
 "H. Peter Anvin" <hpa@zytor.com>
Cc: linux-kernel@vger.kernel.org, linux-trace-kernel@vger.kernel.org, 
 bpf@vger.kernel.org, Andrii Nakryiko <andrii@kernel.org>, 
 Jiri Olsa <jolsa@kernel.org>, Hang Zhengyang <hang.zhengyang1010@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794461178; l=3044;
 i=hang.zhengyang1010@gmail.com; s=20261008; h=from:subject:message-id;
 bh=Me7MxAd288UOXLmc+8UseLP8mB9LDZJcffXOE/7xdVk=;
 b=TYjmkiZhMPeL5rzT4xkvGnJ3DrsPvjpjIzFhdsZncNT4coF1yOvINPkolyEN3eedeLaarMkxV
 TvgA7qBX2+nADm5DZKncRYHiVsy1Wxkr1FyW/V8C3gZGGVMbd/cTrPZ
X-Developer-Key: i=hang.zhengyang1010@gmail.com; a=ed25519;
 pk=5drRny3PqRPLhKVB0YIQXN5YyD8miKCpXWhnEPvafAI=
X-Endpoint-Received: by B4 Relay for hang.zhengyang1010@gmail.com/20261008 with auth_id=1133
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A uprobe on ENDBR64 is single-stepped, so it takes two traps instead of
one: insn_is_nop() doesn't recognize ENDBR, and it isn't a branch or a
push either.  That makes the most common case slow.  With
-fcf-protection, the default for gcc on Ubuntu, every function starts
with ENDBR64, so every uprobe on a function entry pays for the
single-step.  PUSH had the same problem until commit e7ed9d9bd037
("uprobes/x86: Emulate push insns for uprobe on x86").

Userspace IBT is not supported, so ENDBR is just a NOP in user mode.
Emulate it like the other NOPs.  Don't use is_endbr() for the check: it
always returns false without CONFIG_X86_KERNEL_IBT.  If userspace IBT
is ever enabled, uprobes on ENDBR will need rework anyway, since the
int3 replaces the ENDBR at an indirect branch target.

The numbers below are from the selftests/bpf trigger benchmarks, with
an extra target that starts with ENDBR64 (the existing ones are built
with __nocf_check, so they don't have it).  On a Ryzen 7 PRO 5850U,
without this patch, a probe on ENDBR64 is as slow as a single-stepped
one:

             nop       endbr64   ret (single-step)
  uprobe     1.33 M/s  0.65 M/s  0.65 M/s
  uretprobe  0.66 M/s  0.43 M/s  0.43 M/s

With this patch ENDBR64 is emulated like a NOP.  I could only boot the
patched kernel in a KVM guest, where uprobe went from 0.19 to 0.99 M/s
(nop: 1.00) and uretprobe from 0.17 to 0.61 M/s (nop: 0.61).

Signed-off-by: Hang Zhengyang <hang.zhengyang1010@gmail.com>
---
Found and measured with Claude; I reviewed it and ran the measurement.
---
 arch/x86/kernel/uprobes.c | 17 ++++++++++++++++-
 1 file changed, 16 insertions(+), 1 deletion(-)

diff --git a/arch/x86/kernel/uprobes.c b/arch/x86/kernel/uprobes.c
index 0f60c0d076b6..879ce918ebea 100644
--- a/arch/x86/kernel/uprobes.c
+++ b/arch/x86/kernel/uprobes.c
@@ -1484,13 +1484,28 @@ static const struct uprobe_xol_ops push_xol_ops = {
 	.emulate  = push_emulate_op,
 };
 
+/*
+ * ENDBR64/ENDBR32 (f3 0f 1e fa/fb).  Userspace IBT is not supported, so
+ * in a user task they are NOPs, and they start most functions in
+ * binaries built with -fcf-protection.  Revisit if userspace IBT is
+ * ever enabled.
+ */
+static bool insn_is_endbr(struct insn *insn)
+{
+	return insn->length == 4 &&
+	       insn->prefixes.nbytes == 1 && insn->prefixes.bytes[0] == 0xf3 &&
+	       insn->opcode.nbytes == 2 && insn->opcode.bytes[0] == 0x0f &&
+	       insn->opcode.bytes[1] == 0x1e &&
+	       (insn->modrm.bytes[0] & ~1) == 0xfa;
+}
+
 /* Returns -ENOSYS if branch_xol_ops doesn't handle this insn */
 static int branch_setup_xol_ops(struct arch_uprobe *auprobe, struct insn *insn)
 {
 	u8 opc1 = OPCODE1(insn);
 	insn_byte_t p;
 
-	if (insn_is_nop(insn))
+	if (insn_is_nop(insn) || insn_is_endbr(insn))
 		goto setup;
 
 	switch (opc1) {

---
base-commit: 9d66f26fefacebfeed15de31c1123451a17ff119
change-id: 20261112-uprobe-endbr-7c7ab1baa191

Best regards,
-- 
Hang Zhengyang <hang.zhengyang1010@gmail.com>

