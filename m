From: Myria Sarvay <myrialsarvay@gmail.com>
Date: Sat, 07 Nov 2026 21:48:55 +1100
Subject: [PATCH v2 08/15] drivers/perf: apple_m1: Add Apple A18 Support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-m3-plus-pmu-events-v2-8-acf1e78da039@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1387;
 i=myrialsarvay@gmail.com; h=from:subject:message-id;
 bh=s/45yDdB8ys2vFBvaE4TXv63SSRkLqDeAYlpyd8V2AY=;
 b=owJ4nJvAy8zAJRbk4iixYu2/l4yn1ZIYst4zyUyM93DXiI9rWnfb4LvHynVG57bEuTsyN5SkL
 Sr2+3D4g39HKQuDGBeDrJgii75pmvZktoZLpctct8DMYWUCGcLAxSkAE5H2Zvgr5714Rpeyioqf
 w7GnS1Sb25oNN0358UDwwo1TJz7MMno7k5Fhtq/Vx5YCt4c6mzxDbBYlWJloHOFy0TbrZNtpvGD
 fkUBmAFLcRuQ=
X-Developer-Key: i=myrialsarvay@gmail.com; a=openpgp;
 fpr=2F35662B930680D275A645B452444118A8ADFEE9
X-Endpoint-Received: by B4 Relay for myrialsarvay@gmail.com/default with auth_id=1027
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The A18 has events and affinities identical to the M4, so use it.

Signed-off-by: Myria Sarvay <myrialsarvay@gmail.com>
---
 drivers/perf/apple_m1_cpu_pmu.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/perf/apple_m1_cpu_pmu.c b/drivers/perf/apple_m1_cpu_pmu.c
index d6fa58aee886..318baf1a75c4 100644
--- a/drivers/perf/apple_m1_cpu_pmu.c
+++ b/drivers/perf/apple_m1_cpu_pmu.c
@@ -1154,6 +1154,8 @@ APPLE_PMU_INIT(m2, avalanche)
 APPLE_PMU_INIT(m2, blizzard)
 APPLE_PMU_INIT(m3, sawtooth)
 APPLE_PMU_INIT(m3, everest)
+APPLE_PMU_INIT(m4, tahiti_e)
+APPLE_PMU_INIT(m4, tahiti_p)
 APPLE_PMU_INIT(m4, donan_e)
 APPLE_PMU_INIT(m4, donan_p)
 APPLE_PMU_INIT(m4, brava_e)
@@ -1164,6 +1166,8 @@ static const struct of_device_id m1_pmu_of_device_ids[] = {
 	{ .compatible = "apple,brava-p-pmu",	.data = m4_pmu_brava_p_init, },
 	{ .compatible = "apple,donan-e-pmu",	.data = m4_pmu_donan_e_init, },
 	{ .compatible = "apple,donan-p-pmu",	.data = m4_pmu_donan_p_init, },
+	{ .compatible = "apple,tahiti-e-pmu",	.data = m4_pmu_tahiti_e_init, },
+	{ .compatible = "apple,tahiti-p-pmu",	.data = m4_pmu_tahiti_p_init, },
 	{ .compatible = "apple,sawtooth-pmu",	.data = m3_pmu_sawtooth_init, },
 	{ .compatible = "apple,everest-pmu",	.data = m3_pmu_everest_init, },
 	{ .compatible = "apple,avalanche-pmu",	.data = m2_pmu_avalanche_init, },

-- 
2.55.0

