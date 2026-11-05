From: Rajan Yadav <rajanyadav0307@gmail.com>
Date: Wed, 04 Nov 2026 22:07:40 -0600
Subject: [PATCH] cpufreq: sun50i: Handle boards with the
 allwinner,sun50i-a133 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-a133-fix-v1-1-d0b5ad3d4c5d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAsB7GoC/yXMwQ5AMBAE0F+RPWvSVVH8ijgUi3UoaRFJ498Vx
 zeZmQCeHJOHOgng6GTPq43ANIF+NnYiwUM0ZDIrEGUuDColRr4Eaa10KSscKIdY3xzF+Ltq2t/
 +6Bbq93cP9/0AbGKilWwAAAA=
X-Change-ID: 20261104-a133-fix-e77378091de4
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, Yangtao Li <tiny.windzz@gmail.com>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 Rajan Yadav <rajanyadav0307@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793851659; l=2906;
 i=rajanyadav0307@gmail.com; s=20261103; h=from:subject:message-id;
 bh=4A7N9YN5wiX+ZykiP94lXzZf0+Fik83P+lyG8T8jS7g=;
 b=p+QFXeDZgAVLOudiBWC8+l6munkc1+dSGo/H5Tu3dx+asH/x36G4WB9M63AsGRKC1z7f6zyMW
 N8dAO+vX0x2DVlqSLbC9ZZhF5cHmo5aCniUjFwn45Ycc6tNyUp2rca1
X-Developer-Key: i=rajanyadav0307@gmail.com; a=ed25519;
 pk=4ZPeiP5qrv2b44q/Obxi2koUS70Q6npbttJnpUoTlgg=
X-Endpoint-Received: by B4 Relay for rajanyadav0307@gmail.com/20261103 with auth_id=1391
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Teclast P80 uses "allwinner,sun50i-a133" as its only SoC
compatible, as documented in the arm/sunxi.yaml binding. Neither the
sun50i cpufreq driver nor the cpufreq-dt-platdev blocklist lists it.
cpufreq-dt then probes on its own, finds only opp-microvolt-speedN
properties and fails:

  cpu cpu0: opp_parse_microvolt: opp-microvolt missing although OPP managing regulators
  cpu cpu0: _of_add_opp_table_v2: Failed to add OPP, -22
  cpu cpu0: OPP table can't be empty

so the board runs without CPU frequency scaling.

Add the compatible to both lists.

Tested on a KickPi K5C (A133) with its root compatible changed to
"allwinner,sun50i-a133" only: on v7.4-rc1 cpufreq fails as above, with
this change the sun50i driver probes and the A100 speed1 OPPs are used.
v6.18 fails the same way, also with "kickpi,k5c" listed first.

Claude Code (Anthropic) drafted this change and its message from my test
logs; I reviewed and tested it.

Fixes: 60b064eb82e6 ("arm64: dts: allwinner: A133: add basic support for Teclast P80 tablet")
Signed-off-by: Rajan Yadav <rajanyadav0307@gmail.com>
---
This fixes the Teclast P80 support added in v7.4-rc1, so I think it can
go in as a fix for 7.4. I do not have a Teclast P80; I reproduced the
failure on a KickPi K5C as described above. A series with A133 speed
grade support, which Andre asked for, follows separately.
---
 drivers/cpufreq/cpufreq-dt-platdev.c   | 1 +
 drivers/cpufreq/sun50i-cpufreq-nvmem.c | 1 +
 2 files changed, 2 insertions(+)

diff --git a/drivers/cpufreq/cpufreq-dt-platdev.c b/drivers/cpufreq/cpufreq-dt-platdev.c
index bce4c87573a..6bdeba47749 100644
--- a/drivers/cpufreq/cpufreq-dt-platdev.c
+++ b/drivers/cpufreq/cpufreq-dt-platdev.c
@@ -110,6 +110,7 @@ static const struct of_device_id blocklist[] __initconst = {
 	{ .compatible = "airoha,en7581", },
 
 	{ .compatible = "allwinner,sun50i-a100" },
+	{ .compatible = "allwinner,sun50i-a133", },
 	{ .compatible = "allwinner,sun50i-h6", },
 	{ .compatible = "allwinner,sun50i-h616", },
 	{ .compatible = "allwinner,sun50i-h618", },
diff --git a/drivers/cpufreq/sun50i-cpufreq-nvmem.c b/drivers/cpufreq/sun50i-cpufreq-nvmem.c
index 9261d148a16..5d4ff192e99 100644
--- a/drivers/cpufreq/sun50i-cpufreq-nvmem.c
+++ b/drivers/cpufreq/sun50i-cpufreq-nvmem.c
@@ -324,6 +324,7 @@ static struct platform_driver sun50i_cpufreq_driver = {
 static const struct of_device_id sun50i_cpufreq_match_list[] = {
 	{ .compatible = "allwinner,sun50i-h6" },
 	{ .compatible = "allwinner,sun50i-a100" },
+	{ .compatible = "allwinner,sun50i-a133" },
 	{ .compatible = "allwinner,sun50i-h616" },
 	{ .compatible = "allwinner,sun50i-h618" },
 	{ .compatible = "allwinner,sun50i-h700" },

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261104-a133-fix-e77378091de4

Best regards,
--  
Rajan Yadav <rajanyadav0307@gmail.com>

