From: Joel Granados <j.granados@samsung.com>
Date: Thu, 28 Mar 2024 16:57:53 +0100
Subject: [PATCH 6/7] io_uring: Remove the now superfluous sentinel elements
 from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240328-jag-sysctl_remset_misc-v1-6-47c1463b3af2@samsung.com>
References: <20240328-jag-sysctl_remset_misc-v1-0-47c1463b3af2@samsung.com>
In-Reply-To: <20240328-jag-sysctl_remset_misc-v1-0-47c1463b3af2@samsung.com>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Muchun Song <muchun.song@linux.dev>, Miaohe Lin <linmiaohe@huawei.com>, 
 Naoya Horiguchi <naoya.horiguchi@nec.com>, 
 John Johansen <john.johansen@canonical.com>, 
 Paul Moore <paul@paul-moore.com>, James Morris <jmorris@namei.org>, 
 "Serge E. Hallyn" <serge@hallyn.com>, David Howells <dhowells@redhat.com>, 
 Jarkko Sakkinen <jarkko@kernel.org>, Kees Cook <keescook@chromium.org>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Jens Axboe <axboe@kernel.dk>, 
 Pavel Begunkov <asml.silence@gmail.com>, 
 Atish Patra <atishp@atishpatra.org>, Anup Patel <anup@brainfault.org>, 
 Will Deacon <will@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>
Cc: Luis Chamberlain <mcgrof@kernel.org>, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 apparmor@lists.ubuntu.com, linux-security-module@vger.kernel.org, 
 keyrings@vger.kernel.org, linux-crypto@vger.kernel.org, 
 io-uring@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, 
 Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13-dev-2d940
X-Developer-Signature: v=1; a=openpgp-sha256; l=866; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=fE/NZmB4pRzGY5dsPYrxUBO9ZoOr+5OhzOId8tu7QTs=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGYFk8bmxZGot17fJWYqTrmMAyaWIBy9sBUWG
 aHGw/deIYoGrIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmBZPGAAoJELqXzVK3
 lkFPPqgL/j0Ld5LzYavMO9DP8fYz7mNmdGMwclTzF1+obs3fJGdIR8B/yld44GUGxZL131jYcMG
 rHpj3oVP4UfarmvGW9AI2OimEgbMMWPFc1ZmFkY/CrgzinI5TjytwY+i2r2AavTNWRMT7zcLAQf
 Vdq3FZfdbZ+JpLovP5iiwvyb2Cd96kkzD/e4Oa1nyGkxFYPOAxO80j4LDy7GfxL6+9UIIGGFZv4
 DaZKSWK1X2UrZOmVK1qgRXej8kHjlVxhl53AUNyQ+rFa5VbLRO405J68WgjMP32GJMISyVW57h5
 ocoprGgLHRyg4LpPfHIL4yohqv2RIyMpZPgpoTW5dpYZqFRcURac/bVmRZRQx5wpJjjEowDk45c
 H7nH57Hsk+EcGqekPtpXVg4vLZuvXOmv5CConYIlM2ttcTJItblMO8RCNiIqgE21QlZc99oAynV
 a/OGIOEYnrYir1BnHvhD/LINHxzOFzcChPE2iJr9kbQNFsz7wr+soDr8zShfiwcyJ1Ika8nd5s7
 ik=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which will
reduce the overall build time size of the kernel and run time memory
bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel element from kernel_io_uring_disabled_table

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 io_uring/io_uring.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/io_uring/io_uring.c b/io_uring/io_uring.c
index 5d4b448fdc50..fe3c93e21e2c 100644
--- a/io_uring/io_uring.c
+++ b/io_uring/io_uring.c
@@ -169,7 +169,6 @@ static struct ctl_table kernel_io_uring_disabled_table[] = {
 		.mode		= 0644,
 		.proc_handler	= proc_dointvec,
 	},
-	{},
 };
 #endif
 

-- 
2.43.0

