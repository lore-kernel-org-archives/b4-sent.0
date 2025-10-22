From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 21 Oct 2025 22:11:15 -0500
Subject: [PATCH v5] soc: tegra: fuse: speedo-tegra210: Add soc speedo 2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251021-t210-actmon-p3-v5-1-e1ef5e93909d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAFJL+GgC/0XMyw7CIBCF4VdpWEsyM4ClfRXTBcJUWfQiYGPS+
 O5SXbj8T3K+XWROkbPom10k3mKOy1zDnBrh726+sYyhtiAgg0AoCyFI58u0zHJVUlkEUF2wyK2
 opzXxGF9f8DL8OvHjWd3yG/9s3xwoWCRZ+JbcAeeVOSxSt3DukO3Vet9v+oCvLrP0yzTFUo+II
 QQGS2pErYm1C2DI0ahgBAOojfcuODG83x8N0R9P4wAAAA==
X-Change-ID: 20251021-t210-actmon-p3-3810039d81e7
To: Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761102682; l=2079;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=MW8HFEQS9R+lPS9/S1KOlskDpwqUZBJBLhRfvIhSwIQ=;
 b=yWz3YwMw+bcDfQX1L+ueM+/Hyb7SfKE3PywfHQxpycJ9twMvzt9NPJP4u+8wr/tEV0lzwPynB
 dItkF6oCM1ZBMcNqIwok9eKEX+9YUjDQP/l0kxPRqt2Df5iEDoX0eCD
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
Changes in v5:
- Split series
- Link to v4: https://lore.kernel.org/r/20250923-t210-actmon-v4-0-442d1eb6377c@gmail.com

Changes in v4:
- Various cleanups in patch 5 as requested by review
- Fix a couple typos in patch 4
- Link to v3: https://lore.kernel.org/r/20250906-t210-actmon-v3-0-1403365d571e@gmail.com

Changes in v3:
- In patch 5, don't fail mc probe if opp tables are missing
- Add more mc bindings to patch 1
- Add patch to use tegra210-mc bindings in the mc driver
- Re-order series to align patches within a subsystem to each other
- Link to v2: https://lore.kernel.org/r/20250903-t210-actmon-v2-0-e0d534d4f8ea@gmail.com

Changes in v2:
- Assume 64-bit dram bus width in patch 4
- Add dt-bindings patch to document the new properties on the
  tegra210-emc node.
- Link to v1: https://lore.kernel.org/r/20250828-t210-actmon-v1-0-aeb19ec1f244@gmail.com
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

---
base-commit: 211ddde0823f1442e4ad052a2f30f050145ccada
change-id: 20251021-t210-actmon-p3-3810039d81e7
prerequisite-change-id: 20250812-tegra210-speedo-470691e8b8cc:v4
prerequisite-patch-id: d32dd215b54ac46086377c1ce2c8d53d746690c9

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

