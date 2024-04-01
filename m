From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Subject: [PATCH v2 0/3] Add sy7802 flash led driver
Date: Mon, 01 Apr 2024 23:23:54 +0200
Message-Id: <20240401-sy7802-v2-0-1138190a7448@apitzsch.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAOolC2YC/zXMQQ6DIBCF4auYWZcGR9Cmq96jcYEIZTZqGEtqD
 XcvNXH5v7x8O7CL5Bju1Q7RJWKapxJ4qcAGM72coLE0oEQlG9SCt+4mUXglvW29bjVqKOclOk+
 fA3r2pQPxOsftcFP9X0+iO4lUCynGoVNmaNAb4x9mofXLNlzdG/qc8w897YTOngAAAA==
To: Pavel Machek <pavel@ucw.cz>, Lee Jones <lee@kernel.org>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <keescook@chromium.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>
Cc: linux-leds@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 phone-devel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712006653; l=1363;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=JvZ9DjATerhrdZXHJcR5iNqmcuYJoWGExgpd7+c6UhM=;
 b=CsSah5WnQVUtjNjrlw5gu4Gao8S8QY2nMFQ6MIhCxS6uoASsfJ8db1HQdi0pBimstKMB/Wsz7
 BYz4yP8sITnBiqcqs5eQgZrY8IR7yz9VdSWr2xW2mJX2gL5YTJP3gay
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series introduces a driver for the Silergy SY7802 charge pump used
in the BQ Aquaris M5 and X5 smartphones.

The implementation is based on information extracted from downstream as
the datasheet provided by a distributor of the hardware didn't include
any information about the i2c register description.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
Changes in v2:
- bindings: remove unneeded allOf
- bindings: example: move flash-led-controller under i2c node to fix
  check error
- Cc to phone-devel
- Link to v1: https://lore.kernel.org/r/20240327-sy7802-v1-0-db74ab32faaf@apitzsch.eu

---
André Apitzsch (3):
      dt-bindings: leds: Add Silergy SY7802 flash LED
      leds: sy7802: Add support for Silergy SY7802 flash LED controller
      arm64: dts: qcom: msm8939-longcheer-l9100: Add rear flash

 .../devicetree/bindings/leds/silergy,sy7802.yaml   | 100 ++++
 .../boot/dts/qcom/msm8939-longcheer-l9100.dts      |  26 +
 drivers/leds/flash/Kconfig                         |  11 +
 drivers/leds/flash/Makefile                        |   1 +
 drivers/leds/flash/leds-sy7802.c                   | 532 +++++++++++++++++++++
 5 files changed, 670 insertions(+)
---
base-commit: a6bd6c9333397f5a0e2667d4d82fef8c970108f2
change-id: 20240325-sy7802-f40fc6f56525

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

