From: Simon Schuster <schuster.simon@siemens-energy.com>
Date: Thu, 21 Aug 2025 13:27:38 +0200
Subject: [PATCH 2/2] nios2: implement architecture-specific portion of
 sys_clone3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250821-nios2-implement-clone3-v1-2-1bb24017376a@siemens-energy.com>
References: <20250821-nios2-implement-clone3-v1-0-1bb24017376a@siemens-energy.com>
In-Reply-To: <20250821-nios2-implement-clone3-v1-0-1bb24017376a@siemens-energy.com>
To: Dinh Nguyen <dinguyen@kernel.org>, 
 Christian Brauner <brauner@kernel.org>, Arnd Bergmann <arnd@arndb.de>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@redhat.com>, 
 Lorenzo Stoakes <lorenzo.stoakes@oracle.com>, 
 "Liam R. Howlett" <Liam.Howlett@oracle.com>, 
 Vlastimil Babka <vbabka@suse.cz>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Ingo Molnar <mingo@redhat.com>, Peter Zijlstra <peterz@infradead.org>, 
 Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>, 
 Kees Cook <kees@kernel.org>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Simon Schuster <schuster.simon@siemens-energy.com>
X-Mailer: b4 0.14.3-dev-2ce6c
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755775663; l=2259;
 i=schuster.simon@siemens-energy.com; s=20250818; h=from:subject:message-id;
 bh=ZGFd7PEXdNZQ3XvGm96hBqrgf0z3Sn12r48TmNzThTY=;
 b=F2nKl2igsmfyyDF/eUV0oYb5mlZJyimIpk0NXRJVrpnKfItiOUjRR+lvhtzDMtKjVJKvuPs+u
 3hz69QALEOGCg5dAKDF1klwR3WkvjnC1lV0TyZQ2blO79aj8xnAMWyK
X-Developer-Key: i=schuster.simon@siemens-energy.com; a=ed25519;
 pk=PUhOMiSp43aSeRE1H41KApxYOluamBFFiMfKlBjocvo=
X-Endpoint-Received: by B4 Relay for schuster.simon@siemens-energy.com/20250818 with auth_id=495
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit adds the sys_clone3 entrypoint for nios2. An
architecture-specific wrapper (__sys_clone3) is required to save and
restore additional registers to the kernel stack via SAVE_SWITCH_STACK
and RESTORE_SWITCH_STACK.

Signed-off-by: Simon Schuster <schuster.simon@siemens-energy.com>
---
 arch/nios2/include/asm/syscalls.h | 1 +
 arch/nios2/include/asm/unistd.h   | 2 --
 arch/nios2/kernel/entry.S         | 6 ++++++
 arch/nios2/kernel/syscall_table.c | 1 +
 4 files changed, 8 insertions(+), 2 deletions(-)

diff --git a/arch/nios2/include/asm/syscalls.h b/arch/nios2/include/asm/syscalls.h
index b4d4ed3bf9c8..0e214b0a0ac8 100644
--- a/arch/nios2/include/asm/syscalls.h
+++ b/arch/nios2/include/asm/syscalls.h
@@ -7,6 +7,7 @@
 
 int sys_cacheflush(unsigned long addr, unsigned long len,
 				unsigned int op);
+asmlinkage long __sys_clone3(struct clone_args __user *uargs, size_t size);
 
 #include <asm-generic/syscalls.h>
 
diff --git a/arch/nios2/include/asm/unistd.h b/arch/nios2/include/asm/unistd.h
index 1146e56473c5..213f6de3cf7b 100644
--- a/arch/nios2/include/asm/unistd.h
+++ b/arch/nios2/include/asm/unistd.h
@@ -7,6 +7,4 @@
 #define __ARCH_WANT_STAT64
 #define __ARCH_WANT_SET_GET_RLIMIT
 
-#define __ARCH_BROKEN_SYS_CLONE3
-
 #endif
diff --git a/arch/nios2/kernel/entry.S b/arch/nios2/kernel/entry.S
index 99f0a65e6234..dd40dfd908e5 100644
--- a/arch/nios2/kernel/entry.S
+++ b/arch/nios2/kernel/entry.S
@@ -403,6 +403,12 @@ ENTRY(sys_clone)
 	addi    sp, sp, 4
 	RESTORE_SWITCH_STACK
 	ret
+/* long syscall(SYS_clone3, struct clone_args *cl_args, size_t size); */
+ENTRY(__sys_clone3)
+	SAVE_SWITCH_STACK
+	call	sys_clone3
+	RESTORE_SWITCH_STACK
+	ret
 
 ENTRY(sys_rt_sigreturn)
 	SAVE_SWITCH_STACK
diff --git a/arch/nios2/kernel/syscall_table.c b/arch/nios2/kernel/syscall_table.c
index 434694067d8f..c99818aac9e1 100644
--- a/arch/nios2/kernel/syscall_table.c
+++ b/arch/nios2/kernel/syscall_table.c
@@ -13,6 +13,7 @@
 #define __SYSCALL_WITH_COMPAT(nr, native, compat)        __SYSCALL(nr, native)
 
 #define sys_mmap2 sys_mmap_pgoff
+#define sys_clone3 __sys_clone3
 
 void *sys_call_table[__NR_syscalls] = {
 	[0 ... __NR_syscalls-1] = sys_ni_syscall,

-- 
2.39.5

