From: RoyalOughtness <secureblueadmin@proton.me>
Date: Tue, 13 Oct 2026 23:01:43 +0000
Subject: [PATCH] x86/bugs: Restore RETBleed IBRS selection for
 spectre_v2=on
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-x86-bugs-spectre-v2-on-retbleed-v1-1-e75a142da73e@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3NSwqDQBBF0a1IjVPQn6SJ2UrIwNYXUxBaqVIRx
 L2nyfBM7j3IoAKjR3OQYhOTqVT4S0P9pysjWIZqCi4k73zk/Z44r6OxzegXBW+Bp8KKJX+BgWO
 8dW1ODu3VUa3Mirfs/8PzdZ4/B3qS63EAAAA=
X-Change-ID: 20261013-x86-bugs-spectre-v2-on-retbleed-335a9b60e940
To: Thomas Gleixner <tglx@kernel.org>, Borislav Petkov <bp@alien8.de>, 
 Peter Zijlstra <peterz@infradead.org>, Josh Poimboeuf <jpoimboe@kernel.org>, 
 Pawan Gupta <pawan.kumar.gupta@linux.intel.com>, 
 Ingo Molnar <mingo@redhat.com>, Dave Hansen <dave.hansen@linux.intel.com>, 
 x86@kernel.org, "H. Peter Anvin" <hpa@zytor.com>, 
 David Kaplan <david.kaplan@amd.com>
Cc: linux-kernel@vger.kernel.org, 
 RoyalOughtness <secureblueadmin@proton.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791932515; l=4244;
 i=secureblueadmin@proton.me; s=20261013; h=from:subject:message-id;
 bh=aCZG3uVn68cfIUrC6OP+ITWWy5OPDLVQeT5hO/cdR6w=;
 b=97RbSkxGIZvddFgxKmiWEtQS5pSxB3YcAC3GWNjdyWR9sDBlXXe0tlyOLauelORZZoh7WB7rU
 zSwuJuOX37fBxwGsDSsHTHlnB1uo5iBgSaGxGMgIfhVyLejFy/QfMGP
X-Developer-Key: i=secureblueadmin@proton.me; a=ed25519;
 pk=YkW1KzRARgJdVL4mj0zvsoPS/dm7h0hk/X04eckj/xc=
X-Endpoint-Received: by B4 Relay for secureblueadmin@proton.me/20261013 with auth_id=1172
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On Intel CPUs which are affected by RETBleed and support IBRS but not
eIBRS, the Spectre v2 mitigation is switched from retpoline to IBRS,
because IBRS also mitigates RETBleed on these CPUs. Up to v6.15, the
default (SPECTRE_V2_CMD_AUTO) and spectre_v2=on (SPECTRE_V2_CMD_FORCE)
shared this selection.

The restructuring of the spectre_v2 mitigation moved the switch to IBRS
into spectre_v2_update_mitigation() and made it depend on
SPECTRE_V2_CMD_AUTO only. With spectre_v2=on these CPUs now stay on
retpoline, and retbleed_update_mitigation() then sets the RETBleed
mitigation to none:

  RETBleed: WARNING: Spectre v2 mitigation leaves CPU vulnerable to RETBleed attacks, data leaks possible!
  /sys/devices/system/cpu/vulnerabilities/retbleed:Vulnerable

The same system booted with spectre_v2=auto reports "Mitigation: IBRS".
So requesting the mitigation to be unconditionally enabled results in
weaker protection than the default, which contradicts the documented
meaning of spectre_v2=on.

Select IBRS for SPECTRE_V2_CMD_FORCE as well, as was done before the
restructuring.

Fixes: 480e803dacf8 ("x86/bugs: Restructure spectre_v2 mitigation")
Cc: stable@vger.kernel.org
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: RoyalOughtness <secureblueadmin@proton.me>
---
How this was found: secureblue, a distribution built on top of Fedora
Atomic, puts spectre_v2=on on the kernel command line. While auditing it
with an AI assistant (Claude Opus 5.5 in Claude Code), RETBleed was
reported as "Vulnerable" on an Intel Core i7-9750H, while spectre_v2=auto
on the same system reported "Mitigation: IBRS". The assistant traced this
to 480e803dacf8, wrote this patch and drafted the changelog. The
assistant also built the kernels and ran the tests below; I reviewed the
analysis, the change and the results.

Tested on tip/master 7abc52da724b with and without this patch, x86_64
defconfig, gcc 16.2.1. No build warnings, also none with W=1 for bugs.o.
Results are the "Spectre V2 :" and "RETBleed:" boot messages.

On real hardware, a KVM guest with -cpu host on an Intel Core i7-9750H
(Coffee Lake: IBRS, no eIBRS, affected by RETBleed), running a v7.2.9
based distribution kernel that does not modify bugs.c:

  spectre_v2=on                       Retpolines, RETBleed: Vulnerable
  spectre_v2=auto                     IBRS, RETBleed: Mitigation: IBRS
  spectre_v2=auto spectre_v2_user=on  IBRS, IBPB: always-on,
                                      RETBleed: Mitigation: IBRS

The last line is the state this patch gives spectre_v2=on. The patched
kernel itself was only booted under QEMU TCG.

QEMU TCG with -cpu Skylake-Client and setcpuid=ibrs, because TCG does
not expose IBRS:

                            unpatched                patched
  spectre_v2=on             Retpolines, Vulnerable   IBRS, IBRS
  spectre_v2=auto           IBRS, IBRS               IBRS, IBRS
  spectre_v2=on, no IBRS    Retpolines, Vulnerable   Retpolines, Vulnerable

Not tested: CPUs with eIBRS and non-Intel CPUs. The eIBRS and vendor
checks in spectre_v2_update_mitigation() are unchanged, so the patch
only affects CPUs where spectre_v2=auto already selects IBRS.

Until this is fixed, spectre_v2=auto spectre_v2_user=on gives affected
CPUs the result spectre_v2=on is meant to give.
---
 arch/x86/kernel/cpu/bugs.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/arch/x86/kernel/cpu/bugs.c b/arch/x86/kernel/cpu/bugs.c
index 000ebee2d..aec75b3e0 100644
--- a/arch/x86/kernel/cpu/bugs.c
+++ b/arch/x86/kernel/cpu/bugs.c
@@ -2236,7 +2236,8 @@ static void __init spectre_v2_select_mitigation(void)
 
 static void __init spectre_v2_update_mitigation(void)
 {
-	if (spectre_v2_cmd == SPECTRE_V2_CMD_AUTO &&
+	if ((spectre_v2_cmd == SPECTRE_V2_CMD_AUTO ||
+	     spectre_v2_cmd == SPECTRE_V2_CMD_FORCE) &&
 	    !spectre_v2_in_eibrs_mode(spectre_v2_enabled)) {
 		if (IS_ENABLED(CONFIG_MITIGATION_IBRS_ENTRY) &&
 		    boot_cpu_has_bug(X86_BUG_RETBLEED) &&

---
base-commit: 7abc52da724b95eee09c77a1da04c49aec6d31b7
change-id: 20261013-x86-bugs-spectre-v2-on-retbleed-335a9b60e940

Best regards,
-- 
RoyalOughtness <secureblueadmin@proton.me>

