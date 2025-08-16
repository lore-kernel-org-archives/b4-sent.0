From: Aaron Kling <webgeek1234@gmail.com>
Date: Sat, 16 Aug 2025 00:53:33 -0500
Subject: [PATCH 1/5] dt-bindings: clock: tegra124-dfll: Add property to
 limit frequency
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250816-tegra210-speedo-v1-1-a981360adc27@gmail.com>
References: <20250816-tegra210-speedo-v1-0-a981360adc27@gmail.com>
In-Reply-To: <20250816-tegra210-speedo-v1-0-a981360adc27@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755323658; l=1074;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=i008IfPSaYeZDCxQCAJ7fiLJ8vYgRkhMPyZzDoavqYE=;
 b=RsGAR4X/ZLdBD17nQiWJrjizisf+BJBjuFoEXnTzahSr2JDZ4hFiMsowb5/xLuAlDn6sOrX9X
 gmronvaJJWgAovoTwAAj/SWd+3XthQrlMvT1oUzBKVEHfVcnNjjYmMI
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some devices report a cpu speedo value that corresponds to a table that
scales beyond the chips capability. This allows devices to set a lower
limit.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 Documentation/devicetree/bindings/clock/nvidia,tegra124-dfll.txt | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/nvidia,tegra124-dfll.txt b/Documentation/devicetree/bindings/clock/nvidia,tegra124-dfll.txt
index f7d347385b5775ddd702ecbb9821acfc9d4b9ff2..6cdbabc1f036a767bdc8e5df64eeff34171a3b85 100644
--- a/Documentation/devicetree/bindings/clock/nvidia,tegra124-dfll.txt
+++ b/Documentation/devicetree/bindings/clock/nvidia,tegra124-dfll.txt
@@ -70,6 +70,9 @@ Required properties for PWM mode:
   - dvfs_pwm_enable: I/O pad configuration when PWM control is enabled.
   - dvfs_pwm_disable: I/O pad configuration when PWM control is disabled.
 
+Optional properties for limiting frequency:
+- nvidia,dfll-max-freq: Maximum scaling frequency.
+
 Example for I2C:
 
 clock@70110000 {

-- 
2.50.1

