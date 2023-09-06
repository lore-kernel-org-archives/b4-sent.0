From: Joel Granados <j.granados@samsung.com>
Date: Wed, 06 Sep 2023 12:03:29 +0200
Subject: [PATCH 8/8] c-sky: rm sentinel element from ctl_talbe array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230906-jag-sysctl_remove_empty_elem_arch-v1-8-3935d4854248@samsung.com>
References: <20230906-jag-sysctl_remove_empty_elem_arch-v1-0-3935d4854248@samsung.com>
In-Reply-To: <20230906-jag-sysctl_remove_empty_elem_arch-v1-0-3935d4854248@samsung.com>
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
 Christophe Leroy <christophe.leroy@csgroup.eu>, Guo Ren <guoren@kernel.org>
Cc: linux-fsdevel@vger.kernel.org, linux-s390@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-riscv@lists.infradead.org, linuxppc-dev@lists.ozlabs.org, 
 linux-ia64@vger.kernel.org, linux-csky@vger.kernel.org, 
 Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13-dev-86aa5
X-Developer-Signature: v=1; a=openpgp-sha256; l=980; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=7bf5/tJGBhUQ9WK71ygDU4S0n97i+v0/NjwZE0o5pgU=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBk+E6WREfxGpSEon2IoEhHuwmPhd3lTNK0oImor
 fAfRY0k+XKJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZPhOlgAKCRC6l81St5ZB
 TyDwC/9FZEUSgEzlF7Ci/QWFlhzpOZwTgs6G1qVsDC2AsbhA0jgrplsVHcwsNKyVlmGgQ5vfrta
 AH8fSSOEcSJfoy1ev1mzCDfYY+AwZD0Iy9ga2WQ2skPBd9sjsJmzzsq01zWuRA3K8vELOvAmw5X
 5wDlhgg73sM7bY5QFpAvBOUwA0iCDvesjkqvKzOcDtOI7UHvrhvA4aU707BZq6KxCZ2sjHNMG7/
 L0mYjBGd9aLOWanKzP6FdWafWJZVG1SXFRLtfhYGo1kAHi0uSOYPGzvhR0TCbXXWVgwaFfJgjyJ
 CIDqEL5JsAA1uo9NErYbwccIFdf77G8k2faRS0nqc9bwzQkHIYpauUZZgzHkq7RlWXiMx+wiIsX
 ZNw2x+uXfqg2gDOa2PUzENunfeKSWXRdUUbLHyvQylboT6rPMLIct3GIuYh6cpwNTkzK886rmRn
 7/5Cf/CQU1gWgoVV9rRFdJSkFrYISwOHblDUKSVegiC+VPuuYfY+EPVPZcrT2S+IYb74U=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel from alignment_tbl ctl_table array.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 arch/csky/abiv1/alignment.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/arch/csky/abiv1/alignment.c b/arch/csky/abiv1/alignment.c
index b60259daed1b..0d75ce7b0328 100644
--- a/arch/csky/abiv1/alignment.c
+++ b/arch/csky/abiv1/alignment.c
@@ -328,8 +328,7 @@ static struct ctl_table alignment_tbl[5] = {
 		.maxlen = sizeof(align_usr_count),
 		.mode = 0666,
 		.proc_handler = &proc_dointvec
-	},
-	{}
+	}
 };
 
 static int __init csky_alignment_init(void)

-- 
2.30.2

