From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 00/10] Input: support for STM FTS5
Date: Sun, 01 Mar 2026 18:51:14 +0100
Message-Id: <20260301-stmfts5-v1-0-22c458b9ac68@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJJ8pGkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDI0MT3eKS3LSSYlPdJBNzY0PDtKQUc2MjJaDqgqLUtMwKsEnRsbW1ACF
 15gRZAAAA
X-Change-ID: 20260214-stmfts5-b47311fbd732
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, linux-input@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1463; i=david@ixit.cz;
 h=from:subject:message-id; bh=MjnsDPgFAH43KtWaVxLKPW5yKsdDxokV0+MlP67ycVI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBppHyU634xeBikriSOlFJINC2u0T7+JKAJtJW5f
 ar1XfFgWcuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaaR8lAAKCRBgAj/E00kg
 cpAUEACYalYL4mkkSfpqeXUaJbkCmdmssv5VfFW+rERyHBJSp7TnWVxDS1+NVPPKuVWQ3V5jWO1
 95Fpt0i3orAUfQE0HYiJX5IzIKmBACWJKjT79FbHYLhjmNlHj83/xsBU9cWa5ecO15Nq9Xh3PY1
 Tu1TP0ifOnNRy+h7dKppCOvi/1Zun++l/zBq1AaFk1I0R/N6z5Ufhn/trmg0pUuOapn7uEPsmoB
 iJl3d7Rf3ONswHNMKPyGqaUH9liS8+roURXtSpkK5pj+Gtu2L2yfkcw0AZPOeubBwIiFJ/zPCX3
 K8Btrp7+3HVRe7T3lVlj6FvOPEUJzIWpjfJaE+K3WGH9H+/qUTunlhO+a/XtDgSsWmqGP5tgmst
 SfHqdqZPWROchdZzrp6oypxOPnet1oTi6i658H71ftRIgI37D+xR26G1M/hFH7/JMFHLlvEi+31
 7XOCtZTpy0351ebfBvJw+PvjhqmjUszGD7XXyRFKGt2yD2CSZi1om9gkB1AKfcha0lHeTtRiYHP
 44L3zPrYBAuHPFYbtyRSbmGSyZPANqp40p7h4Ndmk3dPrzYO3N41K22EGB95t5R4Lszq7AvhB0w
 2ZeGvRrvkF57XAInWTw2YPRp5yQUqBfhbB9gmdWIBOOBIRvlGuuEwqqPu+t2wkJC+0Uw4otw9+A
 T27k3Kd3cB6D90A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Used on various phones. Minimal basic support.

Includes device-tree with possibility to enable touchscreen on Pixel 3.

Sending as RFC, as this is first, seemingly clean version which works.

What is missing:
 - firmware loading
 - switching between AP and SLPI mode (to wake up phone by touch)
 - anything above basic touch

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (6):
      Input: stmfts - Use dev struct directly
      Input: stmfts - Switch to devm_regulator_bulk_get_const
      Input: stmfts - abstract reading information from the firmware
      Input: stmfts - disable regulators when power on fails
      dt-bindings: input: touchscreen: st,stmfts: Introduce reset GPIO
      dt-bindings: input: touchscreen: st,stmfts: Introduce STM FTS5

Petr Hodina (4):
      Input: stmfts - use client to make future code cleaner
      Input: stmfts - add optional reset GPIO support
      Input: stmfts - support FTS5
      arm64: dts: qcom: sdm845-google: Add STM FTS touchscreen support

 .../bindings/input/touchscreen/st,stmfts.yaml      |  21 +-
 .../arm64/boot/dts/qcom/sdm845-google-blueline.dts |  21 +-
 drivers/input/touchscreen/stmfts.c                 | 595 +++++++++++++++++++--
 3 files changed, 577 insertions(+), 60 deletions(-)
---
base-commit: c6870e543e8d55d725cccfe972fbfb5798daa1af
change-id: 20260214-stmfts5-b47311fbd732

Best regards,
-- 
David Heidelberg <david@ixit.cz>

