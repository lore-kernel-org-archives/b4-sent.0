From: Rajan Yadav <rajanyadav0307@gmail.com>
Subject: [PATCH v2 0/6] sunxi: A133: Add CPU speed grade detection and OPP
 table
Date: Wed, 18 Nov 2026 04:52:23 -0600
Message-Id: <20261118-a133-series-v2-0-8bcec9c9aadf@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGiD/WoC/22P3UrEMBSEX6Xk2khO/hqLLPseshcnyeluxG416
 RZl6bubtoIIXg7MfDNzZ4VyosK65s4yzamk8VqFfGhYuOD1TDzFqpkU0gIIzRGU4nuI994GEUl
 pGwKrifdMffrcaC+nXZebf6UwrYgfR6aPW62ZdhsbqBTcarrm+W9LZfEZOPAovMGoog4mHs8Dp
 rfHMA6HFeixEK9iSFPXWCsdtdVmvTTBRXA9KG1IoRRRgpNPiNSSZuu4SyrTmL+25zNsW/49WRc
 IbpyENnil0LW/C9hpWZZvX7XsRkMBAAA=
X-Change-ID: 20261104-a133-series-fb6c0de346cc
To: Yangtao Li <tiny.windzz@gmail.com>, Viresh Kumar <vireshk@kernel.org>, 
 Nishanth Menon <nm@ti.com>, Stephen Boyd <sboyd@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Alexander Sverdlin <alex@sverdlin.org>, 
 Cody Eksal <masterr3c0rd@epochal.quest>, 
 Paul Kocialkowski <paulk@sys-base.io>, 
 Rajan Yadav <rajanyadav0307@gmail.com>, kernel test robot <lkp@intel.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794999144; l=8641;
 i=rajanyadav0307@gmail.com; s=20261103; h=from:subject:message-id;
 bh=dK4U66K6ZJZQC9rPPJDKQ1oE5tN9CbP2exTQlSVCysk=;
 b=9bMHrQAtT9hESLMAPxi6AihS98ZZeXB+LSOelOMHYz5IhggvlY7KWTtQipW1UXV+jr2i3/sAl
 BGZoVJEeaFkDYX0Rhq6T7CzhgXNdJsJ8KswDHydIHhSEmmqpfsCIptD
X-Developer-Key: i=rajanyadav0307@gmail.com; a=ed25519;
 pk=4ZPeiP5qrv2b44q/Obxi2koUS70Q6npbttJnpUoTlgg=
X-Endpoint-Received: by B4 Relay for rajanyadav0307@gmail.com/20261103 with auth_id=1391
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Andre asked [1], in his review of my A100 thermal trips patch [2], to
look at the A133 speed bin selection and OPPs. Mainline treats the A133
as an A100: it reads only the CPU bin field and picks one of three A100
voltage tables. The vendor BSP for this family (sun50iw10, KickPi A133
Linux SDK, linux-4.9) picks one of 11 grades from the chip marking ID,
the CPU bin, the ICPU current, a field it calls PCPU, a bin extension
bit and the die revision.

The A100 rule in mainline turns out to be the BSP rule for one group of
parts: revision A-E parts with a normal marking ID get a0-a2 from the
same bin rule and with the same voltages as the A100 table, apart from
a small ICPU/PCPU range that the BSP forces to a0. It is wrong for
revision F and later parts (a3-a6) and for the "high speed" marking IDs
(b0-b3).

My KickPi K5C (A133, PCB V1.3) is such a high speed part of revision F:
the BSP rules select b2, up to 1512 MHz at 1.10 V. Mainline selects
A100 speed1, so the chip runs 40 mV below the vendor voltage at
408-816 MHz and 40 mV above it at 1200 and 1320 MHz, and tops out at
1464 MHz at 1.18 V. Alexander tested v1 on a b3 part (marking 0x1400,
bin 4, revision 6): the vendor kernel and this series both top out at
1512 MHz, mainline without it at 1464 MHz.

Patch 1 adds the binding, patch 2 prepares the driver without
functional change, patch 3 adds the grade selection, patch 4 adds the
efuse cells (no effect on its own), patch 5 adds the A133 OPP table and
patch 6 switches the three A133 boards in mainline to it.

Dependencies and merge path:
- "cpufreq: sun50i: Handle boards with the allwinner,sun50i-a133
  compatible" [3] is applied (Viresh, cpufreq/arm/linux-next,
  ba359703fc45). The Teclast P80 needs it for cpufreq at all; the
  other boards do not.
- Patches 1-3 are meant for the cpufreq tree, as the A100 binding and
  driver changes went last time; patches 4-6 are for the sunxi tree.
- The A133 table keeps the A100 compatible as a fallback, with the
  speed bin as its first cell. So patches 5-6 do not break anything if
  they land before patch 3: a kernel without patch 3 gets today's A100
  selection and voltages (with 1008 instead of 1080 MHz).
- The thermal trips patch [2] should land first. All my thermal runs
  had it, and without it patch 6 raises the top OPP of the high speed
  grades with no passive trip.

The die revision comes from SMCCC SOC_ID, as for the H616 and as Andre
asked. On the A133 only TF-A master provides it so far (sun50i_a133
platform, commit a584e8632a7a, not in a release yet). Without it the
driver keeps the A100 selection, adds the BSP's a0 rule for normal
parts (which never lowers a voltage), warns and carries on.

Measurements on the K5C (no heatsink, room temperature not controlled,
4 cores at full load, the 90 C passive trip from [2] in every run):

  OPPs         kernel   top OPP          steady  1 h at full load
  A100 speed1  6.18     1464 MHz 1.18 V  85.6 C  near 90 C from ~20 min,
                                                 throttled at ~33 min
  A133 b2      6.18     1512 MHz 1.10 V  78.2 C  1512 MHz, max 83.7 C
  this series  7.4-rc1  1512 MHz 1.10 V  -       1512 MHz, max 79.4 C

"steady" is the temperature after 10 minutes in a separate run. The b2
row on 6.18 used a test DTB with the b2 voltages. Over the hour, b2 did
3.7% more work (md5 loops) than A100 speed1. At the same 1200 MHz, the
b2 voltage (0.98 V instead of 1.02 V) ran about 2 C cooler. These are
single runs on one board, so take them as indications only.

Still open from v1:
- The factory table has, besides 1608 MHz for b0/b1, a 1416 MHz OPP for
  a0-a2 (a0 1.18 V, a1 1.18 V, a2 1.13 V). It is not in this version;
  I can add it if you want the table to match the factory one.
- A133P: the TrimUI Smart Pro (an "A133 Plus") stock kernel selects a
  grade named "c0", which neither vendor table I have contains. I found
  no published table or selection rule for it, so the A133P is not
  covered; it can be added when such data appears.

As agreed with Chen-Yu on the thermal trips thread [2], the
dynamic-power-coefficient for the power allocator will follow as a
separate patch on top of these OPPs.

AI assistance: I used Claude Code (Anthropic, Claude Opus 5.5)
throughout. It read the vendor BSP sources, the datasheets and my board
logs, drafted the code, the DT table and the commit messages, and wrote
the test scripts. I asked it to extract the vendor's selection rules,
to propose a design that fits the existing binding, to review the
series, and to write tests that compare the code with the BSP rules.
No vendor code was copied; only the rules and numbers were taken. I
reviewed every patch, ran all tests myself, and take responsibility
for the series.

Testing:
- host: the grade function, built from the driver source, matches the
  BSP rules for 120,960 combinations of boundary and typical field
  values, reaches all 11 grades and gives the A100 selection with the
  BSP's a0 rule when the revision is unknown; a second harness,
  written separately (also with Claude Code) from the BSP sources,
  checked 161,280,000 combinations with no difference
- host: a script compared every voltage and the frequency set of every
  grade with both vendor tables: no difference to the BSP table other
  than the added 1608 MHz OPP, and none to the factory table other
  than its 1416 MHz OPP for a0-a2
- each patch on its own: checkpatch --strict (one expected warning:
  the new OPP dtsi is covered by the existing MAINTAINERS entry), W=1
  build, sparse (patch 2 removes the one existing warning in the
  driver), dt_binding_check, and dtbs_check W=1 on the A100 perf1 and
  the three A133 boards; the binding rejects malformed test tables
- K5C: grade, OPPs and measured regulator voltages, a 1 h soak, the
  revision forced to unknown, the A100 table on the patched kernel, the
  new DTB on a kernel without patch 3 (fallback), the a133-only root
  compatible, and a missing efuse cell
- K5C, v2: with a test-only change forcing b0 and b1, the CPU PLL locked
  at 1608 MHz and the PMIC was set to 1.18 V (b0) and 1.13 V (b1); in
  two 20-minute full load runs at b0 the 90 C trip was reached after
  10-13 minutes and the temperature then stayed between 83.5 and 90.4 C

[1] https://lore.kernel.org/all/85dc4135-4684-4e17-95e4-833cf8753b64@arm.com/
[2] https://lore.kernel.org/all/20261103-a100-thermal-trips-v1-1-73bce7ff0767@gmail.com/
[3] https://lore.kernel.org/all/20261104-a133-fix-v1-1-d0b5ad3d4c5d@gmail.com/

---
Changes in v2:
- Patch 5: add 1608 MHz for b0 and b1, from the factory firmware table
  of the KickPi K5C, as Andre asked (keep 1.6 GHz for the parts that
  support it). Alexander's Reviewed-by/Tested-by of v1 are not carried
  over for this patch because of that change.
- Patch 6: the commit message mentions 1608 MHz for b0/b1; the change
  itself is the same as in v1.
- Patches 1-4 and 6: add Alexander's Reviewed-by/Tested-by tags.
- Cover letter: the dependency [3] is applied; the v1 questions are
  answered (keep 1608 MHz; leave the A100 table and the 1008 MHz
  message as they are; use SOC_ID and fail gracefully, as v1 does);
  the 1416 MHz and A133P points are listed above.
- Link to v1: https://patch.msgid.link/20261104-a133-series-v1-0-58217cb33a87@gmail.com

---
Rajan Yadav (6):
      dt-bindings: opp: h6: Add A133 operating points
      cpufreq: sun50i: Move nvmem cell reading into a helper
      cpufreq: sun50i: Add A133 speed grade detection
      arm64: dts: allwinner: a100: Add A133 speed grade efuse cells
      arm64: dts: allwinner: a133: Add CPU OPP table
      arm64: dts: allwinner: a133: Use the A133 CPU OPP table

 .../opp/allwinner,sun50i-h6-operating-points.yaml  |  94 ++++++++-
 arch/arm64/boot/dts/allwinner/sun50i-a100.dtsi     |  12 ++
 .../boot/dts/allwinner/sun50i-a133-cpu-opp.dtsi    | 182 ++++++++++++++++++
 .../allwinner/sun50i-a133-helperboard-core.dtsi    |   2 +-
 .../dts/allwinner/sun50i-a133-liontron-h-a133l.dts |   2 +-
 .../boot/dts/allwinner/sun50i-a133-teclast-p80.dts |   2 +-
 drivers/cpufreq/sun50i-cpufreq-nvmem.c             | 213 +++++++++++++++++++--
 7 files changed, 475 insertions(+), 32 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261104-a133-series-fb6c0de346cc
prerequisite-message-id: <20261104-a133-fix-v1-1-d0b5ad3d4c5d@gmail.com>
prerequisite-patch-id: 24b8eeb24a7f228410c3453027ff79fc785eb38d

Best regards,
--  
Rajan Yadav <rajanyadav0307@gmail.com>

