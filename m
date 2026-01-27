From: Dmitry Safonov <dima@arista.com>
Date: Tue, 27 Jan 2026 14:21:13 +0000
Subject: [PATCH v3] ima_fs: Avoid creating measurement lists for
 unsupported hash algos
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260127-ima-oob-v3-1-1dd09f4c2a6a@arista.com>
X-B4-Tracking: v=1; b=H4sIANjJeGkC/3WNyw7CIBBFf6VhLaZAH+jK/zAuBjpYFi3N0BBN0
 38XujPG5UnuOXdjEcljZNdqY4TJRx/mDOpUMTvC/ETuh8xM1rKrhey5n4CHYPjFgVbQqWboDcv
 rhdD511G6PzIbiMgNwWzH4k8QV6QyHH1cA72PxyTK/DeeBBdcDo10qhEa2/4GlDU42zCxUk/yj
 yiz6JQGoa1ua+u+xH3fP3jSKJ/xAAAA
X-Change-ID: 20260127-ima-oob-9fa83a634d7b
To: Mimi Zohar <zohar@linux.ibm.com>, 
 Roberto Sassu <roberto.sassu@huawei.com>, 
 Dmitry Kasatkin <dmitry.kasatkin@gmail.com>, 
 Eric Snowberg <eric.snowberg@oracle.com>, Paul Moore <paul@paul-moore.com>, 
 James Morris <jmorris@namei.org>, "Serge E. Hallyn" <serge@hallyn.com>, 
 Silvia Sisinni <silvia.sisinni@polito.it>, 
 Enrico Bravi <enrico.bravi@polito.it>
Cc: linux-integrity@vger.kernel.org, linux-security-module@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Dmitry Safonov <0x7f454c46@gmail.com>, Dmitry Safonov <dima@arista.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769523678; l=6162;
 i=dima@arista.com; s=20250521; h=from:subject:message-id;
 bh=0sOqVBGUzXxUF/x1KV8ei9ehoXPsbfmVILKXs/dm3qI=;
 b=6Oe938tXgYfn5XA2flg3KJkYx5yIM2R+mkTsJ47I2H5OejG+aib56b2bSZNDkV6g+8pE1ijK7
 77K8hfut1hcB8eIsnm3BBdO8BN3G10R3WEH38P/nPNu2UC4/bce6lTk
X-Developer-Key: i=dima@arista.com; a=ed25519;
 pk=/z94x2T59rICwjRqYvDsBe0MkpbkkdYrSW2J1G2gIcU=
X-Endpoint-Received: by B4 Relay for dima@arista.com/20250521 with auth_id=405
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ima_init_crypto() skips initializing ima_algo_array[i] if the algorithm
from ima_tpm_chip->allocated_banks[i].crypto_id is not supported.
It seems avoid adding the unsupported algorithm to ima_algo_array will
break all the logic that relies on indexing by NR_BANKS(ima_tpm_chip).

On 6.12.40 I observe the following read out-of-bounds in hash_algo_name:

> ==================================================================
> BUG: KASAN: global-out-of-bounds in create_securityfs_measurement_lists+0x396/0x440
> Read of size 8 at addr ffffffff83e18138 by task swapper/0/1
>
> CPU: 4 UID: 0 PID: 1 Comm: swapper/0 Not tainted 6.12.40 #3
> Call Trace:
>  <TASK>
>  dump_stack_lvl+0x61/0x90
>  print_report+0xc4/0x580
>  ? kasan_addr_to_slab+0x26/0x80
>  ? create_securityfs_measurement_lists+0x396/0x440
>  kasan_report+0xc2/0x100
>  ? create_securityfs_measurement_lists+0x396/0x440
>  create_securityfs_measurement_lists+0x396/0x440
>  ima_fs_init+0xa3/0x300
>  ima_init+0x7d/0xd0
>  init_ima+0x28/0x100
>  do_one_initcall+0xa6/0x3e0
>  kernel_init_freeable+0x455/0x740
>  kernel_init+0x24/0x1d0
>  ret_from_fork+0x38/0x80
>  ret_from_fork_asm+0x11/0x20
>  </TASK>
>
> The buggy address belongs to the variable:
>  hash_algo_name+0xb8/0x420
>
> The buggy address belongs to the physical page:
> page: refcount:1 mapcount:0 mapping:0000000000000000 index:0x0 pfn:0x107ce18
> flags: 0x8000000000002000(reserved|zone=2)
> raw: 8000000000002000 ffffea0041f38608 ffffea0041f38608 0000000000000000
> raw: 0000000000000000 0000000000000000 00000001ffffffff 0000000000000000
> page dumped because: kasan: bad access detected
>
> Memory state around the buggy address:
>  ffffffff83e18000: 00 01 f9 f9 f9 f9 f9 f9 00 01 f9 f9 f9 f9 f9 f9
>  ffffffff83e18080: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
> >ffffffff83e18100: 00 00 00 00 00 00 00 f9 f9 f9 f9 f9 00 05 f9 f9
>                                         ^
>  ffffffff83e18180: f9 f9 f9 f9 00 00 00 00 00 00 00 04 f9 f9 f9 f9
>  ffffffff83e18200: 00 00 00 00 00 00 00 00 04 f9 f9 f9 f9 f9 f9 f9
> ==================================================================

Seems like the TPM chip supports sha3_256, which isn't yet in
tpm_algorithms:
> tpm tpm0: TPM with unsupported bank algorithm 0x0027

Grepping HASH_ALGO__LAST in security/integrity/ima/ shows that is
the check other logic relies on, so add files under TPM_ALG_<ID>
and print 0 as their hash_digest_size.

This is how it looks on the test machine I have:
> # ls -1 /sys/kernel/security/ima/
> ascii_runtime_measurements
> ascii_runtime_measurements_TPM_ALG_27
> ascii_runtime_measurements_sha1
> ascii_runtime_measurements_sha256
> binary_runtime_measurements
> binary_runtime_measurements_TPM_ALG_27
> binary_runtime_measurements_sha1
> binary_runtime_measurements_sha256
> policy
> runtime_measurements_count
> violations

Fixes: 9fa8e7625008 ("ima: add crypto agility support for template-hash algorithm")
Signed-off-by: Dmitry Safonov <dima@arista.com>
Cc: Enrico Bravi <enrico.bravi@polito.it>
Cc: Silvia Sisinni <silvia.sisinni@polito.it>
Cc: Roberto Sassu <roberto.sassu@huawei.com>
Cc: Mimi Zohar <zohar@linux.ibm.com>
---
Changes in v3:
- Now fix the spelling *for real* (sorry, messed it up in v2)
- Link to v2: https://lore.kernel.org/r/20260127-ima-oob-v2-1-f38a18c850cf@arista.com

Changes in v2:
- Instead of skipping unknown algorithms, add files under their TPM_ALG_ID (Roberto Sassu)
- Fix spelling (Roberto Sassu)
- Copy @stable on the fix
- Link to v1: https://lore.kernel.org/r/20260127-ima-oob-v1-1-2d42f3418e57@arista.com
---
 security/integrity/ima/ima_fs.c | 26 ++++++++++++++++++++------
 1 file changed, 20 insertions(+), 6 deletions(-)

diff --git a/security/integrity/ima/ima_fs.c b/security/integrity/ima/ima_fs.c
index 012a58959ff0..3b442e3f84d0 100644
--- a/security/integrity/ima/ima_fs.c
+++ b/security/integrity/ima/ima_fs.c
@@ -160,7 +160,10 @@ int ima_measurements_show(struct seq_file *m, void *v)
 	ima_putc(m, &pcr, sizeof(e->pcr));
 
 	/* 2nd: template digest */
-	ima_putc(m, e->digests[algo_idx].digest, hash_digest_size[algo]);
+	if (algo == HASH_ALGO__LAST)
+		ima_putc(m, "0", 1);
+	else
+		ima_putc(m, e->digests[algo_idx].digest, hash_digest_size[algo]);
 
 	/* 3rd: template name size */
 	namelen = !ima_canonical_fmt ? strlen(template_name) :
@@ -252,7 +255,10 @@ static int ima_ascii_measurements_show(struct seq_file *m, void *v)
 	seq_printf(m, "%2d ", e->pcr);
 
 	/* 2nd: template hash */
-	ima_print_digest(m, e->digests[algo_idx].digest, hash_digest_size[algo]);
+	if (algo == HASH_ALGO__LAST)
+		ima_putc(m, "0", 1);
+	else
+		ima_print_digest(m, e->digests[algo_idx].digest, hash_digest_size[algo]);
 
 	/* 3th:  template name */
 	seq_printf(m, " %s", template_name);
@@ -404,16 +410,24 @@ static int __init create_securityfs_measurement_lists(void)
 		char file_name[NAME_MAX + 1];
 		struct dentry *dentry;
 
-		sprintf(file_name, "ascii_runtime_measurements_%s",
-			hash_algo_name[algo]);
+		if (algo == HASH_ALGO__LAST)
+			sprintf(file_name, "ascii_runtime_measurements_TPM_ALG_%x",
+				ima_tpm_chip->allocated_banks[i].alg_id);
+		else
+			sprintf(file_name, "ascii_runtime_measurements_%s",
+				hash_algo_name[algo]);
 		dentry = securityfs_create_file(file_name, S_IRUSR | S_IRGRP,
 						ima_dir, (void *)(uintptr_t)i,
 						&ima_ascii_measurements_ops);
 		if (IS_ERR(dentry))
 			return PTR_ERR(dentry);
 
-		sprintf(file_name, "binary_runtime_measurements_%s",
-			hash_algo_name[algo]);
+		if (algo == HASH_ALGO__LAST)
+			sprintf(file_name, "binary_runtime_measurements_TPM_ALG_%x",
+				ima_tpm_chip->allocated_banks[i].alg_id);
+		else
+			sprintf(file_name, "binary_runtime_measurements_%s",
+				hash_algo_name[algo]);
 		dentry = securityfs_create_file(file_name, S_IRUSR | S_IRGRP,
 						ima_dir, (void *)(uintptr_t)i,
 						&ima_measurements_ops);

---
base-commit: 63804fed149a6750ffd28610c5c1c98cce6bd377
change-id: 20260127-ima-oob-9fa83a634d7b

Best regards,
-- 
Dmitry Safonov <dima@arista.com>

