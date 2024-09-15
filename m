From: Jasper Korten <jja2000@gmail.com>
Subject: [PATCH 0/2] Add touchscreen and TMP451 tempsensor nodes to Google
 Pixel C (tegra210-smaug) Device Tree
Date: Mon, 16 Sep 2024 00:48:12 +0200
Message-Id: <20240916-touch-temp-v1-0-5a008b2acbc8@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACxk52YC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDS0NT3ZL80uQM3ZLU3ALdZDOTJDMLSzPDxNRUJaCGgqLUtMwKsGHRsbW
 1ALWGrpdcAAAA
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Diogo Ivo <diogo.ivo@tecnico.ulisboa.pt>, 
 Jasper Korten <jja2000@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726440502; l=1112;
 i=jja2000@gmail.com; s=20240916; h=from:subject:message-id;
 bh=W3AVPczafQzhHEPVJeMO8EQOQr9O4ild1Pi+en8FGfY=;
 b=ZPhbv3N1xwYF4OASpscfGJybNimUttAT4cGxgIPHBup4hw6xYif8atQccSUpMV8j5olBjwYP7
 aQ/9X5wnKYNC8DaykgGgExDNs5W7AtHl9JM3Mh/Bje4qv9Xm6+y+H50
X-Developer-Key: i=jja2000@gmail.com; a=ed25519;
 pk=NV6r6q/S3nZILZkoOEuEM7F+uxANotfAYeXyNZTniJc=
X-Endpoint-Received: by B4 Relay for jja2000@gmail.com/20240916 with auth_id=210
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Information to get these working was gained from downstream DTS.
Link: https://android.googlesource.com/kernel/tegra/+/refs/heads/android-tegra-dragon-3.18-oreo-m8/arch/arm64/boot/dts/tegra/tegra210-smaug.dtsi

Both were missing upstream and easy to add:
- It uses a RMI4 HID-over-I2C compatible touchscreen.
- TMP451 is located close to eMMC according to iFixit's teardown.
  Link: https://www.ifixit.com/Teardown/Google+Pixel+C+Teardown/62277#s290806

This is the first time I've ever submitted patches upstream myself.
If there's anything I've missed or could do better in a new rev,
please let me know!

Signed-off-by: Jasper Korten <jja2000@gmail.com>
---
Jasper Korten (2):
      arm64: dts: nvidia: tegra210-smaug: Add touchscreen node
      arm64: dts: nvidia: tegra210-smaug: Add TMP451 temperature sensor node

 arch/arm64/boot/dts/nvidia/tegra210-smaug.dts | 22 ++++++++++++++++++++++
 1 file changed, 22 insertions(+)
---
base-commit: da3ea35007d0af457a0afc87e84fddaebc4e0b63
change-id: 20240915-touch-temp-c64b68961aee

Best regards,
-- 
Jasper Korten <jja2000@gmail.com>

