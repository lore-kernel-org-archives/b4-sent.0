From: David Heidelberg <david@ixit.cz>
Date: Fri, 21 Mar 2025 21:48:43 +0100
Subject: [PATCH v3 1/7] x86/Kconfig: Enable X86_X2APIC by default and
 improve help text
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250321-x86_x2apic-v3-1-b0cbaa6fa338@ixit.cz>
References: <20250321-x86_x2apic-v3-0-b0cbaa6fa338@ixit.cz>
In-Reply-To: <20250321-x86_x2apic-v3-0-b0cbaa6fa338@ixit.cz>
To: Thomas Gleixner <tglx@linutronix.de>, Ingo Molnar <mingo@redhat.com>, 
 Borislav Petkov <bp@alien8.de>, Dave Hansen <dave.hansen@linux.intel.com>, 
 x86@kernel.org, "H. Peter Anvin" <hpa@zytor.com>, 
 Kees Cook <kees@kernel.org>, Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: linux-kernel@vger.kernel.org, Ingo Molnar <mingo@kernel.org>, 
 linux-iio@vger.kernel.org, 
 =?utf-8?q?Mateusz_Jo=C5=84czyk?= <mat.jonczyk@o2.pl>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4973; i=david@ixit.cz;
 h=from:subject:message-id; bh=a9HTfOr2lzvGamzwVwClUGQQDyIsU1IE/XeFaMhNH7o=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn3dCu7PcJ8ZnpTOlCAfTY2brG3A6Z8ExtyTrA2
 nUT0mvsrnqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ93QrgAKCRBgAj/E00kg
 cqFbEACnBDsRY6QVE/dtZrOklQ1NSlLF0Rcyb7OwtbthuMy8lznPBITETuxak868zdMEBKmiXJy
 iZTqKiki0fPSyh635Xdogfhq0mi6YU9bBCAEKg2gzXxILjQIKwexqQfMY9mmJ1jKYlMYlvofd2b
 4nzgWCeQie6jB/z5Htkwvq4V6REAuMoPPaKHCEJox+Gr15Ejt4TCNdeaExi+df4WRLsrjr2gc3/
 Et73cD4ckPRYykEOGCuTnLSC1BorIxPHUe327gQiJnH4XALg9OcDu8LUAPSe5qhJdyypZYYQuwE
 I3g8rMrUJLGGVH7Sr0fLdQWaenF5ZZnEUUc9/FKcHHBaVjHULb6sxTu2ktKNQUL/9WUBbBXeM1H
 Qv7wBsJhMxRhVGiFFy+aJ4dNX23GFnt26MJVftitD5YCXAOPVcRB72SC/OZbQtIYpbBP3GlyvPO
 xWdjyHdbuXG5ZNccSvcF5wPZwqg31fHGuBbGicNnxcdSYmRAATE+D66dqctRvTUEmWiT5s6C+Hn
 kpQD1kg4CNt6NLMgD+OsFqjktOUo8Yyfa8UHlFCJJEEIDA4V7St/TsGZ+7Zb0E5V7u63HlZ7KrV
 FsJAoLImX0wlK8oqMHvS8D2QlqQF0rfND3+3fG2DCtNGW8gGtMAOGKoeASQVxCcYOO2cZL7qvDQ
 FWMp9HRiJ66sDIQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Mateusz Jończyk <mat.jonczyk@o2.pl>

As many current platforms (most modern Intel CPUs and QEMU) have x2APIC
present, enable CONFIG_X86_X2APIC by default as it gives performance
and functionality benefits. Additionally, if the BIOS has already
switched APIC to x2APIC mode, but CONFIG_X86_X2APIC is disabled, the
kernel will panic in arch/x86/kernel/apic/apic.c .

Also improve the help text, which was confusing and really did not
describe what the feature is about.

Help text references and discussion:

Both Intel [1] and AMD [3] spell the name as "x2APIC", not "x2apic".

"It allows faster access to the local APIC"
        [2], chapter 2.1, page 15:
        "More efficient MSR interface to access APIC registers."

"x2APIC was introduced in Intel CPUs around 2008":
        I was unable to find specific information which Intel CPUs
        support x2APIC. Wikipedia claims it was "introduced with the
        Nehalem microarchitecture in November 2008", but I was not able
        to confirm this independently. At least some Nehalem CPUs do not
        support x2APIC [1].

        The documentation [2] is dated June 2008. Linux kernel also
        introduced x2APIC support in 2008, so the year seems to be
        right.

"and in AMD EPYC CPUs in 2019":
        [3], page 15:
        "AMD introduced an x2APIC in our EPYC 7002 Series processors for
        the first time."

"It is also frequently emulated in virtual machines, even when the host
CPU does not support it."
        [1]

"If this configuration option is disabled, the kernel will not boot on
some platforms that have x2APIC enabled."
        According to some BIOS documentation [4], the x2APIC may be
        "disabled", "enabled", or "force enabled" on this system.
        I think that "enabled" means "made available to the operating
        system, but not already turned on" and "force enabled" means
        "already switched to x2APIC mode when the OS boots". Only in the
        latter mode a kernel without CONFIG_X86_X2APIC will panic in
        validate_x2apic() in arch/x86/kernel/apic/apic.c .

	QEMU 4.2.1 and my Intel HP laptop (bought in 2019) use the
	"enabled" mode and the kernel does not panic.

[1] "Re: [Qemu-devel] [Question] why x2apic's set by default without host sup"
        https://lists.gnu.org/archive/html/qemu-devel/2013-07/msg03527.html

[2] Intel® 64 Architecture x2APIC Specification,
        ( https://www.naic.edu/~phil/software/intel/318148.pdf )

[3] Workload Tuning Guide for AMD EPYC ™ 7002 Series Processor Based
        Servers Application Note,
        https://developer.amd.com/wp-content/resources/56745_0.80.pdf

[4] UEFI System Utilities and Shell Command Mobile Help for HPE ProLiant
        Gen10, ProLiant Gen10 Plus Servers and HPE Synergy:
        Enabling or disabling Processor x2APIC Support
        https://techlibrary.hpe.com/docs/iss/proliant-gen10-uefi/s_enable_disable_x2APIC_support.html

Signed-off-by: Mateusz Jończyk <mat.jonczyk@o2.pl>
---
 arch/x86/Kconfig | 25 ++++++++++++++++---------
 1 file changed, 16 insertions(+), 9 deletions(-)

diff --git a/arch/x86/Kconfig b/arch/x86/Kconfig
index 5924c753097b0030fddeba246c72ff8b86e6c8ae..10f48afd67f6fd7d250f2effddcc5bc927b057af 100644
--- a/arch/x86/Kconfig
+++ b/arch/x86/Kconfig
@@ -462,20 +462,27 @@ config SMP
 	  If you don't know what to do here, say N.
 
 config X86_X2APIC
-	bool "Support x2apic"
+	bool "x2APIC interrupt controller architecture support"
 	depends on X86_LOCAL_APIC && X86_64 && (IRQ_REMAP || HYPERVISOR_GUEST)
+	default y
 	help
-	  This enables x2apic support on CPUs that have this feature.
+	  x2APIC is an interrupt controller architecture, a component of which
+	  (the local APIC) is present in the CPU. It allows faster access to
+	  the local APIC and supports a larger number of CPUs in the system
+	  than the predecessors.
 
-	  This allows 32-bit apic IDs (so it can support very large systems),
-	  and accesses the local apic via MSRs not via mmio.
+	  x2APIC was introduced in Intel CPUs around 2008 and in AMD EPYC CPUs
+	  in 2019, but it can be disabled by the BIOS. It is also frequently
+	  emulated in virtual machines, even when the host CPU does not support
+	  it. Support in the CPU can be checked by executing
+		cat /proc/cpuinfo | grep x2apic
 
-	  Some Intel systems circa 2022 and later are locked into x2APIC mode
-	  and can not fall back to the legacy APIC modes if SGX or TDX are
-	  enabled in the BIOS. They will boot with very reduced functionality
-	  without enabling this option.
+	  If this configuration option is disabled, the kernel will not boot on
+	  some platforms that have x2APIC enabled.
 
-	  If you don't know what to do here, say N.
+	  Say N if you know that your platform does not have x2APIC.
+
+	  Otherwise, say Y.
 
 config X86_POSTED_MSI
 	bool "Enable MSI and MSI-x delivery by posted interrupts"

-- 
2.49.0

