From: Rajan Yadav <rajanyadav0307@gmail.com>
Subject: [PATCH 0/6] sunxi: A133: Add CPU speed grade detection and OPP
 table
Date: Wed, 04 Nov 2026 22:40:55 -0600
Message-Id: <20261104-a133-series-v1-0-58217cb33a87@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANgI7GoC/1WNwQ6CMBAFf4X0bE23LQWJMf6H4bBtF6wRVIrEx
 PjvFvDicZJ5894s0hAosip7s4GmEMOtTwCbjLkz9i3x4BMzKaQBEJojKMXXEW+sccKT0sY5lhb
 3gZrwWmqneuX4tBdy45z4GQM9nulmXDXWUYy43FTZ/v8ltfgEHLgXNkevvHa5P7YdhuvW3brDH
 LQYiSfowlhlxsiSiqQZK3NXeigbUDonhVJ4CaXcIVJBmtWfzxdDlZTe+gAAAA==
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
 linux-kernel@vger.kernel.org, Cody Eksal <masterr3c0rd@epochal.quest>, 
 Alexander Sverdlin <alex@sverdlin.org>, 
 Rajan Yadav <rajanyadav0307@gmail.com>, kernel test robot <lkp@intel.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793853656; l=9856;
 i=rajanyadav0307@gmail.com; s=20261103; h=from:subject:message-id;
 bh=JzlzVQevyB3luTQC9Vvd4h8wQVoshWS6n/bxaB0NczI=;
 b=r0rref4Kp7NrxXI5v7O2qA+WvyqjQKRXmVIzT9riIlmQPaPRH0pcilYNHve9bXVwTeEvpyS2P
 yuRfN84US40Dhu/dilWdfVsTPGyLjvAZ51q4ievsCYk0A88dvkABEPw
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
1464 MHz at 1.18 V.

Patch 1 adds the binding, patch 2 prepares the driver without
functional change, patch 3 adds the grade selection, patch 4 adds the
efuse cells (no effect on its own), patch 5 adds the A133 OPP table and
patch 6 switches the three A133 boards in mainline to it.

Dependencies and merge path:
- On the Teclast P80, cpufreq also needs "cpufreq: sun50i: Handle
  boards with the allwinner,sun50i-a133 compatible" [3], which I sent
  separately as a fix for 7.4. The other boards do not need it.
- Patches 1-3 are meant for the cpufreq tree, as the A100 binding and
  driver changes went last time; patches 4-6 are for the sunxi tree.
- The A133 table keeps the A100 compatible as a fallback, with the
  speed bin as its first cell. So patches 5-6 do not break anything if
  they land before patch 3: a kernel without patch 3 gets today's A100
  selection and voltages (with 1008 instead of 1080 MHz).
- The thermal trips patch [2] should land first. All my thermal runs
  had it, and without it patch 6 raises the top OPP of the high speed
  grades with no passive trip.

The die revision comes from SMCCC SOC_ID, as for the H616. On the A133
only TF-A master provides it so far (sun50i_a133 platform, commit
a584e8632a7a, not in a release yet). I did not guess a grade without
it: for the same bin, the revision A-E grades are mostly lower or equal
up to 816 MHz and higher or equal from 1008 MHz. So the driver then
keeps the A100 selection, adds the BSP's a0 rule for normal parts
(which never lowers a voltage) and warns. Revision F parts then still
run 20-40 mV below the vendor voltage at 408 and 600 MHz, some of them
also at 816 MHz, which is why it is a warning; tell me if you prefer a
notice, since owners of some boards may not be able to update their
firmware.

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

Questions:

1. 1.6 GHz. Andre mentioned the nominal 1.6 GHz OPP. The SDK's code
   and table select b2 for this chip and stop at 1512 MHz. The factory
   kernel on this board (built January 2026) has a newer table: there
   1608 MHz exists only for b0 and b1, the revision A-E high speed
   grades, at the same voltage as their 1512 MHz OPP (1.18 V and
   1.13 V), and 1416 MHz is added for a0-a2. That kernel selects b0 for
   this revision F chip; its boot log suggests that its cpufreq code
   does not read the revision (the revision is first read about 110 s
   after boot). With the series' rules this board stays b2, so adding
   1608 MHz for b0/b1 would not change it, and I have no revision A-E
   part to test. With the b0 voltages forced by a test DTB (6.18), the
   K5C was stable for an hour but sat at the 90 C trip, cycling between
   1416 and 1608 MHz, with less than 1% more work than b2. The A133
   datasheet says 1.6 GHz in V1.1 and 1.5 GHz in V1.5. Should 1608 MHz
   be added for speed6/7 (b0/b1), as in the factory table?
2. A100. The BSP uses the same rules for the A100, and the mainline A100
   table has the a0-a2 voltages, but at 1080 MHz where the BSP has
   1008 MHz. U-Boot starts the CPU at 1008 MHz, so mainline now logs
   "unlisted initial frequency". Should the A100 table move to
   1008 MHz too, or the A100 board to the new compatible? I can only
   test an A133.
3. SOC_ID. Would you rather have the driver read the revision from
   SYSCON+0x24 itself (the system controller is already in the DT)?
   Then it would not depend on the firmware, and parts would never run
   below the vendor voltage for lack of it. And do the Teclast P80 and
   the Helperboard run a TF-A with SOC_ID?
4. A133P. My SDK has no A133P data, and Andre expects it to go
   higher. An A133P whose marking ID is in the BSP's high speed list
   gets b grades with A133 voltages; otherwise it gets a grades (at
   most 1464 MHz). If someone has a newer BSP (5.4) with A133P tables
   and marking IDs, I can add them.
5. Testing. Patch 6 changes the Helperboard A133, Liontron H-A133L and
   Teclast P80, which I cannot test. A boot log with
   dyndbg="file sun50i-cpufreq-nvmem.c +p" on the kernel command line,
   and the contents of
   /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies,
   from those boards would be very welcome; no fuse dump is needed. On
   the P80 (secure boot), could someone also check SID bytes 0-1 (the
   marking ID)? If they read as 0 from Linux, a high speed part is
   treated as a normal one: it gets 1464 MHz instead of 1416 and
   1512 MHz and, if its bin extension bit is set, up to 20 mV less than
   its b grade would give.

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
  grade with the BSP table: no difference
- each patch on its own: checkpatch --strict (one expected warning:
  the new OPP dtsi is covered by the existing MAINTAINERS entry), W=1
  build, sparse (patch 2 removes the one existing warning in the
  driver), dt_binding_check, and dtbs_check W=1 on the A100 perf1 and
  the three A133 boards; the binding rejects malformed test tables
- K5C: grade, OPPs and measured regulator voltages, a 1 h soak, the
  revision forced to unknown, the A100 table on the patched kernel, the
  new DTB on a kernel without patch 3 (fallback), the a133-only root
  compatible, and a missing efuse cell

[1] https://lore.kernel.org/all/85dc4135-4684-4e17-95e4-833cf8753b64@arm.com/
[2] https://lore.kernel.org/all/20261103-a100-thermal-trips-v1-1-73bce7ff0767@gmail.com/
[3] https://lore.kernel.org/all/20261104-a133-fix-v1-1-d0b5ad3d4c5d@gmail.com/

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
 .../boot/dts/allwinner/sun50i-a133-cpu-opp.dtsi    | 172 +++++++++++++++++
 .../allwinner/sun50i-a133-helperboard-core.dtsi    |   2 +-
 .../dts/allwinner/sun50i-a133-liontron-h-a133l.dts |   2 +-
 .../boot/dts/allwinner/sun50i-a133-teclast-p80.dts |   2 +-
 drivers/cpufreq/sun50i-cpufreq-nvmem.c             | 213 +++++++++++++++++++--
 7 files changed, 465 insertions(+), 32 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261104-a133-series-fb6c0de346cc
prerequisite-message-id: <20261104-a133-fix-v1-1-d0b5ad3d4c5d@gmail.com>
prerequisite-patch-id: 24b8eeb24a7f228410c3453027ff79fc785eb38d

Best regards,
--  
Rajan Yadav <rajanyadav0307@gmail.com>

