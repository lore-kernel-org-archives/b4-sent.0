From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Tue, 20 Oct 2026 21:18:26 +0200
Subject: [PATCH] thermal/drivers/tegra/soctherm: Program throttrip with hot
 trip temperature
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-upstream-soctherm-throttrip-v1-1-c67f8a02ec3b@tsv-stahl-riesa.de>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQrCMAwA0F8ZORvoCnbMXxEPXRdthK0lyUQY+
 3erHt/l7aAkTAqXbgehFyuXtaE/dZByXB+EPDeDdz70zjvcqppQXFBLskyyoGUpZsIV4xzGcB6
 HYQoJ2lCF7vz+7dfb37pNT0r2LeE4PrY5N+l/AAAA
X-Change-ID: 20261020-upstream-soctherm-throttrip-ad6965977b6c
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Zhang Rui <rui.zhang@intel.com>, Lukasz Luba <lukasz.luba@arm.com>, 
 linux-pm@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Svyatoslav Ryhel <clamor95@gmail.com>, 
 stable@vger.kernel.org, Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792523909; l=2148;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=RYgQxo1Q07jpqk6tE6wjPPC841A4mk8ZdJMQnRXuUBo=;
 b=m+kV5YsJ2VgwipWiC2LRknxKcOCe0vnTOfvlAi1qcANkDyhbRNLWXXlz744RW9VoCNU36PzzD
 ZHRsW+KATFUCWJrcFeXl20/r2ZpMQFT8NFRZNIe0bow92jA3+f4MJNT
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tegra_soctherm_set_hwtrips() is supposed to program the hardware
throttle trip (throttrip) with the temperature of the thermal zone's
hot trip point. Since commit 735a968d2fea ("thermal/drivers/tegra: Use
generic thermal_zone_get_trip() function"), get_hot_temp() only looks
up the hot trip and no longer stores its temperature, and the later
conversion to get_hot_trip() kept that behaviour. throttrip_program()
is therefore called with the value still left in 'temperature', which
is the thermtrip or critical temperature that was just used for
thermtrip_program().

As a result, hardware throttling only starts at the shutdown
temperature instead of at the hot trip. On the NVIDIA Tegra Note 7
(P1640, Tegra114), where tegra114.dtsi defines the hot trips at 100 C
and the critical trips at 102 C, soctherm reports:

  throttrip: will throttle when cpu reaches 102000 mC

instead of 100000 mC. Svyatoslav Ryhel observed the same on the ASUS
Transformer Pad TF701T (Tegra114) and the Xiaomi Mi Pad (Tegra124).
All boards using soctherm with a hot trip bound to a throttle cooling
device are affected.

Use the temperature of the hot trip for throttrip_program() again.

Fixes: 735a968d2fea ("thermal/drivers/tegra: Use generic thermal_zone_get_trip() function")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Tested-by: Svyatoslav Ryhel <clamor95@gmail.com>
Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 drivers/thermal/tegra/soctherm.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/thermal/tegra/soctherm.c b/drivers/thermal/tegra/soctherm.c
index f74acf13b24d..903215502606 100644
--- a/drivers/thermal/tegra/soctherm.c
+++ b/drivers/thermal/tegra/soctherm.c
@@ -765,6 +765,8 @@ static int tegra_soctherm_set_hwtrips(struct device *dev,
 		return 0;
 	}
 
+	temperature = hot_trip->temperature;
+
 	for (i = 0; i < THROTTLE_OC1; i++) {
 		struct thermal_cooling_device *cdev;
 

---
base-commit: f47d223627f80cb7a1eb14c585fe6cb35de5e984
change-id: 20261020-upstream-soctherm-throttrip-ad6965977b6c

Best regards,
--  
Patrick Fischer <admin@tsv-stahl-riesa.de>

