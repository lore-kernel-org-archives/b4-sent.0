From: Joel Granados <j.granados@samsung.com>
Date: Mon, 02 Oct 2023 13:30:41 +0200
Subject: [PATCH v3 6/7] powerpc: Remove now superfluous sentinel element
 from ctl_table arrays
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231002-jag-sysctl_remove_empty_elem_arch-v3-6-606da2840a7a@samsung.com>
References: <20231002-jag-sysctl_remove_empty_elem_arch-v3-0-606da2840a7a@samsung.com>
In-Reply-To: <20231002-jag-sysctl_remove_empty_elem_arch-v3-0-606da2840a7a@samsung.com>
To: Luis Chamberlain <mcgrof@kernel.org>, willy@infradead.org, 
 josh@joshtriplett.org, Kees Cook <keescook@chromium.org>, 
 Iurii Zaikin <yzaikin@google.com>, Heiko Carstens <hca@linux.ibm.com>, 
 Vasily Gorbik <gor@linux.ibm.com>, 
 Alexander Gordeev <agordeev@linux.ibm.com>, 
 Christian Borntraeger <borntraeger@linux.ibm.com>, 
 Sven Schnelle <svens@linux.ibm.com>, 
 Gerald Schaefer <gerald.schaefer@linux.ibm.com>, 
 Russell King <linux@armlinux.org.uk>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Mark Rutland <mark.rutland@arm.com>, Thomas Gleixner <tglx@linutronix.de>, 
 Ingo Molnar <mingo@redhat.com>, Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, x86@kernel.org, 
 "H. Peter Anvin" <hpa@zytor.com>, Andy Lutomirski <luto@kernel.org>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, Guo Ren <guoren@kernel.org>, 
 Alexey Gladkov <legion@kernel.org>
Cc: linux-fsdevel@vger.kernel.org, linux-s390@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-riscv@lists.infradead.org, linuxppc-dev@lists.ozlabs.org, 
 linux-ia64@vger.kernel.org, linux-csky@vger.kernel.org, 
 Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13-dev-86aa5
X-Developer-Signature: v=1; a=openpgp-sha256; l=1565;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=KuV8vOJx81rEwsc5jJ+bbCdW5iZFLCnNJ5xlBjey6xs=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBlGqoUNBAj237epiMRWZjBh+ubamCISZESZIKcM
 v4wF3DSn2OJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZRqqFAAKCRC6l81St5ZB
 T/E4C/sH83tQjgttVLdKVarCnL42oaqUSOJFHysd1DsiW9k53qQQnsAXlsVqmHce59si1viwYD1
 sH8kJoCQVu5ZL6u9tnTirs/zK4lZGplOB1GmJ9G2GrDQ7BixLBRmvacBDYUehYBA7tw3zGUd7FE
 0us2Q0Ofke+qX+Aq9JR+UVjqxUoqi03EaBLXuFErDsGsAmhooB6D4ZI0rVHGdk22B9ACXaGfasi
 NvOx99FDQTiP3JolHAsOZjSYq4Oy/YDI5UDS0ERDATzQqvFlImM4MgIualdQl5wQHhfPnBjJJhR
 dnwS5MzD0E++5583ev51gUpQKRjAalnsN6549TOd2IdupjmILcpEaqD/tyIjjqcawm8ZLXpCGbX
 6Y9Qv8eSDL/Odbt+5yhXaeyHFpDsMB4SR9yDDiFgefg0A4DkcGiVGGn2Qm7iKkEY3A1fcz9QUZN
 YU/lcI5cnxARaCSGzjd+XwLHFHFyTjzB9ZJErDjBhYnwzz/H7M0JxdT3nEQwaAGkTTnZI=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel from powersave_nap_ctl_table and nmi_wd_lpm_factor_ctl_table.
This removal is safe because register_sysctl implicitly uses ARRAY_SIZE()
in addition to checking for the sentinel.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 arch/powerpc/kernel/idle.c                | 1 -
 arch/powerpc/platforms/pseries/mobility.c | 1 -
 2 files changed, 2 deletions(-)

diff --git a/arch/powerpc/kernel/idle.c b/arch/powerpc/kernel/idle.c
index b1c0418b25c8..30b56c67fa61 100644
--- a/arch/powerpc/kernel/idle.c
+++ b/arch/powerpc/kernel/idle.c
@@ -105,7 +105,6 @@ static struct ctl_table powersave_nap_ctl_table[] = {
 		.mode		= 0644,
 		.proc_handler	= proc_dointvec,
 	},
-	{}
 };
 
 static int __init
diff --git a/arch/powerpc/platforms/pseries/mobility.c b/arch/powerpc/platforms/pseries/mobility.c
index 0161226d8fec..1798f0f14d58 100644
--- a/arch/powerpc/platforms/pseries/mobility.c
+++ b/arch/powerpc/platforms/pseries/mobility.c
@@ -61,7 +61,6 @@ static struct ctl_table nmi_wd_lpm_factor_ctl_table[] = {
 		.mode		= 0644,
 		.proc_handler	= proc_douintvec_minmax,
 	},
-	{}
 };
 
 static int __init register_nmi_wd_lpm_factor_sysctl(void)

-- 
2.30.2

