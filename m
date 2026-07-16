From: Jia Wang <wangjia@ultrarisc.com>
Date: Thu, 16 Jul 2026 14:47:10 +0800
Subject: [PATCH] riscv: require vmemmap for NUMA balancing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260716-numa_kconfig-v1-1-b0cd6d29accb@ultrarisc.com>
X-B4-Tracking: v=1; b=H4sIAG1+WGoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDc0Mz3bzS3MT47OT8vLTMdF1DI+NUU0tLA1NTizQloJaCotS0zAqwcdG
 xEH5xaVJWanIJyAyl2loApLKF33AAAAA=
X-Change-ID: 20260716-numa_kconfig-123e5990558f
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784184444; l=2137;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=zX7msVePD9cWH1tEIezrckJapIDNnZ2LJUbuDS1r9Mw=;
 b=+GzWBgzTf9QJL3KiJ+0unqSrHP/5cWqUcnSLsVPvDjP0JMqzlClZX+fwtSLZ5ee7lnb/pLJXQ
 E8jeyNr/Xc+CSPNQYXkrgYOgMVTUk+LOqUVA+iabCBNXn7oKeVb9wot
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

RISC-V randconfig can enable NUMA balancing while selecting
SPARSEMEM_EXTREME without SPARSEMEM_VMEMMAP. In that layout, the
section and node fields can consume enough page flag bits that
LAST_CPUPID cannot fit in page->flags.

The generic MM code then stores last_cpupid in struct page and emits
the "Unfortunate NUMA and NUMA Balancing config" warning from
mm/memory.c.

NUMA balancing needs LAST_CPUPID storage, but this fallback grows
struct page for a configuration that randconfig can select
accidentally. Keep NUMA support available, but advertise RISC-V NUMA
balancing support only when SPARSEMEM_VMEMMAP is enabled, where the
page flag layout leaves room for LAST_CPUPID.

This was originally seen with a RISC-V randconfig generated from
KCONFIG_SEED=550012.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
RISC-V randconfig can enable NUMA balancing with SPARSEMEM_EXTREME while
leaving SPARSEMEM_VMEMMAP disabled. In that layout, LAST_CPUPID may not
fit in page->flags, so the generic MM code falls back to growing struct
page and emits the "Unfortunate NUMA and NUMA Balancing config" warning.

Limit RISC-V NUMA balancing support to SPARSEMEM_VMEMMAP configurations.
This keeps NUMA available while preventing randconfig from selecting the
known-bad NUMA balancing layout.

The issue was originally seen with a RISC-V randconfig generated from
KCONFIG_SEED=550012.
---
 arch/riscv/Kconfig | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/riscv/Kconfig b/arch/riscv/Kconfig
index c0a6992933e4..681c5a2eb006 100644
--- a/arch/riscv/Kconfig
+++ b/arch/riscv/Kconfig
@@ -481,7 +481,7 @@ endchoice
 config NUMA
 	bool "NUMA Memory Allocation and Scheduler Support"
 	depends on SMP && MMU
-	select ARCH_SUPPORTS_NUMA_BALANCING
+	select ARCH_SUPPORTS_NUMA_BALANCING if SPARSEMEM_VMEMMAP
 	select GENERIC_ARCH_NUMA
 	select HAVE_SETUP_PER_CPU_AREA
 	select NEED_PER_CPU_EMBED_FIRST_CHUNK

---
base-commit: 37e2f878a7a660a216cc7a60459995fefd150f25
change-id: 20260716-numa_kconfig-123e5990558f

Best regards,
--  
Jia Wang <wangjia@ultrarisc.com>

