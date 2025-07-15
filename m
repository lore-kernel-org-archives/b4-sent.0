From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 14 Jul 2025 23:02:46 -0500
Subject: [PATCH 03/17] dt-bindings: usb: tegra-xusb: Document Tegra210B01
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250714-t210b01-v1-3-e3f5f7de5dce@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752552229; l=897;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=SJeTsauuKP0+H7jkmqGKY8VKb/OI6/mySaMOj0+bvYI=;
 b=yP0lTSFS+l0N6akf6j/Cx5vcgWxbeDL25VLHkBqPLHnPqGgYP7JniA3VxMZeSd3vKOtlkIUzs
 QsCWwkRQTthAZcI5/X4dFlCPXtsob+ynCYeNWGvmCj7J3v6PypT99tp
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the compatible string for Tegra210B01 XUSB

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 Documentation/devicetree/bindings/usb/nvidia,tegra210-xusb.yaml | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/usb/nvidia,tegra210-xusb.yaml b/Documentation/devicetree/bindings/usb/nvidia,tegra210-xusb.yaml
index c0e313c70bbaba4f5da9cb090ab6f3027d274a2d..543355118282f52b276a087185709320dd8e09d6 100644
--- a/Documentation/devicetree/bindings/usb/nvidia,tegra210-xusb.yaml
+++ b/Documentation/devicetree/bindings/usb/nvidia,tegra210-xusb.yaml
@@ -15,7 +15,9 @@ description: The Tegra xHCI controller supports both USB2 and USB3 interfaces
 
 properties:
   compatible:
-    const: nvidia,tegra210-xusb
+    enum:
+      - nvidia,tegra210-xusb
+      - nvidia,tegra210b01-xusb
 
   reg:
     items:

-- 
2.50.0

