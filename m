From: Simon Schuster <schuster.simon@siemens-energy.com>
Date: Thu, 21 Aug 2025 12:37:07 +0200
Subject: [PATCH] nios2: ensure that memblock.current_limit is set when
 setting pfn limits
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250821-nios2-adjust-lowmem-bounds-v1-1-ea2dd8661ae5@siemens-energy.com>
X-B4-Tracking: v=1; b=H4sIANL2pmgC/x3MwQqDMAwA0F+RnA3UglD3K8NDZ9KZMVtpVhXEf
 1/x+C7vBOUsrPBoTsi8iUqKFV3bwDT7+GYUqgZrbG9c5zBKUouePkV/+E37wgu+Uomk2JOlwfl
 ggndQgzVzkOPOn+N1/QFbLef4bAAAAA==
X-Change-ID: 20250818-nios2-adjust-lowmem-bounds-5d2d98af0fa8
To: Dinh Nguyen <dinguyen@kernel.org>
Cc: linux-kernel@vger.kernel.org, 
 Simon Schuster <schuster.simon@siemens-energy.com>, 
 Andreas Oetken <andreas.oetken@siemens-energy.com>
X-Mailer: b4 0.14.3-dev-2ce6c
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755772650; l=2529;
 i=schuster.simon@siemens-energy.com; s=20250818; h=from:subject:message-id;
 bh=XAavluzVGgOGPX323zI/x3pk1jtcKLayQnaSWVVemI4=;
 b=GcI81uCNpdeGjwM6REZsMNAj6DwIQzDGRCbchylCEARbO7bSUHPyscSO5GSDw63uq9NqcCk20
 zGrVRHgILeSCebLJY4VTfGDt6FGAlApBgqOENV2dbv+4T0ZzTkxcKWz
X-Developer-Key: i=schuster.simon@siemens-energy.com; a=ed25519;
 pk=PUhOMiSp43aSeRE1H41KApxYOluamBFFiMfKlBjocvo=
X-Endpoint-Received: by B4 Relay for schuster.simon@siemens-energy.com/20250818 with auth_id=495
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On nios2, with CONFIG_FLATMEM set, the kernel relies on
memblock_get_current_limit() to determine the limits of mem_map, in
particular for max_low_pfn.
Unfortunately, memblock.current_limit is only default initialized to
MEMBLOCK_ALLOC_ANYWHERE at this point of the bootup, potentially leading
to situations where max_low_pfn can erroneously exceed the value of
max_pfn and, thus, the valid range of available DRAM.

This can in turn cause kernel-level paging failures, e.g.:

[   76.900000] Unable to handle kernel paging request at virtual address 20303000
[   76.900000] ea = c0080890, ra = c000462c, cause = 14
[   76.900000] Kernel panic - not syncing: Oops
[   76.900000] ---[ end Kernel panic - not syncing: Oops ]---

This patch fixes this by pre-calculating memblock.current_limit
based on the upper limits of the available memory ranges via
adjust_lowmem_bounds, a simplified version of the equivalent
implementation within the arm architecture.

Signed-off-by: Simon Schuster <schuster.simon@siemens-energy.com>
Signed-off-by: Andreas Oetken <andreas.oetken@siemens-energy.com>
---
This patch was tested internally on 5.10.x stable for some time now and
applies and boots cleanly on next-20250815, as well.
---
 arch/nios2/kernel/setup.c | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/arch/nios2/kernel/setup.c b/arch/nios2/kernel/setup.c
index 2a40150142c3..f43f01c4ab93 100644
--- a/arch/nios2/kernel/setup.c
+++ b/arch/nios2/kernel/setup.c
@@ -142,6 +142,20 @@ static void __init find_limits(unsigned long *min, unsigned long *max_low,
 	*max_high = PFN_DOWN(memblock_end_of_DRAM());
 }
 
+static void __init adjust_lowmem_bounds(void)
+{
+	phys_addr_t block_start, block_end;
+	u64 i;
+	phys_addr_t memblock_limit = 0;
+
+	for_each_mem_range(i, &block_start, &block_end) {
+		if (block_end > memblock_limit)
+			memblock_limit = block_end;
+	}
+
+	memblock_set_current_limit(memblock_limit);
+}
+
 void __init setup_arch(char **cmdline_p)
 {
 	console_verbose();
@@ -157,6 +171,7 @@ void __init setup_arch(char **cmdline_p)
 	/* Keep a copy of command line */
 	*cmdline_p = boot_command_line;
 
+	adjust_lowmem_bounds();
 	find_limits(&min_low_pfn, &max_low_pfn, &max_pfn);
 
 	memblock_reserve(__pa_symbol(_stext), _end - _stext);

---
base-commit: 1357b2649c026b51353c84ddd32bc963e8999603
change-id: 20250818-nios2-adjust-lowmem-bounds-5d2d98af0fa8

Best regards,
-- 
Simon Schuster <schuster.simon@siemens-energy.com>

