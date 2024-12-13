From: Ross Burton <ross.burton@arm.com>
Date: Fri, 13 Dec 2024 16:12:58 +0000
Subject: [PATCH] arm64: defconfig: remove obsolete CONFIG_SM_DISPCC_8650
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241213-clkmaster-v1-1-dcbf7fad37b1@arm.com>
X-B4-Tracking: v=1; b=H4sIAAldXGcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDI0Nj3eSc7NzE4pLUIl1TU4tU0xTzZEszs2QloPqCotS0zAqwWdGxtbU
 AZmVDoFsAAAA=
X-Change-ID: 20241213-clkmaster-558e5d7c966c
To: Catalin Marinas <catalin.marinas@arm.com>, 
 Will Deacon <will@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ross Burton <ross.burton@arm.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1058; i=ross.burton@arm.com;
 h=from:subject:message-id; bh=epENDaJFaEN+XJXFXZ723Iyyxb7oJBNFgTPKcQODkWo=;
 b=kA0DAAgBZItO7TOROJ0ByyZiAGdcXQvIqGC4hPhLJYfOvCIyA/T+rzDsNRxIyP39hHE1cxwB3
 IkCMwQAAQgAHRYhBIf9jOMBgVWcojlzDGSLTu0zkTidBQJnXF0LAAoJEGSLTu0zkTidtUUQALlI
 eHpo8h7c6m53q4NRc5Oca+Yj504O56wR7RfZApjR1hmzhklavRFuDBkfXtpYmoja3Mg73mN1cu0
 jhnHVRn8azedLxL5BQnh5UNa6ZH7voXrmeFyp+DrEPnozElBSlYilXvyfmj5sdkU7J/hxSiux8g
 Egyclnn6TYepZ+t59SajE3gmtQLj/Q731dS8B/7Tc/pr0dcxLxozTohv3o1Yl2c9vCK/r5AvgNy
 +t3Xm85Dc6JLnDgv00iR8a/FsbKC7N0/jcv0RwZZKfjAu8TFdSsZCM7ki/ppKRa9H9ZPQ4NLkgK
 YlnY3h9wtj5BI/cpDecn/X4cg5hln5RvjmAMRurk/zDwjekzmFUGCMV+UKdMT4FmWHcpvE0BWvx
 CNHLMb8Adu2wDe+1VYqJbZY1vHWUZSKNlbSb2AOEjaNf3K/jDiTEy6aaxAtuzipb2Hs/JvT/n20
 HM6i2Gy2tsvLsonwd/T2U8fDhAPOH2/nJEj5HjH+r/f6DnPn61Oqed1DR99GJtV7YwLVaClXa1J
 63WeHvvVi71mEaBpWSUV+QJo8Ygfq9AREPUZrTEGX8N9VadFUNIbvphZQnoUKA0ScHeIqS73ml9
 qfNGVimrwZc5Mz+2Itqrq1k2paKu8CESgrbgSP5O78mlsuTpXIjZN/W/eyWv3A7hkzTGItFsU2N
 6VWsg
X-Developer-Key: i=ross.burton@arm.com; a=openpgp;
 fpr=87FD8CE30181559CA239730C648B4EED3391389D
X-Endpoint-Received: by B4 Relay for ross.burton@arm.com/default with auth_id=59
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This option was removed from the Kconfig in commit 802b83205519 ("clk:
qcom: fold dispcc-sm8650 info dispcc-sm8550") but it was not removed
from the defconfig.

Fixes: 802b83205519 ("clk: qcom: fold dispcc-sm8650 info dispcc-sm8550")
Signed-off-by: Ross Burton <ross.burton@arm.com>
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
---
 arch/arm64/configs/defconfig | 1 -
 1 file changed, 1 deletion(-)

diff --git a/arch/arm64/configs/defconfig b/arch/arm64/configs/defconfig
index c62831e6158633f07c1f3532fba62f09b31e7448..c6d6a31a8f48c7ce9c9ca74e29db3b8835bfd556 100644
--- a/arch/arm64/configs/defconfig
+++ b/arch/arm64/configs/defconfig
@@ -1352,7 +1352,6 @@ CONFIG_SM_DISPCC_6115=m
 CONFIG_SM_DISPCC_8250=y
 CONFIG_SM_DISPCC_8450=m
 CONFIG_SM_DISPCC_8550=m
-CONFIG_SM_DISPCC_8650=m
 CONFIG_SM_GCC_4450=y
 CONFIG_SM_GCC_6115=y
 CONFIG_SM_GCC_8350=y

---
base-commit: 231825b2e1ff6ba799c5eaf396d3ab2354e37c6b
change-id: 20241213-clkmaster-558e5d7c966c

Best regards,
-- 
Ross Burton <ross.burton@arm.com>

