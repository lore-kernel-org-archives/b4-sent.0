From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Subject: [PATCH v5 0/3] Add sy7802 flash led driver
Date: Mon, 24 Jun 2024 23:25:11 +0200
Message-Id: <20240624-sy7802-v5-0-7abc9d96bfa6@apitzsch.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIADfkeWYC/2XMz47CIBDH8VcxnBczMwwFPO17GA8UYctFTXEb/
 6TvLm3SuhuPv8l8vk9RYp9jEbvNU/RxyCWfT3Xor40InT/9RJmPdQsCYlCkZbkbCyQTQwpN0o0
 mLerzpY8p3+bQ/lB3l8v13N/n7oDTdUmYJTGgBHlsDftWUfI+fftLvj5K6LbxV0yRgd6QAVdIF
 SIqiw68YbafUL1hg7RCNcHoQsBgXGvcJ+S/sFkhV2isc47RQgT9H47j+ALY5ftgSQEAAA==
To: Pavel Machek <pavel@ucw.cz>, Lee Jones <lee@kernel.org>, 
 Rob Herring <robh@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, 
 Christophe JAILLET <christophe.jaillet@wanadoo.fr>, 
 Trilok Soni <quic_tsoni@quicinc.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, Kees Cook <kees@kernel.org>
Cc: linux-leds@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 phone-devel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719264313; l=2726;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=zQ98WnpG0JS8Dssh65NBCz5MYdX4mFaEXFHE8wBH70U=;
 b=YEw1M0JRz0f27X+0u33DsvNyHech4TZDlKYbKcpUp+07ESglivJXbiYsX99pSELo5eu29iArZ
 WxHtlDSi1wvCLi3s3SmH8aMq+1bPTLbhL3zXy4N+p60QjmyiERm4cRu
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
Changes in v5:
- Fix language in driver description comment
- Unwrap function arguments
- Remove unnecessary empty lines
- Add Acked-by tag to second patch
- Link to v4: https://lore.kernel.org/r/20240616-sy7802-v4-0-789994180e05@apitzsch.eu

Changes in v4:
- Use for_each_available_child_of_node_scoped() to simplify code
- Use dev_err_probe() to be consistent with the other code in
  sy7802_probe()
- Split devm_add_action() into 2 devm_add_action_or_reset() to simplify
  code and balance regulator_enable()
- Link to v3: https://lore.kernel.org/r/20240612-sy7802-v3-0-1e9cc1c79b79@apitzsch.eu

Changes in v3:
- Add R-b tag to first patch
- Extend driver commit message
- Improve readability of defines by using BIT()
- Rename some variables/parameters
  * led_no -> led_id
  * level -> brightness
  * curr -> fled_{strobe,torch}_used_tmp
  * mask -> {flash,torch}_mask
  * i -> child_num
- Restructure structs ("Place th big stuff at the top")
- Declare 'child' on a separate line
- Move multi-line assignments out of declaration block
- Update warning/error messages and comments
- Use gotos to handle error path
- Use devm API to cleanup module's resources
- Init mutex before LED class device is registered to avoid race
  condition
- Link to v2: https://lore.kernel.org/r/20240401-sy7802-v2-0-1138190a7448@apitzsch.eu

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
 drivers/leds/flash/leds-sy7802.c                   | 539 +++++++++++++++++++++
 5 files changed, 677 insertions(+)
---
base-commit: 6a03b35e4395eb2d6e89a38aca00a9fe9cb39ba1
change-id: 20240325-sy7802-f40fc6f56525

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

