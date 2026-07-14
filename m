From: Esteban Urrutia <esteuwu@proton.me>
Date: Tue, 14 Jul 2026 02:36:40 -0400
Subject: [PATCH 2/6] phy: qcom: qmp-pcie: Add pcs_lane1 offset to V5
 offsets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260714-sm8475-bup-v1-2-b2871be2b4ec@proton.me>
References: <20260714-sm8475-bup-v1-0-b2871be2b4ec@proton.me>
In-Reply-To: <20260714-sm8475-bup-v1-0-b2871be2b4ec@proton.me>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784011013; l=843;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=F5UdqLwC15G2UvXxjasu1py1N0XW4szUwdIBq6LGK4E=;
 b=ukvHRLACirQxzxbOSPAUlwEJxKSXdNkzqU6q+GVamPSQ3lpZuOe5DzquAmqEfaNvWl8yf1oIP
 sFQ68JpJZt7AtJNyt3vGciWQpBB+WnTuLnfQR8W+8tuIRbWVlrZMOjV
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some SoCs such as SM8475 write data to registers using this offset,
specifically SW_CTRL2 and MX_CTRL2.
Add pcs_lane1 offset to V5 offsets using the proper offset, otherwise these
registers would be part of RX and would not be defined.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 drivers/phy/qualcomm/phy-qcom-qmp-pcie.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/phy/qualcomm/phy-qcom-qmp-pcie.c b/drivers/phy/qualcomm/phy-qcom-qmp-pcie.c
index d3effad7a074..3618812e84d5 100644
--- a/drivers/phy/qualcomm/phy-qcom-qmp-pcie.c
+++ b/drivers/phy/qualcomm/phy-qcom-qmp-pcie.c
@@ -3554,6 +3554,7 @@ static const struct qmp_pcie_offsets qmp_pcie_offsets_v5 = {
 	.pcs_misc	= 0x0600,
 	.tx		= 0x0e00,
 	.rx		= 0x1000,
+	.pcs_lane1	= 0x1400,
 	.tx2		= 0x1600,
 	.rx2		= 0x1800,
 };

-- 
2.55.0

