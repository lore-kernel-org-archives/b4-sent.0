From: EMCP333 <emcp@enser.io>
Date: Sun, 22 Nov 2026 05:12:17 +0000
Subject: [PATCH] gpu: host1x: mipi: Disable the clock
 tegra114_mipi_power_down() enables
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-host1x-mipi-clk-leak-v1-1-c14ac933945a@enser.io>
X-B4-Tracking: v=1; b=H4sIALB5AmsC/yXMwQ6CMBAE0F8he3aV1gYTf8V46K6LXUEgLRISw
 r/b6vFNZmaDJFElwbXaIMqiScchwxwq4OCHp6A+ssHWtjHGWiSHYUyzWfGtkyL3HfbiOxRqLZ8
 dmcbVkNdTlFbX3/Pt/nf60Et4LnelQT4JUvQDhxIVnpbL0WFkC/v+BQtT4aGbAAAA
X-Change-ID: 20261122-b4-host1x-mipi-clk-leak-ebf2c34b1640
To: Thierry Reding <thierry.reding@kernel.org>, 
 Mikko Perttunen <mperttunen@nvidia.com>
Cc: David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jonathan Hunter <jonathanh@nvidia.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, dri-devel@lists.freedesktop.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 EMCP333 <emcp@enser.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324337; l=1713;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=VGbtm9BeYSryKFEeMyTEi0gGwHdJTCkQyOlvmFoDkwo=;
 b=DYbtM9drcCf73KA8nDzug6e9NoLHkS655765BRprUKsqCyKFuFILPSeuaiaIANKNWRt0iUsx9
 zw37LaQzJYeCQJDQwmMITxyYAZ73wpS0ReG3A1+SE+MxoZM6f1XX2GA
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tegra114_mipi_power_down() enables the MIPI calibration clock to write
the bias pad registers and never disables it. tegra114_mipi_power_up()
pairs the same clk_enable() with a clk_disable(). Every DSI power-down
(each DPMS off, each suspend) therefore leaves one more enable behind,
and the clock never gates again.

On a Tegra Note 7 (Tegra114) the mipi-cal enable count is 0 at boot and
4 after four DPMS-offs, with the clock still running while the display
is off.

No register access follows the new clk_disable(), and every other access
in this driver takes the clock itself, so nothing depends on the leaked
enable.

Tested on that board: the mipi-cal enable count stays at 0 across three
DSI power-down/power-up cycles.

The code and this changelog were prepared with the help of an AI coding
assistant. The submitter has reviewed both and takes responsibility for
them.

Fixes: 15372d4be7f0 ("gpu: host1x: mipi: Power down regulators when unused")
Signed-off-by: EMCP333 <emcp@enser.io>
---
 drivers/gpu/host1x/tegra114-mipi.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/gpu/host1x/tegra114-mipi.c b/drivers/gpu/host1x/tegra114-mipi.c
index 49ed05d1a6..06130d453b 100644
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
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261122-b4-host1x-mipi-clk-leak-ebf2c34b1640

Best regards,
--  
EMCP333 <emcp@enser.io>

