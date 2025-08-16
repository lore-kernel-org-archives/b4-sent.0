From: Aaron Kling <webgeek1234@gmail.com>
Date: Sat, 16 Aug 2025 00:53:35 -0500
Subject: [PATCH 3/5] soc: tegra: fuse: speedo-tegra210: Add sku 0x8F
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250816-tegra210-speedo-v1-3-a981360adc27@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755323658; l=976;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=pWQFdNwG5wqAUfrAYFEYhFd3g2VQZFhe1CBj1AG4N/Q=;
 b=hIQ9qJnm6qDoO0yAW2MX7dJ374+oXSQkdsje8YbYZoXPkHMerXkpgbxMnshwM0GU9PBkgI/FV
 +Z4KGZDvD4WAS1Ei5l804K8fZ1T7uKGLAjZhSgq6U1WrRdUaGAJbSxB
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is used by the Jetson Nano series of SoMs

Fixes: 579db6e5d9b8 ("arm64: tegra: Enable DFLL support on Jetson Nano")
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/soc/tegra/fuse/speedo-tegra210.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/soc/tegra/fuse/speedo-tegra210.c b/drivers/soc/tegra/fuse/speedo-tegra210.c
index 909fdf8fcc9d9f5ac936ae322e7a73dc720e5ab6..1cdd70c59c0753e602709f9179c0ab67d1b8f5e3 100644
--- a/drivers/soc/tegra/fuse/speedo-tegra210.c
+++ b/drivers/soc/tegra/fuse/speedo-tegra210.c
@@ -99,6 +99,14 @@ static void __init rev_sku_to_speedo_ids(struct tegra_sku_info *sku_info,
 		sku_info->gpu_speedo_id = 1;
 		break;
 
+	case 0x8F:
+		if (speedo_rev >= 2) {
+			sku_info->cpu_speedo_id = 9;
+			sku_info->gpu_speedo_id = 2;
+			break;
+		}
+		fallthrough;
+
 	default:
 		pr_err("Tegra210: unknown SKU %#04x\n", sku);
 		/* Using the default for the error case */

-- 
2.50.1

