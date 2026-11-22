From: EMCP333 <emcp@enser.io>
Date: Sun, 22 Nov 2026 05:13:50 +0000
Subject: [PATCH 1/3] dt-bindings: input: syna,rmi4: Document wakeup-source
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-rmi4-wakeup-v1-1-1b662be4a9d6@enser.io>
References: <20261122-b4-rmi4-wakeup-v1-0-1b662be4a9d6@enser.io>
In-Reply-To: <20261122-b4-rmi4-wakeup-v1-0-1b662be4a9d6@enser.io>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>, 
 Abel Vesa <abelvesa@kernel.org>, Casey Connolly <casey.connolly@linaro.org>, 
 linux-input@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 EMCP333 <emcp@enser.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324430; l=1368;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=ibrZrS/G/KWUW6WvA1g5ly3Yt1Di9/yHqulMV+RT/tA=;
 b=OjgsAqKLRdguBshmfdwAa6AQdxl/df/CLVH/lThmy9HBz9+19CZ4x5uUYtVXcCeVCkZVGbGU+
 z6sCwm9aNXMBWXJr34lcMsZcKtPDf3CzHXQbrwhr/Qurpm/ktoNkxdM
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The I2C core already turns a "wakeup-source" property into a
wakeup-capable device: of_i2c_get_board_info() sets I2C_CLIENT_WAKE and
i2c_device_probe() then calls device_init_wakeup() and
dev_pm_set_wake_irq(). rmi_driver additionally arms the attention IRQ
with enable_irq_wake() in rmi_disable_irq() when device_may_wakeup() is
true.

The binding does not list the property, so a board that sets it fails
dtbs_check:

  sdm845-oneplus-fajita.dtb: synaptics-rmi4-i2c@20 (syna,rmi4-s3706b):
    Unevaluated properties are not allowed ('wakeup-source' was unexpected)

Allow it.

The code and this changelog were prepared with the help of an AI coding
assistant. The submitter has reviewed both and takes responsibility for
them.

Signed-off-by: EMCP333 <emcp@enser.io>
---
 Documentation/devicetree/bindings/input/syna,rmi4.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/input/syna,rmi4.yaml b/Documentation/devicetree/bindings/input/syna,rmi4.yaml
index fb4804ac35..34bcc25135 100644
--- a/Documentation/devicetree/bindings/input/syna,rmi4.yaml
+++ b/Documentation/devicetree/bindings/input/syna,rmi4.yaml
@@ -57,6 +57,8 @@ properties:
   vdd-supply: true
   vio-supply: true
 
+  wakeup-source: true
+
   rmi4-f01@1:
     type: object
     additionalProperties: false

-- 
2.47.3

