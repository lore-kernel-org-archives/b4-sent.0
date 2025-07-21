From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 20 Jul 2025 21:15:00 -0500
Subject: [PATCH v2 06/17] dt-bindings: clock: tegra: Document Tegra210B01
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250720-t210b01-v2-6-9cb209f1edfc@gmail.com>
References: <20250720-t210b01-v2-0-9cb209f1edfc@gmail.com>
In-Reply-To: <20250720-t210b01-v2-0-9cb209f1edfc@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753064238; l=1600;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=Cj+m/fB3eeAdMaIIZwt0Ih/S0OtnqsxT3QW3PAC9JvE=;
 b=O5KPaGIZppqEfJdwPtQFnaBWV/PmQMESQEbEt9SVW75ehrbBGKx4tBjt6LsmYFYVAhrZrzYt1
 F2AWSf1yZb5CKSciKkv3G48Q1pv9oKkZNv8G7/JGs753OKwa5Wpqa/A
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

* Add the compatible string for Tegra210B01 clock and reset
* Add Tegra210B01 specific clock bindings

Acked-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 Documentation/devicetree/bindings/clock/nvidia,tegra20-car.yaml | 1 +
 include/dt-bindings/clock/tegra210-car.h                        | 5 ++++-
 2 files changed, 5 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/clock/nvidia,tegra20-car.yaml b/Documentation/devicetree/bindings/clock/nvidia,tegra20-car.yaml
index bee2dd4b29bfe391caee346aa5afad49772c2c41..88cce500bbc43de934f6c56152e5b2d006f8a8bb 100644
--- a/Documentation/devicetree/bindings/clock/nvidia,tegra20-car.yaml
+++ b/Documentation/devicetree/bindings/clock/nvidia,tegra20-car.yaml
@@ -32,6 +32,7 @@ properties:
       - nvidia,tegra30-car
       - nvidia,tegra114-car
       - nvidia,tegra210-car
+      - nvidia,tegra210b01-car
 
   reg:
     maxItems: 1
diff --git a/include/dt-bindings/clock/tegra210-car.h b/include/dt-bindings/clock/tegra210-car.h
index 9cfcc3baa52c6eef0439c859200cf44446a1cd17..27485d9b80f68fc0e7668a8abbd1b821f62035dd 100644
--- a/include/dt-bindings/clock/tegra210-car.h
+++ b/include/dt-bindings/clock/tegra210-car.h
@@ -409,6 +409,9 @@
 #define TEGRA210_CLK_DMIC3_SYNC_CLK 392
 #define TEGRA210_CLK_DMIC3_SYNC_CLK_MUX 393
 
-#define TEGRA210_CLK_CLK_MAX 394
+#define TEGRA210_CLK_UTMIPLL_60M 531
+#define TEGRA210_CLK_PLL_P_UPHY_OUT 532
+
+#define TEGRA210_CLK_CLK_MAX 533
 
 #endif	/* _DT_BINDINGS_CLOCK_TEGRA210_CAR_H */

-- 
2.50.1

