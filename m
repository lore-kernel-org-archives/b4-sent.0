From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 21 Oct 2025 14:47:06 -0500
Subject: [PATCH] memory: tegra210: Fix incorrect client ids
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251021-t210-mem-clientid-fixup-v1-1-5094946faa31@gmail.com>
X-B4-Tracking: v=1; b=H4sIADnj92gC/x2MQQqAIBAAvxJ7bsE1FOor0aF0q4Wy0Iog+nvSc
 RhmHkgchRM0xQORL0myhQxUFuDmPkyM4jODVtqQ0oSHJoUrr+gW4XCIx1Huc0frjeN6GKyqCHK
 9R87iP7fd+35l7UmeaQAAAA==
X-Change-ID: 20251021-t210-mem-clientid-fixup-6d5ce9bb6031
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 linux-kernel@vger.kernel.org, linux-tegra@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761076027; l=1235;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=LT4M0FZugp2BvBr6W8Smqc6NSDGFFyx1kOqJIqzRmDo=;
 b=Y7UbDNdsPxaxd6U4wZtJN2c+50XyeiJkpq1l16Ni3Vr0iTDH8dMmMvv2On+fjKVXPPAbnx0dJ
 tVnE8a45EgHCw+A8SginP61YLlGxpQ1xHdzPN9YFPWBoPrCcgqS2xxp
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The original commit had typos for two of the memory client ids. Fix them
to reference the correct bindings.

Fixes: 3804cef4c597 ("memory: tegra210: Use bindings for client ids")
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/memory/tegra/tegra210.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/memory/tegra/tegra210.c b/drivers/memory/tegra/tegra210.c
index cfa61dd885577a8fbd79c396a1316101197ca1f2..3c2949c16fdef4911682da5e3cbfb91899e34c87 100644
--- a/drivers/memory/tegra/tegra210.c
+++ b/drivers/memory/tegra/tegra210.c
@@ -1015,7 +1015,7 @@ static const struct tegra_mc_client tegra210_mc_clients[] = {
 			},
 		},
 	}, {
-		.id = TEGRA210_MC_SESRD,
+		.id = TEGRA210_MC_SESWR,
 		.name = "seswr",
 		.swgroup = TEGRA_SWGROUP_SE,
 		.regs = {
@@ -1079,7 +1079,7 @@ static const struct tegra_mc_client tegra210_mc_clients[] = {
 			},
 		},
 	}, {
-		.id = TEGRA210_MC_ETRR,
+		.id = TEGRA210_MC_ETRW,
 		.name = "etrw",
 		.swgroup = TEGRA_SWGROUP_ETR,
 		.regs = {

---
base-commit: 211ddde0823f1442e4ad052a2f30f050145ccada
change-id: 20251021-t210-mem-clientid-fixup-6d5ce9bb6031

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

