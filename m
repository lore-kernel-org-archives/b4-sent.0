From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/2] Introduce OnePlus 6/6T touchscreen compatible
Date: Wed, 08 Apr 2026 19:34:31 +0200
Message-Id: <20260408-synaptics-rmi4-dt-v1-0-2d32bacce673@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKeR1mkC/x3MTQ5AMBBA4as0szZJi/i7ilhUO5iFko4IEXfXW
 H6L9x4QikwCnXog0snCW0gwmQK32DATsk+GXOeVLnWDcge7H+wE48ol+gMbS+NUmLrV3kHq9kg
 TX/+zH973A7nUXfhjAAAA
X-Change-ID: 20260408-synaptics-rmi4-dt-8aebf31790dc
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=766; i=david@ixit.cz;
 h=from:subject:message-id; bh=JzKGMSO1Qx98W099lIY3XmzWJxWoll9867PldA76mjU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp1pGnAYMMzfmWVcCoSBFRXxcsIHcyzsFYYsnCw
 LV/rmkIDtiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadaRpwAKCRBgAj/E00kg
 cmpSEACRduCxZQPGLcSjXukxyg+Is/ZozXUdsnX4cggpr/x5ZQRcu6UBppSw7dD/CtCepy4ieZ5
 3p33gqJs1q+bed23rLuPGo8aBqBZ1FzYaskzHqU8FSmGIHHDJK4jepK3QFbYG7s0QUK1yxhwNkB
 WydDiRnL/HUhjnVoQjI6NcIHZd0lo+8cy4rTnw3ZE8cRP0qFS6HyGtHjVDiu2bfDeUtifX3o+Dp
 qMMRMXs7rSec7ZwpkdH9ZICDCXql1y70IZ1b2Lm2zgDbKlWxsH1dyWw9CGJOAVoCW76LfJQ4VL3
 X1KR1W/nBNea/Je09+qXRHjEh8rzDVJLwIwU6xzO7HTll62bT1ldHrKOglQjCWHdDr98BXwWGFN
 eYu0/vlBcw2Rm7pEWBH/wTXKkzAiqB67gpDQW8VZ+DYXEOpkCXxQrdijSbBgzMU7ikVMdZXdG/E
 lA8qO5ez1v96CVaz7ysgA74aDcaVk2yXe3EPYUOa1hD4hr48ckFJ2c5cRrKEAT4yZIT+apWIhW3
 zBRylTDonCLUrAuV9b/hsIFA6s4GeQMnBhvXexaYJ0nFHrE0u9BvVl/O6XSGy1b1Llzx2/JIr2e
 rYZDcjJMAS1Cf9ozQ9uLnzV2UuTeIV7CIJscLWSkNceZMxT6QSwC7ujsbCBXm1WZ7VWqLRPLeBe
 63DkU6NxRswBFrg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Mostly related to the
  https://codeberg.org/sdm845/linux/commits/branch/b4/synaptics-rmi4
series, but independent on other changes which I trying to upstream for
more than one year.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (2):
      dt-bindings: input: syna,rmi4: Document syna,rmi4-s3706b
      arm64: dts: qcom: sdm845-oneplus: Update compatible to include model

 Documentation/devicetree/bindings/input/syna,rmi4.yaml | 11 ++++++++---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi    |  2 +-
 2 files changed, 9 insertions(+), 4 deletions(-)
---
base-commit: f3e6330d7fe42b204af05a2dbc68b379e0ad179e
change-id: 20260408-synaptics-rmi4-dt-8aebf31790dc

Best regards,
-- 
David Heidelberg <david@ixit.cz>

