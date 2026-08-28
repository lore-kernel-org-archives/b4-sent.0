From: Johan Jonker <jbx6244@gmail.com>
Date: Sat, 29 Aug 2026 01:40:57 +0200
Subject: [PATCH] ARM: rockchip: smp: enable CPU1 for rk3066a
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260829-cpu-v1-1-33dca576db92@gmail.com>
X-B4-Tracking: v=1; b=H4sIAIgckmoC/x2Myw5AMBAAf0X2rAn19ivi0NZiD0p2EYn4d+U4m
 cncIMiEAm10A+NJQqsPkMYRuNn4CRUNgUEnukxq3Si3HcoVaW0HbGxeZRBKawSVZePd/LWLkR3
 5ExvjSNe/7/rneQFSUuj+bgAAAA==
To: Russell King <linux@armlinux.org.uk>, Heiko Stuebner <heiko@sntech.de>
Cc: linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?H=C3=BCseyin_BIYIK?= <boogiepop@gmx.com>, 
 Johan Jonker <jbx6244@gmail.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787960488; l=1108;
 i=jbx6244@gmail.com; s=20260824; h=from:subject:message-id;
 bh=Q4ZSXnEGPX/xMD0x0AdrlN53Gm6CKYRCS3MOUSLsunY=;
 b=Vw6eld+44Gh/khFTRVcv/sOa5YWLdfmEdWq01JtLn4DNUXt+gABYGzH9ZTyfxX2eCa+C2CNu0
 VDZe77oCt0WAimJY5KI+u9V3ya0gu5smP2WQO5UaK52asUC0kxxqc/7
X-Developer-Key: i=jbx6244@gmail.com; a=ed25519;
 pk=MK5Flx1ndjAF0uwXdNm8VvvoghD4KWCNd2hQE8QGyl0=
X-Endpoint-Received: by B4 Relay for jbx6244@gmail.com/20260824 with auth_id=971
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hüseyin BIYIK <boogiepop@gmx.com>

RK3066a CPU1 fails to come online. Fix by using
a similar mailbox construction as in use with
other Rockchip SoCs.

Signed-off-by: Hüseyin BIYIK <boogiepop@gmx.com>
Signed-off-by: Johan Jonker <jbx6244@gmail.com>
---
 arch/arm/mach-rockchip/platsmp.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/arch/arm/mach-rockchip/platsmp.c b/arch/arm/mach-rockchip/platsmp.c
index f659d894bfae..d7d080c29f3c 100644
--- a/arch/arm/mach-rockchip/platsmp.c
+++ b/arch/arm/mach-rockchip/platsmp.c
@@ -133,7 +133,8 @@ static int rockchip_boot_secondary(unsigned int cpu, struct task_struct *idle)
 	if (ret < 0)
 		return ret;
 
-	if (read_cpuid_part() != ARM_CPU_PART_CORTEX_A9) {
+	if (read_cpuid_part() != ARM_CPU_PART_CORTEX_A9 ||
+	    of_machine_is_compatible("rockchip,rk3066a")) {
 		/*
 		 * We communicate with the bootrom to active the cpus other
 		 * than cpu0, after a blob of initialize code, they will

---
base-commit: 2709dd5ae32f0828f386327c76bba9f39f63a1c6
change-id: 20260829-cpu-c518bde9b473

Best regards,
-- 
Johan Jonker <jbx6244@gmail.com>

