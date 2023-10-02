From: Joel Granados <j.granados@samsung.com>
Date: Mon, 02 Oct 2023 13:30:40 +0200
Subject: [PATCH v3 5/7] riscv: Remove now superfluous sentinel element from
 ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231002-jag-sysctl_remove_empty_elem_arch-v3-5-606da2840a7a@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1051;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=9kAdzbJ0epk3/P6EpAV9vd4QjpNqWvr+n+FA2hz33XU=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBlGqoUqzQP1ga/GoiJ0FClHtC0lD+GYjQLmhMIw
 G1+chIK9j6JAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZRqqFAAKCRC6l81St5ZB
 T8IJC/0aXv1UnFZ3T3wgTUKiHct/kuXoaLC4d8ZDBMbdNxt3Hju+Z0GvUVGvESI4+5BmjbKiCjI
 OEnLHgskb4UAwTZ//wbb0U3ij6vQ1u5zajvF7ViOx0F8h0Rc5ZF3eO5NQIGCVF7dm/01TLUPx9B
 SJTxpAQc7AAVf+Iepo1c8YPT+MZ2MS3an+30CfS7/N4vBeg0o0qAx1VOf5Ihzudw42VS0IYU9o7
 /1LEq92xg3EofmSBqdel0txihdsPFHX1w2sOoVOO90ES+0IL6EkLOfH1rgA8+/t/bd9Al1xxSQr
 sXufmyGj2nU9EV1Cprju+/HsFlFgXlVYvVq1fjdThtd2hq/jd08w2M0MSGTtpQwrzkQsrMd4uu7
 /HdpUWgSX8GyzVAgvtCLpJFHstU4EVN93y7tNGQezi1GAhg+CJHwTO3GcXzwUW7L0sUBNnSY4uY
 +khUbsBnsUzqYzHI/lYlxcFqilu/yYPcDPoEJsULfpVWj9i7DIxDXO3xAUaTzcw7JVThE=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel element from riscv_v_default_vstate_table. This removal
is safe because register_sysctl implicitly uses ARRAY_SIZE() in addition
to checking for the sentinel.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 arch/riscv/kernel/vector.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/arch/riscv/kernel/vector.c b/arch/riscv/kernel/vector.c
index 8d92fb6c522c..578b6292487e 100644
--- a/arch/riscv/kernel/vector.c
+++ b/arch/riscv/kernel/vector.c
@@ -255,7 +255,6 @@ static struct ctl_table riscv_v_default_vstate_table[] = {
 		.mode		= 0644,
 		.proc_handler	= proc_dobool,
 	},
-	{ }
 };
 
 static int __init riscv_v_sysctl_init(void)

-- 
2.30.2

