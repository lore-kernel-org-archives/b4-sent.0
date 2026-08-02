From: Esteban Urrutia <esteuwu@proton.me>
Date: Sun, 02 Aug 2026 03:30:54 -0400
Subject: [PATCH v2 1/4] pinctrl: qcom: sm8450: Remove duplicate reference
 to gpio81
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-sm8475-tlmm-v2-1-a93e1d1cb53b@proton.me>
References: <20260802-sm8475-tlmm-v2-0-a93e1d1cb53b@proton.me>
In-Reply-To: <20260802-sm8475-tlmm-v2-0-a93e1d1cb53b@proton.me>
To: Bjorn Andersson <andersson@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vinod Koul <vkoul@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-gpio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785656048; l=759;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=n3jh4Uj3nEySZi7aHaFMNoe1kPorY7QnSDR1AOA3wjQ=;
 b=vIlqVCtvW62RJAYsVjChLseYjbfg7mSs00DqW0UBU0DfryjTNRxHRBlhn2giIj80SSD6sYbRF
 tDv2NvkTuW5BL9WQNh5Cjc+mj/CCPksN3I4MXmqaEodhLKQWeQifT/r
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gpio81 is referenced twice in prng_rosc_groups.
Remove the duplicate reference.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 drivers/pinctrl/qcom/pinctrl-sm8450.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/pinctrl/qcom/pinctrl-sm8450.c b/drivers/pinctrl/qcom/pinctrl-sm8450.c
index 8ca5b6e15e6c..8bb6702cebe2 100644
--- a/drivers/pinctrl/qcom/pinctrl-sm8450.c
+++ b/drivers/pinctrl/qcom/pinctrl-sm8450.c
@@ -962,7 +962,7 @@ static const char * const pri_mi2s_groups[] = {
 };
 
 static const char * const prng_rosc_groups[] = {
-	"gpio73", "gpio75", "gpio81", "gpio83",  "gpio81",
+	"gpio73", "gpio75", "gpio81", "gpio83",
 };
 
 static const char * const qdss_cti_groups[] = {

-- 
2.55.0

