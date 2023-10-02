From: Joel Granados <j.granados@samsung.com>
Date: Mon, 02 Oct 2023 13:30:39 +0200
Subject: [PATCH v3 4/7] x86/vdso: Remove now superfluous sentinel element
 from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231002-jag-sysctl_remove_empty_elem_arch-v3-4-606da2840a7a@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1052;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=cvzMuUejqMQP+BGPAXWnJqy+jCdRUm5VfxRP0+Qgc7g=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBlGqoT7g4+JWiQV8k/61XdOPQ2RonRomvKi5kxu
 mRiOWMGwOuJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZRqqEwAKCRC6l81St5ZB
 TzjdC/9fKc+Cn6prbqpjfusVIp8cAMfZKAPr4G3moB2aTF1BnakvXHfY7Wf9qwA/bzZeofKl7SL
 M1RA2NsVoOzzKzIwtzVeR1Kgk1eRKiCCLRhMJRzoIhlnBR3/jLV5ygVGxnehDO9QwyxuPBS7bH/
 n6q/KD3vIeim+dgRREVJhCB0KtJ0kkl7dDm9c+iXNgXuxzcE79yiM1ljMw3v887zH5IUulV62vj
 7u/dB2tzjJS5b8Nv8RHdLNWr41UUEXu34VNBYbeAZQ0IKyBb4NGS2n96ZuxpwbLIri3BIYaC8Tw
 SU3xeiJ2N98pVOgDSYA1ZcpyFFPmKSCPDBeaJ48w3mkpLW6BwYvYb2F6lqwTUzDKfNhkti7+nOK
 UnZy656UxYdqQ+D5YLCSK8yHkWSvy87yo/DFL3YDErBvdoUZftuyxuV1jvPf50fO8rFalb9YQ1N
 E9YxTE4f+PYvGFKRxMLF+jQGebqh+zmc2AcJX/3ETJb6Hcl/7hAJXaAHf8nsOaWQ0Wxcw=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel element from abi_table2. This removal is safe because
register_sysctl implicitly uses ARRAY_SIZE() in addition to checking for
the sentinel.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 arch/x86/entry/vdso/vdso32-setup.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/arch/x86/entry/vdso/vdso32-setup.c b/arch/x86/entry/vdso/vdso32-setup.c
index f3b3cacbcbb0..76e4e74f35b5 100644
--- a/arch/x86/entry/vdso/vdso32-setup.c
+++ b/arch/x86/entry/vdso/vdso32-setup.c
@@ -67,7 +67,6 @@ static struct ctl_table abi_table2[] = {
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
 	},
-	{}
 };
 
 static __init int ia32_binfmt_init(void)

-- 
2.30.2

