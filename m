From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Sun, 25 Oct 2026 18:13:44 +0100
Subject: [PATCH] gpu: host1x: mipi: Disable clock again after powering down
 the pads
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-upstream-host1x-mipi-clk-v1-1-6bc6e755b4cb@tsv-stahl-riesa.de>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrB1IAjXSqxQXMZnqtFVDJhZBv
 HtTXb7F/zsIJSaBe7VDoi8LL3OBrivwo5sHQg7FYJRptDI3XKPkRG7CcZGsN5w4MvrPG9vGUnB
 BW9srKHlM9OTtXD+6y7L2L/L5/4Pj+AFsAn58fAAAAA==
X-Change-ID: 20261025-upstream-host1x-mipi-clk-867edad177b0
To: Thierry Reding <thierry.reding@kernel.org>, 
 Mikko Perttunen <mperttunen@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Jonathan Hunter <jonathanh@nvidia.com>
Cc: Thierry Reding <treding@nvidia.com>, dri-devel@lists.freedesktop.org, 
 Svyatoslav Ryhel <clamor95@gmail.com>, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792948429; l=2449;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=IqCP8sWJtCLgWyd5xt/XstbRFuDUueRcejtTTWyeurE=;
 b=lBTdo24bssxZ/0pg7gT0fqak5kfrXQlhLtVnpWYodJfpjoF4etnW0lF+foOFhOoHAiunw9n1x
 8qt7ntmx10hAiLVKjs8lOCLZ3ymbg5E2EhAuFgYhXHvL7Kxy5OQwynN
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tegra114_mipi_power_down() enables the MIPI calibration clock to access
the bias pad registers but never disables it. Every disable/enable cycle
of a DSI or CSI user therefore leaks one enable count, and the clock
stays on for good after the first power down.

Add the missing clk_disable(), matching tegra114_mipi_power_up().

The leak gets more costly with "clk: tegra: Fix Tegra114 MIPI
calibration clock parent", which makes PLL_P_OUT3 the parent of
mipi-cal: without this fix PLL_P_OUT3 would then stay on as well.

On a Tegra Note 7 (P1640) the enable count of mipi-cal in clk_summary
grew by one with each DPMS off/on cycle of the DSI panel. With this
patch it returns to 0 after each cycle.

Fixes: 15372d4be7f0 ("gpu: host1x: mipi: Power down regulators when unused")
Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
Mikko's "clk: tegra: Fix Tegra114 MIPI calibration clock parent" [1]
fixes the MIPI calibration timeouts on Tegra114. While testing the same
change on a Tegra Note 7 (P1640) I noticed that
tegra114_mipi_power_down() leaks the clock enable it takes. With [1]
applied that leak keeps PLL_P_OUT3 on after the first DPMS off, so the
two belong together, although this patch applies and makes sense on
its own.

[1] https://lore.kernel.org/all/20260930-b4-dalmore-fixes-mipical-clk-v1-1-0518be6c7979@nvidia.com/

Tool use (see Documentation/process/generated-content.rst): this patch,
its changelog and this note were prepared with an LLM coding assistant
(Claude Code). It traced the clock enable counts from my clk_summary
dumps and wrote the code change and the texts from my measurements and
instructions. I reviewed the change and ran the test on the device.
---
 drivers/gpu/host1x/tegra114-mipi.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/gpu/host1x/tegra114-mipi.c b/drivers/gpu/host1x/tegra114-mipi.c
index c084a09784d1..83a43a5e33af 100644
--- a/drivers/gpu/host1x/tegra114-mipi.c
+++ b/drivers/gpu/host1x/tegra114-mipi.c
@@ -197,6 +197,8 @@ static int tegra114_mipi_power_down(struct tegra_mipi *mipi)
 	value |= MIPI_CAL_BIAS_PAD_PDVCLAMP;
 	tegra_mipi_writel(mipi, value, MIPI_CAL_BIAS_PAD_CFG0);
 
+	clk_disable(mipi->clk);
+
 	return 0;
 }
 

---
base-commit: 734bef548a96e8774d6eef5dfa2026c6edc4e80b
change-id: 20261025-upstream-host1x-mipi-clk-867edad177b0

Best regards,
--  
Patrick Fischer <admin@tsv-stahl-riesa.de>

