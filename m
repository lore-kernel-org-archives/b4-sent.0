From: Roman Vivchar <rva333@protonmail.com>
Date: Wed, 23 Sep 2026 10:23:35 +0300
Subject: [PATCH 2/3] cpufreq: mediatek: add mt6572 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-6572-cpufreq-v1-2-41f7af6d6d1a@protonmail.com>
References: <20260923-6572-cpufreq-v1-0-41f7af6d6d1a@protonmail.com>
In-Reply-To: <20260923-6572-cpufreq-v1-0-41f7af6d6d1a@protonmail.com>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790148240; l=1524;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=b8RMk+Zv48cfJke7eSfTbaAxttUL1iUBiWM/BLYw9Fw=;
 b=WAtqaltRs4wSpqv0CO4qpYqEoudV+Gy+Tl/BfW9ztNKoM+pdXzu5ZvgkpisnwelUGwfCf0jXZ
 TU3bA3ie/SIAkFBJYaQbX87KwRldSLbbgOO/qXeUjDSAqfNG2EZuWf4
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add mt6572 SoC platform data for CPU frequency scaling.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/cpufreq/mediatek-cpufreq.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/cpufreq/mediatek-cpufreq.c b/drivers/cpufreq/mediatek-cpufreq.c
index f15135b2898b..615bccc77c98 100644
--- a/drivers/cpufreq/mediatek-cpufreq.c
+++ b/drivers/cpufreq/mediatek-cpufreq.c
@@ -737,6 +737,14 @@ static const struct mtk_cpufreq_platform_data mt2701_platform_data = {
 	.ccifreq_supported = false,
 };
 
+static const struct mtk_cpufreq_platform_data mt6572_platform_data = {
+	.min_volt_shift = 100000,
+	.max_volt_shift = 200000,
+	.proc_max_volt = 1250000,
+	.sram_min_volt = 0,
+	.ccifreq_supported = false,
+};
+
 static const struct mtk_cpufreq_platform_data mt7622_platform_data = {
 	.min_volt_shift = 100000,
 	.max_volt_shift = 200000,
@@ -793,6 +801,7 @@ static const struct mtk_cpufreq_platform_data mt8516_platform_data = {
 static const struct of_device_id mtk_cpufreq_machines[] __initconst __maybe_unused = {
 	{ .compatible = "mediatek,mt2701", .data = &mt2701_platform_data },
 	{ .compatible = "mediatek,mt2712", .data = &mt2701_platform_data },
+	{ .compatible = "mediatek,mt6572", .data = &mt6572_platform_data },
 	{ .compatible = "mediatek,mt7622", .data = &mt7622_platform_data },
 	{ .compatible = "mediatek,mt7623", .data = &mt7623_platform_data },
 	{ .compatible = "mediatek,mt7988a", .data = &mt7988_platform_data },

-- 
2.55.0

