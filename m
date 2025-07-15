From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 14 Jul 2025 23:02:54 -0500
Subject: [PATCH 11/17] usb: xhci: tegra: Add Tegra210B01 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250714-t210b01-v1-11-e3f5f7de5dce@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752552229; l=1932;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=FYMpkpyzM578fnGIvudlc1If8b1f7SqQ00jSgTIDo10=;
 b=IZGaeuYCPAcdA7HqcAhnztHUBEbuakRfcaUkoGkPrr6y5zD9XB/sAdNRtnBLyEObkWOFTY8rJ
 HpGkX93861dAVCZYBhothATAUfHwdGyH+JllEFyOyHZAbASs9eIFtb5
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This uses a different firmware, but is otherwise compatible with
Tegra210.
---
 drivers/usb/host/xhci-tegra.c | 25 +++++++++++++++++++++++++
 1 file changed, 25 insertions(+)

diff --git a/drivers/usb/host/xhci-tegra.c b/drivers/usb/host/xhci-tegra.c
index 0c7af44d4dae5066e66bd29c961510892b6e1301..aef100415f453fdd95c83cf511a914cf62e3e775 100644
--- a/drivers/usb/host/xhci-tegra.c
+++ b/drivers/usb/host/xhci-tegra.c
@@ -2547,6 +2547,30 @@ static const struct tegra_xusb_soc tegra210_soc = {
 };
 MODULE_FIRMWARE("nvidia/tegra210/xusb.bin");
 
+static const struct tegra_xusb_soc tegra210b01_soc = {
+	.firmware = "nvidia/tegra210b01/xusb.bin",
+	.supply_names = tegra210_supply_names,
+	.num_supplies = ARRAY_SIZE(tegra210_supply_names),
+	.phy_types = tegra210_phy_types,
+	.num_types = ARRAY_SIZE(tegra210_phy_types),
+	.context = &tegra124_xusb_context,
+	.ports = {
+		.usb2 = { .offset = 4, .count = 4, },
+		.hsic = { .offset = 8, .count = 1, },
+		.usb3 = { .offset = 0, .count = 4, },
+	},
+	.scale_ss_clock = false,
+	.has_ipfs = true,
+	.otg_reset_sspi = true,
+	.mbox = {
+		.cmd = 0xe4,
+		.data_in = 0xe8,
+		.data_out = 0xec,
+		.owner = 0xf0,
+	},
+};
+MODULE_FIRMWARE("nvidia/tegra210b01/xusb.bin");
+
 static const char * const tegra186_supply_names[] = {
 };
 MODULE_FIRMWARE("nvidia/tegra186/xusb.bin");
@@ -2659,6 +2683,7 @@ static const struct tegra_xusb_soc tegra234_soc = {
 static const struct of_device_id tegra_xusb_of_match[] = {
 	{ .compatible = "nvidia,tegra124-xusb", .data = &tegra124_soc },
 	{ .compatible = "nvidia,tegra210-xusb", .data = &tegra210_soc },
+	{ .compatible = "nvidia,tegra210b01-xusb", .data = &tegra210b01_soc },
 	{ .compatible = "nvidia,tegra186-xusb", .data = &tegra186_soc },
 	{ .compatible = "nvidia,tegra194-xusb", .data = &tegra194_soc },
 	{ .compatible = "nvidia,tegra234-xusb", .data = &tegra234_soc },

-- 
2.50.0

