From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 15 Dec 2025 16:47:37 +0100
Subject: [PATCH] alloc_tag: move memory_allocation_profiling_sysctls into
 .rodata
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251215-jag-alloc_tag_const-v1-1-35ea56a1ce13@kernel.org>
X-B4-Tracking: v=1; b=H4sIAJgtQGkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDI0NT3azEdN3EnJz85PiSxPT45Py84hLdlGTLFPNk4zTzRIs0JaDOgqL
 UtMwKsKnRsbW1AMZQZlFlAAAA
X-Change-ID: 20251215-jag-alloc_tag_const-dc9d7c3f7a8f
To: Suren Baghdasaryan <surenb@google.com>, 
 Kent Overstreet <kent.overstreet@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1430;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=LDUL2rRv2z6sqgcL/GxlNcgNQGncefAQrlvxFNU0nqA=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGlALZrSh2JjzWixeXMWIrdctFPERl6yyv4NN
 LiieH5jSdOOe4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJpQC2aAAoJELqXzVK3
 lkFP/8UL/RsRUSRnehvvpzMWT0nhllOcXeF6+qvVoyOV8NZSqZkfmeCn4u9EIM6Ov8ThiHs8Yd9
 SVo+BaVYsRqD4XPadAYoX7BcjpzhkHzESWjwQo2vjJRMjsGfP8W4WPTv+59w/WE+3cY0yOSmSy4
 CO9VoV975iWwfysgWTmaTkNfOJZjwsVTPGWwgNrkX9wzBSXW15s1weqjWtx6MrA17T3BUEQsIiT
 Y6AtSyAe648ALEfaHeHnloxe+X5BcFNyjaYjr3hTk3myG5BoHdpemFobJzs8JUNSC5puAMRZA1c
 WL/lfm/sZDJjVxm8OpkOlY2VSrWj4R6QPNxMf1OrvKyqS38Z4mHg8yYmVmdjw616ZFooCy+7lTl
 rvUnfAMBAPN1Ry+6yDLMKfb7GGg0WdU/FTfzkqoc/AW8rfBoK+zHPPT31NOfGR9oQwkONpuSGw4
 9zsDqvQU8bZVGO5VA5ivmovnSPdQfe+IT5sk8vxWqzhjTpeRuOPa6tXbWwuO2QcFPs7ryixJta5
 Z4=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove the change in file mode permissions done before initializing the
sysctl. It is not necessary as the writing of the kernel variable will
be blocked by the proc_mem_profiling_handler when writing is disallowed
(also controlled by mem_profiling_support).

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 lib/alloc_tag.c | 5 +----
 1 file changed, 1 insertion(+), 4 deletions(-)

diff --git a/lib/alloc_tag.c b/lib/alloc_tag.c
index 27fee57a5c91db8067c05bff974a9e801e0ef6a0..846a5b5b44a4e5f530605c97a200e03260e73d77 100644
--- a/lib/alloc_tag.c
+++ b/lib/alloc_tag.c
@@ -783,7 +783,7 @@ static int proc_mem_profiling_handler(const struct ctl_table *table, int write,
 }
 
 
-static struct ctl_table memory_allocation_profiling_sysctls[] = {
+static const struct ctl_table memory_allocation_profiling_sysctls[] = {
 	{
 		.procname	= "mem_profiling",
 		.data		= &mem_alloc_profiling_key,
@@ -798,9 +798,6 @@ static struct ctl_table memory_allocation_profiling_sysctls[] = {
 
 static void __init sysctl_init(void)
 {
-	if (!mem_profiling_support)
-		memory_allocation_profiling_sysctls[0].mode = 0444;
-
 	register_sysctl_init("vm", memory_allocation_profiling_sysctls);
 }
 #else /* CONFIG_SYSCTL */

---
base-commit: 8f0b4cce4481fb22653697cced8d0d04027cb1e8
change-id: 20251215-jag-alloc_tag_const-dc9d7c3f7a8f

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

