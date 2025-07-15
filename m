From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 14 Jul 2025 23:02:58 -0500
Subject: [PATCH 15/17] arm64: tegra: Add BPMP node for Tegra210
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250714-t210b01-v1-15-e3f5f7de5dce@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752552229; l=1355;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=EGqGpsmvVUcZ9BC/fErJCUcbZka+SWE7U9kl0UCL2e0=;
 b=mdM9cDjp2UVQwDqZNIt4haw/jqF7QKWVAk+1bKi6m2zSE+O3aSw0x9JGVxpwNHm7atlknU0w/
 CazoxeUkeIQAXH/SGE+z9O1gO9SzReVSRTf5oDW6/2gMtHB7hJriSrp
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Tegra210 soc supports bpmp offload for power management among other
things. This was considered insecure partway through the soc's lifecycle
and support was removed in the bootloader. However, Tegra210B01 returned
to using the bpmp. Plus old bootloaders on the original Tegra210 still
work with the existing driver. So add the node to the common Tegra210
soc dtsi, but disabled by default.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra210.dtsi | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra210.dtsi b/arch/arm64/boot/dts/nvidia/tegra210.dtsi
index 402b0ede1472af625d9d9e811f5af306d436cc98..3361de1ab41b37e430d399df2bf77d64226f33e8 100644
--- a/arch/arm64/boot/dts/nvidia/tegra210.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra210.dtsi
@@ -968,6 +968,17 @@ cec@70015000 {
 		status = "disabled";
 	};
 
+	bpmp: bpmp@70016000 {
+		compatible = "nvidia,tegra210-bpmp";
+		reg = <0x0 0x70016000 0x0 0x2000
+		       0x0 0x60001000 0x0 0x1000>;
+		status = "disabled";
+
+		interrupts = <GIC_SPI 6 IRQ_TYPE_EDGE_RISING>,
+			     <GIC_SPI 4 IRQ_TYPE_EDGE_RISING>;
+		interrupt-names = "tx", "rx";
+	};
+
 	mc: memory-controller@70019000 {
 		compatible = "nvidia,tegra210-mc";
 		reg = <0x0 0x70019000 0x0 0x1000>;

-- 
2.50.0

