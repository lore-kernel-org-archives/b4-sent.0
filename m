From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Fri, 06 Nov 2026 21:31:55 +0100
Subject: [PATCH 1/2] thermal: tegra: soctherm-fuse: Fix shifted_cp
 extension
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-upstream-soctherm-t114-v1-1-c875d1921084@tsv-stahl-riesa.de>
References: <20261106-upstream-soctherm-t114-v1-0-c875d1921084@tsv-stahl-riesa.de>
In-Reply-To: <20261106-upstream-soctherm-t114-v1-0-c875d1921084@tsv-stahl-riesa.de>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Mikko Perttunen <mperttunen@nvidia.com>, linux-pm@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793997117; l=1434;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=MLvTnVsW0kVdSgK51jO4RNGfRwj0oR/unyRQ4OwOQTg=;
 b=7CKnSpoLD386zMftzrm0HMM+g7cE5QtB0xWJNCCAWsgCyVJ6mYNiRP2bEC6WP4y6N85K33quW
 UOh8I/6qWgaB+7GyapE7IitnT+qt4w4hqzlUvSrY0PoY0U8kjfUGI5q
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Svyatoslav Ryhel <clamor95@gmail.com>

The shifted_cp value in tegra_calc_shared_calib() should be passed to
sign_extend32() similarly to how shifted_ft is handled. This omission
caused malfunctions in the GPU and memory thermal zones, which was
observed on the Tegratab.

Tegra124, Tegra132 and Tegra210 are not affected: SHIFT_CP is in the
low six bits of their fuse word, so sign-extending the whole word gives
the same result. Only Tegra114 has SHIFT_CP in bits [15:10].

Fixes: 48fc33b95159 ("thermal/drivers/tegra/soctherm-fuse: Prepare calibration for Tegra114 support")
Cc: stable@vger.kernel.org
Signed-off-by: Svyatoslav Ryhel <clamor95@gmail.com>
Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 drivers/thermal/tegra/soctherm-fuse.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/thermal/tegra/soctherm-fuse.c b/drivers/thermal/tegra/soctherm-fuse.c
index 8d37cd8c9122..2de1d0cb676e 100644
--- a/drivers/thermal/tegra/soctherm-fuse.c
+++ b/drivers/thermal/tegra/soctherm-fuse.c
@@ -102,7 +102,7 @@ int tegra_calc_shared_calib(const struct tegra_soctherm_fuse *tfuse,
 
 	shifted_cp = (val & tfuse->fuse_shift_cp_mask) >>
 		     tfuse->fuse_shift_cp_shift;
-	shifted_cp = sign_extend32(val, 5);
+	shifted_cp = sign_extend32(shifted_cp, 5);
 
 	shared->actual_temp_cp = 2 * NOMINAL_CALIB_CP + shifted_cp;
 	shared->actual_temp_ft = 2 * tfuse->nominal_calib_ft + shifted_ft;

-- 
2.56.0

