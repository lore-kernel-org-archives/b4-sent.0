From: David Heidelberg <david@ixit.cz>
Date: Wed, 25 Mar 2026 17:41:14 +0100
Subject: [PATCH v3 3/3] arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable
 ath10k host-cap skip quirk
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260325-skip-host-cam-qmi-req-v3-3-b163cf7b3c81@ixit.cz>
References: <20260325-skip-host-cam-qmi-req-v3-0-b163cf7b3c81@ixit.cz>
In-Reply-To: <20260325-skip-host-cam-qmi-req-v3-0-b163cf7b3c81@ixit.cz>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Paul Sajna <sajattack@postmarketos.org>
Cc: Amit Pundir <amit.pundir@linaro.org>, linux-wireless@vger.kernel.org, 
 devicetree@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=872; i=david@ixit.cz;
 h=from:subject:message-id; bh=UMGVnHrK6pCDEFTzYCQCMat5Ekz90Tnn8gJJq27l4D8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpxBAsImtUxcwDcuRQMT2RSZfTcA3re//OcMpda
 28Dc4T3s42JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCacQQLAAKCRBgAj/E00kg
 cs8ID/9d8cdH52NkCDRPgE25911WcApLT2YMEJpTG5Y4a2frJfmGQpsZWKlAeSrofnqoWTNnLjk
 XSaWdtvercDcwqk9kY/CH3tuLpeUJwhu10wuTmejuqCw6r1QgpybI6TQdJDDxhESYrtCGtjXuOY
 mlvFae/u7Fss9Y0HU9Gi0jckJkYKzok4X6/FWDPzU+LvBEcS+yDHh9IlaybcFnhcBGsKiCgfXu4
 GY0cWoujkiqgAFC2cGZc53/td6utuG5+Ek7YMfGt8jyqDfXUxTkMHkx7t0p2iTfyZo8yvyDFR7s
 1igCwudvjHPnulQ+opB7Oyh7mUyG1mNDlEtJQyiHZOqpSBgYlQk2p2llQ70TI1jjY4d8+bhU9Nr
 kJUaXAakMcgZTrrLC4fKutDx+0k1AY/LUz0lmO+YlnijROhTZikHQXKoHC45E5NZqIHw0slDOQs
 Vx0nFbdVR3znZ1GzIIbMFy96GGdiAgo8bpw3wEyu1rOVHzlt+mpAK1PRWAo8weAluR9xGTrWYVR
 B/XdR9rCbYl+gAqAO+ikNRXJvBcI1AUYfLSmMC4MovUjisWpPCm6klUCooiaWpuK/448AKucRNp
 CZkwUwQWpg1jaRUG+tjIWMB6WAA/gXOlqb13/ixqd+IqwVOagJjJfpHq8h034x+WT83P/oSQCL5
 idr7kEpNjPNiALg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Amit Pundir <amit.pundir@linaro.org>

The WiFi firmware used on Xiaomi PocoPhone F1 (beryllium) phone
doesn't support the host-capability QMI request, hence enable
the skip quirk for this device.

Signed-off-by: Amit Pundir <amit.pundir@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 1298485c42142..950bbcc3bf91f 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -661,5 +661,6 @@ &wifi {
 	vdd-3.3-ch1-supply = <&vreg_l23a_3p3>;
 
 	qcom,calibration-variant = "xiaomi_beryllium";
+	qcom,snoc-host-cap-skip-quirk;
 };
 

-- 
2.53.0

