From: Charlie Jenkins <thecharlesjenkins@gmail.com>
Date: Tue, 27 Jan 2026 15:58:15 -0800
Subject: [PATCH] lib: sbi_pmu: Track SBI_PMU_FW_PLATFORM started counter
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260127-pmu_platform_stop-v1-1-b07d1abd1ef2@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDQyNz3YLc0viCnMSStPyi3PjikvwC3bTUpNQ0M9PEpDRTEyWgvoKi1LT
 MCrCZ0bG1tQC1VSDXYwAAAA==
X-Change-ID: 20260127-pmu_platform_stop-febef65abf54
To: opensbi@lists.infradead.org
Cc: Charlie Jenkins <thecharlesjenkins@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769558303; l=1617;
 i=thecharlesjenkins@gmail.com; s=20260127; h=from:subject:message-id;
 bh=tj6syk7F+QBPYvFgdhMk+dIRCVB7V4CGNm5JdEIntMk=;
 b=lDq3WIP/TZ8xkAt+Haaz4tTYh4BWQH8wWkjnx3Gk9r1Ldf54ka1XheZfAwi7/3ZrzVwDVjlxV
 c1JpB9MFtYUDlWhAsyPQDpERYJF0ffaoohLk0PqoCPvdHuWpgi6pdwl
X-Developer-Key: i=thecharlesjenkins@gmail.com; a=ed25519;
 pk=4AzEw2rmBYSzmHkYTjITwPc2sWIvqjw/Fu3GnQmSMTI=
X-Endpoint-Received: by B4 Relay for thecharlesjenkins@gmail.com/20260127 with auth_id=619
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a SBI_PMU_FW_PLATFORM starts, add the counter to the counter array
instead of returning early. This will cause fw_counter_stop() to be
called when a SBI_PMU_FW_PLATFORM counter should be stopped.

Signed-off-by: Charlie Jenkins <thecharlesjenkins@gmail.com>
---
 lib/sbi/sbi_pmu.c | 10 ++++++----
 1 file changed, 6 insertions(+), 4 deletions(-)

diff --git a/lib/sbi/sbi_pmu.c b/lib/sbi/sbi_pmu.c
index e084005d..3c61079b 100644
--- a/lib/sbi/sbi_pmu.c
+++ b/lib/sbi/sbi_pmu.c
@@ -448,6 +448,8 @@ static int pmu_ctr_start_fw(struct sbi_pmu_hart_state *phs,
 			    uint64_t event_data, uint64_t ival,
 			    bool ival_update)
 {
+	int rc = 0;
+
 	if ((event_code >= SBI_PMU_FW_MAX &&
 	    event_code <= SBI_PMU_FW_RESERVED_MAX) ||
 	    event_code > SBI_PMU_FW_PLATFORM)
@@ -468,9 +470,9 @@ static int pmu_ctr_start_fw(struct sbi_pmu_hart_state *phs,
 							cidx - num_hw_ctrs,
 							ival);
 
-		return pmu_dev->fw_counter_start(phs->hartid,
-						 cidx - num_hw_ctrs,
-						 event_data);
+		rc = pmu_dev->fw_counter_start(phs->hartid,
+					       cidx - num_hw_ctrs,
+					       event_data);
 	} else {
 		if (ival_update)
 			phs->fw_counters_data[cidx - num_hw_ctrs] = ival;
@@ -478,7 +480,7 @@ static int pmu_ctr_start_fw(struct sbi_pmu_hart_state *phs,
 
 	phs->fw_counters_started |= BIT(cidx - num_hw_ctrs);
 
-	return 0;
+	return rc;
 }
 
 static void pmu_update_inhibit_flags(unsigned long flags, uint64_t *mhpmevent_val)

---
base-commit: 74434f255873d74e56cc50aa762d1caf24c099f8
change-id: 20260127-pmu_platform_stop-febef65abf54

- Charlie

