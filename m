From: Fenglin Wu <quic_fenglinw@quicinc.com>
Date: Fri, 12 Apr 2024 20:36:25 +0800
Subject: [PATCH v10 1/4] input: pm8xxx-vibrator: correct VIB_MAX_LEVELS
 calculation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240412-pm8xxx-vibrator-new-design-v10-1-0ec0ad133866@quicinc.com>
References: <20240412-pm8xxx-vibrator-new-design-v10-0-0ec0ad133866@quicinc.com>
In-Reply-To: <20240412-pm8xxx-vibrator-new-design-v10-0-0ec0ad133866@quicinc.com>
To: kernel@quicinc.com, Andy Gross <agross@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Fenglin Wu <quic_fenglinw@quicinc.com>
X-Mailer: b4 0.13-dev-83828
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712925404; l=1309;
 i=quic_fenglinw@quicinc.com; s=20240327; h=from:subject:message-id;
 bh=t75pzebWYsBpS9YipaE4zw2bQKsUcZAihoKdmtGp74A=;
 b=YtCTA1CmZN2cm3NtM2xXw4EX1VXMqT/MDV3Qn2DTUJ+AzruJdiuW3rieHUdYCU81qymp2/gIA
 5QWFyJYudKOAsl78E36sVwaZaLJD/Hmv4W3TLR9I9Gc0at5cfVhC+Dr
X-Developer-Key: i=quic_fenglinw@quicinc.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for quic_fenglinw@quicinc.com/20240327 with auth_id=146
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The output voltage is inclusive hence the max level calculation is
off-by-one-step. Correct it.

Fixes: 11205bb63e5c ("Input: add support for pm8xxx based vibrator driver")
Signed-off-by: Fenglin Wu <quic_fenglinw@quicinc.com>
---
 drivers/input/misc/pm8xxx-vibrator.c | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)

diff --git a/drivers/input/misc/pm8xxx-vibrator.c b/drivers/input/misc/pm8xxx-vibrator.c
index 04cb87efd799..844ca7e1f59f 100644
--- a/drivers/input/misc/pm8xxx-vibrator.c
+++ b/drivers/input/misc/pm8xxx-vibrator.c
@@ -14,7 +14,8 @@
 
 #define VIB_MAX_LEVEL_mV	(3100)
 #define VIB_MIN_LEVEL_mV	(1200)
-#define VIB_MAX_LEVELS		(VIB_MAX_LEVEL_mV - VIB_MIN_LEVEL_mV)
+#define VIB_PER_STEP_mV		(100)
+#define VIB_MAX_LEVELS		(VIB_MAX_LEVEL_mV - VIB_MIN_LEVEL_mV + VIB_PER_STEP_mV)
 
 #define MAX_FF_SPEED		0xff
 
@@ -118,10 +119,10 @@ static void pm8xxx_work_handler(struct work_struct *work)
 		vib->active = true;
 		vib->level = ((VIB_MAX_LEVELS * vib->speed) / MAX_FF_SPEED) +
 						VIB_MIN_LEVEL_mV;
-		vib->level /= 100;
+		vib->level /= VIB_PER_STEP_mV;
 	} else {
 		vib->active = false;
-		vib->level = VIB_MIN_LEVEL_mV / 100;
+		vib->level = VIB_MIN_LEVEL_mV / VIB_PER_STEP_mV;
 	}
 
 	pm8xxx_vib_set(vib, vib->active);

-- 
2.25.1

