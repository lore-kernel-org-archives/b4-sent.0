From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 26 Nov 2026 13:08:10 +0100
Subject: [PATCH] mm/page_alloc: drop staging copy in
 lowmem_reserve_ratio_sysctl_handler
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-lklm-sysctl-remvectmp-v1-1-602568b53c0b@kernel.org>
X-B4-Tracking: v=1; b=H4sIACkhCGsC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDSyMj3ZzsnFzd4sri5JIc3aLU3LLU5JLcAl1TQ5MkCwNzQ1PztEQloN6
 CotS0zAqwudGxtbUAFgPELWcAAAA=
X-Change-ID: 20260922-lklm-sysctl-remvectmp-514b807157fa
To: Andrew Morton <akpm@linux-foundation.org>, 
 Vlastimil Babka <vbabka@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, Brendan Jackman <brendan.jackman@linux.dev>, 
 Johannes Weiner <hannes@cmpxchg.org>, Zi Yan <ziy@nvidia.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1985;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=3iZebsEPxjDB2kT6KSg7TMzGxHwXEuJwadUR+Zkznm0=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGsIIT8ychip7xYNXtSZnDY+3UhHZ1IFIQV98
 oi/6l6RmFTonYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJrCCE/AAoJELqXzVK3
 lkFPz0YMAJZPPSibHZHi4iyHPD2l6UQ8oaD+Ysq5JXLnhI6vHCH3Ycqgy0zKCg+7t9L/A94P1iH
 /tdqmBWbaLROmVUyps1nrrw5kLFlOpJRbvw30QZuHp4jUEBwI4K3NTtbF/rIuBbl21rmGnuVNez
 LFY+/6/koB3poSCuVlOaLWuzL26FStZlT9CtmWwswBIsMaqwuCcVAYgEXTpRE6shAIVhf0LKWvu
 3r41qD7QiYnWOBqUoX6rTqpU8aJgFwdD5bFNvNfiw1/sICtzInFkOr2BexdhsWiWkLL82UE+Egi
 4G4OF6sY8w9Cs5Flh20/TOxLkw9M7+K5hctRjErKnYSioeNi3wXIGtHqjQAD8pHNEST/tYF0UfP
 F+tfx7ZqI6xdRrP2C6/I7bh4N6UprhPkk3Z63nilXgchmBaWPBJs6kxpf5AvjZcn3mt/TGh5Wdq
 TIUYgcPHnWVNC5bGARY71GYZ4QUotfJ57UFvkYOweCuBfwRe9VL29mziOW1sKhgWtq+wA0SYwY6
 tA=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sysctl_lowmem_reserve_ratio[] can no longer be left partially updated as
sysctl now stages vector writes and commits after making sure that there
are no parse errors. Remove the local copy and let the staging happen
within sysctl.

Link: https://lore.kernel.org/20260814-lklm-partial_ctlvec-v2-0-9df50d26e477@kernel.org
Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
Now that sysctl vectors cannot be left partially updated due to
formating errors, there is no longer a need to stage it in the caller.
---
 mm/page_alloc.c | 18 +++---------------
 1 file changed, 3 insertions(+), 15 deletions(-)

diff --git a/mm/page_alloc.c b/mm/page_alloc.c
index 2fef4092c913c1c06d827a37e8af60641129b44e..54b93f5367df5b4fd00fec225611447a87917beb 100644
--- a/mm/page_alloc.c
+++ b/mm/page_alloc.c
@@ -6927,26 +6927,14 @@ static int sysctl_min_slab_ratio_sysctl_handler(const struct ctl_table *table, i
 static int lowmem_reserve_ratio_sysctl_handler(const struct ctl_table *table,
 		int write, void *buffer, size_t *length, loff_t *ppos)
 {
-	struct ctl_table tmp = *table;
-	int ratio[ARRAY_SIZE(sysctl_lowmem_reserve_ratio)];
 	int rc;
 
-	if (!write)
-		return proc_dointvec_minmax(table, write, buffer, length, ppos);
-
-	/*
-	 * proc_dointvec_max() works incrementally. Use a buffer and only set
-	 * the values if all of them parse cleanly.
-	 */
-	memcpy(ratio, sysctl_lowmem_reserve_ratio, sizeof(ratio));
-	tmp.data = ratio;
-
-	rc = proc_dointvec_minmax(&tmp, write, buffer, length, ppos);
+	rc = proc_dointvec_minmax(table, write, buffer, length, ppos);
 	if (rc)
 		return rc;
 
-	memcpy(sysctl_lowmem_reserve_ratio, ratio, sizeof(ratio));
-	setup_per_zone_lowmem_reserve();
+	if (write)
+		setup_per_zone_lowmem_reserve();
 
 	return 0;
 }

---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20260922-lklm-sysctl-remvectmp-514b807157fa

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

