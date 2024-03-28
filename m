From: Joel Granados <j.granados@samsung.com>
Date: Thu, 28 Mar 2024 16:57:51 +0100
Subject: [PATCH 4/7] initrd: Remove the now superfluous sentinel element
 from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240328-jag-sysctl_remset_misc-v1-4-47c1463b3af2@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=936; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=dgUaKeQvY6Yod09xLYXFtRCigrPjq/BXAkqZRZrGl5Y=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGYFk8XUCfilPNsCftny+5XBz8vuxkpLL6JS7
 SCj0hqJr2zVAokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmBZPFAAoJELqXzVK3
 lkFPpf4L+wRgtVGVBHjTE3dn5OJC+qANHV6TvS+aBE93+XlWcxZos/8ML4JUmXrCqyDX+EjaEmt
 Bl1MIWQAVqLXLuV7NDHWaNzl/KaCn7lS4MToV9Ele72KR+KWBLrnjQ/I+5IQf/JDUlRkkrcBNbS
 552foz839UfCmsc3qOa6OcB6/xYB/gBK5DxflSgUd+Ziu6Ae7iaojNn+RGbv1ZDklEFh/f8/jpD
 UqCAWxXD2JyYCZsEEpmsCmkOQB8efRr99QTCROusfn8mUMush1Bxod1cPFXq4Fekw4ycYERCYdk
 T7vpnaafd/mbKKROVnW0INiF64qLruVon1sVyPP7Jz/t2QGRfmb6SFLwTjQweUjiOxn0HPXQchy
 EIundt+krY0mkCcBVyKC6gb5Uo5ccOPPvzY1kjXyAJhmVlp7vjnoX3aUdTxwrpov1YY2pPjzf8J
 YpUSnaTsAtN6NIWpJsNhma0X8Fa3853Wn+ZChtFx+TOxMj9f6Srzl8C2TOGe/baq643G4sE5nC6
 EY=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which will
reduce the overall build time size of the kernel and run time memory
bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel from kern_do_mounts_initrd_table.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 init/do_mounts_initrd.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/init/do_mounts_initrd.c b/init/do_mounts_initrd.c
index 425f4bcf4b77..22c7f41ff642 100644
--- a/init/do_mounts_initrd.c
+++ b/init/do_mounts_initrd.c
@@ -29,7 +29,6 @@ static struct ctl_table kern_do_mounts_initrd_table[] = {
 		.mode           = 0644,
 		.proc_handler   = proc_dointvec,
 	},
-	{ }
 };
 
 static __init int kernel_do_mounts_initrd_sysctls_init(void)

-- 
2.43.0

