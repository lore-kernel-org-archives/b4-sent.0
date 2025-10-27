From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 27 Oct 2025 13:55:18 -0500
Subject: [PATCH v4 4/5] memory: tegra186: Support icc scaling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251027-tegra186-icc-p2-v4-4-e4e4f57e2103@gmail.com>
References: <20251027-tegra186-icc-p2-v4-0-e4e4f57e2103@gmail.com>
In-Reply-To: <20251027-tegra186-icc-p2-v4-0-e4e4f57e2103@gmail.com>
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761591315; l=2383;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=a/aaiaGuHyMc5nlB9Xe5+rxhKDOKwn8mtxYy/DM7ELQ=;
 b=sTiZwi1CKAAV0SWUPFee8cPPc6/4LR4iIF4TCTBWzREoSjQSVh+iuY/5/P5da1ERPlGnM+Olh
 Gi6l1d3fHY0BANgm5dmTyL1R19RlZTrjC2pCDMtEzMTIOJP0WO3mSg0
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Interconnect framework support to dynamically set the DRAM
bandwidth from different clients. The MC driver is added as an ICC
provider and the EMC driver is already a provider.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/memory/tegra/tegra186.c | 48 +++++++++++++++++++++++++++++++++++++++++
 1 file changed, 48 insertions(+)

diff --git a/drivers/memory/tegra/tegra186.c b/drivers/memory/tegra/tegra186.c
index aee11457bf8e032637d1772affb87da0cac68494..1384164f624af5d4aaccedc84443d203ba3db2c6 100644
--- a/drivers/memory/tegra/tegra186.c
+++ b/drivers/memory/tegra/tegra186.c
@@ -899,9 +899,56 @@ static const struct tegra_mc_client tegra186_mc_clients[] = {
 				.security = 0x51c,
 			},
 		},
+	}, {
+		.id = TEGRA_ICC_MC_CPU_CLUSTER0,
+		.name = "sw_cluster0",
+		.type = TEGRA_ICC_NISO,
+	}, {
+		.id = TEGRA_ICC_MC_CPU_CLUSTER1,
+		.name = "sw_cluster1",
+		.type = TEGRA_ICC_NISO,
 	},
 };
 
+static int tegra186_mc_icc_set(struct icc_node *src, struct icc_node *dst)
+{
+	/* TODO: program PTSA */
+	return 0;
+}
+
+static int tegra186_mc_icc_aggregate(struct icc_node *node, u32 tag, u32 avg_bw,
+				     u32 peak_bw, u32 *agg_avg, u32 *agg_peak)
+{
+	struct icc_provider *p = node->provider;
+	struct tegra_mc *mc = icc_provider_to_tegra_mc(p);
+
+	if (node->id == TEGRA_ICC_MC_CPU_CLUSTER0 ||
+	    node->id == TEGRA_ICC_MC_CPU_CLUSTER1) {
+		if (mc)
+			peak_bw = peak_bw * mc->num_channels;
+	}
+
+	*agg_avg += avg_bw;
+	*agg_peak = max(*agg_peak, peak_bw);
+
+	return 0;
+}
+
+static int tegra186_mc_icc_get_init_bw(struct icc_node *node, u32 *avg, u32 *peak)
+{
+	*avg = 0;
+	*peak = 0;
+
+	return 0;
+}
+
+static const struct tegra_mc_icc_ops tegra186_mc_icc_ops = {
+	.xlate = tegra_mc_icc_xlate,
+	.aggregate = tegra186_mc_icc_aggregate,
+	.get_bw = tegra186_mc_icc_get_init_bw,
+	.set = tegra186_mc_icc_set,
+};
+
 const struct tegra_mc_soc tegra186_mc_soc = {
 	.num_clients = ARRAY_SIZE(tegra186_mc_clients),
 	.clients = tegra186_mc_clients,
@@ -912,6 +959,7 @@ const struct tegra_mc_soc tegra186_mc_soc = {
 		   MC_INT_SECERR_SEC | MC_INT_DECERR_VPR |
 		   MC_INT_SECURITY_VIOLATION | MC_INT_DECERR_EMEM,
 	.ops = &tegra186_mc_ops,
+	.icc_ops = &tegra186_mc_icc_ops,
 	.ch_intmask = 0x0000000f,
 	.global_intstatus_channel_shift = 0,
 };

-- 
2.51.0

