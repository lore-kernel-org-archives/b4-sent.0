From: Dmitry Safonov <dima@arista.com>
Date: Tue, 28 Apr 2026 18:35:31 +0100
Subject: [PATCH] x86/CPU/AMD: Clear RDRAND CPUID if Built-In-Self-Test
 failed on boot
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-rdrand-cpubug-v1-1-ac8384c841f3@arista.com>
X-B4-Tracking: v=1; b=H4sIAOLv8GkC/x3MQQrDIBBA0auEWXdoFLHQq5QuRp0kA60NYwxCy
 N1ru3yL/w8orMIF7sMByrsU+eQOcxkgLpRnRkndYEfrR2dvqEkpJ4xrDXVGb5g8Td44F6E3q/I
 k7f97PLsDFcbQi7j8Li/JtWHmtl3fVDZWOM8vixJMzoMAAAA=
X-Change-ID: 20260427-rdrand-cpubug-61ea6af6144c
To: Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, "H. Peter Anvin" <hpa@zytor.com>, 
 Ingo Molnar <mingo@redhat.com>, Thomas Gleixner <tglx@kernel.org>
Cc: Dmitry Safonov <0x7f454c46@gmail.com>, 
 Tom Lendacky <thomas.lendacky@amd.com>, Peter Edwards <peadar@arista.com>, 
 linux-kernel@vger.kernel.org, x86@kernel.org, 
 Dmitry Safonov <dima@arista.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777397760; l=6222;
 i=dima@arista.com; s=20250521; h=from:subject:message-id;
 bh=zY+/MadCaKRzhuk03rxiuRI9MDX1T0Cjb1oF6jSoXlk=;
 b=1/59vjE9pz0UUKGsNFUNAMOyCKCamwtkhrtxCFdV32i7bNx1DB0Q3xtl7v1/ivXGFKcJBNqGS
 B5dSF1AZJl8CA55gUAc+B5Znz9ro/1Tj7Dhz5TLOWdUOdVwrDLEbkrA
X-Developer-Key: i=dima@arista.com; a=ed25519;
 pk=/z94x2T59rICwjRqYvDsBe0MkpbkkdYrSW2J1G2gIcU=
X-Endpoint-Received: by B4 Relay for dima@arista.com/20250521 with auth_id=405
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On AMD Embedded R-Series RX-421ND (family: 0x15, model: 0x60, stepping: 0x1)
with microcode revision 0x0600611a RDRAND is constantly giving zeros:
: #include <stdio.h>
: #include <stdint.h>
: #define _rdrand(x) ({ unsigned char err; asm volatile("rdrand %0; setc %1":"=r"(*x), "=qm"(err)); err; })
:
: int main(int argc, char *argv[])
: {
:         uint64_t x;
:         int i;
:
:         for (i = 0; i < 20; i++) {
:                 _rdrand(&x);
:                 printf("%llx ", x);
:         }
:         putchar('\n');
:         return 0;
: }
Prints:
: # /tmp/check
: 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

BIST correctly detects a broken implementation on boot:
[..] RDRAND is not reliable on this platform; disabling.
...
[..] smpboot: x86: Booting SMP configuration:
[..] .... node  #0, CPUs:      #1 #2 #3
[..] RDRAND is not reliable on this platform; disabling.
[..] RDRAND is not reliable on this platform; disabling.
[..] RDRAND is not reliable on this platform; disabling.
[..] smp: Brought up 1 node, 4 CPUs

Yet, CPUID gets cleared only for previously known broken
implementations, see i.e., commit c49a0a80137c ("x86/CPU/AMD: Clear
RDRAND CPUID bit on AMD family 15h/16h"), that disabled RDRAND on
the same CPU family, where it was broken only after suspend-resume.

As RDRAND is not masked in CPUID, some userspace may attempt using it,
for example, libstdc++ with the following reproducer (thanks to Peter):
: #include <random>
: #include <iostream>
: int main() {
:    std::random_device rd;
:    std::uniform_int_distribution<int> dist(0, 9);
:    for (int i = 0; i < 10; ++i)
:       std::cout << dist(rd) << " ";
:    std::cout << "\n";
: }
crashes when RDRAND is unmasked:
: # /tmp/rdrand
: terminate called after throwing an instance of 'std::runtime_error'
:   what():  random_device: rdrand failed
: Aborted (core dumped)

Some userspace already migrated to vgetrandom() instead of raw RDRAND,
i.e. systemd [1] and glibc [2], yet unfortunately, some hasn't.

Let Built-In-Self-Test mask CPUID on AMD with MSR register when
it detects that implementation is not functioning.

[1]: https://github.com/systemd/systemd/commit/ffa047a03e4c5f6bd3af73b7eecb99cd230fe204
[2]: https://sourceware.org/git/?p=glibc.git;a=commit;h=461cab1de747f3842f27a5d24977d78d561d45f9

Signed-off-by: Dmitry Safonov <dima@arista.com>
---
 arch/x86/include/asm/processor.h |  5 +++++
 arch/x86/kernel/cpu/amd.c        | 28 +++++++++++++++-------------
 arch/x86/kernel/cpu/rdrand.c     |  1 +
 3 files changed, 21 insertions(+), 13 deletions(-)

diff --git a/arch/x86/include/asm/processor.h b/arch/x86/include/asm/processor.h
index 10b5355b323e..23c980697cc5 100644
--- a/arch/x86/include/asm/processor.h
+++ b/arch/x86/include/asm/processor.h
@@ -716,9 +716,14 @@ static __always_inline void amd_clear_divider(void)
 }
 
 extern void amd_check_microcode(void);
+extern int amd_try_clear_rdrand_cpuid(struct cpuinfo_x86 *c);
 #else
 static inline void amd_clear_divider(void)		{ }
 static inline void amd_check_microcode(void)		{ }
+static inline int amd_try_clear_rdrand_cpuid(struct cpuinfo_x86 *c)
+{
+	return 0;
+}
 #endif
 
 extern unsigned long arch_align_stack(unsigned long sp);
diff --git a/arch/x86/kernel/cpu/amd.c b/arch/x86/kernel/cpu/amd.c
index 2d9ae6ab1701..37a2ce19845a 100644
--- a/arch/x86/kernel/cpu/amd.c
+++ b/arch/x86/kernel/cpu/amd.c
@@ -808,22 +808,16 @@ static int __init rdrand_cmdline(char *str)
 }
 early_param("rdrand", rdrand_cmdline);
 
-static void clear_rdrand_cpuid_bit(struct cpuinfo_x86 *c)
+int amd_try_clear_rdrand_cpuid(struct cpuinfo_x86 *c)
 {
 	/*
 	 * Saving of the MSR used to hide the RDRAND support during
-	 * suspend/resume is done by arch/x86/power/cpu.c, which is
-	 * dependent on CONFIG_PM_SLEEP.
-	 */
-	if (!IS_ENABLED(CONFIG_PM_SLEEP))
-		return;
-
-	/*
+	 * suspend/resume is done by arch/x86/power/cpu.c
 	 * The self-test can clear X86_FEATURE_RDRAND, so check for
 	 * RDRAND support using the CPUID function directly.
 	 */
 	if (!(cpuid_ecx(1) & BIT(30)) || rdrand_force)
-		return;
+		return -1;
 
 	msr_clear_bit(MSR_AMD64_CPUID_FN_1, 62);
 
@@ -833,11 +827,17 @@ static void clear_rdrand_cpuid_bit(struct cpuinfo_x86 *c)
 	 */
 	if (cpuid_ecx(1) & BIT(30)) {
 		pr_info_once("BIOS may not properly restore RDRAND after suspend, but hypervisor does not support hiding RDRAND via CPUID.\n");
-		return;
+		return -1;
 	}
 
-	clear_cpu_cap(c, X86_FEATURE_RDRAND);
 	pr_info_once("BIOS may not properly restore RDRAND after suspend, hiding RDRAND via CPUID. Use rdrand=force to reenable.\n");
+	return 0;
+}
+
+static void clear_rdrand_cpuid(struct cpuinfo_x86 *c)
+{
+	if (!amd_try_clear_rdrand_cpuid(c))
+		clear_cpu_cap(c, X86_FEATURE_RDRAND);
 }
 
 static void init_amd_jg(struct cpuinfo_x86 *c)
@@ -847,7 +847,8 @@ static void init_amd_jg(struct cpuinfo_x86 *c)
 	 * across suspend and resume. Check on whether to hide the RDRAND
 	 * instruction support via CPUID.
 	 */
-	clear_rdrand_cpuid_bit(c);
+	if (IS_ENABLED(CONFIG_PM_SLEEP))
+		clear_rdrand_cpuid(c);
 }
 
 static void init_amd_bd(struct cpuinfo_x86 *c)
@@ -870,7 +871,8 @@ static void init_amd_bd(struct cpuinfo_x86 *c)
 	 * across suspend and resume. Check on whether to hide the RDRAND
 	 * instruction support via CPUID.
 	 */
-	clear_rdrand_cpuid_bit(c);
+	if (IS_ENABLED(CONFIG_PM_SLEEP))
+		clear_rdrand_cpuid(c);
 }
 
 static const struct x86_cpu_id erratum_1386_microcode[] = {
diff --git a/arch/x86/kernel/cpu/rdrand.c b/arch/x86/kernel/cpu/rdrand.c
index eeac00d20926..1075e18a75f6 100644
--- a/arch/x86/kernel/cpu/rdrand.c
+++ b/arch/x86/kernel/cpu/rdrand.c
@@ -43,6 +43,7 @@ void x86_init_rdrand(struct cpuinfo_x86 *c)
 		failure = true;
 
 	if (failure) {
+		amd_try_clear_rdrand_cpuid(c);
 		clear_cpu_cap(c, X86_FEATURE_RDRAND);
 		clear_cpu_cap(c, X86_FEATURE_RDSEED);
 		pr_emerg("RDRAND is not reliable on this platform; disabling.\n");

---
base-commit: 9974969c14031a097d6b45bcb7a06bb4aa525c40
change-id: 20260427-rdrand-cpubug-61ea6af6144c

Best regards,
-- 
Dmitry Safonov <dima@arista.com>

