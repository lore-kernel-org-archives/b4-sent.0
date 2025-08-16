From: Aaron Kling <webgeek1234@gmail.com>
Date: Sat, 16 Aug 2025 00:53:36 -0500
Subject: [PATCH 4/5] clk: tegra: dfll: Support limiting max clock per
 device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250816-tegra210-speedo-v1-4-a981360adc27@gmail.com>
References: <20250816-tegra210-speedo-v1-0-a981360adc27@gmail.com>
In-Reply-To: <20250816-tegra210-speedo-v1-0-a981360adc27@gmail.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Joseph Lo <josephl@nvidia.com>, 
 Peter De Schrijver <pdeschrijver@nvidia.com>, 
 Prashant Gaikwad <pgaikwad@nvidia.com>
Cc: linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Thierry Reding <treding@nvidia.com>, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755323658; l=1449;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=F+yoRA15M31xbQIkPC6+4/poN2QJpx1PWxc/bXVO320=;
 b=sTV9RkNktfketMdtjuEkak8xkFZnoPszZGHh0v811QDSMTwmDGvJcopPKY1LzaYtIHzfBNHjB
 hRnt+C6cfP4AOceWHEFlJfKImaM+xDoRl0w16UCBz4iG2j9tBImXSRL
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some devices like the Jetson Nano report a cpu speedo value that scales
past the capabilities of the cpu. This allows limiting the maximum
scaling to a lower value within the table.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/clk/tegra/clk-tegra124-dfll-fcpu.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/drivers/clk/tegra/clk-tegra124-dfll-fcpu.c b/drivers/clk/tegra/clk-tegra124-dfll-fcpu.c
index 0251618b82c8321724ba0aec7a5bd90b2c2ffaf2..0c84f7e85baaa96fee005a1c9a5dd6afbd1875fa 100644
--- a/drivers/clk/tegra/clk-tegra124-dfll-fcpu.c
+++ b/drivers/clk/tegra/clk-tegra124-dfll-fcpu.c
@@ -556,6 +556,7 @@ static int tegra124_dfll_fcpu_probe(struct platform_device *pdev)
 	struct tegra_dfll_soc_data *soc;
 	const struct dfll_fcpu_data *fcpu_data;
 	struct rail_alignment align;
+	u32 max_freq;
 
 	fcpu_data = of_device_get_match_data(&pdev->dev);
 	if (!fcpu_data)
@@ -589,7 +590,12 @@ static int tegra124_dfll_fcpu_probe(struct platform_device *pdev)
 			return err;
 	}
 
-	soc->max_freq = fcpu_data->cpu_max_freq_table[speedo_id];
+	if (!of_property_read_u32(pdev->dev.of_node,
+				 "nvidia,dfll-max-freq",
+				 &max_freq))
+		soc->max_freq = max_freq;
+	else
+		soc->max_freq = fcpu_data->cpu_max_freq_table[speedo_id];
 
 	soc->cvb = tegra_cvb_add_opp_table(soc->dev, fcpu_data->cpu_cvb_tables,
 					   fcpu_data->cpu_cvb_tables_size,

-- 
2.50.1

