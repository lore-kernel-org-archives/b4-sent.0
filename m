From: EMCP333 <emcp@enser.io>
Date: Sun, 22 Nov 2026 05:13:52 +0000
Subject: [PATCH 3/3] arm64: dts: qcom: sdm845-oneplus: Mark the touchscreen
 as a wakeup source
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-rmi4-wakeup-v1-3-1b662be4a9d6@enser.io>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324430; l=1595;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=BkQi/aNaLB67MHOxqLW5Gip80XqiKJZrg366Q7Ri004=;
 b=J53g3RH6mgQUU1cTTdsIFH+7zNmEtVWORHfkzsm+AxjYIaboThSB1k48F2OE4wyxbZ24qVK+w
 f03KZuq8B+SBnLvJsXW19NtdD1zXyMLsXmg4sNMiuJF9abQalhPkjjS
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Without "wakeup-source" the Synaptics touchscreen on the OnePlus 6 and 6T
has no power/wakeup attribute and its attention IRQ is not armed across
system suspend, so a touch (for example double-tap-to-wake) cannot wake
the SoC from s2idle.

Mark it as a wakeup source. The I2C core registers it as a wakeup-capable
device and arms its IRQ for wake.

This needs "Input: synaptics-rmi4 - keep an I2C device that may wake the
system powered". Without it rmi_i2c cuts the touchscreen supplies in
suspend, the attention line falls and every s2idle ends within seconds.

Tested on a OnePlus 6T on v7.4-rc3 with that change:
/sys/bus/i2c/devices/12-0020/power/wakeup reads "enabled". With nothing
touching the phone, "rtcwake -m freeze -s 30" slept the full 30 seconds,
and a double-tap woke it with a 60 second RTC fallback.

The code and this changelog were prepared with the help of an AI coding
assistant. The submitter has reviewed both and takes responsibility for
them.

Signed-off-by: EMCP333 <emcp@enser.io>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index 1df09da3c4..187bd6f45e 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -533,6 +533,7 @@ synaptics-rmi4-i2c@20 {
 
 		syna,reset-delay-ms = <200>;
 		syna,startup-delay-ms = <200>;
+		wakeup-source;
 
 		rmi4-f01@1 {
 			reg = <0x01>;

-- 
2.47.3

