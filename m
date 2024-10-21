From: Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>
Date: Mon, 21 Oct 2024 18:43:03 +0300
Subject: [PATCH v6] lib: fix dereferencing of a NULL pointer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241021-null_der-v6-1-8dfc261cfc91@gmail.com>
X-B4-Tracking: v=1; b=H4sIAIZ2FmcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyzHQUlJIzE
 vPSU3UzU4B8JSMDIxNDAyND3bzSnJz4lNQiXUNjcwsjQ+M0g5REIyWg8oKi1LTMCrBR0bG1tQA
 njtWrWgAAAA==
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729525395; l=1766;
 i=abdelrahmanyossef12@gmail.com; s=20241017; h=from:subject:message-id;
 bh=kai+Z49hC8e6geQiU2ef8bSL6Qi7IG7gmC3/9g9xYtw=;
 b=+tyf/kjS7Ea0QVO1Axu7HX6xK6t2NTlnziAB0BO+Mr/pHQChdyjtDdIb6ChxZ9/2OCCjSd5nf
 frDn7Ah6QK2C7GjzX0Pdm/uDa5eyj0lUJcSkf72/Muy/e8STrkpCu/q
X-Developer-Key: i=abdelrahmanyossef12@gmail.com; a=ed25519;
 pk=ayjFVDSRo1qKm+PGih8rsNvcMQvJ4ROQWuZWrYU8ujc=
X-Endpoint-Received: by B4 Relay for abdelrahmanyossef12@gmail.com/20241017 with auth_id=251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Runtime reported by AddressSanitizer due to time a NULL pointer dereference.

This is the stack trace:
    #0 0x5b2550e70c4b in get_param_by_name /barebox/lib/parameter.c:56:2
    #1 0x5b2550e70c4b in __dev_add_param /barebox/lib/parameter.c:153:6
    #2 0x5b2550e71666 in __dev_add_param_int /barebox/lib/parameter.c:471:8
    #3 0x5b2550daece8 in dev_add_param_uint32 /barebox/include/param.h:266:1
    #4 0x5b2550daece8 in dos_partition /barebox/common/partitions/dos.c:289:2
    #5 0x5b2550dadc62 in fuzz_partition_table_parser /barebox/common/partitions.c:331:10
    #6 0x5b2550dadc62 in fuzz_partition_table_parser_ramdisk /barebox/common/partitions.c:344:1
    #7 0x5b2550ebb94d in fuzz_test_once /barebox/include/fuzz.h:68:2
    #8 0x5b2550ebb94d in fuzz_main /barebox/lib/fuzz.c:38:3
    #9 0x5b2550d8eb41 in start_barebox /barebox/common/startup.c:381:3
    #10 0x5b2550f4ea6d in sandbox_main (/barebox/images/main.elf+0x411a6d) (BuildId: dfdb3401891b94e86545eddb1502f0815ffd0afb)
    #11 0x5b2550f4f2b2 in start_barebox_coop fuzz.c

Signed-off-by: Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>
---
 lib/parameter.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/lib/parameter.c b/lib/parameter.c
index bf9e83152b..21fa9e7e70 100644
--- a/lib/parameter.c
+++ b/lib/parameter.c
@@ -51,6 +51,9 @@ const char *get_param_type(struct param_d *param)
 
 struct param_d *get_param_by_name(struct device *dev, const char *name)
 {
+	if (!dev)
+		return NULL;
+
 	struct param_d *p;
 
 	list_for_each_entry(p, &dev->parameters, list) {

---
base-commit: 9d47ff66c3892c5a6ddd4704993365a797fbeb68
change-id: 20241021-null_der-1378213f0da2

Best regards,
-- 
Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>

