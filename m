From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/2] Commonize pinctrl for camera master clock on Qualcomm
 SDM845
Date: Sat, 13 Dec 2025 13:00:19 +0100
Message-Id: <20251213-sdm845-mclk-v1-0-197bc947d4c6@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFNVPWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDI0Nj3eKUXAsTU93c5JxsXQMTwzSjREtTo1RjQyWgjoKi1LTMCrBp0bG
 1tQCvJsaeXQAAAA==
X-Change-ID: 20251213-sdm845-mclk-041f2a952e31
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1041; i=david@ixit.cz;
 h=from:subject:message-id; bh=63XuyAt3Hq0F57+SA31YuHpdBuIPGjstOhaQOX2ZYXQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpPVVVryo+SCUdri61vJQT7ECSguj8+prZd9pLs
 0UsbDBCAt2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaT1VVQAKCRBgAj/E00kg
 cjrED/4wsLEjsQFUxo5GQPRV4lroh1eHac1XUGYk53KuCgPuy8uPzJC/G0NTZyDkLdcglXgtKWL
 tRQHYQ2PumcvnoKVFI0aIQreytNSKjMvljey+yWnI7LwN1Enw9xEMXosCVSW2h/IeFG012kBdRs
 U8lQNUcSUTMA7At8UiAv24em5Y7aVDo55hm3krcXWrwf65EK/cBq0c/iBy6M+55itYk2nVy5Jen
 Cx9j6xSwey20DxhNDa438kzOzfHkYTvM/wyF1KwdE+xKYgLLkUaGzyghmQfRIG0Dv0WMgbGEKMx
 JvpFyHB+9UNRPkk2OZTHIqHyoBqKRvb6YHlu+Pk1PM7+tG5QlGG8ohJkPMPTY3hiwxkK+KudWGU
 gWmTixLuA8YSPj7qp0EYFjDNt736aF5I9p723oRpSchGrzbjyFTsSqMkydQ7b9maH2hii2LEo2L
 nfPXFsill/Zn9vqO8wl/3N6cEgQQ0noex8Qw9DJtam9Wk3hItYUoUwvOnhEui2TpBvok2ltv+81
 Pg/j1W84cRjt+/uJDk+ptLbri7TKD9hV9OEAqEYQRKfBxlDVdILrPiRn2XKezgu7ibQYoXym93N
 HMzB82wdiVpdrhQMOmnV2LlqAIbr1/Cqns50UxHFYBfMd3OIx8x6um1zmrbMECAcOHxLkoMBUIT
 H9iFXIyCJKe/rPg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Inspired by Richard's patch set for SDM670, I noticed that SDM845
follows the same pattern. This change prepares for enabling
additional cameras.

These pinctrl settings have been verified against the downstream
SDM845 kernel.

Since most of these are not yet used in mainline, testing was done
on sdm845-next using OnePlus 6 cameras with downstream drivers.

Thank you
David

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (2):
      arm64: qcom: sdm845: Introduce camera master clock pinctrl
      arm64: dts: qcom: sdm845-db845c: Use introduced platform wide cam_mclk0_default

 .../qcom/sdm845-db845c-navigation-mezzanine.dtso   |  2 +-
 arch/arm64/boot/dts/qcom/sdm845-db845c.dts         |  8 ----
 arch/arm64/boot/dts/qcom/sdm845.dtsi               | 43 ++++++++++++++++++++++
 3 files changed, 44 insertions(+), 9 deletions(-)
---
base-commit: d9771d0dbe18dd643760431870a6abf9b0866bb0
change-id: 20251213-sdm845-mclk-041f2a952e31

Best regards,
-- 
David Heidelberg <david@ixit.cz>

