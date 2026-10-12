From: Juerg Haefliger <juerg.haefliger@canonical.com>
Date: Mon, 12 Oct 2026 17:50:59 +0200
Subject: [PATCH v2 2/2] arm64: dts: qcom: hp-elitebook-ultra-g1q: Drop
 omnibook-x14.dts include
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261012-dts-qcom-hp-omnibook-x14-cleanup-v2-2-c859ac395b81@canonical.com>
References: <20261012-dts-qcom-hp-omnibook-x14-cleanup-v2-0-c859ac395b81@canonical.com>
In-Reply-To: <20261012-dts-qcom-hp-omnibook-x14-cleanup-v2-0-c859ac395b81@canonical.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Abel Vesa <abel.vesa@oss.qualcomm.com>, 
 Juerg Haefliger <juerg.haefliger@canonical.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1606;
 i=juerg.haefliger@canonical.com; s=F9F8B48C; h=from:subject:message-id;
 bh=wYZi3Ex+jcuLvYp1WrG2Ggo1op8kwvdM5pUYcvKt6HA=;
 b=owEBbQKS/ZANAwAKAQ/TiwkLpkK3AcsmYgBqzQH88nC9bXlSpbY6dITBWCBaGw/yv+1WNe4LZ
 3+Te+d1ComJAjMEAAEKAB0WIQSFl9T3oi6mu+It14sP04sJC6ZCtwUCas0B/AAKCRAP04sJC6ZC
 t1wnEACRm8OMf4PB5mK/A5V3KH60pFadUFHPyKA3im9RW5porxJrnJjBAOxP9Sz1mogMpiovqY2
 lmvDDtt1RkHXMIAWVyVZMuaNO91VOJPVhF0hwN2O3K3W1IFHGb0Bnw6+laFm5pKJ2TkMbyExzP0
 tkPE31s8HGYduMrmmiUiwBba6XFpmWXRoFS1horVHrE+5NAukL/Cj9GvgIxecoLzEiLG0hrC3K1
 PoKkWCgNo3YZAyJ4v48T63G8MDO1rDhE/ehAm5fq7AIM8WEengp7uYiv7a0KwC1pkL4Q3LZ23Mm
 LB12mFLN3eFFaAku5Gcuk8JOqZsHdn3tE4Jot6/mF4ogEpgiF2wwst0rPGJPZ4Id1p6bt+hiy6R
 tFI2KjF7EFEE8E1QXKk72I+qp6hwSf7Z56muLXzI2SqQztpX5pGzPDUgkIYWjWySrbkE86GVVcW
 jUJhhwtvvCZQySf4G36dA+gXfJsQu2tdD9BeT8YWO+3pkZKpzVsj7H4gJ7hJPt2Uz9TVcCRT9eW
 sk5zA3++pGSUQVNkLhzE0pHSqfXn2U5anBC3n9PYs0n55EEddkUHvQ8ErhrZ743kGOkJLe2A18A
 yilmxKpZxa8FtTMMRoObC8xxFOAAZKH+HsHykCqSb8T+xX9NAhwHxW+w+g4ZRbC7JWKSdJG578w
 bSdixhDOT7vtZsQ==
X-Developer-Key: i=juerg.haefliger@canonical.com; a=openpgp;
 fpr=52B5BDD2A6EDC76A0FE0AB4A754C3A96F9F8B48C
X-Endpoint-Received: by B4 Relay for juerg.haefliger@canonical.com/F9F8B48C with auth_id=1135
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The EliteBook Ultra G1q is a different product from the OmniBook X14 that
happens to reuse the same mainboard, not a variant of it. As such, it
should not be a child of x1e80100-hp-omnibook-x14 but rather a sibling.
Include the shared base platform dtsi to match the other OmniBook X14s.

Explicitly enable the remoteprocs which is required now that the status is
no longer inherited from x1e80100-hp-omnibook-x14.

Reviewed-by: Abel Vesa <abel.vesa@oss.qualcomm.com>
Signed-off-by: Juerg Haefliger <juerg.haefliger@canonical.com>
---
 arch/arm64/boot/dts/qcom/x1e80100-hp-elitebook-ultra-g1q.dts | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/x1e80100-hp-elitebook-ultra-g1q.dts b/arch/arm64/boot/dts/qcom/x1e80100-hp-elitebook-ultra-g1q.dts
index 0b3b6cb23e1a..9327eaa16b92 100644
--- a/arch/arm64/boot/dts/qcom/x1e80100-hp-elitebook-ultra-g1q.dts
+++ b/arch/arm64/boot/dts/qcom/x1e80100-hp-elitebook-ultra-g1q.dts
@@ -2,7 +2,8 @@
 
 /dts-v1/;
 
-#include "x1e80100-hp-omnibook-x14.dts"
+#include "hamoa.dtsi"
+#include "x1-hp-omnibook-x14.dtsi"
 
 / {
 	model = "HP EliteBook Ultra G1q";
@@ -16,11 +17,15 @@ &gpu_zap_shader {
 &remoteproc_adsp {
 	firmware-name = "qcom/x1e80100/hp/elitebook-ultra-g1q/qcadsp8380.mbn",
 			"qcom/x1e80100/hp/elitebook-ultra-g1q/adsp_dtbs.elf";
+
+	status = "okay";
 };
 
 &remoteproc_cdsp {
 	firmware-name = "qcom/x1e80100/hp/elitebook-ultra-g1q/qccdsp8380.mbn",
 			"qcom/x1e80100/hp/elitebook-ultra-g1q/cdsp_dtbs.elf";
+
+	status = "okay";
 };
 
 &sound {

-- 
2.53.0

