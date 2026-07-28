From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 27 Jul 2026 20:57:36 -0500
Subject: [PATCH v2 2/2] soc/tegra: fuse: speedo-tegra210: Support revision
 B01
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260727-t210b01-speedo-v2-2-4f287a3dab72@gmail.com>
References: <20260727-t210b01-speedo-v2-0-4f287a3dab72@gmail.com>
In-Reply-To: <20260727-t210b01-speedo-v2-0-4f287a3dab72@gmail.com>
To: Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>, Alex Frid <afrid@nvidia.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785203864; l=1864;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=VxU37xckYtNrvl4zdEjsAkIv4u2CSVJlt2LBjQhhA24=;
 b=sLwzwZ4QNo66hkggLWXOCvvxdiLfwB1fawvYs7ok8l5XgveewMOSL4b+xKAzMz9tX7t0n3Qiy
 TwSxsXkDlEaCbdNdkhz1dD2EPlR3SEq8QhYpkbCFr+Itp+fNSuPESk5
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Tegra210B01 has a separate set of skus and speedo tables

Based-on: https://gitlab.com/nvidia/nv-tegra/linux-5.10/-/commit/8555ef4988d3b39d91791794825c354b3c9377ba
Based-on-patch-by: Alex Frid <afrid@nvidia.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/soc/tegra/fuse/speedo-tegra210.c | 22 ++++++++++++++++++++--
 1 file changed, 20 insertions(+), 2 deletions(-)

diff --git a/drivers/soc/tegra/fuse/speedo-tegra210.c b/drivers/soc/tegra/fuse/speedo-tegra210.c
index 06c2bcbee5734..699751f4bd0c0 100644
--- a/drivers/soc/tegra/fuse/speedo-tegra210.c
+++ b/drivers/soc/tegra/fuse/speedo-tegra210.c
@@ -65,7 +65,25 @@ static void __init rev_sku_to_speedo_ids(struct tegra_sku_info *sku_info,
 	sku_info->gpu_speedo_id = 0;
 	*threshold = THRESHOLD_INDEX_0;
 
-	if (sku_info->revision >= TEGRA_REVISION_A02) {
+	if (sku_info->revision >= TEGRA_REVISION_B01) {
+		sku_info->gpu_speedo_id = 1;
+
+		switch (sku) {
+		case 0x00: /* Engineering SKU */
+		case 0x01: /* Engineering SKU */
+		case 0x83:
+			break;
+
+		case 0x87:
+			sku_info->cpu_speedo_id = 3;
+			break;
+
+		default:
+			pr_err("Tegra210B01: unknown SKU %#04x\n", sku);
+			/* Using the default for the error case */
+			break;
+		}
+	} else if (sku_info->revision >= TEGRA_REVISION_A02) {
 		switch (sku) {
 		case 0x00: /* Engineering SKU */
 		case 0x01: /* Engineering SKU */
@@ -154,7 +172,7 @@ void __init tegra210_init_speedo_data(struct tegra_sku_info *sku_info)
 	speedo_revision = get_speedo_revision();
 	pr_info("Speedo Revision %u\n", speedo_revision);
 
-	if (speedo_revision >= 3) {
+	if (sku_info->revision == TEGRA_REVISION_B01 || speedo_revision >= 3) {
 		sku_info->cpu_speedo_value = cpu_speedo[0];
 		sku_info->gpu_speedo_value = cpu_speedo[2];
 		sku_info->soc_speedo_value = soc_speedo[0];

-- 
2.54.0

