From: Myria Sarvay <myrialsarvay@gmail.com>
Date: Tue, 03 Nov 2026 21:14:40 +1100
Subject: [PATCH 05/13] drivers/perf: apple_m1: Use macros for
 per-implementation init functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-m3-plus-pmu-events-v1-5-a8eb6c1139fe@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4754;
 i=myrialsarvay@gmail.com; h=from:subject:message-id;
 bh=Xf+Ed/oAri86Vq9SpKX25Hm7YiUp82G8Mq/Z76SJGJE=;
 b=owJ4nJvAy8zAJRbk4iixYu2/l4yn1ZIYsl5uERGYY5X6t0J5xhu7i2If/fP3fo3yVbA1brhx4
 90NjWc1P493lLIwiHExyIopsuibpmlPZmu4VLrMdQvMHFYmkCEMXJwCMJGJiowMj8KuRj55YVrR
 fbNXyvizxJuQmOlzRM5lvD5/fwZPg82ZFYwMG2tZ6k3/uZ893/VqyuebQU5PTpxvDdhtK+tzavm
 cIFFnBgBJxU3A
X-Developer-Key: i=myrialsarvay@gmail.com; a=openpgp;
 fpr=2F35662B930680D275A645B452444118A8ADFEE9
X-Endpoint-Received: by B4 Relay for myrialsarvay@gmail.com/default with auth_id=1027
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

6 generations of apple silicon, with at least 2 init functions for each
lead to at least 12 init functions. Template them with macros to save
boilterplate code.

Signed-off-by: Myria Sarvay <myrialsarvay@gmail.com>
---
 drivers/perf/apple_m1_cpu_pmu.c | 91 ++++++++++++++---------------------------
 1 file changed, 30 insertions(+), 61 deletions(-)

diff --git a/drivers/perf/apple_m1_cpu_pmu.c b/drivers/perf/apple_m1_cpu_pmu.c
index a14864263bf1..e7e9b51ffadc 100644
--- a/drivers/perf/apple_m1_cpu_pmu.c
+++ b/drivers/perf/apple_m1_cpu_pmu.c
@@ -653,71 +653,40 @@ static int apple_pmu_init(struct arm_pmu *cpu_pmu)
 }
 
 /* Device driver gunk */
-static int m1_pmu_ice_init(struct arm_pmu *cpu_pmu)
-{
-	cpu_pmu->name = "apple_icestorm_pmu";
-	cpu_pmu->enable		  = m1_pmu_enable_event;
-	cpu_pmu->get_event_idx	  = m1_pmu_get_event_idx;
-	cpu_pmu->map_event	  = m1_pmu_map_event;
-	cpu_pmu->set_event_filter = m1_pmu_set_event_filter;
-
-	cpu_pmu->map_pmuv3_event  = m1_pmu_map_pmuv3_event;
-
-	cpu_pmu->attr_groups[ARMPMU_ATTR_GROUP_EVENTS] = &m1_pmu_events_attr_group;
-	cpu_pmu->attr_groups[ARMPMU_ATTR_GROUP_FORMATS] = &m1_pmu_format_attr_group;
-	return apple_pmu_init(cpu_pmu);
-}
-
-static int m1_pmu_fire_init(struct arm_pmu *cpu_pmu)
-{
-	cpu_pmu->name = "apple_firestorm_pmu";
-	cpu_pmu->enable		  = m1_pmu_enable_event;
-	cpu_pmu->get_event_idx	  = m1_pmu_get_event_idx;
-	cpu_pmu->map_event	  = m1_pmu_map_event;
-	cpu_pmu->set_event_filter = m1_pmu_set_event_filter;
-
-	cpu_pmu->map_pmuv3_event  = m1_pmu_map_pmuv3_event;
-
-	cpu_pmu->attr_groups[ARMPMU_ATTR_GROUP_EVENTS] = &m1_pmu_events_attr_group;
-	cpu_pmu->attr_groups[ARMPMU_ATTR_GROUP_FORMATS] = &m1_pmu_format_attr_group;
-	return apple_pmu_init(cpu_pmu);
-}
-
-static int m2_pmu_avalanche_init(struct arm_pmu *cpu_pmu)
-{
-	cpu_pmu->name = "apple_avalanche_pmu";
-	cpu_pmu->enable		  = m1_pmu_enable_event;
-	cpu_pmu->get_event_idx	  = m1_pmu_get_event_idx;
-	cpu_pmu->map_event	  = m2_pmu_map_event;
-	cpu_pmu->set_event_filter = m1_pmu_set_event_filter;
-
-	cpu_pmu->map_pmuv3_event  = m1_pmu_map_pmuv3_event;
-
-	cpu_pmu->attr_groups[ARMPMU_ATTR_GROUP_EVENTS] = &m1_pmu_events_attr_group;
-	cpu_pmu->attr_groups[ARMPMU_ATTR_GROUP_FORMATS] = &m1_pmu_format_attr_group;
-	return apple_pmu_init(cpu_pmu);
-}
-
-static int m2_pmu_blizzard_init(struct arm_pmu *cpu_pmu)
-{
-	cpu_pmu->name = "apple_blizzard_pmu";
-	cpu_pmu->enable		  = m1_pmu_enable_event;
-	cpu_pmu->get_event_idx	  = m1_pmu_get_event_idx;
-	cpu_pmu->map_event	  = m2_pmu_map_event;
-	cpu_pmu->set_event_filter = m1_pmu_set_event_filter;
-
-	cpu_pmu->map_pmuv3_event  = m1_pmu_map_pmuv3_event;
-
-	cpu_pmu->attr_groups[ARMPMU_ATTR_GROUP_EVENTS] = &m1_pmu_events_attr_group;
-	cpu_pmu->attr_groups[ARMPMU_ATTR_GROUP_FORMATS] = &m1_pmu_format_attr_group;
-	return apple_pmu_init(cpu_pmu);
-}
+#define APPLE_PMU_INIT(gen, family)								\
+static int gen ## _pmu_ ## family ## _init(struct arm_pmu *cpu_pmu)				\
+{												\
+	cpu_pmu->name			= "apple_" #family "_pmu";				\
+	cpu_pmu->enable			= gen ## _pmu_enable_event;				\
+	cpu_pmu->get_event_idx		= gen ## _pmu_get_event_idx;				\
+	cpu_pmu->map_event		= gen ## _pmu_map_event;				\
+	cpu_pmu->set_event_filter	= gen ## _pmu_set_event_filter;				\
+												\
+	cpu_pmu->map_pmuv3_event	= gen ## _pmu_map_pmuv3_event;				\
+												\
+	cpu_pmu->attr_groups[ARMPMU_ATTR_GROUP_EVENTS] = &gen ## _pmu_events_attr_group;	\
+	cpu_pmu->attr_groups[ARMPMU_ATTR_GROUP_FORMATS] = &gen ## _pmu_format_attr_group;	\
+	return apple_pmu_init(cpu_pmu);								\
+}
+
+#define m2_pmu_enable_event		m1_pmu_enable_event
+#define m2_pmu_get_event_idx		m1_pmu_get_event_idx
+#define m2_pmu_set_event_filter		m1_pmu_set_event_filter
+#define m2_pmu_map_pmuv3_event		m1_pmu_map_pmuv3_event
+#define m2_pmu_init_pmceid		m1_pmu_init_pmceid
+#define m2_pmu_events_attr_group	m1_pmu_events_attr_group
+#define m2_pmu_format_attr_group	m1_pmu_format_attr_group
+
+APPLE_PMU_INIT(m1, icestorm)
+APPLE_PMU_INIT(m1, firestorm)
+APPLE_PMU_INIT(m2, avalanche)
+APPLE_PMU_INIT(m2, blizzard)
 
 static const struct of_device_id m1_pmu_of_device_ids[] = {
 	{ .compatible = "apple,avalanche-pmu",	.data = m2_pmu_avalanche_init, },
 	{ .compatible = "apple,blizzard-pmu",	.data = m2_pmu_blizzard_init, },
-	{ .compatible = "apple,icestorm-pmu",	.data = m1_pmu_ice_init, },
-	{ .compatible = "apple,firestorm-pmu",	.data = m1_pmu_fire_init, },
+	{ .compatible = "apple,icestorm-pmu",	.data = m1_pmu_icestorm_init, },
+	{ .compatible = "apple,firestorm-pmu",	.data = m1_pmu_firestorm_init, },
 	{ },
 };
 MODULE_DEVICE_TABLE(of, m1_pmu_of_device_ids);

-- 
2.56.0

