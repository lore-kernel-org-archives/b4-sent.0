From: Petr Hodina <petr.hodina@protonmail.com>
Date: Tue, 20 Jan 2026 13:24:24 +0100
Subject: [PATCH v2 1/2] arm64: dts: qcom: sdm845-sony-xperia-tama: Correct
 uart instances
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260120-akatsuki-uart-v2-1-867ee7f042d0@protonmail.com>
References: <20260120-akatsuki-uart-v2-0-867ee7f042d0@protonmail.com>
In-Reply-To: <20260120-akatsuki-uart-v2-0-867ee7f042d0@protonmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Petr Hodina <petr.hodina@protonmail.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768911867; l=1043;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=Uiq6uInCG+ev6OjtV0dsVw/tbeOLla0LBEDxIr+Q7H4=;
 b=e4omXnaL5Zccdi2Xe4Z3YKy8cyONcP6HQcIYvPqEfKP8xEGBIQeumy47YRbY9jMwZfGPleZHv
 JE3vDo2Jts6D17GMBp4qKxYzOzXTwji+UGHmpfBMzqknx+nfEd5oPFU
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Change the uart instances:
- uart6 is for bluetooth
- uart9 is for serial console (available on the uSD pinout)

Most OSes assume serial0 is for console UART. Bluetooth interface uses
UART interface. uart6 is standard debug console and uart9 bluetooth on
SDM845 devices.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Reviewed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi b/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi
index 7dc9349eedfd..68841e036c20 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi
@@ -17,8 +17,8 @@ / {
 	qcom,board-id = <8 0>;
 
 	aliases {
-		serial0 = &uart6;
-		serial1 = &uart9;
+		serial0 = &uart9;
+		serial1 = &uart6;
 	};
 
 	chosen {

-- 
2.52.0

