From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Wed, 11 Nov 2026 11:10:57 +0100
Subject: [PATCH 2/6] memory: tegra114-emc: Use the full DRAM bus width for
 interconnect requests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-upstream-emc-t114-v1-2-54d9e1bceb6a@tsv-stahl-riesa.de>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794391862; l=2117;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=UKyU8gpXKnhxvj2H37ZDY9d2HuSp5Dvn+JPZlIlWg+0=;
 b=N3OmQ1Ge4ojApoGjsEOZEqZvTWPcxMM0WKEHL1mgIyk4GG4Dw72eK7Oq9+XJzRvklgzMxjl/K
 M26mI6Vim7BDGO/wUHjVsVRAZdHlruwZz2RegL7L3wH4bcYFpAo7Umo
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Tegra114 has two 32-bit EMC channels, so the DRAM data bus is 64 bits
wide: the Tegra 4 TRM describes a "dual-channel (2x 32-bit)" DRAM
interface with separate EMC0 and EMC1 register blocks, and the
downstream kernel says "On Tegra11 dual channel MC effectively operates
as 64-bit bus" and returns 8 from tegra_mc_get_effective_bytes_width()
(arch/arm/mach-tegra/include/mach/mc.h, rel-tegranote-r8).

emc_icc_set() divides the requested bandwidth by 4 bytes instead, so
every interconnect request asks for twice the EMC rate it needs. The
actmon OPP table in tegra114-peripherals-opp.dtsi already uses
kBps = kHz x 16, which matches the 64-bit bus: with the current driver
actmon at 312 MHz requests an EMC rate of 624 MHz, and actmon at 624 MHz
requests 1248 MHz, which ends up at the highest table.

Use 8 bytes. On a Tegra Note 7 (P1640) the EMC rate now follows the
actmon level (102 -> 102 MHz, 204 -> 204 MHz, 624 -> 624 MHz).

With the correct width the EMC ends up at a real 624 MHz on pll_c more
often. Both kernel panics I saw on a rate change to 624 MHz were with
the auto-calibration cleared, so this should not be backported without
"memory: tegra114-emc: Stop clearing EMC_AUTO_CAL_CONFIG".

Fixes: dce208b5405f ("memory: tegra: Add Tegra114 EMC driver")
Cc: stable@vger.kernel.org
Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 drivers/memory/tegra/tegra114-emc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/memory/tegra/tegra114-emc.c b/drivers/memory/tegra/tegra114-emc.c
index eb1360627ece..6ec1bb2c3ed0 100644
--- a/drivers/memory/tegra/tegra114-emc.c
+++ b/drivers/memory/tegra/tegra114-emc.c
@@ -1163,7 +1163,7 @@ static int emc_icc_set(struct icc_node *src, struct icc_node *dst)
 	unsigned long long peak_bw = icc_units_to_bps(dst->peak_bw);
 	unsigned long long avg_bw = icc_units_to_bps(dst->avg_bw);
 	unsigned long long rate = max(avg_bw, peak_bw);
-	unsigned int dram_data_bus_width_bytes = 4;
+	unsigned int dram_data_bus_width_bytes = 8;
 	const unsigned int ddr = 2;
 	int err;
 

-- 
2.56.0

