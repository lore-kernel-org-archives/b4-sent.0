From: David Heidelberg <david@ixit.cz>
Date: Tue, 18 Nov 2025 15:52:26 +0100
Subject: [PATCH v2 2/3] arm64: dts: qcom: sdm845-oneplus: Don't keep panel
 regulator always on
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251118-dts-oneplus-regulators-v2-2-3e67cea1e4e7@ixit.cz>
References: <20251118-dts-oneplus-regulators-v2-0-3e67cea1e4e7@ixit.cz>
In-Reply-To: <20251118-dts-oneplus-regulators-v2-0-3e67cea1e4e7@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=900; i=david@ixit.cz;
 h=from:subject:message-id; bh=j0QnjGANGmzRmUOnq9jdVWDCQrtTASbh7BGRtKRJX+A=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpHIgrJLbt+5shKWrJ9vnhDSlhzTU2zrY4SYHBX
 F7g+zZy6duJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRyIKwAKCRBgAj/E00kg
 coQUD/408Q1Kwch7A9SU42JCBBgEbRR3x860qPjiDEvqphiwRgk0ei3ZfJstJ2Ygg7Q00yjOzG2
 LMAjNk/mPv3ELYN+DH+jfEaK5NClhwtiODKXH8Zmv/yTHFemTtK4pFpBuS+mcaxX3XdA1vSrRbl
 ZTqed0mYjP6TG9+C3olItdS3vhC9JDYTEoHBEFZL3dwSt1t2tdTEfWHEP68Ny61bEb7f1B1NG3q
 Qw+XKssfHDhhI7A3U7ZxE8aVys/qhxDnA39no7bhkhL4N/OBHk1QaIswwfDFRLBl5U8UPNDLoNv
 4NGOtuLopq+HdbCeNkVa6EGBvCVhAnvjgYufukfobq7fT4GQZ+hpRVkwaL/trsjlQA7vy6buMYf
 DfTAT9wO+zLTh/sTIMXmOI0yKnx7KoqGtYubozUX9wmrj9qNFqE2gEAeUGro1SGVbfHs3Nkd57F
 1LHgiUKXri+8Sjic7dIV42BX7nN8bANf6FSQfCYotwU+cxRy2740sujchElGZvj9SdkpELlRnH6
 X8QJvx8f83k9GJjBsYe5piHQ4dXC73Y1krvMkWq3Lj8HqSYf9W2uUUj3Bj3eRNxL6GMt6ywTg6l
 YGfZKc87r1PP67voAPQ7Mw1X3E6QNlAeQZquzR0RTZtL6+RLsGX15nWETxkLxFJd4WVG1PJgYcF
 3IAKDLka65EN5Zw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

The panel regulator doesn't need to be always on, so remove this
property.

Fixes: 288ef8a42612 ("arm64: dts: sdm845: add oneplus6/6t devices")
Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 1 -
 1 file changed, 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index ee62adfa6af0b..5845bc3bb80b2 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -272,7 +272,6 @@ vreg_l14a_1p88: ldo14 {
 			regulator-min-microvolt = <1800000>;
 			regulator-max-microvolt = <1800000>;
 			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
-			regulator-always-on;
 		};
 
 		vreg_l17a_1p3: ldo17 {

-- 
2.51.0

