From: Joel Granados <j.granados@samsung.com>
Date: Thu, 28 Mar 2024 16:57:52 +0100
Subject: [PATCH 5/7] ipc: Remove the now superfluous sentinel element from
 ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240328-jag-sysctl_remset_misc-v1-5-47c1463b3af2@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1263;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=JOrcDebyPdeQyVF1o8hVyIGZcNOEUHOhqgwA2b/7KxA=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGYFk8WY7+nF4T/aynBPi+a0SWAqJw+C58bGs
 dIDFmbETTURK4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmBZPFAAoJELqXzVK3
 lkFPtKYMAIWyicivuHYgLcu7kcoKi4dh5VzhBVmU1d1+zzEnR2f4BqPMWMLwExZKwt0v0rPf/iU
 VZqwFLCJUE4M6vX+VueRURT03H99gHyLgGMHwe5rlh/JUKiqlLQVzwaWCGrg4BG8jkIQgCXfv84
 gAArkvSzOc8a35wOKAMKVRINK7w4fuDO5JFG7WGw90+v5WSY50dXGOmigPWIbA7P+EsriFvVDlf
 N7UHpuSG0nytDxusQM71WHX2MxSQ+RTJgscogj75JzJehbmXTDZMtP/iGBTDfeaBRx0b7ETHJfh
 0a0bG+JnXuG4kxqxIV9k8fY5uQ94V09mvexhYMDSoOwKKWEHkwf7t26SYW4VgFtIFSEUyemvxmZ
 tf3YlaL8wMsdBYj/4fwIlc1m9N3DOPv57ze5SEt8ileyVjKISuOlfRioVbFCF+fqVHKqi9zScRs
 kqPhFL/gsIIeNp2Qv4tfJFyeHcFT20yhcmYz5E1RFipwOOD9XwQG8aCNvTZOZ00zy2zfSAJ8yU5
 s0=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which will
reduce the overall build time size of the kernel and run time memory
bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove the sentinels from ipc_sysctls and mq_sysctls

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 ipc/ipc_sysctl.c | 1 -
 ipc/mq_sysctl.c  | 1 -
 2 files changed, 2 deletions(-)

diff --git a/ipc/ipc_sysctl.c b/ipc/ipc_sysctl.c
index 45cb1dabce29..0867535af96f 100644
--- a/ipc/ipc_sysctl.c
+++ b/ipc/ipc_sysctl.c
@@ -178,7 +178,6 @@ static struct ctl_table ipc_sysctls[] = {
 		.extra2		= SYSCTL_INT_MAX,
 	},
 #endif
-	{}
 };
 
 static struct ctl_table_set *set_lookup(struct ctl_table_root *root)
diff --git a/ipc/mq_sysctl.c b/ipc/mq_sysctl.c
index 21fba3a6edaf..22ec532c7fa1 100644
--- a/ipc/mq_sysctl.c
+++ b/ipc/mq_sysctl.c
@@ -64,7 +64,6 @@ static struct ctl_table mq_sysctls[] = {
 		.extra1		= &msg_maxsize_limit_min,
 		.extra2		= &msg_maxsize_limit_max,
 	},
-	{}
 };
 
 static struct ctl_table_set *set_lookup(struct ctl_table_root *root)

-- 
2.43.0

