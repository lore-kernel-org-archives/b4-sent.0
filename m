From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Subject: [PATCH 0/2] arm64: dts: qcom: x1p42100-lenovo-thinkbook-16: enable
 HDMI out
Date: Sat, 20 Dec 2025 18:47:08 +0100
Message-Id: <20251220-tb16-hdmi-v1-0-18b1e20b396e@oldschoolsolutions.biz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABzhRmkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDIyMD3ZIkQzPdjJTcTF1jc0MzE4tkCwNjS3MloPqCotS0zAqwWdGxtbU
 AACzBbVsAAAA=
X-Change-ID: 20251220-tb16-hdmi-371648c80397
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Val Packett <val@packett.cool>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766252834; l=1743;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=Ff6jht1U9mxQ/WboaC+zNf0mm6lryMuMDMOQWfHF+V8=;
 b=BQLU+RpGtPJrTxMyBag9Am0lSQCkY6flGuZYTq8MBr/3yfh5H9cME1pIUdWyve9AaYDGGv2cL
 iCGp3ZuYa87AvbtkI6lnGDLya7a6uJEg+vhhbI57gT3/aEL79xGqn5W
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch set enables the HDMI port on the Lenovo ThinkBook 16 G7 QOY. 
The definitions have been derived from the T14s device tree, with some
necessary changes. The HDMI bridge seems to utilize the enable pin. 
The required GPIO was derived from the AeoB dump of the Windows GPU 
driver. 

Since the qmpphy involved is usb_1_ss2_qmpphy, and that usb_1_ss2 block 
is also used to operate the fingerprint reader, there's some possible
interference. The explicit port configuration on usb_1_ss2_dwc3 minimizes
this, however it works more reliable with the pipe_clk patch [1] that 
is discussed. Booting with HDMI cable cold-plugged results in the 
fingerprint reader not enumerating. Hot-plug and suspend doesn't kill it,
though.

[1]: https://lore.kernel.org/all/2564cdec-9726-4efa-ba07-a2f2646168c6@packett.cool/

To: Bjorn Andersson <andersson@kernel.org>
To: Konrad Dybcio <konradybcio@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: Val Packett <val@packett.cool>

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
Jens Glathe (2):
      arm64: dts: qcom: x1p42100-lenovo-thinkbook-16: force usb2-only mode on usb_1_ss2_dwc3
      arm64: dts: qcom: x1p42100-lenovo-thinkbook-16: add hdmi bridge with enable pin

 .../boot/dts/qcom/x1p42100-lenovo-thinkbook-16.dts | 102 +++++++++++++++++++++
 1 file changed, 102 insertions(+)
---
base-commit: cc3aa43b44bdb43dfbac0fcb51c56594a11338a8
change-id: 20251220-tb16-hdmi-371648c80397

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

