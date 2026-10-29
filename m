From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Subject: [PATCH 0/3] Tegra114: Fix CPU DFLL voltages
Date: Thu, 29 Oct 2026 10:32:58 +0100
Message-Id: <20261029-upstream-speedo-t114-v1-0-81457cc9d94c@tsv-stahl-riesa.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQrCMBCE4Vcpe3bBpKYFX0U8xGTUFWxDNimF0
 nc36mEO32H+jRRZoHTuNspYRGWeGsyho/D00wMssZns0Q6mjWvSkuHfrAmIMxdjTty7YRx7F52
 3gdo1Zdxl/WUv17+13l4I5duiff8A9Srl2XgAAAA=
X-Change-ID: 20261026-upstream-speedo-t114-3567735d5a2c
To: Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Mikko Perttunen <mperttunen@nvidia.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, 
 Prashant Gaikwad <pgaikwad@nvidia.com>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, linux-clk@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793266385; l=4081;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=/lrIR8C9aN0HrUcDE1aMGU8c1QUaKAoG4KgVSPwL7/s=;
 b=sDqEJpNgmEA5eRDywidt+SLNcWdfGwXPBATBDqtk2yn4iRbSKEeYFNrOXiunqPjQ2H90QRFC6
 RWg2mWdmOF8CsvJ0MXR6mUbgPtAmFWdvM70SrH2N3TbSmG/jhwvGWGx
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since the Tegra114 CPU DFLL got its CVB tables in v6.18, it computes
the CPU OPP voltages from tegra_sku_info.cpu_speedo_value and the step
of the vdd_cpu regulator. On a Tegra Note 7 (Tegra114, TPS65913) every
CPU OPP from 306 MHz to 1810.5 MHz ends up at 1000 mV, and the DFLL
never changes vdd_cpu: it stays at the 1.10 V left by the bootloader,
and the CPU runs at about 1.34 GHz whatever cpufreq requests. Three
bugs cause this:

1. Since 2014 the speedo code reads the Tegra114 speedo fuses at offsets
   that are 0x100 too large.
2. It never stores the CPU and SoC speedo values in tegra_sku_info, so
   the DFLL computes with speedo 0, which overflows in
   round_cvb_voltage().
3. The DFLL takes the voltage step from regulator_get_linear_step(),
   which is 0 for the Palmas SMPS. Every OPP is rounded to 0 and so
   clamped to the minimum, and the I2C LUT holds a single selector.

On its own, patch 3 fixes the Xiaomi Mi Pad (Tegra124 with Palmas). On
Tegra114, which includes the TF701T, it needs patches 1 and 2: with
speedo 0 every OPP would still overflow to 1000 mV. That is why the
three patches go together, all with Cc: stable.

Since patch 3 is only useful on Tegra114 together with patches 1 and 2,
it would be easiest to take all three through the Tegra tree.

The Tegra Note 7 device tree is not in mainline yet; I used
Svyatoslav's tegratab series on top of v7.3, with these patches
applied. Results on a P1640 (Tegra114 A02, SKU 5, CPU speedo ID 1):

- The fuse values match what the vendor kernel prints for this device:
  CPU speedo 1742, SoC speedo 1156, CPU and SoC process 1 (before:
  SoC process 0).
- CPU OPPs: 1000 mV up to 1122 MHz, then 1040, 1070, 1110, 1150, 1180,
  1220 and 1270 mV at 1810.5 MHz, as computed from the CVB table.
  Before: all 1000 mV.
- The DFLL LUT holds selectors 0x38 to 0x53 (1000 mV to 1270 mV)
  instead of a single selector 0.
- The DFLL rate follows cpufreq within 2% from 306 MHz to 1708.5 MHz,
  with vdd_cpu between 1020 mV and 1260 mV. At 1810.5 MHz it stays at
  about 1.74 GHz at the end of the LUT (1270 mV). Before: about
  1.34 GHz at any request.
- At 1122 MHz under load on four cores for 480 s the CPU stays at
  52 degC with 3.15 W from the battery, compared to 73 degC and 4.48 W
  before.
- No errors in a memory test with 25 passes, in three 600 s load runs
  with cpufreq limits of 1428, 1606.5 and 1810.5 MHz (throttled to
  about 1.0 to 1.2 GHz by a board thermal zone), and in 316 s at
  1810.5 MHz with that trip raised (DFLL at about 1.73 GHz, 1270 mV, closed
  loop throughout, stopped by the test at 98 degC).

Svyatoslav measured the CPU OPPs on an Asus TF701T (CPU speedo ID 2):
without the series all of them are at 1000 mV; with it they are
1000 mV up to 1122 MHz, then 1020, 1050, 1090, 1120, 1150, 1190, 1240
and 1290 mV at 1912.5 MHz. The speedo IDs come from the SKU and do not
change, so the core, EMC and GPU OPPs stay the same, which he confirmed
on the TF701T.

Tool use (see Documentation/process/generated-content.rst): the patches,
their changelogs and this cover letter were prepared with an LLM coding
assistant (Claude Code). It compared the fuse offsets with the vendor
kernel, read the fuse words on the device, traced the zero voltage step
through the DFLL code, wrote the code changes and drafted the texts from
my measurements and instructions. I reviewed the changes and ran all
tests on the device.

---
Patrick Fischer (3):
      soc/tegra: fuse: Fix Tegra114 speedo fuse offsets
      soc/tegra: fuse: Store Tegra114 CPU and SoC speedo values
      clk: tegra: dfll: Get the voltage step of range-based regulators

 drivers/clk/tegra/clk-tegra124-dfll-fcpu.c | 26 ++++++++++++++++++++++++++
 drivers/soc/tegra/fuse/speedo-tegra114.c   | 16 ++++++++++++----
 2 files changed, 38 insertions(+), 4 deletions(-)
---
base-commit: c339f4010dea8b0d754f84ace70cd1b089878ef8
change-id: 20261026-upstream-speedo-t114-3567735d5a2c

Best regards,
--  
Patrick Fischer <admin@tsv-stahl-riesa.de>

