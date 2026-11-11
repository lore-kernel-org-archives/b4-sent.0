From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Wed, 11 Nov 2026 11:10:56 +0100
Subject: [PATCH 1/6] memory: tegra114-emc: Stop clearing
 EMC_AUTO_CAL_CONFIG
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-upstream-emc-t114-v1-1-54d9e1bceb6a@tsv-stahl-riesa.de>
References: <20261111-upstream-emc-t114-v1-0-54d9e1bceb6a@tsv-stahl-riesa.de>
In-Reply-To: <20261111-upstream-emc-t114-v1-0-54d9e1bceb6a@tsv-stahl-riesa.de>
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, 
 Mikko Perttunen <mperttunen@nvidia.com>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-tegra@vger.kernel.org, 
 Thierry Reding <thierry.reding@gmail.com>, devicetree@vger.kernel.org, 
 stable@vger.kernel.org, Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794391862; l=2555;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=VedvDoHeeh9Rio1y6TI1PoAGPqxv39pJW1v6xrOmiGA=;
 b=mXxhCsFz2yS8pLPwTfK02jdkktTzaRUq+XULbNJStzWwzYL3CXRJnpToHH73+rlvv+dObA/ko
 0MPJS13WleJCR7GD893vCIpKgc1YG3bS3RHmY016ye4+YT1tL6vhQkA
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tegra114_emc_prepare_timing_change() masks the EMC_AUTO_CAL_CONFIG value
of the timing with AUTO_CAL_START before writing it, which leaves only
the self-clearing start bit. As last_timing starts out zeroed, the first
rate change already does this write. From then on AUTO_CAL_ENABLE is
off and, according to the Tegra 4 TRM, the pads no longer use the
pull-up and pull-down codes from the calibration logic but the static
settings from the pad control registers. On a Tegra Note 7 (P1640) the
bootloader leaves 0x20f10f0f in channel 0 and 0x28f10f0f in channel 1;
after the first rate change both read 0.

The full value cannot be written through the broadcast registers
either: channel 0 runs the calibration and channel 1 is its slave
(AUTO_CAL_SLAVE_MODE, bit 27), so a broadcast write would make both
channels masters. Leave the register alone, which keeps the calibration
the way the bootloader set it up. That value is not necessarily the one
in the timing tables: on the P1640 the bootloader uses the pull-up and
pull-down offsets that the tables only have at 792 MHz (0xf0f). A later
patch programs the table values per channel where the device tree
describes the channel registers.

Tested on a Tegra Note 7 (P1640) with this series but without the
channel registers in the device tree, which takes the path this patch
leaves for existing device trees: both channels keep the bootloader
values through rate changes between 204, 408 and 624 MHz, and a 10
minute memory test switching between 408 and 624 MHz ran without
errors.

Fixes: dce208b5405f ("memory: tegra: Add Tegra114 EMC driver")
Cc: stable@vger.kernel.org
Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 drivers/memory/tegra/tegra114-emc.c | 6 ------
 1 file changed, 6 deletions(-)

diff --git a/drivers/memory/tegra/tegra114-emc.c b/drivers/memory/tegra/tegra114-emc.c
index e50d71842d3a..eb1360627ece 100644
--- a/drivers/memory/tegra/tegra114-emc.c
+++ b/drivers/memory/tegra/tegra114-emc.c
@@ -609,12 +609,6 @@ static int tegra114_emc_prepare_timing_change(struct tegra_emc *emc,
 		emc_ccfifo_writel(emc, timing->emc_auto_cal_config3,
 				  EMC_AUTO_CAL_CONFIG3);
 
-	if (timing->emc_auto_cal_config != last->emc_auto_cal_config) {
-		val = timing->emc_auto_cal_config;
-		val &= EMC_AUTO_CAL_CONFIG_AUTO_CAL_START;
-		emc_ccfifo_writel(emc, val, EMC_AUTO_CAL_CONFIG);
-	}
-
 	/* DDR3: predict MRS long wait count */
 	if (emc->dram_type == DRAM_TYPE_DDR3 &&
 	    dll_change == DLL_CHANGE_ON) {

-- 
2.56.0

