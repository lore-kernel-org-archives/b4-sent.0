From: Esteban Urrutia <esteuwu@proton.me>
Subject: [PATCH v2 0/2] SM8450 QoL changes (qmp)
Date: Sat, 11 Jul 2026 23:13:16 -0400
Message-Id: <20260711-sm8450-qol-qmp-v2-0-d14353bd6ff4@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/02Nyw6CMBBFf4XM2jHtIC9X/odhwWOQGmmhxUZD+
 HcLbFye5NxzF3BsFTu4RgtY9sopowPQKYKmr/SDUbWBgQSlIpMS3ZBfEoGTeeE0jJjEXc1NURf
 EOYTRaLlTnz14Lw927/rJzbxVNqNXbjb2uz96uXlHPCX6j3uJAuOMiTlvu6KtbqM1s9HngaFc1
 /UH0Nswv7oAAAA=
X-Change-ID: 20260711-sm8450-qol-qmp-53fbec9b92e8
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Dmitry Baryshkov <lumag@kernel.org>, Bjorn Andersson <andersson@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Esteban Urrutia <esteuwu@proton.me>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783826002; l=809;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=CnxT7IX+/QaPvXduAC/yoSfn8VJxlMb0Yx8cduWN740=;
 b=gFTD4IDaLgOS67N2qExQKGIXVwukbZhnviwPA81Xq+PlqE6e/hDwEJe1mLhb86Q01IOMncjPs
 d1IwSV9+EDhCVQ3SFjV4VqECrN9/UQcG/2z8ICawtQtRwsKnR79v1f9
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These two patches drop qmp_v4_calibrate_dp_phy() and modify a pre-emphasis
table for v4 DP PHYs to match downstream behavior.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
Changes in v2:
- Split series in subseries (dispcc, dts, qmp, smmu)
- Link to v1: https://patch.msgid.link/20260622-sm8450-qol-v1-0-37e2ee8df9da@proton.me

---
Esteban Urrutia (2):
      phy: qcom: qmp-combo: Correct pre-emphasis table for QMP v4 DP PHYs
      phy: qcom: qmp-combo: Drop qmp_v4_calibrate_dp_phy

 drivers/phy/qualcomm/phy-qcom-qmp-combo.c | 33 +------------------------------
 1 file changed, 1 insertion(+), 32 deletions(-)
---
base-commit: 96615101b3caf73612f80a217abb9a0da0effbc7
change-id: 20260711-sm8450-qol-qmp-53fbec9b92e8

Best regards,
--  
Esteban Urrutia <esteuwu@proton.me>

