From: Hitesh Murali <hitesh.murali@imperva.com>
Date: Thu, 01 Oct 2026 19:12:27 +0300
Subject: [PATCH] x86/mm/fault: Test _PAGE_RW, not pte_write(), in
 spurious_kernel_fault_check()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261001-x86-fault-spurious-rw-v1-1-7fe1189b5efd@imperva.com>
X-B4-Tracking: v=1; b=H4sIAGqGvmoC/yXMQQqDQAxA0atI1g1MjQzqVUoXU41tiqgkM1YQ7
 +60Xb7F/zsYq7BBW+ygvIrJPGVcLwV0rzA9GaXPhtKV3jXkcKs9DiGNEW1JKnMy1A/WDREFJue
 rCnK7KA+y/b63+9+WHm/u4ncGx3EC3BK0f3kAAAA=
X-Change-ID: 20260930-x86-fault-spurious-rw-89333ae30644
To: Dave Hansen <dave.hansen@linux.intel.com>, 
 Andy Lutomirski <luto@kernel.org>, Peter Zijlstra <peterz@infradead.org>, 
 Thomas Gleixner <tglx@kernel.org>, Ingo Molnar <mingo@redhat.com>, 
 Borislav Petkov <bp@alien8.de>, x86@kernel.org, 
 "H. Peter Anvin" <hpa@zytor.com>, 
 Rick Edgecombe <rick.p.edgecombe@intel.com>, 
 Yu-cheng Yu <yu-cheng.yu@intel.com>, 
 "Mike Rapoport (IBM)" <rppt@kernel.org>
Cc: linux-kernel@vger.kernel.org, Hitesh Murali <hitesh.murali@imperva.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790871153; l=5905;
 i=hitesh.murali@imperva.com; s=20260930; h=from:subject:message-id;
 bh=um02QXKjfD4K0WAcPvJgtdQiY6QeH6ENFD+z7x2HjO8=;
 b=O3rQogz/th5dWZgydip8gFEwBPtx0I47HzqQspG98+NaYrpDuiF0bBJrR7oQdeMa4abhgK7lf
 nOACEzbtFq4Dk9708HLbzX8X7wvag0cwlUhpwc0ZhQ0Jvv8SdwUDtjp
X-Developer-Key: i=hitesh.murali@imperva.com; a=ed25519;
 pk=u+EU1sWLTi0JU+w6N94rfNf+D0ev1cH486lE6MBQTak=
X-Endpoint-Received: by B4 Relay for hitesh.murali@imperva.com/20260930 with auth_id=1088
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

spurious_kernel_fault() only considers faults whose error code is exactly
X86_PF_WRITE | X86_PF_PROT or X86_PF_INSTR | X86_PF_PROT. A write fault
that reaches spurious_kernel_fault_check() is therefore a normal store,
never a shadow stack access, and with CR0.WP set, which the kernel pins,
the hardware permits a normal store only if _PAGE_RW is set. The check is
applied to 4K, 2M and 1G leaves and to the PMD table entry, and _PAGE_RW
means the same at each of these levels.

Commit bb3aadf7d446 ("x86/mm: Start actually marking _PAGE_SAVED_DIRTY")
made pte_write() return true for Write=0,Dirty=1 entries, the encoding of
shadow stack memory, so that core mm treats shadow stacks as writable.
pte_shstk() decides this from X86_FEATURE_SHSTK alone, so it applies on
every shadow stack capable CPU, also with CONFIG_X86_USER_SHADOW_STACK=n.
For a kernel mapping the hardware does not agree: the kernel never sets
IA32_S_CET.SH_STK_EN, so a supervisor Write=0,Dirty=1 entry is an
ordinary read-only entry.

Kernel read-only mappings are created without Dirty since commit
f788b71768ff ("x86/mm: Remove _PAGE_DIRTY from kernel RO pages"), but a
store made while _PAGE_RW is temporarily set leaves Dirty behind, and the
kernel does not clear it again. A later normal store to such an entry
raises a protection fault, which is then classified as spurious. The
store is restarted, faults again, and the CPU makes no progress.

When the soft lockup watchdog reports it, it reports a stuck CPU at the
store, which reads as a long running loop rather than as a write to a
read-only page. This was found with an out-of-tree module that writes to
.rodata; on a distribution kernel carrying bb3aadf7d446, on Sapphire
Rapids, one CPU looped on the store for days.

Test _PAGE_RW directly. The fault then takes the regular
bad_area_nosemaphore() path: an exception table fixup where the access
has one, as for any other read-only page, and otherwise an oops that
reports the faulting address and the page table entry.

Fixes: bb3aadf7d446 ("x86/mm: Start actually marking _PAGE_SAVED_DIRTY")
Assisted-by: LLM
Signed-off-by: Hitesh Murali <hitesh.murali@imperva.com>
Cc: stable@vger.kernel.org
---
Observed on a distribution kernel carrying bb3aadf7d446 (RHEL 9.8,
5.14.0-687.10.1.el9_8) on Sapphire Rapids, with a proprietary out-of-tree
module storing into sys_call_table:

  watchdog: BUG: soft lockup - CPU#53 stuck for 23s! [<task>:5016]
  RIP: 0010:<module store function>+0x1d/0x30 [<out-of-tree module>]
    faulting insn: mov %r8,(%rsi,%rdx,8)       (plain store, not WRSS)
  CR0: 0000000080050033   (WP=1)
  CR2: ffffffff96c02250   (= sys_call_table + 0x2a * 8)
  CR4: 0000000000f73ef0   (CET=1)
  Kernel panic - not syncing: softlockup: hung tasks
                                  (softlockup_panic=1 on this host)

  vmcore page table walk of CR2:
  PMD: 8000004af5e001e1 -> 2MB page, PRESENT|ACCESSED|DIRTY|PSE|GLOBAL|NX

Reproduced on mainline v7.3-rc5-37-g551c722f4080 without this patch, on
an Amazon EC2 m7i.metal-24xl (Xeon Platinum 8488C, user shadow stack
enabled, CR4.CET=1). Only two small GPL test modules were loaded
(taint O, E). They are available on request.

1) A test module sets _PAGE_RW on the live leaf that maps sys_call_table,
   stores an entry's own value back, and clears _PAGE_RW again. As read
   back through lookup_address():

     before: level=2M flags=0x80000000000001a1 RW=0 DIRTY=0 pte_write()=0
     after:  level=2M flags=0x80000000000001e1 RW=0 DIRTY=1 pte_write()=1

2) A second module stores sys_call_table[39]'s own value back (a plain
   MOV; sys_call_table is no longer used for x86-64 dispatch, so the
   store would be harmless if it completed). It never completes. Nine
   minutes later the task was still running, with CPU time equal to wall
   time, and the leaf was unchanged. An NMI backtrace (sysrq-l), trimmed:

     RIP: 0010:sct_store_init+0xaa/0xff0 [sct_store]
     Code: ... <48> 89 83 38 01 00 00     mov %rax,0x138(%rbx)
     RBX: ffffffffa2a029c0 (sys_call_table)
     CR0: 0000000080050033 (WP=1)  CR2: ffffffffa2a02af8  CR4: 0000000000f73ef0 (CET=1)
     Call Trace:
      do_one_initcall
      do_init_module
      init_module_from_file
      __x64_sys_finit_module

   CR2 is sys_call_table + 39 * 8, the slot being written: the same
   leaf state, the same kind of store, and the same fault address as on
   the distribution kernel.

Testing:
 - W=1 build of arch/x86/mm/fault.o on v7.3-rc5-37-g551c722f4080, no
   warnings. The patched kernel was built from the same tree and config.
 - The patched kernel has not been boot or runtime tested yet. The
   expected result is an oops at the store ("supervisor write access in
   kernel mode", "permissions violation") instead of the loop.
---
 arch/x86/mm/fault.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/arch/x86/mm/fault.c b/arch/x86/mm/fault.c
index aa88370ce739..84298cb38fae 100644
--- a/arch/x86/mm/fault.c
+++ b/arch/x86/mm/fault.c
@@ -955,7 +955,13 @@ do_sigbus(struct pt_regs *regs, unsigned long error_code, unsigned long address,
 
 static int spurious_kernel_fault_check(unsigned long error_code, pte_t *pte)
 {
-	if ((error_code & X86_PF_WRITE) && !pte_write(*pte))
+	/*
+	 * Only normal stores get here: the caller's exact error code match
+	 * filters out shadow stack accesses, and a normal store requires
+	 * _PAGE_RW. Do not use pte_write(), which also reports
+	 * Write=0,Dirty=1 as writable.
+	 */
+	if ((error_code & X86_PF_WRITE) && !(pte_flags(*pte) & _PAGE_RW))
 		return 0;
 
 	if ((error_code & X86_PF_INSTR) && !pte_exec(*pte))

---
base-commit: 551c722f40809618230001baccf219193e22fc5a
change-id: 20260930-x86-fault-spurious-rw-89333ae30644

Best regards,
--  
Hitesh Murali <hitesh.murali@imperva.com>

