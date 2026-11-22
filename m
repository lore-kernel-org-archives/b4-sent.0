From: EMCP333 <emcp@enser.io>
Date: Sun, 22 Nov 2026 05:13:07 +0000
Subject: [PATCH] arm64: dts: qcom: sdm845-oneplus-fajita: Route the
 microphones to MCLK
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-fajita-codec-mclk-v1-1-ee4bca21d8ba@enser.io>
X-B4-Tracking: v=1; b=H4sIAOJ5AmsC/yXMwQ6CMBAE0F8he3aV1orRXzEetstWFrWYFokJ4
 d+lenyTmZkhS1LJcK5mSDJp1iGuMJsKuKN4E9R2NdjaNsZYi95hoF5HQh5aYXzy445mbwK5kw9
 NfYB1+koS9PO7vVz/zm/fC4/lqzQ8ZUGfKHJXosLddNw6TGxhWb5cZyAomAAAAA==
X-Change-ID: 20261122-b4-fajita-codec-mclk-131fa49bf605
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Abel Vesa <abelvesa@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Dylan Van Assche <me@dylanvanassche.be>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 EMCP333 <emcp@enser.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324388; l=2514;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=DGyS7iiSyD0F0W5165hIjMOEexnA6ODF4zyy8Qhxe84=;
 b=MPSGHzz05h1QrnlkAVXZ9JRXshJXFKZpSpb6sX3os1zzdzqFHl1RSXes0z96fFYozLT4XnMsl
 BEs3Zsx4KpLA2HsUkADPwgt7hB2Zvcor24BKNgGVeghlUjx9UfbIszz
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The WCD934x system clock is a DAPM supply widget, "MCLK", and the codec
driver routes nothing into it, so each board has to. fajita connects it
only to RX_BIAS, which only the playback paths use. A capture-only
stream therefore powers the microphone input, ADC, decimator and SLIMbus
TX path, but not the clock they run from, and records digital silence
until something has started playback.

Route each analog microphone input to MCLK, as other WCD934x boards do
for their microphones (sdm845-samsung-starqltechn,
sdm850-huawei-matebook-e-2019).

Tested on a OnePlus 6T with this change on the postmarketOS sdm845
kernel (6.18). With no playback stream open, a recording from the
bottom microphone powers MCLK while RX_BIAS stays off, and captures real
signal (peak 22307 over 6 s). Without it, the same recording is
constant zero. On v7.4-rc2, dtbs_check gives the same output before and
after.

The OnePlus 6 (enchilada) has the same routing and probably the same
problem. It is left alone here because I cannot test it.

The code and this changelog were prepared with the help of an AI coding
assistant. The submitter has reviewed both and takes responsibility for
them.

Fixes: b7b734286856 ("arm64: dts: qcom: sdm845-oneplus-*: add audio devices")
Signed-off-by: EMCP333 <emcp@enser.io>
---
Also ran on v7.4-rc3 on the same phone, as this exact commit: with no
playback open, DAPM MCLK is On and RX_BIAS Off, and the bottom mic
records (956 distinct sample values, peak 654, in a quiet room; the
failure is a constant zero).
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
index e9d1a1c6ac..a03c1ea8fe 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
@@ -51,10 +51,15 @@ &sound {
 	model = "OnePlus 6T";
 	audio-routing = "RX_BIAS", "MCLK",
 			"AMIC1", "MIC BIAS3",
+			"AMIC1", "MCLK",
 			"AMIC2", "MIC BIAS2",
+			"AMIC2", "MCLK",
 			"AMIC3", "MIC BIAS4",
+			"AMIC3", "MCLK",
 			"AMIC4", "MIC BIAS1",
-			"AMIC5", "MIC BIAS3";
+			"AMIC4", "MCLK",
+			"AMIC5", "MIC BIAS3",
+			"AMIC5", "MCLK";
 };
 
 &pmi8998_charger {

---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261122-b4-fajita-codec-mclk-131fa49bf605

Best regards,
--  
EMCP333 <emcp@enser.io>

