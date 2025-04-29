From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 29 Apr 2025 16:33:31 -0500
Subject: [PATCH 2/4] dt-bindings: gpio: tegra186: Add gpio-ranges
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250429-tegra186-pinctrl-v1-2-722c7c42394e@gmail.com>
References: <20250429-tegra186-pinctrl-v1-0-722c7c42394e@gmail.com>
In-Reply-To: <20250429-tegra186-pinctrl-v1-0-722c7c42394e@gmail.com>
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745962426; l=832;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=Wl311uxZwU0cPpD42k7mMpBtBfmhP2gvdwX4d/QrBw8=;
 b=EyJ3/CJnhzAuVJWSJI2G7LrgO6QcbHlVkZ6h6DfEgvgUXROCOOpDiVgLfGn47OLvE1x/JFs2D
 uJIOiGc9cqdCzglXLHOFqTJog5uWX5SKvnNkvvwibNm01ulHiKKvJ7r
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add optional gpio-ranges property.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 Documentation/devicetree/bindings/gpio/nvidia,tegra186-gpio.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/gpio/nvidia,tegra186-gpio.yaml b/Documentation/devicetree/bindings/gpio/nvidia,tegra186-gpio.yaml
index 4ef06b2ff1ff04c38801b621b8e9be2ed749861f..065f5761a93f61d6b2c501102eadd492026a64d0 100644
--- a/Documentation/devicetree/bindings/gpio/nvidia,tegra186-gpio.yaml
+++ b/Documentation/devicetree/bindings/gpio/nvidia,tegra186-gpio.yaml
@@ -111,6 +111,9 @@ properties:
 
   gpio-controller: true
 
+  gpio-ranges:
+    maxItems: 1
+
   "#gpio-cells":
     description: |
       Indicates how many cells are used in a consumer's GPIO specifier. In the

-- 
2.48.1

