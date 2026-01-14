From: Ricardo Pardini <ricardo@pardini.net>
Subject: [PATCH 0/2] NPU and i2c3 + FUSB302 addition for Radxa Zero 2
Date: Wed, 14 Jan 2026 23:48:35 +0100
Message-Id: <20260114-arm64-dts-amlogic-radxa-zero2-additions-v1-0-8b5cdf328fde@pardini.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEMdaGkC/x3NQQqDQAxA0atI1g3MTEfBXqV0kZpoA9UpiYhUv
 HuHLv/m/QNcTMXh1hxgsqlrWWrESwPDi5ZJULk2pJC6EGNGsrnLyKsjze8y6YBGvBN+xUpCYta
 1Eo59aNvcj0/hq0DVPiaj7v/T/XGeP71Rk6t5AAAA
X-Change-ID: 20260114-arm64-dts-amlogic-radxa-zero2-additions-905549fbed3e
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=738; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=jMo5ERNKRtgqeiruc+F9jPMXJYYBxN74dlDkfmQDZII=;
 b=owEBbQGS/pANAwAIATteP+Oex+3pAcsmYgBpaB1JBGAoliEo92rosUySpTcYh5fjuWErzCmR5
 HppGRKGo4yJATMEAAEIAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCaWgdSQAKCRA7Xj/jnsft
 6RtgB/4l+A3LhNDT4b9cqXMNp5csRFFGWyKfDyPpXympkNaPKRbH2REuAMiE/0+I4iXxIZpORqQ
 JE1Cw9dxQT9yD1M+ZcSswPFin8PKwPZ5GGfulCLXBFXsF9arrByXGMD4mZeBqfRGna7UTcpJpm0
 Wzifn828+izdBYeFmi1TCS7QckWEeU+C2r+Zgu+boyziOgXPRDHEn/HSDiFD63cePM6p+kWzbSo
 BIgswY+uhQZ4AQhpCLJNt9XhRNZLtc9G9KZAMvP49gUFPYO2nHKHMnUql8n3N/rF2UkYOWVdR2x
 qBfS74rdAAEK0Cfj2wSqEP45cqGa5NfeahwW1H+Dyku6xTpz
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a few things missing from the Radxa Zero 2:

1) NPU (etnaviv), just enable the node, similar to what was done for VIM3
2) i2c3 (also exposed on the 40-pin header) and the FUSB302 at 0x22

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
Ricardo Pardini (2):
      arm64: dts: amlogic: Enable the npu node on Radxa Zero 2
      arm64: dts: amlogic: add the type-c controller on Radxa Zero 2

 .../boot/dts/amlogic/meson-g12b-radxa-zero2.dts    | 36 ++++++++++++++++++++++
 1 file changed, 36 insertions(+)
---
base-commit: 0f61b1860cc3f52aef9036d7235ed1f017632193
change-id: 20260114-arm64-dts-amlogic-radxa-zero2-additions-905549fbed3e

Best regards,
-- 
Ricardo Pardini <ricardo@pardini.net>

