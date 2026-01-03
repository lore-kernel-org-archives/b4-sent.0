From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Subject: [PATCH v2 0/2] arm64: dts: qcom: x1p42100-lenovo-thinkbook-16:
 enable HDMI out
Date: Sat, 03 Jan 2026 10:00:22 +0100
Message-Id: <20260103-tb16-hdmi-v2-0-92b0930fa82e@oldschoolsolutions.biz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKfaWGkC/22Oyw6CMBBFf4XM2ppOUR6u/A/DwtLRToKUdCpRC
 f9uZe3ynNyc3AWEIpPAqVgg0szCYcxgdgX0/jreSbHLDEabIxqjVbJYKe8erMoaq0PTN7psa8j
 7KdKNX1vr0mX2LCnE95ae8Wf/VWZUWmFjkYy2ZVvROQxOeh/CIGF4pvxH9pY/0K3r+gU67aPFr
 wAAAA==
X-Change-ID: 20251220-tb16-hdmi-371648c80397
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Val Packett <val@packett.cool>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767430836; l=1759;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=N2OSZfc5uZLO/gIUqkPklt/LFJmMqkpMheBcHTaPCcQ=;
 b=GxvpZXagkg+xw3vJhP/lGMgzegRQDT2TwWeurIUKIcSkak/ker15k3EUzDWfKtsqJZpztC3Dw
 lQu8BTQTcUfCAQZWmnLAXa0Qe+pxtOHaDE2cqHv9u4MOWWhdyJpav79
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch set enables the HDMI port on the Lenovo ThinkBook 16 G7 QOY. 
The definitions have been derived from the T14s device tree, with some
necessary changes. The HDMI bridge seems to utilize the enable pin. 
The required GPIO was derived from the AeoB dump of the Windows GPU 
driver, and then actually guessed with comparision to pinctrl-x1e80100.c.

Since the qmpphy involved is usb_1_ss2_qmpphy, and that usb_1_ss2 block 
is also used to operate the fingerprint reader, there's some possible
interference. The explicit port configuration on usb_1_ss2_dwc3 minimizes
this, however it works more reliable with the pipe_clk patch [1] that 
is discussed. Booting with HDMI cable cold-plugged results in the 
fingerprint reader not enumerating. Hot-plug and suspend doesn't kill it,
though.

[1]: https://lore.kernel.org/all/2564cdec-9726-4efa-ba07-a2f2646168c6@packett.cool/

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
Changes in v2:
- reviewed and discovered / verified hdmi bridge enable is gpio120, 
  resolving the previous clash. Also, configured the gpio120 with 
  pull-down to avoid a floating pin.
- Link to v1: https://lore.kernel.org/r/20251220-tb16-hdmi-v1-0-18b1e20b396e@oldschoolsolutions.biz

---
Jens Glathe (2):
      arm64: dts: qcom: x1p42100-lenovo-thinkbook-16: force usb2-only mode on usb_1_ss2_dwc3
      arm64: dts: qcom: x1p42100-lenovo-thinkbook-16: add hdmi bridge with enable pin

 .../boot/dts/qcom/x1p42100-lenovo-thinkbook-16.dts | 90 ++++++++++++++++++++++
 1 file changed, 90 insertions(+)
---
base-commit: cc3aa43b44bdb43dfbac0fcb51c56594a11338a8
change-id: 20251220-tb16-hdmi-371648c80397

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

