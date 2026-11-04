From: David Heidelberg <david@ixit.cz>
Subject: [PATCH RFC 0/3] Input - Tap to wake for FT5452
Date: Wed, 04 Nov 2026 13:54:42 +0100
Message-Id: <20261104-ft5x06-double-tap-v1-0-5a1bd80449cc@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwMT3bQS0woDM92U/NKknFTdksQCXQsDI6CsQUqqsZGxElBfQVFqWmY
 F2MxopSA3Z6VYiGBxaVJWanIJyDSl2loACo0QQHoAAAA=
X-Change-ID: 20261104-ft5x06-double-tap-8022020de323
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1258; i=david@ixit.cz;
 h=from:subject:message-id; bh=pzSw6TKmONM6czBm61/vbfVAdGJHk+kTaSJEbz59twU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq6ytM/Owsjy5J6firfogdWwPvKt+ZEZb8PK7um
 529GuYtDsuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCausrTAAKCRBgAj/E00kg
 chBsD/0YUwsWoetDiBLm9SRyuFDq/RO6ukE3DxRxLUgI7ht59clz+7UKoMKfrwC5SMJWI3CL4x+
 YujCy4QgbLfQW1KwV+tR8eZkoDf6Qy6okZbNBRR1qKQZBeE0cFdXPVXYVCQvPtT2gqwQtuUxkoq
 IZO9VNp5YBcuWMGcwJyh+quufE1lvkfOUQB4+gBtw6jRirm3gdAUOixoMZtvcHsuAnZYgKcv9ND
 rC8G/djBpzK3qOCwzGLXFYyedgl2/XbABbmKoIjiMDl6HdBiSateeZuphC/+GM/M8/cyVmPrfiO
 IPoO6sHE/EwA5HnERE6xd/czgqLqGruI6H5/4bNl5B+izcGLLt7ZLPOAZTBFEcaOfq/YfNYo7mB
 N6FiJdWQ6gkhD5Jw0HZB6ErihUpK5+LpXgBO4tAMJTUqzcA59HCRGeIAZ35t2zMz8or/9p9NfJU
 J1epB0Pq9BwUmqVrzejfiwS9uubHiLfzDj0GC8nCvamEbFLYxMGM19kQrLW0yG1ETbsxCjupZW/
 1blNrGbIggErc+bHW2etFmqL78GbMRqtInIS+WSUIdkjZ6DmNDrNPZBRki6jLsQ1L8UaUUIxRW9
 7jeZnFgiMhgQ4ZAGo+KbV/k3wDK1hva+sYq5PEd7OcPBTJrF309nNUM/7uteCDHJo3S9IaT4aYt
 r0EqJWOJzgyyMrA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sending RFC just to validate if this would be the correct approach to
implementing the tap toi wake functionality

I've tested this patch, it does wake up the phone.
The second assessment is let device shell to react to double-tap input
device when phone is only in screen-off mode, thus the second input
device to bind to (when touchscreen is in the runtime sleep).

Feel free to skip detailed review for RFC v1, I'll polish the code for
upcoming v2 submission, after design discussion and approval.

Thanks

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (3):
      dt-bindings: input: touchscreen: edt-ft5x06: Add wakeup gestures
      Input: edt-ft5x06 - Add wakeup gesture support for FT5452
      arm64: dts: qcom: sdm845-shift-axolotl: Wake the system on a touchscreen double tap

 .../bindings/input/touchscreen/edt-ft5x06.yaml     |  37 ++++
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts  |   6 +
 drivers/input/touchscreen/edt-ft5x06.c             | 205 ++++++++++++++++++++-
 3 files changed, 244 insertions(+), 4 deletions(-)
---
base-commit: 2637bdec0535a2044cd830eba9a79363651d9043
change-id: 20261104-ft5x06-double-tap-8022020de323

Best regards,
--  
David Heidelberg <david@ixit.cz>

