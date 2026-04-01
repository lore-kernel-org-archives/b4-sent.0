From: David Heidelberg <david@ixit.cz>
Date: Wed, 01 Apr 2026 18:51:44 +0200
Subject: [PATCH v2 2/3] arm64: dts: qcom: sdm845-shift-axolotl: Set higher
 touchscreen i2c clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260401-axolotl-misc-p1-v2-2-f3af384bbb50@ixit.cz>
References: <20260401-axolotl-misc-p1-v2-0-f3af384bbb50@ixit.cz>
In-Reply-To: <20260401-axolotl-misc-p1-v2-0-f3af384bbb50@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dylan Van Assche <me@dylanvanassche.be>
Cc: linux-arm-msm@vger.kernel.org, Petr Hodina <phodina@protonmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=838; i=david@ixit.cz;
 h=from:subject:message-id; bh=I0Y7L1PsS3Jhw9nUJ5UreIwD0pMxhXyzUsaI/TIX2V8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpzU0jNGGXoC33T+AVl2tjBGQZ4i6IupF4X7Y4z
 6gEqV2RzVKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac1NIwAKCRBgAj/E00kg
 cvCkD/4pAu+7Ud3PoqBKltvqJCumdqwBdGkFnrGryy2unNZmvFgJnkQHHTeafTNLOQtZ2XStLgp
 Lx9DaCSmRrAk+twJG1LEcaIYISN4pxo+HaFMCHXNecdqei1oXR+uZoTzX9RaJmEFKG/PwR6Or+r
 mJA201ockb7844c+d66lJXb6zvsPc2UBRv1ZlFGEBMHfkJpKVUBDm6pRSkvaLLZvdXb4U7B6dTA
 h1xy001b1xFQOXCGlV22sqrQ9uHOvjR8gkPTFwHARE2BHXkdiix13cI1aC0MiQ0Xz1brhueFOoC
 dyWPJIGZRiMEvM8kDNgJuF4gmblIG2mCcjv9cjw9w2hYfClDCGCbV0BlI4BPelOR9rKZveM5fX3
 k6u3DXTJcoRc8iW5DuqgIwxcpshzq4lwd1/jVxbyHRCrkSM03oIGy4M2KKb0Kc6i4zWpfw/UIR8
 skCV5rz2kYDZzr5j6Ga7Flj6A/0UYZ+GuNgKaBoy1skA9ejHYrpouM/T63os/e8r3azknWt+Van
 cI6d6U1tqSxtaeRUvMKSRAfvptGm+OsrotrlmMTj2irl1pbeGuvFYb6jPpXF3X+hsS2M8kMmkKm
 Ch6jmAHxV9raXO0lEiDGMGT+AV747nMCPEwIDhp4rL5B9ofD/CGQPTy4Gxl8L8Qm+qnehVPZJI3
 zO/wwP+MfGHL2UA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

Sets a higher rate than the default for good responsiveness of
touchscreen.

Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index c394350998c26..181c61e8ed748 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -432,6 +432,8 @@ &gpu_zap_shader {
 };
 
 &i2c5 {
+	clock-frequency = <400000>;
+
 	status = "okay";
 
 	touchscreen@38 {

-- 
2.53.0

