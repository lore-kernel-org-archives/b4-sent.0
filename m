From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:07:23 -0400
Subject: [PATCH] soc: samsung: exynos-pmu: order pmu_base_addr before the
 pmu_context gate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-exynos-pmu-v1-1-4babb522ce0d@vt.edu>
X-B4-Tracking: v=1; b=H4sIAMrUsWoC/yXMwQ6CMBAE0F8he3ZNKQjRXzEe2rKVmlDIrhAM4
 d9p8fgmM7OBEAcSeBQbMC1BwhgTyksBrjfxTRi6ZNBKN+quSxws0vqLo+A0zNh525JvbopqA2k
 zMfmwnn/P198y2w+5bz7JDWuE0LKJrs/RyaW9Vsiuhn0/ANw7fnKRAAAA
X-Change-ID: 20260921-mb-exynos-pmu-dfb7ef650e4a
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790039246; l=2856;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=UHR1UXjtE/06jj6xsUliAK/0kfots+oi3SOpgn/U5a0=;
 b=emgwjZHZPHwQPyCmK57xog9f0D9CGIiNUr3ZrTqr+KJqBuFfPTVUBxx1VaPGQZsF7pKzwROTq
 UtmcfDuxk84AcRnKpDmF69AxBApeqLip8cS++McKsMWbSb4nWPblxu0
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

exynos_sys_powerdown_conf() returns early while pmu_context is NULL and
otherwise programs the PMU through pmu_raw_writel(), which uses the
separate global pmu_base_addr. exynos_pmu_probe() maps pmu_base_addr and
stores pmu_context afterwards, both with plain stores, and the reader
loads both plainly.

Neither the two stores nor the two loads are ordered. The callers are
the Exynos cpuidle AFTR path and the suspend path on 32-bit Exynos,
which run on other CPUs, so a caller that sees pmu_context before
pmu_base_addr writes the power-down configuration through a NULL base.

Publish pmu_context with smp_store_release() and read it with
smp_load_acquire().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/soc/samsung/exynos-pmu.c | 23 +++++++++++++++++------
 1 file changed, 17 insertions(+), 6 deletions(-)

diff --git a/drivers/soc/samsung/exynos-pmu.c b/drivers/soc/samsung/exynos-pmu.c
index efccdd63e..5ca5cfb8e 100644
--- a/drivers/soc/samsung/exynos-pmu.c
+++ b/drivers/soc/samsung/exynos-pmu.c
@@ -59,11 +59,14 @@ void exynos_sys_powerdown_conf(enum sys_powerdown mode)
 {
 	unsigned int i;
 	const struct exynos_pmu_data *pmu_data;
+	struct exynos_pmu_context *ctx;
 
-	if (!pmu_context || !pmu_context->pmu_data)
+	/* Pairs with the smp_store_release() in exynos_pmu_probe(). */
+	ctx = smp_load_acquire(&pmu_context);
+	if (!ctx || !ctx->pmu_data)
 		return;
 
-	pmu_data = pmu_context->pmu_data;
+	pmu_data = ctx->pmu_data;
 
 	if (pmu_data->powerdown_conf)
 		pmu_data->powerdown_conf(mode);
@@ -474,6 +477,7 @@ static int exynos_pmu_probe(struct platform_device *pdev)
 {
 	struct device *dev = &pdev->dev;
 	struct regmap_config pmu_regmcfg;
+	struct exynos_pmu_context *ctx;
 	struct regmap *regmap;
 	struct resource *res;
 	int ret;
@@ -482,12 +486,19 @@ static int exynos_pmu_probe(struct platform_device *pdev)
 	if (IS_ERR(pmu_base_addr))
 		return PTR_ERR(pmu_base_addr);
 
-	pmu_context = devm_kzalloc(&pdev->dev,
-			sizeof(struct exynos_pmu_context),
-			GFP_KERNEL);
-	if (!pmu_context)
+	ctx = devm_kzalloc(&pdev->dev, sizeof(struct exynos_pmu_context),
+			   GFP_KERNEL);
+	if (!ctx)
 		return -ENOMEM;
 
+	/*
+	 * exynos_sys_powerdown_conf() gates on pmu_context and then writes
+	 * through pmu_base_addr, which is a separate global. Publish the
+	 * context with release semantics so that the mapping is visible to
+	 * a CPU that passes the gate.
+	 */
+	smp_store_release(&pmu_context, ctx);
+
 	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
 	if (!res)
 		return -ENODEV;

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-exynos-pmu-dfb7ef650e4a

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

