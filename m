From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 14 Jul 2025 23:02:55 -0500
Subject: [PATCH 12/17] usb: gadget: tegra-xudc: Add Tegra210B01 Support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250714-t210b01-v1-12-e3f5f7de5dce@gmail.com>
References: <20250714-t210b01-v1-0-e3f5f7de5dce@gmail.com>
In-Reply-To: <20250714-t210b01-v1-0-e3f5f7de5dce@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Nagarjuna Kristam <nkristam@nvidia.com>, JC Kuo <jckuo@nvidia.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Mathias Nyman <mathias.nyman@intel.com>, 
 Peter De Schrijver <pdeschrijver@nvidia.com>, 
 Prashant Gaikwad <pgaikwad@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-phy@lists.infradead.org, 
 linux-usb@vger.kernel.org, Thierry Reding <treding@nvidia.com>, 
 linux-pm@vger.kernel.org, linux-clk@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752552229; l=1624;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=hwelDVF01l5ZRuL1g/lhcmuuedoseJ2J1ZVrnMI3gXs=;
 b=baFB1DdUEiia6vOQK8oaNGYQd3FsJhUrLGKbcFZMIszCMnODWRn0Ug45lihanr925q/MIEhwc
 MiBWkJ36UueBY0taC3Y8kgN3WP59wXKyUpgQRjaLt6QHrUdgjgRhxJ5
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It doesn't need some of the workarounds that the original Tegra210 does.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/usb/gadget/udc/tegra-xudc.c | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/drivers/usb/gadget/udc/tegra-xudc.c b/drivers/usb/gadget/udc/tegra-xudc.c
index 2957316fd3d003e8444a825a72d228b7db06febe..1d2fb9bd51c7369dc5d056e49ae184659a40406c 100644
--- a/drivers/usb/gadget/udc/tegra-xudc.c
+++ b/drivers/usb/gadget/udc/tegra-xudc.c
@@ -3652,6 +3652,22 @@ static struct tegra_xudc_soc tegra210_xudc_soc_data = {
 	.has_ipfs = true,
 };
 
+static struct tegra_xudc_soc tegra210b01_xudc_soc_data = {
+	.supply_names = tegra210_xudc_supply_names,
+	.num_supplies = ARRAY_SIZE(tegra210_xudc_supply_names),
+	.clock_names = tegra210_xudc_clock_names,
+	.num_clks = ARRAY_SIZE(tegra210_xudc_clock_names),
+	.num_phys = 4,
+	.u1_enable = false,
+	.u2_enable = true,
+	.lpm_enable = false,
+	.invalid_seq_num = false,
+	.pls_quirk = false,
+	.port_reset_quirk = true,
+	.port_speed_quirk = false,
+	.has_ipfs = true,
+};
+
 static struct tegra_xudc_soc tegra186_xudc_soc_data = {
 	.clock_names = tegra186_xudc_clock_names,
 	.num_clks = ARRAY_SIZE(tegra186_xudc_clock_names),
@@ -3698,6 +3714,10 @@ static const struct of_device_id tegra_xudc_of_match[] = {
 		.compatible = "nvidia,tegra210-xudc",
 		.data = &tegra210_xudc_soc_data
 	},
+	{
+		.compatible = "nvidia,tegra210b01-xudc",
+		.data = &tegra210b01_xudc_soc_data
+	},
 	{
 		.compatible = "nvidia,tegra186-xudc",
 		.data = &tegra186_xudc_soc_data

-- 
2.50.0

