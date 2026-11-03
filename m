From: Myria Sarvay <myrialsarvay@gmail.com>
Date: Tue, 03 Nov 2026 21:14:37 +1100
Subject: [PATCH 02/13] drivers/perf: apple_m1: Remove unused variables
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-m3-plus-pmu-events-v1-2-a8eb6c1139fe@gmail.com>
References: <20261103-m3-plus-pmu-events-v1-0-a8eb6c1139fe@gmail.com>
In-Reply-To: <20261103-m3-plus-pmu-events-v1-0-a8eb6c1139fe@gmail.com>
To: Will Deacon <will@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sven Peter <sven@kernel.org>, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Marc Zyngier <maz@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-perf-users@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, Yuvan Shen <yuvanshen09@gmail.com>, 
 Myria Sarvay <myrialsarvay@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1077;
 i=myrialsarvay@gmail.com; h=from:subject:message-id;
 bh=tqfKByDug9XSrpXX1trL6e24TzZYUYwCyC7bLswrs2o=;
 b=owJ4nJvAy8zAJRbk4iixYu2/l4yn1ZIYsl5uEcl+dSZ+X5hXZ335TA//YpED/579NTH5antr/
 o4e26K2K9IdpSwMYlwMsmKKLPqmadqT2RoulS5z3QIzh5UJZAgDF6cATGRVIiPD9t28Vy6kuPtK
 avEa9SjJuCe3Xpnr5Jm+7Isq375eX7e3jAzt/CZvnz5dJTy1LLDc9curdb4fvlUfL+sXtP3u/sP
 zcBkPAIF7Sp8=
X-Developer-Key: i=myrialsarvay@gmail.com; a=openpgp;
 fpr=2F35662B930680D275A645B452444118A8ADFEE9
X-Endpoint-Received: by B4 Relay for myrialsarvay@gmail.com/default with auth_id=1027
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These variables are calculated elsewhere as well, remove the extra dead
code.

Signed-off-by: Myria Sarvay <myrialsarvay@gmail.com>
Fixes: a639027a1be1 ("drivers/perf: Add Apple icestorm/firestorm CPU PMU driver")
---
 drivers/perf/apple_m1_cpu_pmu.c | 7 -------
 1 file changed, 7 deletions(-)

diff --git a/drivers/perf/apple_m1_cpu_pmu.c b/drivers/perf/apple_m1_cpu_pmu.c
index 1f73c8a77462..de4026c63afd 100644
--- a/drivers/perf/apple_m1_cpu_pmu.c
+++ b/drivers/perf/apple_m1_cpu_pmu.c
@@ -421,13 +421,6 @@ static void m1_pmu_configure_counter(unsigned int index, unsigned long config_ba
 /* arm_pmu backend */
 static void m1_pmu_enable_event(struct perf_event *event)
 {
-	bool user, kernel;
-	u8 evt;
-
-	evt = event->hw.config_base & M1_PMU_CFG_EVENT;
-	user = event->hw.config_base & M1_PMU_CFG_COUNT_USER;
-	kernel = event->hw.config_base & M1_PMU_CFG_COUNT_KERNEL;
-
 	m1_pmu_configure_counter(event->hw.idx, event->hw.config_base);
 	m1_pmu_enable_counter(event->hw.idx);
 	m1_pmu_enable_counter_interrupt(event->hw.idx);

-- 
2.56.0

