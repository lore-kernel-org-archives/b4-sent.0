From: Myria Sarvay <myrialsarvay@gmail.com>
Date: Tue, 03 Nov 2026 21:14:43 +1100
Subject: [PATCH 08/13] drivers/perf: apple_m1: Add Apple A18 Support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-m3-plus-pmu-events-v1-8-a8eb6c1139fe@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2108;
 i=myrialsarvay@gmail.com; h=from:subject:message-id;
 bh=UCf5Ut3/9kqWE1oyxM0BkEKM/qq87rW8s0tj0xwB5ms=;
 b=owJ4nJvAy8zAJRbk4iixYu2/l4yn1ZIYsl5uEdXzn3Ez62zT8rshMy99n2rktfbv5WYD+R+fg
 g9+4ymV+mvaUcrCIMbFICumyKJvmqY9ma3hUuky1y0wc1iZQIYwcHEKwESC6xkZFrtqv5zdO1vm
 nrn/+98LQwTfO/l8M97yQ3K7zZHNOblPdBn+mZZm2xz23P4tvnj156jbUQXJ2fVhk9yX/uKROiq
 p7ZHOAwCT20yk
X-Developer-Key: i=myrialsarvay@gmail.com; a=openpgp;
 fpr=2F35662B930680D275A645B452444118A8ADFEE9
X-Endpoint-Received: by B4 Relay for myrialsarvay@gmail.com/default with auth_id=1027
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The A18 has events and affinities identical to the M4, so use it.

Signed-off-by: Myria Sarvay <myrialsarvay@gmail.com>
---
 drivers/perf/apple_m1_cpu_pmu.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/perf/apple_m1_cpu_pmu.c b/drivers/perf/apple_m1_cpu_pmu.c
index bdbd138cf1db..775f3d5aba7e 100644
--- a/drivers/perf/apple_m1_cpu_pmu.c
+++ b/drivers/perf/apple_m1_cpu_pmu.c
@@ -1149,12 +1149,23 @@ static int gen ## _pmu_ ## family ## _init(struct arm_pmu *cpu_pmu)				\
 #define m4_pmu_set_event_filter		m3_pmu_set_event_filter
 #define m4_pmu_format_attr_group	m3_pmu_format_attr_group
 
+#define a18_pmu_enable_event		m4_pmu_enable_event
+#define a18_pmu_map_event		m4_pmu_map_event
+#define a18_pmu_get_event_idx		m4_pmu_get_event_idx
+#define a18_pmu_set_event_filter	m4_pmu_set_event_filter
+#define a18_pmu_map_pmuv3_event		m4_pmu_map_pmuv3_event
+#define a18_pmu_init_pmceid		m4_pmu_init_pmceid
+#define a18_pmu_events_attr_group	m4_pmu_events_attr_group
+#define a18_pmu_format_attr_group	m4_pmu_format_attr_group
+
 APPLE_PMU_INIT(m1, icestorm)
 APPLE_PMU_INIT(m1, firestorm)
 APPLE_PMU_INIT(m2, avalanche)
 APPLE_PMU_INIT(m2, blizzard)
 APPLE_PMU_INIT(m3, sawtooth)
 APPLE_PMU_INIT(m3, everest)
+APPLE_PMU_INIT(a18, tahiti_e)
+APPLE_PMU_INIT(a18, tahiti_p)
 APPLE_PMU_INIT(m4, donan_e)
 APPLE_PMU_INIT(m4, donan_p)
 APPLE_PMU_INIT(m4, brava_e)
@@ -1165,6 +1176,8 @@ static const struct of_device_id m1_pmu_of_device_ids[] = {
 	{ .compatible = "apple,brava-p-pmu",	.data = m4_pmu_brava_p_init, },
 	{ .compatible = "apple,donan-e-pmu",	.data = m4_pmu_donan_e_init, },
 	{ .compatible = "apple,donan-p-pmu",	.data = m4_pmu_donan_p_init, },
+	{ .compatible = "apple,tahiti-e-pmu",	.data = a18_pmu_tahiti_e_init, },
+	{ .compatible = "apple,tahiti-p-pmu",	.data = a18_pmu_tahiti_p_init, },
 	{ .compatible = "apple,sawtooth-pmu",	.data = m3_pmu_sawtooth_init, },
 	{ .compatible = "apple,everest-pmu",	.data = m3_pmu_everest_init, },
 	{ .compatible = "apple,avalanche-pmu",	.data = m2_pmu_avalanche_init, },

-- 
2.56.0

