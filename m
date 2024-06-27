From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/3] Power: A5: add power domain driver
Date: Thu, 27 Jun 2024 19:47:50 +0800
Message-Id: <20240627-a5_secpower-v1-0-1f47dde1270c@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGZRfWYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDMyNz3UTT+OLU5IL88tQi3aS0RMOkJJOkFMtkEyWgjoKi1LTMCrBp0bG
 1tQCowTXwXQAAAA==
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jianxin Pan <jianxin.pan@amlogic.com>, Ulf Hansson <ulf.hansson@linaro.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Hongyu Chen <hongyu.chen1@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719488872; l=823;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=AqD5B1YwKKcyDo3GQkyVkWdvVTiw9+IO2HJ8jhgiwXg=;
 b=iM+aPix2qzXLnRj/1pDN59/EkAe3QJF+Tz3mKsuS3Hbh+C4AwVDZWkg5pc2ye1/YjyydTBabq
 Kqa0jzqnk6JDSOiEKPf7bPE7bH1eDzABCrpkfF3m06l0LbrPn2cqaIH
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add power controller driver support for Amlogic A5 SoC. 

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (3):
      dt-bindings: power: add Amlogic A5 power domains
      pmdomain: amlogic: Add support for A5 power domains controller
      arm64: dts: amlogic: a5: add power domain controller node

 .../bindings/power/amlogic,meson-sec-pwrc.yaml     |  1 +
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi        | 10 +++++++++
 drivers/pmdomain/amlogic/meson-secure-pwrc.c       | 26 ++++++++++++++++++++++
 include/dt-bindings/power/amlogic,a5-pwrc.h        | 21 +++++++++++++++++
 4 files changed, 58 insertions(+)
---
base-commit: cc647e931a249605e06d3eb3ec89a7e320fc28cc
change-id: 20240627-a5_secpower-bfa1bb4bd9c4

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

