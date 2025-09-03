From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 03 Sep 2025 14:30:16 -0500
Subject: [PATCH v2 1/4] dt-bindings: clock: tegra124-dfll: Add property to
 limit frequency
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250903-tegra210-speedo-v2-1-89e6f86b8942@gmail.com>
References: <20250903-tegra210-speedo-v2-0-89e6f86b8942@gmail.com>
In-Reply-To: <20250903-tegra210-speedo-v2-0-89e6f86b8942@gmail.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Joseph Lo <josephl@nvidia.com>, 
 Peter De Schrijver <pdeschrijver@nvidia.com>, 
 Prashant Gaikwad <pgaikwad@nvidia.com>
Cc: linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Thierry Reding <treding@nvidia.com>, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756927822; l=1194;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=axF8VoKW1z4zF0BEmMzp42sD9+64WYeJh7/vhD2MdRk=;
 b=GFrHH9RpV8qd9w+3EfHF0coPiEC42v2Wpr+Ti33KTvOfyXPFojo6VwAuDz5QqhZ61O3hrwYom
 eSIF1u9ke9TAUtRBS6TbBOmUErspN5p7rIUcnz3VDv7vTTIPoIwYyNc
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dfll driver generates opp tables based on internal CVB tables
instead of using dt opp tables. Some devices such as the Jetson Nano
require limiting the max frequency even further than the corresponding
CVB table allows in order to maintain thermal limits.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 Documentation/devicetree/bindings/clock/nvidia,tegra124-dfll.txt | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/nvidia,tegra124-dfll.txt b/Documentation/devicetree/bindings/clock/nvidia,tegra124-dfll.txt
index f7d347385b5775ddd702ecbb9821acfc9d4b9ff2..8a049b684f962f2b06209a47866711b92c15c085 100644
--- a/Documentation/devicetree/bindings/clock/nvidia,tegra124-dfll.txt
+++ b/Documentation/devicetree/bindings/clock/nvidia,tegra124-dfll.txt
@@ -70,6 +70,9 @@ Required properties for PWM mode:
   - dvfs_pwm_enable: I/O pad configuration when PWM control is enabled.
   - dvfs_pwm_disable: I/O pad configuration when PWM control is disabled.
 
+Optional properties for limiting frequency:
+- nvidia,dfll-max-freq: Maximum scaling frequency in hertz.
+
 Example for I2C:
 
 clock@70110000 {

-- 
2.50.1

