From: Joel Granados <j.granados@samsung.com>
Date: Thu, 28 Mar 2024 16:57:50 +0100
Subject: [PATCH 3/7] crypto: Remove the now superfluous sentinel element
 from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240328-jag-sysctl_remset_misc-v1-3-47c1463b3af2@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=843; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=PsRDF4iHKhFg1x0ZSp/XUca2d9GI60WeSwOtfnTJcKU=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGYFk8Sn6Fir1TrXxzcrJeA20C4FmUqvYJhos
 nJVoW2ScjI/aIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmBZPEAAoJELqXzVK3
 lkFPCAQL/0dpS5DBrYR+5mZqJK2pQcAA0QQqBm8y2Tq391CKvm30tew2wtkScDHoRiyul8QyzWC
 D5/YpkG8dWaCHAkj+HOhXbtB8Rfi/cf4BchHZ0+cRj41OMxCePLa+yG5/nfgar5oc2nXN2gcrYK
 ntIUgfJExh6PEDQXr6Xk4RK675RUtgLxch2ojMfz4S3qe9J4DmkUPtR+VQs52+lmteyOBMwdh8/
 DgmBLGsimvyq20RbSHwzZRPUwk7y6YTCDhKz6oLyB97eOjbuarD4FwBd1nLHwpS1su80Ul8kYu4
 OmnEs9ucp2Ne9WIybw3frLNgnmJRfjHa3nQalXpp7yFOENLnS9QK2RvrYCmjKIep2FZIA7t5Jvr
 0Iod9HPfrNohN1XK0AjqT+ihZTjhFd8fSHnf2YnS/oSYtZf1kJuljhIFoLNl3PKVsRUHhhUHlHC
 dW+jquu6DydspJi9zZEyoeHoSbs1S2+5jvkBGfrXYVn8pQWjKMpvfOWKuIw6sqQuxre2VZIjR26
 SY=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which will
reduce the overall build time size of the kernel and run time memory
bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel from crypto_sysctl_table

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 crypto/fips.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/crypto/fips.c b/crypto/fips.c
index 92fd506abb21..8a784018ebfc 100644
--- a/crypto/fips.c
+++ b/crypto/fips.c
@@ -63,7 +63,6 @@ static struct ctl_table crypto_sysctl_table[] = {
 		.mode		= 0444,
 		.proc_handler	= proc_dostring
 	},
-	{}
 };
 
 static struct ctl_table_header *crypto_sysctls;

-- 
2.43.0

