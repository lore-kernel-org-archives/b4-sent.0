From: Joel Granados <j.granados@samsung.com>
Date: Thu, 28 Mar 2024 16:57:49 +0100
Subject: [PATCH 2/7] security: Remove the now superfluous sentinel element
 from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240328-jag-sysctl_remset_misc-v1-2-47c1463b3af2@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2166;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=MMRfTm4NsPGzunc+jLCBGXNs5d6MSZ7h8iaXBibxUBo=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGYFk8R1UXVA6OVx01bpEwxUOhfTMICbrVR2h
 1f4SggspLYarIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmBZPEAAoJELqXzVK3
 lkFPOkcL/iL3V8wwR26L9QEsybs3FPUiCWjpFGJI5kszPVk0Stt5Whqa6ZRa3moK5yHXtROXmvH
 isu58CfDXlwnMMhjVDwBIJZd3E2mAxRS9baf5sTt0gDgfa0r546kRS/vV46bg4zIffFfucqpDvg
 0fbbU/XhggxQ1E6Q2Vx19634oyUaqMW6dcA8Eb+mcpWiNtSXYJE7P54ZWgiJ+2+Q/k9nz7bCClt
 sEf6hL/2xqZg+knPxHu9eD/l1KgNVEmSCLGALUzExhRUHlM0pbydHbqK2OYALSMv/PdEgBKs6Gc
 bcSJHtuhVAopg7QCAi5uPSAsV5kKgSCCSBm2lPmOMiK16fx+3Cjhbr6h8H6SHMOYdFj4mbWCd45
 LuweyC40jgWA9KA9AWJ5GbTqKDsNDBskuxjTGdV56ullhWNEauQL28puh5SoCK+byTFGBI4C3Zk
 idQbenpimWdJS+vXICzHjVOiMZZZeDcJN+nBisWSI5knBOJJhnflKNDQ1lTTBr8PkMV24lIia23
 HQ=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which will
reduce the overall build time size of the kernel and run time memory
bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove the sentinel from all files under security/ that register a
sysctl table.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 security/apparmor/lsm.c    | 1 -
 security/keys/sysctl.c     | 1 -
 security/loadpin/loadpin.c | 1 -
 security/yama/yama_lsm.c   | 1 -
 4 files changed, 4 deletions(-)

diff --git a/security/apparmor/lsm.c b/security/apparmor/lsm.c
index cef8c466af80..6239777090c4 100644
--- a/security/apparmor/lsm.c
+++ b/security/apparmor/lsm.c
@@ -2064,7 +2064,6 @@ static struct ctl_table apparmor_sysctl_table[] = {
 		.mode           = 0600,
 		.proc_handler   = apparmor_dointvec,
 	},
-	{ }
 };
 
 static int __init apparmor_init_sysctl(void)
diff --git a/security/keys/sysctl.c b/security/keys/sysctl.c
index b348e1679d5d..91f000eef3ad 100644
--- a/security/keys/sysctl.c
+++ b/security/keys/sysctl.c
@@ -66,7 +66,6 @@ static struct ctl_table key_sysctls[] = {
 		.extra2 = (void *) SYSCTL_INT_MAX,
 	},
 #endif
-	{ }
 };
 
 static int __init init_security_keys_sysctls(void)
diff --git a/security/loadpin/loadpin.c b/security/loadpin/loadpin.c
index 8e93cda130f1..93fd4d47b334 100644
--- a/security/loadpin/loadpin.c
+++ b/security/loadpin/loadpin.c
@@ -63,7 +63,6 @@ static struct ctl_table loadpin_sysctl_table[] = {
 		.extra1         = SYSCTL_ONE,
 		.extra2         = SYSCTL_ONE,
 	},
-	{ }
 };
 
 static void set_sysctl(bool is_writable)
diff --git a/security/yama/yama_lsm.c b/security/yama/yama_lsm.c
index 49dc52b454ef..b6684a074a59 100644
--- a/security/yama/yama_lsm.c
+++ b/security/yama/yama_lsm.c
@@ -463,7 +463,6 @@ static struct ctl_table yama_sysctl_table[] = {
 		.extra1         = SYSCTL_ZERO,
 		.extra2         = &max_scope,
 	},
-	{ }
 };
 static void __init yama_init_sysctl(void)
 {

-- 
2.43.0

