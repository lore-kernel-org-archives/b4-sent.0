From: =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
Date: Fri, 22 May 2026 12:43:26 +0200
Subject: [PATCH v2 10/10] arm64: dts: qcom: sc8280xp-arcata: Drop duplicate
 DMIC supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260522-surface-sp9-5g-for-next-v2-10-dd9d477407f5@gmail.com>
References: <20260522-surface-sp9-5g-for-next-v2-0-dd9d477407f5@gmail.com>
In-Reply-To: <20260522-surface-sp9-5g-for-next-v2-0-dd9d477407f5@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Johan Hovold <johan@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Krzysztof Kozlowski <krzk@kernel.org>, 
 =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779446623; l=1416;
 i=jerome.debretagne@gmail.com; s=20260520; h=from:subject:message-id;
 bh=JlRG4nTcgg3o5MKMFi2SWQY9MXhILWt8VcNKctZNamw=;
 b=8qu1s7ecMCbQOFhN3sTt5DFnmB6ExgzvNv057us0GMNE3dcWrNZVlHucqpnZDpkqo3wbhbODp
 XAC/8BfDmMGB5hyIceCbdwAgVxFmuf6LvOLTeJZEsmOFKj6hMvCKbea
X-Developer-Key: i=jerome.debretagne@gmail.com; a=ed25519;
 pk=3/JYhgYjGg5V9mlFxc0A0+pFiyjsuDB/TtDlNMId9fk=
X-Endpoint-Received: by B4 Relay for jerome.debretagne@gmail.com/20260520 with auth_id=785
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Align with the reference implementation from the ThinkPad X13s.

The audio-routing setup specifies two power supplies for each DMIC,
but only one of them can be active at the same time.

Drop the redundant routes to the pull-up "VA MIC BIASn" supplies as
done in commit a2e617f4e698 ("arm64: dts: qcom: sc8280xp-x13s: Drop
duplicate DMIC supplies").

There is no functional difference except that we skip briefly switching
to pull-up mode when shutting down the microphone.

Cc: Stephan Gerhold <stephan.gerhold@linaro.org>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Jérôme de Bretagne <jerome.debretagne@gmail.com>
---
 arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts | 3 ---
 1 file changed, 3 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts
index 60f65fd450ecba8196509a620be029314e5efc05..74e218cf8aaaa5658982c5cda0b231802712650d 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts
+++ b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts
@@ -776,9 +776,6 @@ &sound {
 			"VA DMIC0", "MIC BIAS1",
 			"VA DMIC1", "MIC BIAS1",
 			"VA DMIC2", "MIC BIAS3",
-			"VA DMIC0", "VA MIC BIAS1",
-			"VA DMIC1", "VA MIC BIAS1",
-			"VA DMIC2", "VA MIC BIAS3",
 			"TX SWR_ADC1", "ADC2_OUTPUT";
 
 	wcd-playback-dai-link {

-- 
2.47.3

