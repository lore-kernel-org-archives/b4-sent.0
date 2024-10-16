From: Celeste Liu <CoelacanthusHex@gmail.com>
Date: Thu, 17 Oct 2024 01:49:49 +0800
Subject: [PATCH] riscv/entry: get correct syscall number from
 syscall_get_nr()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241017-fix-riscv-syscall-nr-v1-1-4edb4ca07f07@gmail.com>
X-B4-Tracking: v=1; b=H4sIALz8D2cC/x2MSQqAMAwAvyI5G7AuFf2KeNCaakCqJFAU8e8Wj
 wMz84CSMCn02QNCkZWPkMDkGbhtCishL4mhLMraFMai5wuF1UXUW9207xgEO9POjbW+a30FKT2
 Fkvdvh/F9P1Mix5BmAAAA
X-Change-ID: 20241016-fix-riscv-syscall-nr-917b566f97f3
To: Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 =?utf-8?q?Bj=C3=B6rn_T=C3=B6pel?= <bjorn@rivosinc.com>, 
 Celeste Liu <coelacanthushex@gmail.com>
Cc: Palmer Dabbelt <palmer@rivosinc.com>, Alexandre Ghiti <alex@ghiti.fr>, 
 "Dmitry V. Levin" <ldv@strace.io>, Andrea Bolognani <abologna@redhat.com>, 
 Felix Yan <felixonmars@archlinux.org>, Ruizhe Pan <c141028@gmail.com>, 
 Shiqi Zhang <shiqi@isrc.iscas.ac.cn>, Guo Ren <guoren@kernel.org>, 
 Yao Zi <ziyao@disroot.org>, Han Gao <gaohan@iscas.ac.cn>, 
 linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Celeste Liu <CoelacanthusHex@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2366;
 i=CoelacanthusHex@gmail.com; h=from:subject:message-id;
 bh=lQHWH4mdPxR6fSPtGuLhEmZBLbEpDpJ9XVmyzF+kIjU=;
 b=owJ4nJvAy8zAJfY4pvNJRPo6U8bTakkM6fx//rDbHWUTjFeQ1lxc+evTyrQnVWz7ZnMl5gXGN
 bKeX89itrCjlIVBjItBVkyRRWzn09fLSh99WMZrMgNmDisTyBAGLk4BmIiTFyPDhFnn9dIvunfM
 ezeRcxLDm791Uyo+aE9KqdXql5lxwCePn5HhUrLiJuNJhmd61+wIi3naMVdOfk7c5X/cwk3Xt4c
 4mnjxAQABV0jh
X-Developer-Key: i=CoelacanthusHex@gmail.com; a=openpgp;
 fpr=892EBC7DC392DFF9C9C03F1D15F4180E73787863
X-Endpoint-Received: by B4 Relay for CoelacanthusHex@gmail.com/default with auth_id=84
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The return value of syscall_enter_from_user_mode() is always -1 when the
syscall was filtered. We can't know whether syscall_nr is -1 when we get -1
from syscall_enter_from_user_mode(). And the old syscall variable is
unusable because syscall_enter_from_user_mode() may change a7 register.
So get correct syscall number from syscall_get_nr().

So syscall number part of return value of syscall_enter_from_user_mode()
is completely useless. We can remove it from API and require caller to
get syscall number from syscall_get_nr(). But this change affect more
architectures and will block more time. So we split it into another
patchset to avoid block this fix. (Other architectures can works
without this change but riscv need it, see Link: tag below)

Fixes: 61119394631f ("riscv: entry: always initialize regs->a0 to -ENOSYS")
Reported-by: Andrea Bolognani <abologna@redhat.com>
Closes: https://github.com/strace/strace/issues/315
Link: https://lore.kernel.org/all/59505464-c84a-403d-972f-d4b2055eeaac@gmail.com/
Signed-off-by: Celeste Liu <CoelacanthusHex@gmail.com>
---
 arch/riscv/kernel/traps.c | 13 ++++++++++---
 1 file changed, 10 insertions(+), 3 deletions(-)

diff --git a/arch/riscv/kernel/traps.c b/arch/riscv/kernel/traps.c
index 51ebfd23e0076447518081d137102a9a11ff2e45..3125fab8ee4af468ace9f692dd34e1797555cce3 100644
--- a/arch/riscv/kernel/traps.c
+++ b/arch/riscv/kernel/traps.c
@@ -316,18 +316,25 @@ void do_trap_ecall_u(struct pt_regs *regs)
 {
 	if (user_mode(regs)) {
 		long syscall = regs->a7;
+		long res;
 
 		regs->epc += 4;
 		regs->orig_a0 = regs->a0;
-		regs->a0 = -ENOSYS;
 
 		riscv_v_vstate_discard(regs);
 
-		syscall = syscall_enter_from_user_mode(regs, syscall);
+		res = syscall_enter_from_user_mode(regs, syscall);
+		/*
+		 * Call syscall_get_nr() again because syscall_enter_from_user_mode()
+		 * may change a7 register.
+		 */
+		syscall = syscall_get_nr(current, regs);
 
 		add_random_kstack_offset();
 
-		if (syscall >= 0 && syscall < NR_syscalls)
+		if (syscall < 0 || syscall >= NR_syscalls)
+			regs->a0 = -ENOSYS;
+		else if (res != -1)
 			syscall_handler(regs, syscall);
 
 		/*

---
base-commit: 2f87d0916ce0d2925cedbc9e8f5d6291ba2ac7b2
change-id: 20241016-fix-riscv-syscall-nr-917b566f97f3

Best regards,
-- 
Celeste Liu <CoelacanthusHex@gmail.com>

