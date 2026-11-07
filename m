From: Myria Sarvay <myrialsarvay@gmail.com>
Date: Sat, 07 Nov 2026 21:48:51 +1100
Subject: [PATCH v2 04/15] drivers/perf: apple_m1: Support
 per-implementation event size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-m3-plus-pmu-events-v2-4-acf1e78da039@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=7619;
 i=myrialsarvay@gmail.com; h=from:subject:message-id;
 bh=JhSnErAvV8k8B/pR0xbZ9CAqGWkNZJsjGAvcOAujYmo=;
 b=owJ4nJvAy8zAJRbk4iixYu2/l4yn1ZIYst4zSZ888Sw16pbzgdfffjNf6tnywmCze5HT/q8Tv
 lUuy9knnjezo5SFQYyLQVZMkUXfNE17MlvDpdJlrltg5rAygQxh4OIUgInMbWZkeBxQ3+sVFLhc
 8rLK4WKRZ9euvy3UlSv2Zvq4Ren1dwPD8wz/wx8EbmN11lklLxx2+JP8b9nVq2dsK9jSEiS37eX
 VrI46XgCa/k0j
X-Developer-Key: i=myrialsarvay@gmail.com; a=openpgp;
 fpr=2F35662B930680D275A645B452444118A8ADFEE9
X-Endpoint-Received: by B4 Relay for myrialsarvay@gmail.com/default with auth_id=1027
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On M3 and later silicon, events are 16-bits instead of the 8-bits of
earlier implementations.

Co-developed-by: Yuvan Shen <yuvanshen09@gmail.com>
Signed-off-by: Yuvan Shen <yuvanshen09@gmail.com>
Signed-off-by: Myria Sarvay <myrialsarvay@gmail.com>
---
 drivers/perf/apple_m1_cpu_pmu.c | 54 ++++++++++++++++++++++++++---------------
 1 file changed, 35 insertions(+), 19 deletions(-)

diff --git a/drivers/perf/apple_m1_cpu_pmu.c b/drivers/perf/apple_m1_cpu_pmu.c
index 2ff0c2e0b737..a14864263bf1 100644
--- a/drivers/perf/apple_m1_cpu_pmu.c
+++ b/drivers/perf/apple_m1_cpu_pmu.c
@@ -209,10 +209,13 @@ static const struct attribute_group m1_pmu_events_attr_group = {
 	.attrs = m1_pmu_event_attrs,
 };
 
-PMU_FORMAT_ATTR(event, "config:0-7");
+PMU_FORMAT_ATTR_SHOW(event_8b, "config:0-7");
+
+static struct device_attribute format_attr_event_8b =
+	__ATTR(event, 0444, event_8b_show, NULL);
 
 static struct attribute *m1_pmu_format_attrs[] = {
-	&format_attr_event.attr,
+	&format_attr_event_8b.attr,
 	NULL,
 };
 
@@ -373,7 +376,8 @@ static void __m1_pmu_configure_event_filter(unsigned int index, bool user,
 		sysreg_clear_set_s(SYS_IMP_APL_PMCR1_EL12, clear, set);
 }
 
-static void __m1_pmu_configure_eventsel(unsigned int index, u8 event)
+static void __apple_pmu_configure_eventsel(unsigned int index, u16 event,
+					   unsigned int size, u64 mask)
 {
 	u64 clear = 0, set = 0;
 	int shift;
@@ -388,14 +392,14 @@ static void __m1_pmu_configure_eventsel(unsigned int index, u8 event)
 	case 0 ... 1:
 		break;
 	case 2 ... 5:
-		shift = (index - 2) * 8;
-		clear |= (u64)0xff << shift;
+		shift = (index - 2) * size;
+		clear |= mask << shift;
 		set |= (u64)event << shift;
 		sysreg_clear_set_s(SYS_IMP_APL_PMESR0_EL1, clear, set);
 		break;
 	case 6 ... 9:
-		shift = (index - 6) * 8;
-		clear |= (u64)0xff << shift;
+		shift = (index - 6) * size;
+		clear |= mask << shift;
 		set |= (u64)event << shift;
 		sysreg_clear_set_s(SYS_IMP_APL_PMESR1_EL1, clear, set);
 		break;
@@ -412,7 +416,7 @@ static void m1_pmu_configure_counter(unsigned int index, unsigned long config_ba
 
 	__m1_pmu_configure_event_filter(index, user && host, kernel && host, true);
 	__m1_pmu_configure_event_filter(index, user && guest, kernel && guest, false);
-	__m1_pmu_configure_eventsel(index, evt);
+	__apple_pmu_configure_eventsel(index, evt, 8, M1_PMU_CFG_EVENT);
 }
 
 /* arm_pmu backend */
@@ -485,10 +489,8 @@ static void m1_pmu_write_counter(struct perf_event *event, u64 value)
 
 static int apple_pmu_get_event_idx(struct pmu_hw_events *cpuc,
 				   struct perf_event *event,
-				   const u16 event_affinities[])
+				   unsigned long affinity)
 {
-	unsigned long evtype = event->hw.config_base & M1_PMU_CFG_EVENT;
-	unsigned long affinity = event_affinities[evtype];
 	int idx;
 
 	/*
@@ -510,7 +512,10 @@ static int apple_pmu_get_event_idx(struct pmu_hw_events *cpuc,
 static int m1_pmu_get_event_idx(struct pmu_hw_events *cpuc,
 				struct perf_event *event)
 {
-	return apple_pmu_get_event_idx(cpuc, event, m1_pmu_event_affinity);
+	unsigned long evtype = event->hw.config_base & M1_PMU_CFG_EVENT;
+	unsigned long affinity = m1_pmu_event_affinity[evtype];
+
+	return apple_pmu_get_event_idx(cpuc, event, affinity);
 }
 
 static void m1_pmu_clear_event_idx(struct pmu_hw_events *cpuc,
@@ -542,10 +547,10 @@ static void m1_pmu_stop(struct arm_pmu *cpu_pmu)
 
 static int apple_pmu_map_event(struct perf_event *event,
 			       const unsigned int (*perf_map)[],
-			       unsigned int flags)
+			       unsigned int flags, u32 mask)
 {
 	event->hw.flags |= flags;
-	return armpmu_map_event(event, perf_map, NULL, M1_PMU_CFG_EVENT);
+	return armpmu_map_event(event, perf_map, NULL, mask);
 }
 
 /*
@@ -557,12 +562,14 @@ static int apple_pmu_map_event(struct perf_event *event,
  */
 static int m1_pmu_map_event(struct perf_event *event)
 {
-	return apple_pmu_map_event(event, &m1_pmu_perf_map, ARMPMU_EVT_47BIT);
+	return apple_pmu_map_event(event, &m1_pmu_perf_map, ARMPMU_EVT_47BIT,
+				   M1_PMU_CFG_EVENT);
 }
 
 static int m2_pmu_map_event(struct perf_event *event)
 {
-	return apple_pmu_map_event(event, &m1_pmu_perf_map, ARMPMU_EVT_63BIT);
+	return apple_pmu_map_event(event, &m1_pmu_perf_map, ARMPMU_EVT_63BIT,
+				   M1_PMU_CFG_EVENT);
 }
 
 static int apple_pmu_map_pmuv3_event(unsigned int eventsel, const u16 pmceid_map[])
@@ -631,7 +638,6 @@ static int m1_pmu_set_event_filter(struct hw_perf_event *event,
 static int apple_pmu_init(struct arm_pmu *cpu_pmu)
 {
 	cpu_pmu->handle_irq	  = m1_pmu_handle_irq;
-	cpu_pmu->enable		  = m1_pmu_enable_event;
 	cpu_pmu->disable	  = m1_pmu_disable_event;
 	cpu_pmu->read_counter	  = m1_pmu_read_counter;
 	cpu_pmu->write_counter	  = m1_pmu_write_counter;
@@ -639,12 +645,10 @@ static int apple_pmu_init(struct arm_pmu *cpu_pmu)
 	cpu_pmu->start		  = m1_pmu_start;
 	cpu_pmu->stop		  = m1_pmu_stop;
 	cpu_pmu->reset		  = m1_pmu_reset;
-	cpu_pmu->set_event_filter = m1_pmu_set_event_filter;
 
 	apple_pmu_init_pmceid(cpu_pmu);
 
 	bitmap_set(cpu_pmu->cntr_mask, 0, M1_PMU_NR_COUNTERS);
-	cpu_pmu->attr_groups[ARMPMU_ATTR_GROUP_FORMATS] = &m1_pmu_format_attr_group;
 	return 0;
 }
 
@@ -652,48 +656,60 @@ static int apple_pmu_init(struct arm_pmu *cpu_pmu)
 static int m1_pmu_ice_init(struct arm_pmu *cpu_pmu)
 {
 	cpu_pmu->name = "apple_icestorm_pmu";
+	cpu_pmu->enable		  = m1_pmu_enable_event;
 	cpu_pmu->get_event_idx	  = m1_pmu_get_event_idx;
 	cpu_pmu->map_event	  = m1_pmu_map_event;
+	cpu_pmu->set_event_filter = m1_pmu_set_event_filter;
 
 	cpu_pmu->map_pmuv3_event  = m1_pmu_map_pmuv3_event;
 
 	cpu_pmu->attr_groups[ARMPMU_ATTR_GROUP_EVENTS] = &m1_pmu_events_attr_group;
+	cpu_pmu->attr_groups[ARMPMU_ATTR_GROUP_FORMATS] = &m1_pmu_format_attr_group;
 	return apple_pmu_init(cpu_pmu);
 }
 
 static int m1_pmu_fire_init(struct arm_pmu *cpu_pmu)
 {
 	cpu_pmu->name = "apple_firestorm_pmu";
+	cpu_pmu->enable		  = m1_pmu_enable_event;
 	cpu_pmu->get_event_idx	  = m1_pmu_get_event_idx;
 	cpu_pmu->map_event	  = m1_pmu_map_event;
+	cpu_pmu->set_event_filter = m1_pmu_set_event_filter;
 
 	cpu_pmu->map_pmuv3_event  = m1_pmu_map_pmuv3_event;
 
 	cpu_pmu->attr_groups[ARMPMU_ATTR_GROUP_EVENTS] = &m1_pmu_events_attr_group;
+	cpu_pmu->attr_groups[ARMPMU_ATTR_GROUP_FORMATS] = &m1_pmu_format_attr_group;
 	return apple_pmu_init(cpu_pmu);
 }
 
 static int m2_pmu_avalanche_init(struct arm_pmu *cpu_pmu)
 {
 	cpu_pmu->name = "apple_avalanche_pmu";
+	cpu_pmu->enable		  = m1_pmu_enable_event;
 	cpu_pmu->get_event_idx	  = m1_pmu_get_event_idx;
 	cpu_pmu->map_event	  = m2_pmu_map_event;
+	cpu_pmu->set_event_filter = m1_pmu_set_event_filter;
 
 	cpu_pmu->map_pmuv3_event  = m1_pmu_map_pmuv3_event;
 
 	cpu_pmu->attr_groups[ARMPMU_ATTR_GROUP_EVENTS] = &m1_pmu_events_attr_group;
+	cpu_pmu->attr_groups[ARMPMU_ATTR_GROUP_FORMATS] = &m1_pmu_format_attr_group;
 	return apple_pmu_init(cpu_pmu);
 }
 
 static int m2_pmu_blizzard_init(struct arm_pmu *cpu_pmu)
 {
 	cpu_pmu->name = "apple_blizzard_pmu";
+	cpu_pmu->enable		  = m1_pmu_enable_event;
 	cpu_pmu->get_event_idx	  = m1_pmu_get_event_idx;
 	cpu_pmu->map_event	  = m2_pmu_map_event;
+	cpu_pmu->set_event_filter = m1_pmu_set_event_filter;
 
 	cpu_pmu->map_pmuv3_event  = m1_pmu_map_pmuv3_event;
 
 	cpu_pmu->attr_groups[ARMPMU_ATTR_GROUP_EVENTS] = &m1_pmu_events_attr_group;
+	cpu_pmu->attr_groups[ARMPMU_ATTR_GROUP_FORMATS] = &m1_pmu_format_attr_group;
 	return apple_pmu_init(cpu_pmu);
 }
 

-- 
2.55.0

