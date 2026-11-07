From: Myria Sarvay <myrialsarvay@gmail.com>
Date: Sat, 07 Nov 2026 21:48:49 +1100
Subject: [PATCH v2 02/15] drivers/perf: apple_m1: Remove unused variables
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-m3-plus-pmu-events-v2-2-acf1e78da039@gmail.com>
References: <20261107-m3-plus-pmu-events-v2-0-acf1e78da039@gmail.com>
In-Reply-To: <20261107-m3-plus-pmu-events-v2-0-acf1e78da039@gmail.com>
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
 bh=EV9fXCfpL3fKlyENxSrnQelkd6v71gDBFcBUcbGRPcg=;
 b=kA0DAAoWUkRBGKit/ukByyZiAGrvAhuiEb8Z1U79UtMuB3jppw2vSZr9YBVd6ehn9EEHlYM5m
 oh1BAAWCgAdFiEELzVmK5MGgNJ1pkW0UkRBGKit/ukFAmrvAhsACgkQUkRBGKit/ulGHQD/ZBKe
 pqjGQ6JyFX3Qkph4r3K87D0/UipcTgbP1BRt11kBAOos0/WKS4V4c/u8rgoYM9oFAk67XawY2h1
 r7RuF9jcC
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
2.55.0

