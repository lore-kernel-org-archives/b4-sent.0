From: Joel Granados <j.granados@samsung.com>
Date: Thu, 28 Mar 2024 16:57:54 +0100
Subject: [PATCH 7/7] drivers: perf: Remove the now superfluous sentinel
 elements from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240328-jag-sysctl_remset_misc-v1-7-47c1463b3af2@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=941; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=x6LKxIed1g3mBTsVnM3LyyId0GhLgp5Sc+vsy/qx9t0=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGYFk8b3d2Da02YyON9nng/oh0az7TH1At0Oj
 Klqtpadz8QDfYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmBZPGAAoJELqXzVK3
 lkFPn8AL/RQuAkZvqODJOaCfSxnffeO8fIdKo3HY6jpLrbB1T2bwX+NMLubJdUp3yENm7YB8nRa
 WW22oyyDlvKBzvMdpZd+FKjXo7UBi7qchJGagofe3xiSIEGW50zF5NJDsM7ktMH5gzkhzIXDn2y
 zr/ABmufu4M7Zp2Wr9jVGv4y27IaAVDyFc4zrPnoSa0mN49bPR3NDQWuqqdYJEL6TmQnN2pKz1K
 wTPVnaqmhRdvr5Rjm7bltaHte6Bc8+h5J14i2UXK1jWSg1QYCATTJjpTGopxecIhWetPhrcfO1l
 3sSGhEU/sq2scZklB97vertazO6s46/yNljcLygRX2jL+HciVVcAOzhjZZMUQWAqUDPhCH5PQyL
 oF5sSgTDRjbTSNQpMGp+Zz4Le+f0MYjgkudGjGozgrNAA/i//Ct6jR22lj9qFmZGqe9IxsUEDiI
 mlqlj7Zr6yMfYyLS/gGgRPGvV1D6kyV9cMFEdPnBexcqwE/4lVrh9+wu+JqVoOoY6+a/ZCRcCN7
 k8=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which will
reduce the overall build time size of the kernel and run time memory
bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel from sbi_pmu_sysctl_table

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 drivers/perf/riscv_pmu_sbi.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/perf/riscv_pmu_sbi.c b/drivers/perf/riscv_pmu_sbi.c
index 8cbe6e5f9c39..5aef5a8737b2 100644
--- a/drivers/perf/riscv_pmu_sbi.c
+++ b/drivers/perf/riscv_pmu_sbi.c
@@ -1043,7 +1043,6 @@ static struct ctl_table sbi_pmu_sysctl_table[] = {
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_TWO,
 	},
-	{ }
 };
 
 static int pmu_sbi_device_probe(struct platform_device *pdev)

-- 
2.43.0

