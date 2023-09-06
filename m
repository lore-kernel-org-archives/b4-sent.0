From: Joel Granados <j.granados@samsung.com>
Date: Wed, 06 Sep 2023 12:03:24 +0200
Subject: [PATCH 3/8] arch/x86: Remove sentinel elem from ctl_table arrays
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230906-jag-sysctl_remove_empty_elem_arch-v1-3-3935d4854248@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1462;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=zE8VMMPVQAIy8aYws+rz9C7nboCop5JGzS4P9YCQBl8=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBk+E6UOpNP14i3hne/osuimerfTGC3syLUxLuIE
 wJnpVtSWo2JAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZPhOlAAKCRC6l81St5ZB
 Ty+ADACIdkG3Hd7tMm/sgfnkWqZQ41Yqd4IqdWF3+e/5NOpevgoE/o35ullHAkd+2+l54Gro3re
 805skkVS7qQpu0GSacvMb47Ph0nmJsJ/3t+fQxhqRqfQZlhrqDpTY3sJYdbls932x0mXiXdRePW
 onZGnYDxlkWQlKKOjPUAdV8ydzH8RRVhEibZfi/O9W/oqOCvySZGu3WH/frsjAvYcR5m9xeYOV1
 sWc6C293qC6bApVsEyywLxZb6a/FO+J3R5mFpq8AEIoKH5HLwQe7kj8DbPLQ7Hy8OVR6Xg5cXFr
 17bCYjl2uGbwXx90Zeg8x1lmyvF86/CWj6u+wrPIyXxT99cq6GWFGsIzA62RT+vtmiqa51QrniI
 27jCQay0zabmB/WRkRMcq6n2I7Lt6wGJ0g/i7gI3MfBBqi/cpAtcvde3NNHcGoZoDKvnPY3bhSB
 dQdCAAKz/tFS678n2zpX68mI+DJnUxqI/EweCEX18IdWgPBEkYQ0iOIhXhO/XiPyrsM/g=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel element from sld_sysctl and itmt_kern_table.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 arch/x86/kernel/cpu/intel.c | 3 +--
 arch/x86/kernel/itmt.c      | 3 +--
 2 files changed, 2 insertions(+), 4 deletions(-)

diff --git a/arch/x86/kernel/cpu/intel.c b/arch/x86/kernel/cpu/intel.c
index be4045628fd3..e63391b82624 100644
--- a/arch/x86/kernel/cpu/intel.c
+++ b/arch/x86/kernel/cpu/intel.c
@@ -1015,8 +1015,7 @@ static struct ctl_table sld_sysctls[] = {
 		.proc_handler	= proc_douintvec_minmax,
 		.extra1         = SYSCTL_ZERO,
 		.extra2         = SYSCTL_ONE,
-	},
-	{}
+	}
 };
 
 static int __init sld_mitigate_sysctl_init(void)
diff --git a/arch/x86/kernel/itmt.c b/arch/x86/kernel/itmt.c
index ee4fe8cdb857..5f2ccff38297 100644
--- a/arch/x86/kernel/itmt.c
+++ b/arch/x86/kernel/itmt.c
@@ -73,8 +73,7 @@ static struct ctl_table itmt_kern_table[] = {
 		.proc_handler	= sched_itmt_update_handler,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
-	},
-	{}
+	}
 };
 
 static struct ctl_table_header *itmt_sysctl_header;

-- 
2.30.2

