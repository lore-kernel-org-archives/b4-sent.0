From: Joel Granados <j.granados@samsung.com>
Date: Wed, 06 Sep 2023 12:03:28 +0200
Subject: [PATCH 7/8] ia64: Remove sentinel element from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230906-jag-sysctl_remove_empty_elem_arch-v1-7-3935d4854248@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=904; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=KVD0r38Cili5TZDRzSBYSSUVuCqs3hfxf9D58EVeiJs=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBk+E6WE//Xcwga/1NK2RLvtOot92IMQidneKT5p
 v+BAfqJ9cuJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZPhOlgAKCRC6l81St5ZB
 TydxC/9h8/rccF341foOCgTiAME0wS/e9CbIyL0MBWHLnGQcnYp+RhqdOL0GqHAz726Be1j15kO
 v6YfgptJJw0OJvMP2WWim+xDgOYuBwfWffbIOEjiAZuahyU2itf1YdleanEZfHhbUqci//oJqSh
 0ajDFBrA+FJKGxCR89VZ01mvGJI5OzswbPnBN32NY4P6KwIE5UoxBLOyxfcT7EtwIQWKpqTk8Pk
 Tulducj2tt8/hPjMNRJetxGELK6ZaYDuLeG7JX3IXgv06/gZXR08QuTLJXmTBEC7oy80w8isUKr
 hY3CrAwd+3lFltSZdYchIvP73k94L3GvSEJz/G4tAoYa/ULVVQw5ClmPo4Se9AmCl7KWNCFFxk3
 YU67Wru1bC8mqE+BTU32baxgXb4PMz/bRGO5NXF5C2K7CYClJy4ZobHb94Ib7QdkgbMhGjwyBoE
 AxKe/dAVVCRcQ7EK66c3SmG+78AEf84jHaVHhmR0xjp7NumHR5XRJFCWi13YS3+jpgjhc=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel from kdump_ctl_table.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 arch/ia64/kernel/crash.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/arch/ia64/kernel/crash.c b/arch/ia64/kernel/crash.c
index 88b3ce3e66cd..fbf8893a570c 100644
--- a/arch/ia64/kernel/crash.c
+++ b/arch/ia64/kernel/crash.c
@@ -231,8 +231,7 @@ static struct ctl_table kdump_ctl_table[] = {
 		.maxlen = sizeof(int),
 		.mode = 0644,
 		.proc_handler = proc_dointvec,
-	},
-	{ }
+	}
 };
 #endif
 

-- 
2.30.2

