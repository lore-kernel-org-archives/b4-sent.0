From: Dmitry Safonov <dima@arista.com>
Date: Tue, 27 Jan 2026 03:05:47 +0000
Subject: [PATCH] ima_fs: Avoid creating measurement lists for unsupported
 hash algos
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260127-ima-oob-v1-1-2d42f3418e57@arista.com>
X-B4-Tracking: v=1; b=H4sIAIoreGkC/x3MQQqDQAyF4atI1gZ0lLHtVaSLjBNrFs6URIog3
 t2xyw/+9w4wVmGDV3WA8k9Mcipo6wqmhdKHUWIxuMb5pnUDykqYc8DnTI+OfNfHIUCpv8qz7P+
 n8V0cyBiDUpqWe7+SbaxwnhevFZN9cgAAAA==
X-Change-ID: 20260127-ima-oob-9fa83a634d7b
To: Mimi Zohar <zohar@linux.ibm.com>, 
 Roberto Sassu <roberto.sassu@huawei.com>, 
 Dmitry Kasatkin <dmitry.kasatkin@gmail.com>, 
 Eric Snowberg <eric.snowberg@oracle.com>, Paul Moore <paul@paul-moore.com>, 
 James Morris <jmorris@namei.org>, "Serge E. Hallyn" <serge@hallyn.com>, 
 Silvia Sisinni <silvia.sisinni@polito.it>, 
 Enrico Bravi <enrico.bravi@polito.it>
Cc: linux-integrity@vger.kernel.org, linux-security-module@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dmitry Safonov <0x7f454c46@gmail.com>, 
 Dmitry Safonov <dima@arista.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769483167; l=3581;
 i=dima@arista.com; s=20250521; h=from:subject:message-id;
 bh=c+A1wVTblU3Pa0pnPVfuEEFYkjoaAOyomgx0XFJM0mw=;
 b=pSgR7v4OOF6hVP4J6eiaNzfI8UORA86wojK8puty4pIe0NC8rzcIo6Q3HUDBNlvDLQaavjIv1
 GcKOa6qXOS7A+NoSOy31MinrqTkD/FAPYeOlqJDqQe1gupg6xzm8wLH
X-Developer-Key: i=dima@arista.com; a=ed25519;
 pk=/z94x2T59rICwjRqYvDsBe0MkpbkkdYrSW2J1G2gIcU=
X-Endpoint-Received: by B4 Relay for dima@arista.com/20250521 with auth_id=405
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ima_init_crypto() skips initializing ima_algo_array[i] if the alogorithm
from ima_tpm_chip->allocated_banks[i].crypto_id is not supported.
It seems avoid adding the unsupported algorithm to ima_algo_array will
break all the logic that relies on indexing by NR_BANKS(ima_tpm_chip).

Grepping HASH_ALGO__LAST in security/integrity/ima/ shows that is
the check other logic relies on, so make
create_securityfs_measurement_lists() ignore unknown algorithms.

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

Fixes: 9fa8e7625008 ("ima: add crypto agility support for template-hash algorithm")
Signed-off-by: Dmitry Safonov <dima@arista.com>
Cc: Enrico Bravi <enrico.bravi@polito.it>
Cc: Silvia Sisinni <silvia.sisinni@polito.it>
Cc: Roberto Sassu <roberto.sassu@huawei.com>
Cc: Mimi Zohar <zohar@linux.ibm.com>
---
 security/integrity/ima/ima_fs.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/security/integrity/ima/ima_fs.c b/security/integrity/ima/ima_fs.c
index 012a58959ff0..e9283229acea 100644
--- a/security/integrity/ima/ima_fs.c
+++ b/security/integrity/ima/ima_fs.c
@@ -404,6 +404,9 @@ static int __init create_securityfs_measurement_lists(void)
 		char file_name[NAME_MAX + 1];
 		struct dentry *dentry;
 
+		if (algo == HASH_ALGO__LAST)
+			continue;
+
 		sprintf(file_name, "ascii_runtime_measurements_%s",
 			hash_algo_name[algo]);
 		dentry = securityfs_create_file(file_name, S_IRUSR | S_IRGRP,

---
base-commit: 63804fed149a6750ffd28610c5c1c98cce6bd377
change-id: 20260127-ima-oob-9fa83a634d7b

Best regards,
-- 
Dmitry Safonov <dima@arista.com>

