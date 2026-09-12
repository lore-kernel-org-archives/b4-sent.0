From: Myria Sarvay <myrialsarvay@gmail.com>
Date: Sat, 12 Sep 2026 18:03:35 +1000
Subject: [PATCH] drivers/perf: apple_m1: Add macOS 27 M2 Event
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260912-m2-9f-pmu-name-v1-1-da682557453c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrB3QKajjVYoLm07aEZJKYkQQ7
 96oy7f4f4coQSVCX+wQZNWoP59RlwWY7+g/gvrOBqqoqbgmdIRscXYJ/egE246NbejBtmXI0Rz
 E6nYNn8PtmF6TmOW8wHH8AWdXnI5yAAAA
X-Change-ID: 20260912-m2-9f-pmu-name-789cf6239f79
To: Will Deacon <will@kernel.org>, Mark Rutland <mark.rutland@arm.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-perf-users@vger.kernel.org, 
 linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 Myria Sarvay <myrialsarvay@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1883;
 i=myrialsarvay@gmail.com; h=from:subject:message-id;
 bh=WE/9S0PEWj724ZfvllqIPRhYse7Qz5ha7AiDrC/FTsg=;
 b=owJ4nJvAy8zAJRbk4iixYu2/l4yn1ZIYspayxz65P616LZ9MUu9hz417PhrzyN/98Wr2pZPXq
 g4Kqv4IMn/eUcrCIMbFICumyKJvmqY9ma3hUuky1y0wc1iZQIYwcHEKwET0rRgZlv4v+ytisH/V
 bqWbC7UP50ttuHTvbs7Vdjcvb+b+oMU3lBgZdvy9F5kzfcrGTY6/DLfXWXYdFnbz/DBZV4Jt0QP
 NvyEKzADqTksT
X-Developer-Key: i=myrialsarvay@gmail.com; a=openpgp;
 fpr=2F35662B930680D275A645B452444118A8ADFEE9
X-Endpoint-Received: by B4 Relay for myrialsarvay@gmail.com/default with auth_id=1027
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds another known PMU event that can be found under
/usr/share/kpep on macOS 27 for M2 macs. INST_SIMD_ALU_VEC purports to
count "Retired non-load/store vector Advanced SIMD instructions", and as
we already noted, can only be registered on counter 7. Though this event
only shows up on the M2 kpep records, it can be set on M1 CPUs, and
records something.

Link: https://github.com/0ax1/apmc/blob/9cff99a9df2ae055f1e3065c64f633e38bb6beec/counters/m2.md
Signed-off-by: Myria Sarvay <myrialsarvay@gmail.com>
---
 drivers/perf/apple_m1_cpu_pmu.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/perf/apple_m1_cpu_pmu.c b/drivers/perf/apple_m1_cpu_pmu.c
index 81b6f1a62349..1f73c8a77462 100644
--- a/drivers/perf/apple_m1_cpu_pmu.c
+++ b/drivers/perf/apple_m1_cpu_pmu.c
@@ -81,7 +81,7 @@ enum m1_pmu_events {
 	M1_PMU_PERFCTR_INST_SIMD_ALU				= 0x9a,
 	M1_PMU_PERFCTR_INST_LDST				= 0x9b,
 	M1_PMU_PERFCTR_INST_BARRIER				= 0x9c,
-	M1_PMU_PERFCTR_UNKNOWN_9f				= 0x9f,
+	M1_PMU_PERFCTR_INST_SIMD_ALU_VEC			= 0x9f,
 	M1_PMU_PERFCTR_L1D_TLB_ACCESS				= 0xa0,
 	M1_PMU_PERFCTR_L1D_TLB_MISS				= 0xa1,
 	M1_PMU_PERFCTR_L1D_CACHE_MISS_ST			= 0xa2,
@@ -150,7 +150,7 @@ static const u16 m1_pmu_event_affinity[M1_PMU_PERFCTR_LAST + 1] = {
 	[M1_PMU_PERFCTR_INST_SIMD_ALU]				= BIT(7),
 	[M1_PMU_PERFCTR_INST_LDST]				= BIT(7),
 	[M1_PMU_PERFCTR_INST_BARRIER]				= ONLY_5_6_7,
-	[M1_PMU_PERFCTR_UNKNOWN_9f]				= BIT(7),
+	[M1_PMU_PERFCTR_INST_SIMD_ALU_VEC]			= BIT(7),
 	[M1_PMU_PERFCTR_L1D_CACHE_MISS_LD_NONSPEC]		= ONLY_5_6_7,
 	[M1_PMU_PERFCTR_L1D_CACHE_MISS_ST_NONSPEC]		= ONLY_5_6_7,
 	[M1_PMU_PERFCTR_L1D_TLB_MISS_NONSPEC]			= ONLY_5_6_7,

---
base-commit: cee9395acd8043be0644b25c34bfa86623f2b935
change-id: 20260912-m2-9f-pmu-name-789cf6239f79

Best regards,
--  
Myria Sarvay <myrialsarvay@gmail.com>

