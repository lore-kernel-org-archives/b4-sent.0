From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 23 Sep 2025 12:05:32 -0500
Subject: [PATCH v4 6/9] soc: tegra: fuse: speedo-tegra210: Add soc speedo 2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250923-t210-actmon-v4-6-442d1eb6377c@gmail.com>
References: <20250923-t210-actmon-v4-0-442d1eb6377c@gmail.com>
In-Reply-To: <20250923-t210-actmon-v4-0-442d1eb6377c@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758647133; l=904;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=N7lGBqhTJZWYrEQodS0d8DsadeWZ1d1qRRIiTkeqLjU=;
 b=0ONLH6ndKxZB2LMvLtiqBopdbgCrCSk4YmehtNa9VxW4daIveaj3XylChxGrkFq4vGm0xqGaD
 0ATVgLUrkUEC5QH52Cfo1AI8F4A+/a80q5p9EOZyclW/kXX1FZrOR12
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
index a8cc3632977230fbfda0f8c3bfa7b7b25c2378fe..06c2bcbee5734207e3ebacb4057da2195f85321c 100644
--- a/drivers/soc/tegra/fuse/speedo-tegra210.c
+++ b/drivers/soc/tegra/fuse/speedo-tegra210.c
@@ -97,6 +97,7 @@ static void __init rev_sku_to_speedo_ids(struct tegra_sku_info *sku_info,
 			break;
 
 		case 0x8F:
+			sku_info->soc_speedo_id = 2;
 			sku_info->cpu_speedo_id = 9;
 			sku_info->gpu_speedo_id = 2;
 			break;

-- 
2.51.0

