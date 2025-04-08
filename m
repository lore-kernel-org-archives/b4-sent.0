From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 07 Apr 2025 23:39:49 -0500
Subject: [PATCH 2/4] media: tegra-cec: Support Tegra186 and Tegra194
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250407-tegra-cec-v1-2-e25dd9577b5f@gmail.com>
References: <20250407-tegra-cec-v1-0-e25dd9577b5f@gmail.com>
In-Reply-To: <20250407-tegra-cec-v1-0-e25dd9577b5f@gmail.com>
To: Hans Verkuil <hverkuil@xs4all.nl>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-tegra@vger.kernel.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744087203; l=912;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=qzkH1Lb60CcGemYqjTXGR/2EtCT8x42nYq6ZuIVdnn4=;
 b=mwF6j61IoAjC9rHwr0PFWe+bAwWv8DsDyMBsHvheZZiELfnwymmTHlpUfaTRnASpGWoBIj4iX
 bz+hBJqhv2oCc5KOObnqKqs0WPxo25aU3fuZuBhPz3sHFgmjZoF1+Ss
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The tegra186 and tegra194 controllers are working with the driver as-is,
so add the compatibles to allow them to probe.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/media/cec/platform/tegra/tegra_cec.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/media/cec/platform/tegra/tegra_cec.c b/drivers/media/cec/platform/tegra/tegra_cec.c
index 3ed50097262f64c32fe0480698cea9a1056a0953..aa3d36286d256d59f9d726e5c3cee5decacd1d23 100644
--- a/drivers/media/cec/platform/tegra/tegra_cec.c
+++ b/drivers/media/cec/platform/tegra/tegra_cec.c
@@ -456,6 +456,8 @@ static const struct of_device_id tegra_cec_of_match[] = {
 	{ .compatible = "nvidia,tegra114-cec", },
 	{ .compatible = "nvidia,tegra124-cec", },
 	{ .compatible = "nvidia,tegra210-cec", },
+	{ .compatible = "nvidia,tegra186-cec", },
+	{ .compatible = "nvidia,tegra194-cec", },
 	{},
 };
 

-- 
2.48.1

