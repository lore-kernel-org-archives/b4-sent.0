From: Reza Arbab <arbab@linux.ibm.com>
Date: Wed, 08 Mar 2023 11:26:47 -0600
Subject: [PATCH] powerpc: Remove TM XER[SO] bug workaround on POWER9 v2.3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230308-cpu_ftr_p9_tm_xer_so_bug-v1-1-75e4c53c026a@linux.ibm.com>
X-B4-Tracking: v=1; b=H4sIAFbFCGQC/x2NQQqDMBBFryKzbmBU2mqvUmRI0lGzMIaZWATx7
 o1dPj7vvwOUJbDCqzpA+Bs0rLFAfavAzzZObMKnMDTYtNhiZ3zaaMxCqae80M5CupLbJsP+3jl
 E2z/rBxTdWWXjxEY/XweL1cxyDUl4DPu/+R7O8weAvdfkgwAAAA==
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: linuxppc-dev@lists.ozlabs.org, Reza Arbab <arbab@linux.ibm.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1833; i=arbab@linux.ibm.com;
 h=from:subject:message-id; bh=YY0g8Df5qjX6rJn6WmSARM9BAtsZyWTzfiGLnFG1Vnw=;
 b=owEBzQIy/ZANAwAKAdAlkqhpa2bdAcsmYgBkCMVdrTHkwCd44WVG04LfAi0LQWaygx2ucP4Ga
 PuzsAjQntOJApMEAAEKAH0WIQT1XwGdMQOjW/syvwXQJZKoaWtm3QUCZAjFXV8UgAAAAAAuAChp
 c3N1ZXItZnByQG5vdGF0aW9ucy5vcGVucGdwLmZpZnRoaG9yc2VtYW4ubmV0RjU1RjAxOUQzMTA
 zQTM1QkZCMzJCRjA1RDAyNTkyQTg2OTZCNjZERAAKCRDQJZKoaWtm3W3QD/9/GDY4/Lr5gHTJmi
 M+RRu7NlGYQhLGUtK+Z1U4BQ7W4b5p/qJtDZw7mVoI9TF38dvhLYhS14QJUr+NnQL0yh/kcVbSY
 pF64ucQXT5rnd0M32YHJKv5n/Y6CltBzjKfBvS0SYj8rmLWbI1e18hz9nA+5r9kD7xadd8A4fxL
 slgzM+aEv8fLm/2Xat7AYvAhg7qiwTSo3LLabE6tF+p6qCeQEjA6vNhIxX3CmvTkYa3q6snzx9x
 aMIALxV26WCu03swEI+8lAeWJaM+LXBMXCh6/jJNOMb8pR8K8qWl2H7HrMc0pB2gW9WmlQkYfJe
 jBpkuDIswQu4br0D5Bo4jw73uU8GbQHT3V7g7ehG2CKBcIcQvKePooZu1NnWUUog8OV7PIjsH4v
 fgRzG5kwnzwlY6kl4ZMBzXQa8ThE1KryiDnAVlo1dJ1tYiCx+jH6hpbkSODlDVj+UkE6EmrTZ0b
 GtjYDe9140ZDGzZzl/PoeS1JcVmUpeTsI3mxAfaBnKA1xDGyAVRB3h3kO6aRV6c9r4ssL2E6BOQ
 yL62JNX8nP3W7Yy5fGXdIOrI0yYBMqzhyPar6BgImJ0TnAA8/Vf8Da01EspV91o2BGQaUFe2+Hx
 rG1kaQS+weagoVHFE7U4xH6/AZ3J6Q2t8sGn9vvNtEqB2Fp15wpg/8Za6bjfMfaYMW+Q==
X-Developer-Key: i=arbab@linux.ibm.com; a=openpgp;
 fpr=F55F019D3103A35BFB32BF05D02592A8696B66DD
X-Endpoint-Received: by B4 Relay for arbab@linux.ibm.com/default with auth_id=37
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When creating the CPU feature bits for DD2.3, I should not have carried
forward CPU_FTR_P9_TM_XER_SO_BUG. That bug is fixed in DD2.3, so remove
the flag.

Fixes: 26b78c81e84c ("powerpc: Enable the DAWR on POWER9 DD2.3 and above")
Signed-off-by: Reza Arbab <arbab@linux.ibm.com>
---
 arch/powerpc/include/asm/cputable.h | 1 -
 arch/powerpc/kernel/dt_cpu_ftrs.c   | 1 -
 2 files changed, 2 deletions(-)

diff --git a/arch/powerpc/include/asm/cputable.h b/arch/powerpc/include/asm/cputable.h
index 757dbded11dc..5dc6906498ef 100644
--- a/arch/powerpc/include/asm/cputable.h
+++ b/arch/powerpc/include/asm/cputable.h
@@ -439,7 +439,6 @@ static inline void cpu_feature_keys_init(void) { }
 			       CPU_FTR_P9_TM_XER_SO_BUG)
 #define CPU_FTRS_POWER9_DD2_3 (CPU_FTRS_POWER9 | CPU_FTR_POWER9_DD2_1 | \
 			       CPU_FTR_P9_TM_HV_ASSIST | \
-			       CPU_FTR_P9_TM_XER_SO_BUG | \
 			       CPU_FTR_DAWR)
 #define CPU_FTRS_POWER10 (CPU_FTR_LWSYNC | \
 	    CPU_FTR_PPCAS_ARCH_V2 | CPU_FTR_CTRL | CPU_FTR_ARCH_206 |\
diff --git a/arch/powerpc/kernel/dt_cpu_ftrs.c b/arch/powerpc/kernel/dt_cpu_ftrs.c
index c3fb9fdf5bd7..afcdbeed8b44 100644
--- a/arch/powerpc/kernel/dt_cpu_ftrs.c
+++ b/arch/powerpc/kernel/dt_cpu_ftrs.c
@@ -782,7 +782,6 @@ static __init void cpufeatures_cpu_quirks(void)
 		cur_cpu_spec->cpu_features &= ~(CPU_FTR_DAWR);
 	} else if ((version & 0xffffefff) == 0x004e0203) {
 		cur_cpu_spec->cpu_features |= CPU_FTR_P9_TM_HV_ASSIST;
-		cur_cpu_spec->cpu_features |= CPU_FTR_P9_TM_XER_SO_BUG;
 		cur_cpu_spec->cpu_features |= CPU_FTR_POWER9_DD2_1;
 	} else if ((version & 0xffff0000) == 0x004e0000) {
 		/* DD2.1 and up have DD2_1 */

---
base-commit: fe15c26ee26efa11741a7b632e9f23b01aca4cc6
change-id: 20230308-cpu_ftr_p9_tm_xer_so_bug-ec58b00a9716

Best regards,
-- 
Reza Arbab

