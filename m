From: =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
Date: Wed, 20 May 2026 18:40:15 +0200
Subject: [PATCH 11/11] arm64: dts: qcom: sc8280xp-arcata: Drop duplicate
 DMIC supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260520-surface-sp9-5g-for-next-v1-11-9df52552bf87@gmail.com>
References: <20260520-surface-sp9-5g-for-next-v1-0-9df52552bf87@gmail.com>
In-Reply-To: <20260520-surface-sp9-5g-for-next-v1-0-9df52552bf87@gmail.com>
To: Douglas Anderson <dianders@chromium.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 Krzysztof Kozlowski <krzk@kernel.org>, 
 =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779295238; l=1355;
 i=jerome.debretagne@gmail.com; s=20260520; h=from:subject:message-id;
 bh=zKav9HnHTj8DgP+Z9y+E814drSGNPU5bW2do5oedD5A=;
 b=jd63XVNVGo/QGrpVcEm+/DDF4Q/3SVr5c2azDz7Dhq8sS+H+BzUrp5rqDGwTydj26e1IU4R6W
 aMgOb7aIf4zD9WFH9SSEPHvEOAEo9UHNfDMJOBHTLhsuIHiZdo0YfNQ
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
Signed-off-by: Jérôme de Bretagne <jerome.debretagne@gmail.com>
---
 arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts | 3 ---
 1 file changed, 3 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts
index ae0a054f2f9d90c9341766528d6be0b9561a530f..f938e68c69ea9276ca89d75b659dbea6a7a832f7 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts
+++ b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts
@@ -793,9 +793,6 @@ &sound {
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

