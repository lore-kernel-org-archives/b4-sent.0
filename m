From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 20 Jul 2025 21:15:02 -0500
Subject: [PATCH v2 08/17] dt-bindings: tegra: Document Shield TV 2019
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250720-t210b01-v2-8-9cb209f1edfc@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753064238; l=1023;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=jUFLE92y2/PfCSBvqONGStmGuDJvfBuTDqHYcdODYfE=;
 b=8QZhDXxyyxbYWujP3EM+c1w7vC8MFuxCgA84+GksQL8DhJSKxVyanTeWEYaCaUkVOFAwXzVeS
 8motLEpoEtUDgGNlCjgLRszJ4dtW4IyP+JrFzORzbltXMVA85ITCPNB
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the device tree binding documentation for NVIDIA Shield TV 2019

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 Documentation/devicetree/bindings/arm/tegra.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/tegra.yaml b/Documentation/devicetree/bindings/arm/tegra.yaml
index 9cae3268a8274fd3a38580939c79a6f21de48a3f..11689e040504c57287a8a742c775070a33dfc0ff 100644
--- a/Documentation/devicetree/bindings/arm/tegra.yaml
+++ b/Documentation/devicetree/bindings/arm/tegra.yaml
@@ -174,6 +174,12 @@ properties:
               - nvidia,p2571
               - nvidia,p2894-0050-a08
           - const: nvidia,tegra210
+      - description: SHIELD TV Pro 2019
+        items:
+          - const: nvidia,p2894-0050-a08
+          - const: nvidia,darcy
+          - const: nvidia,tegra210b01
+          - const: nvidia,tegra210
       - description: Jetson TX2 Developer Kit
         items:
           - const: nvidia,p2771-0000

-- 
2.50.1

