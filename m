From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Subject: [PATCH 0/6] memory: tegra114-emc: Fix bus width and pad
 auto-calibration
Date: Wed, 11 Nov 2026 11:10:55 +0100
Message-Id: <20261111-upstream-emc-t114-v1-0-54d9e1bceb6a@tsv-stahl-riesa.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMywqDMBBA0V+RWXcgE1/QX5Eu0mTUEXyQiVIQ/
 920XZ7FvScoR2GFZ3FC5ENU1iWDHgX40S0Do4RssMY2RKbFfdMU2c3Is8dEVGEV6tJZVxtDAXK
 3Re7l83t2r791f0/s03cE13UDcS0LVXUAAAA=
X-Change-ID: 20261107-upstream-emc-t114-4d53a2a5001d
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794391862; l=5983;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=gWkZ9sMR0wqVhYJEWQWSZiG5AKiQGnM8VYMjsshbjj8=;
 b=0T0mLCBKLbK+HF1RGAP25033S6Ovp+Jd2Vjs9+qkwsXJPxyTb16YyHJJjjAKG63JuVFRG3OMa
 qhZPzEEeJ0fCX2qPuknx30/GFgtXnmSffN3C3Q6ePX4rY1R0aifSY2w
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a Tegra Note 7 (Tegra114, P1640) I had kernel panics, bit errors and
WLAN firmware hangs under load, and two kernel panics on EMC rate
changes from pll_p to 624 MHz on pll_c. Looking at the EMC I
found three problems in the Tegra114 EMC driver:

1. EMC_AUTO_CAL_CONFIG is masked down to the self-clearing start bit
   before it is written, which clears AUTO_CAL_ENABLE on the first rate
   change. The bootloader leaves calibration enabled, with channel 0 as
   master and channel 1 as slave. Patch 1 stops clearing the register.
   Programming the table values needs the channel registers, which
   patches 4 to 6 describe and use.
2. emc_icc_set() assumes a 32-bit DRAM bus, but Tegra114 has two 32-bit
   channels. Every interconnect request asks for twice the EMC rate, so
   actmon at 312 MHz moves the EMC to 624 MHz (patch 2).
3. Pad auto-calibration is disabled for every clock change, but the
   interval is only restored if EMC_CTT_TERM_CTRL changes, so it stays
   off after the first change (patch 3).

Patches 1 to 3 are small, do not depend on the device tree change and
are marked for stable. Patch 1 comes first on purpose: patch 2 and the
clk patch mentioned below make the EMC run at a real 624 MHz on pll_c
more often, and both panics I saw on a change to that rate were with
the calibration cleared. Patches 4 to 6 are not marked: they need the
binding and the device tree. Patches 1 to 5 are for the memory
controller tree, patch 6 for the Tegra tree. The driver has been there
since v7.2, but the first in-tree Tegra114 device tree with EMC timings
(TF701T) came with v7.4-rc1, so the stable tags matter for v7.4 and for
out-of-tree device trees.

A separate patch for clk-tegra124-emc.c deals with a related problem:
PLLM is fixed on Tegra114, but the device trees have timings at PLLM
rates the bootloader did not set up, and those are loaded with the EMC
at another rate. I am sending it to the clk maintainers at the same
time. It does not need this series to build, but it should not land in
a release without patch 1, for the reason above, so it is not marked
for stable and asks to be left out of AUTOSEL.

The Tegra Note 7 device tree is not in mainline yet; I used
Svyatoslav's tegratab series on top of v7.3 with this series. Results
on the P1640 (Micron MT41K128M16, 1 GB, RAM code 0), with the channel
registers in the device tree unless noted:

- EMC rate follows the actmon level (102, 204 and 624 MHz). The timing
  registers match the table at each rate.
- EMC_AUTO_CAL_CONFIG reads 0x20f10000 and 0x28f10000 in the two
  channels after rate changes (before: 0), the interval is set (before:
  0), and EMC_AUTO_CAL_STATUS keeps changing (before: stuck).
- A memory test of 3 h 20 min on a wall charger (1700 passes of
  checksums and copies over 160 MB, memory sensor up to 65 degC, EMC at
  624 MHz in 1208 of the 1700 passes) ran without errors, the first two
  hours together with a WLAN upload of 36 GB. That kernel had this
  series, an unrelated wlcore fix and a debug print.
- With an earlier version that mapped the channel registers at fixed
  addresses, a memory test of about an hour with the EMC switching
  between 408 MHz on pll_p and 624 MHz on pll_c, and a 32 minute hold
  test at 624 MHz (pattern left untouched for 150 s per round, then
  compared), ran without errors or panics.
- With the same kernel but without the channel registers in the device
  tree, so that the driver takes the path patch 1 leaves for existing
  device trees (what a stable kernel with patches 1 to 3 does):
  EMC_AUTO_CAL_CONFIG keeps the bootloader values 0x20f10f0f and
  0x28f10f0f in the two channels through rate changes between 204, 408
  and 624 MHz, EMC_AUTO_CAL_STATUS keeps changing, and a 10 minute
  memory test switching between 408 MHz on pll_p and 624 MHz on pll_c
  on every pass (261 passes) ran without errors.

These runs do not prove that the missing calibration caused the earlier
panics, since those runs also had the wrong bus width, but I have not
seen a panic on a 624 MHz change since. I also do not claim that this
series fixes the WLAN hangs: on 7 November the WLAN chip stopped
transmitting for about a day with these patches applied and then worked
again, for reasons I could not find, and I have not been able to
reproduce it. Not tested: Dalmore, Roth, TF701T, suspend and resume.

Mikko, tegra124-emc.c has the same masking of EMC_AUTO_CAL_CONFIG
(since 73a7f0a90641). I cannot test on Tegra124 and do not know
whether its channels need the same per-channel setup, so I left it
alone. Is it worth a look there?

Tool use (see Documentation/process/generated-content.rst): the
patches, their changelogs and this cover letter were prepared with an
LLM coding assistant (Claude Code). It compared the driver with the
downstream tegra11_emc.c and the Tegra 4 TRM, read the EMC registers on
the device, wrote the code changes and drafted the texts from my
measurements and instructions. I reviewed the changes and ran all tests
on the device.

---
Patrick Fischer (6):
      memory: tegra114-emc: Stop clearing EMC_AUTO_CAL_CONFIG
      memory: tegra114-emc: Use the full DRAM bus width for interconnect requests
      memory: tegra114-emc: Always restore the auto-calibration interval
      dt-bindings: memory: tegra: Add Tegra114 EMC channel registers
      memory: tegra114-emc: Program pad auto-calibration per channel
      ARM: tegra: Add EMC channel registers on Tegra114

 .../memory-controllers/nvidia,tegra124-emc.yaml    | 11 ++++++-
 arch/arm/boot/dts/nvidia/tegra114.dtsi             |  3 +-
 drivers/memory/tegra/tegra114-emc.c                | 37 ++++++++++++++++------
 3 files changed, 39 insertions(+), 12 deletions(-)
---
base-commit: 1e88944ecbe9def8aeef898a2e9ce29cf509a9de
change-id: 20261107-upstream-emc-t114-4d53a2a5001d

Best regards,
--  
Patrick Fischer <admin@tsv-stahl-riesa.de>

