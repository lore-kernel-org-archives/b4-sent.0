From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Wed, 11 Nov 2026 11:14:10 +0100
Subject: [PATCH] clk: tegra: tegra124-emc: Skip timings whose parent rate
 cannot be set
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-upstream-clk-emc-parent-v1-1-636eea572572@tsv-stahl-riesa.de>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSw7CMAwA0atUXmMpKSq/qyAWqeOCgYbIThFS1
 bs3wPItZmYwVmGDUzOD8ltMXqnCbxqgW0hXRonV0Lp2573b45StKIcR6flAHglzUE4Ft52PLtJ
 w7OMBap2VB/n8zufL3zb1d6by3cGyrPLnGj17AAAA
X-Change-ID: 20261107-upstream-clk-emc-parent-351d0dcf9bd8
To: Prashant Gaikwad <pgaikwad@nvidia.com>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>, 
 Mikko Perttunen <mperttunen@nvidia.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>
Cc: Brian Masney <bmasney@redhat.com>, Thierry Reding <treding@nvidia.com>, 
 linux-clk@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable+noautosel@kernel.org, 
 Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794392093; l=5092;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=6O+WzvkYoAaO5jXWXFBWqRwW5kYIxCEWKdPNp4Ndczk=;
 b=FTrv+GtupkxKHloaZku+A8CmQfPKs7Jw2RLUllNkiQ39lY2K/SZIafaFEiPVqwi2WGVxpNsVw
 HAh0WYWsz55CQiIDQaZpA4G58xqwqLe9lTrWmaTaUs/hp4U2nKHiw+g
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Each EMC timing names a parent clock and the rate that parent has to run
at. On Tegra114, PLLM is registered with TEGRA_PLL_FIXED, so its rate
cannot be changed, but the Tegra114 device trees still contain timings
on pll_m at rates the bootloader did not set up, e.g. 792 MHz on a
Tegra Note 7 where the bootloader leaves PLLM at 408 MHz.

emc_set_timing() calls clk_set_rate() on the parent, which succeeds
without changing anything, and then loads the 792 MHz timing while the
EMC runs at 408 MHz. On the Tegra Note 7 that gives a refresh interval
of about 15 us instead of 7.7 us (DDR3 allows 7.8 us), and the clock
core then reports 408 MHz, so later requests for 408 MHz keep the
792 MHz register values.

Skip timings whose parent cannot be rounded to the requested rate when
loading them, so that the highest reachable timing is used instead.
On Tegra124 PLLM is not fixed, so its timings should all stay; this was
not tested on Tegra124.

Fixes: cf561283254d ("clk: tegra: set up proper EMC clock implementation for Tegra114")
Cc: stable+noautosel@kernel.org # needs the Tegra114 EMC auto-calibration fixes
Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
Tested on a Tegra Note 7 (Tegra114, P1640) with Svyatoslav's tegratab
device tree on top of v7.3: both 792 MHz timings on pll_m are skipped at
boot ("pll_m cannot run at 792000000 Hz, skipping"), the EMC goes up to
624 MHz on pll_c instead, and the timing registers match the table at
each rate. Actmon requests for 792 MHz now end up at 624 MHz without
errors; a memory test of 3 h 20 min with mostly such requests ran
without errors, together with the EMC series below. Before, an actmon
request for 792 MHz left the EMC at 408 MHz with the 792 MHz register
values.

This came up together with a series for the Tegra114 EMC driver,
"memory: tegra114-emc: Fix bus width and pad auto-calibration" [1],
which I sent to the memory controller tree earlier today. This patch
builds without it, but please do not let it land in a release without
"memory: tegra114-emc: Stop clearing EMC_AUTO_CAL_CONFIG" from that
series: this patch moves the EMC from 408 MHz with the wrong register
values to a real 624 MHz on pll_c, and both kernel panics I saw on a
change to 624 MHz were with the pad auto-calibration cleared. For the
same reason it is not marked for stable and asks to be left out of
AUTOSEL, despite the Fixes tag: I could not show that the wrong register
values cause failures, while 624 MHz without calibration did.

[1] https://lore.kernel.org/r/20261111-upstream-emc-t114-v1-0-54d9e1bceb6a@tsv-stahl-riesa.de

As Svyatoslav confirmed, PLLM does not have to be fixed on Tegra114, so
the proper fix would be to make it scalable, as the downstream kernel
does. Until then, this keeps the EMC from running with register values
for another rate.

Tool use (see Documentation/process/generated-content.rst): the patch,
its changelog and this note were prepared with an LLM coding assistant
(Claude Code). It traced the rate change through the EMC clock code,
read the EMC registers on the device, wrote the code change and drafted
the texts from my measurements and instructions. I reviewed the change
and ran the tests on the device.
---
 drivers/clk/tegra/clk-tegra124-emc.c | 23 ++++++++++++++++++++---
 1 file changed, 20 insertions(+), 3 deletions(-)

diff --git a/drivers/clk/tegra/clk-tegra124-emc.c b/drivers/clk/tegra/clk-tegra124-emc.c
index 0fc74808fe39..2f4d39922b73 100644
--- a/drivers/clk/tegra/clk-tegra124-emc.c
+++ b/drivers/clk/tegra/clk-tegra124-emc.c
@@ -458,7 +458,7 @@ static int load_timings_from_dt(struct tegra_clk_emc *tegra,
 	tegra->num_timings += child_count;
 
 	for_each_child_of_node_scoped(node, child) {
-		struct emc_timing *timing = timings_ptr + (i++);
+		struct emc_timing *timing = timings_ptr + i;
 
 		err = load_one_timing_from_dt(tegra, timing, child);
 		if (err) {
@@ -466,11 +466,28 @@ static int load_timings_from_dt(struct tegra_clk_emc *tegra,
 			return err;
 		}
 
+		/*
+		 * The register values of a timing are only valid at its rate.
+		 * If the parent cannot provide the parent rate, for example
+		 * because the PLL has a fixed rate, the EMC would run at a
+		 * different rate with these values. Skip such a timing.
+		 */
+		if (clk_round_rate(timing->parent, timing->parent_rate) !=
+		    timing->parent_rate) {
+			pr_warn("timing %pOF: %s cannot run at %lu Hz, skipping\n",
+				child, __clk_get_name(timing->parent),
+				timing->parent_rate);
+			clk_put(timing->parent);
+			continue;
+		}
+
 		timing->ram_code = ram_code;
+		i++;
 	}
 
-	sort(timings_ptr, child_count, sizeof(struct emc_timing),
-	     cmp_timings, NULL);
+	tegra->num_timings -= child_count - i;
+
+	sort(timings_ptr, i, sizeof(struct emc_timing), cmp_timings, NULL);
 
 	return 0;
 }

---
base-commit: f4897f9ed38a327ce63658e025c7d2229a0d9368
change-id: 20261107-upstream-clk-emc-parent-351d0dcf9bd8

Best regards,
--  
Patrick Fischer <admin@tsv-stahl-riesa.de>

