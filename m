From: Andrew Gigena <mail@andrewgigena.dev>
Date: Fri, 06 Nov 2026 03:24:54 +0000
Subject: [PATCH v2 3/5] media: qcom: camss: Match VFE lite clocks by name
 prefix
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-sm8150-v7.4-rc1-camss-v2-3-39ee37787b00@andrewgigena.dev>
References: <20261106-sm8150-v7.4-rc1-camss-v2-0-39ee37787b00@andrewgigena.dev>
In-Reply-To: <20261106-sm8150-v7.4-rc1-camss-v2-0-39ee37787b00@andrewgigena.dev>
To: Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Robert Foss <rfoss@kernel.org>, Andi Shyti <andi.shyti@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-i2c@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-media@vger.kernel.org, Andrew Gigena <mail@andrewgigena.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793935531; l=1422;
 i=mail@andrewgigena.dev; s=20261104; h=from:subject:message-id;
 bh=2iraXBb5zNtm/r+ImYDkshzAf5Ek9NUXiemEdTIIU6Q=;
 b=LTtcKd0GgAp9XbWN+VH8CNJQKE6a/Mh1li3LvFsoa+Rw8EwOlPtbH+gEXH8PTiXfvlNNw3JdU
 15P1RDicxrSDXb/66oMyY2IbHMK+LdgpJw1cw0IbWNmmPGzKohhGUFt
X-Developer-Key: i=mail@andrewgigena.dev; a=ed25519;
 pk=OMhlYIBaOEC8g4mJ4JCKy7kbg+lrwRxuujieZF8Ne6U=
X-Endpoint-Received: by B4 Relay for mail@andrewgigena.dev/20261104 with auth_id=1402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vfe_match_clock_names() builds the expected lite clock name from
vfe->id, but vfe->id is the index of the VFE in the resources array.
On SoCs where the lite VFEs come after the full VFEs, the generated
name is vfe_lite2, vfe_lite3, ... and never matches the actual
vfe_lite0/vfe_lite1 clocks, so their rates are never programmed.

This affects SM8150, SC7280 and SC8280XP. On a Pixel 4 (SM8150),
streaming through VFE-lite0 left cam_cc_ife_lite_0_clk at 19.2 MHz and
failed with "VFE reset timeout".

Match any clock whose name starts with "vfe_lite" when the VFE is a
lite instance, in addition to the existing exact matches.

Signed-off-by: Andrew Gigena <mail@andrewgigena.dev>
---
 drivers/media/platform/qcom/camss/camss-vfe.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/media/platform/qcom/camss/camss-vfe.c b/drivers/media/platform/qcom/camss/camss-vfe.c
index 2680a9914765..9866ac09eefd 100644
--- a/drivers/media/platform/qcom/camss/camss-vfe.c
+++ b/drivers/media/platform/qcom/camss/camss-vfe.c
@@ -914,6 +914,7 @@ static int vfe_match_clock_names(struct vfe_device *vfe,
 	return (!strcmp(clock->name, vfe_name) ||
 		!strcmp(clock->name, vfe_lite_name) ||
 		!strcmp(clock->name, "vfe_lite") ||
+		(vfe->res->is_lite && !strncmp(clock->name, "vfe_lite", 8)) ||
 		!strcmp(clock->name, "camnoc_axi") ||
 		!strcmp(clock->name, "camnoc_rt_axi"));
 }

-- 
2.56.0

