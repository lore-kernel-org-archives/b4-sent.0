From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Sat, 28 Nov 2026 00:44:38 +0100
Subject: [PATCH v2 1/2] thermal: tegra: soctherm-fuse: Fix shifted_cp
 extension
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-upstream-soctherm-t114-v2-1-abba0b143037@tsv-stahl-riesa.de>
References: <20261128-upstream-soctherm-t114-v2-0-abba0b143037@tsv-stahl-riesa.de>
In-Reply-To: <20261128-upstream-soctherm-t114-v2-0-abba0b143037@tsv-stahl-riesa.de>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795823083; l=1488;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=IcjQLi3EWU6uv5WDPVnI7H+1UDXjOHTlhu+GBJlQqns=;
 b=PgIHvzOtSW3OLtcWYAoN4ygEWEv/nJyAbtlhH6pa0gTNCPLy+U1zvXYZZwcGageMbNMYQlO8u
 0JhS/246hv/CTm7TdNmTUGdL2OxuIp7B8e+EgZmYlUhDG78kgtkD1kj
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
Reviewed-by: Mikko Perttunen <mperttunen@nvidia.com>
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
2.56.1

