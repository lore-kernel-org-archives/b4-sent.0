From: Joel Granados <j.granados@samsung.com>
Date: Wed, 13 Sep 2023 11:10:58 +0200
Subject: [PATCH v2 4/8] x86/vdso: Remove now superfluous sentinel element
 from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230913-jag-sysctl_remove_empty_elem_arch-v2-4-d1bd13a29bae@samsung.com>
References: <20230913-jag-sysctl_remove_empty_elem_arch-v2-0-d1bd13a29bae@samsung.com>
In-Reply-To: <20230913-jag-sysctl_remove_empty_elem_arch-v2-0-d1bd13a29bae@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1118;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=mobvr+1RgXQsfarnPqkIwzTWvcFKWXaq/pj/RSIk4eU=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBlAXy+NsgXY5S9mwVEQGhj4lM9wRuJzSo3tbcRP
 WD9kEpUcv+JAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZQF8vgAKCRC6l81St5ZB
 TxObC/9Z4dNEvfnMP1bUXWKfUoJirbjQe+i6TcQ6EY2ZoXS0+6CjRcjGOnh11RNPS4YBwzf6u+O
 mXPr1yV6j5IazDCs+LXcgb7XhWpvHgGOE4+DuAXD/hvf+fDEKkSYxxFmJXLNtk/PQ9e+8NGxQUx
 7kwnx9OpemaKoBQpRVr7M/Nodalu52YPoyNwE377qdVdES+l0p9lUzR+019muavTD6q3IEhV17b
 sJAQhhOzSSySjyIAX/+tvd7NS3cBfT0tk9NaoKeg9wtyNkcedTqKgUg5Z6pPi7wq26YSI5cizb1
 aIKJtE/YvtJDkq/qkbYjon4fMarirUWNOxO5BO9EzR4zihF+QxTYMTw4fdHO7uTeWxxvHXIAUpX
 EenIpLPD2kxY1m2yuSvY+gQ0tQDPtHZ/vpF3ZB08YDZYJ2ra4dHQ37KlDSsrjCjXLdBbZAzC75x
 mwBVBmEnYN4uf9TFa8H3zRLf+nlvlG7jNFi7QFKWEEVI8pTKMXEKALUjbeRpCzok85jHQ=
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
 arch/x86/entry/vdso/vdso32-setup.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/arch/x86/entry/vdso/vdso32-setup.c b/arch/x86/entry/vdso/vdso32-setup.c
index f3b3cacbcbb0..37b761802181 100644
--- a/arch/x86/entry/vdso/vdso32-setup.c
+++ b/arch/x86/entry/vdso/vdso32-setup.c
@@ -66,8 +66,7 @@ static struct ctl_table abi_table2[] = {
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
-	},
-	{}
+	}
 };
 
 static __init int ia32_binfmt_init(void)

-- 
2.30.2

