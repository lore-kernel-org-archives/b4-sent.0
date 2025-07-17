From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/2] rtc: add amlogic C3 RTC node
Date: Thu, 17 Jul 2025 17:38:36 +0800
Message-Id: <20250717-rtc-c3-node-v1-0-4f9ae059b8e6@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJzEeGgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDc0Nz3aKSZN1kY928/JRU3aQkcwtTS4sUS8MkYyWgjoKi1LTMCrBp0bG
 1tQD5coUqXQAAAA==
To: Yiting Deng <yiting.deng@amlogic.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-rtc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752745121; l=635;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=SSrptMa19AA/XTd/MCF/BLG2gYrgYjh0sTQ0u3DDHqU=;
 b=1Jqgf8NPSE7AO66ZMlpxMqW+iQaU9ydrgRT4qpUFi1Uv4UGyEUcAN6agdhwHQqm9FqRSysslV
 k2tboqtelnLAnleh9ywMSUYZjh+K/q1JBXMPnZy73WrgbjpraPQhO18
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add C3 rtc compatible string and device node.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (2):
      dt-bindings: rtc: amlogic,a4-rtc: Add compatible string for C3
      arm64: dts: amlogic: C3: Add RTC controller node

 .../devicetree/bindings/rtc/amlogic,a4-rtc.yaml          | 11 ++++++++---
 arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi              | 16 ++++++++++++++++
 2 files changed, 24 insertions(+), 3 deletions(-)
---
base-commit: 0bafe291cb429d39b5ff70bcf7b2f3ab026dcb02
change-id: 20250717-rtc-c3-node-bb78598d91b3

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

