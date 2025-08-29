From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 28 Aug 2025 23:01:29 -0500
Subject: [PATCH RFC 3/7] soc: tegra: fuse: speedo-tegra210: Add soc speedo
 2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250828-t210-actmon-v1-3-aeb19ec1f244@gmail.com>
References: <20250828-t210-actmon-v1-0-aeb19ec1f244@gmail.com>
In-Reply-To: <20250828-t210-actmon-v1-0-aeb19ec1f244@gmail.com>
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Kyungmin Park <kyungmin.park@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, Dmitry Osipenko <digetx@gmail.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-pm@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756440091; l=920;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=isojD+vsQ6GMUI0n4UiI6pXl1P82vMLWzP2XI6DOUIc=;
 b=X+oENOtJ6PSQK6w4M/b6v+yDlwJUZO3OSStcth+1qalGBeKfPpEtGc4atN/hx6XMeQ8M8e2/j
 ncYPgf1yFrhDvPH8t5qb40TXI+YezXwulKE1eq2xbPh73GxaM9s2ha5
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Jetson Nano series of modules only have 2 emc table entries,
different from other soc sku's. As the emc driver uses the soc speedo to
populate the emc opp tables, add a new speedo id to uniquely identify
this.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/soc/tegra/fuse/speedo-tegra210.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/soc/tegra/fuse/speedo-tegra210.c b/drivers/soc/tegra/fuse/speedo-tegra210.c
index 1cdd70c59c0753e602709f9179c0ab67d1b8f5e3..56d7b0858050b7e5bc931a9491d68b1ce7cc427c 100644
--- a/drivers/soc/tegra/fuse/speedo-tegra210.c
+++ b/drivers/soc/tegra/fuse/speedo-tegra210.c
@@ -101,6 +101,7 @@ static void __init rev_sku_to_speedo_ids(struct tegra_sku_info *sku_info,
 
 	case 0x8F:
 		if (speedo_rev >= 2) {
+			sku_info->soc_speedo_id = 2;
 			sku_info->cpu_speedo_id = 9;
 			sku_info->gpu_speedo_id = 2;
 			break;

-- 
2.50.1

