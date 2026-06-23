From: Esteban Urrutia <esteuwu@proton.me>
Date: Mon, 22 Jun 2026 20:54:29 -0400
Subject: [PATCH 8/8] arm64: defconfig: Add SM8450 camcc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260622-sm8450-qol-v1-8-37e2ee8df9da@proton.me>
References: <20260622-sm8450-qol-v1-0-37e2ee8df9da@proton.me>
In-Reply-To: <20260622-sm8450-qol-v1-0-37e2ee8df9da@proton.me>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, "Joerg Roedel (AMD)" <joro@8bytes.org>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 iommu@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-phy@lists.infradead.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782176157; l=617;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=tJTk/lG/kNTnUjOLpx+gWVzUbilr34jSWya5odqqhqs=;
 b=qSquq9luNtdbeWsRumnnqskxOKb6XsFmPQk/wqQyMxMqshJHpQq5fAYeBMGjGEGP/BW3Zq/30
 KQKqkVP7EE1BbZmsUl2lhoH3RDA25jfGC+mzxoned9J0JrGpVs7snP3
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SM8450 camcc as a module since it's enabled in SM8450 dtsi.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 arch/arm64/configs/defconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/configs/defconfig b/arch/arm64/configs/defconfig
index f2e6ae93e533..8c50c16ee0b8 100644
--- a/arch/arm64/configs/defconfig
+++ b/arch/arm64/configs/defconfig
@@ -1541,6 +1541,7 @@ CONFIG_SDX_GCC_75=y
 CONFIG_SM_CAMCC_6350=m
 CONFIG_SM_CAMCC_MILOS=m
 CONFIG_SM_CAMCC_8250=m
+CONFIG_SM_CAMCC_8450=m
 CONFIG_SM_CAMCC_8550=m
 CONFIG_SM_CAMCC_8650=m
 CONFIG_SM_CAMCC_8750=m

-- 
2.54.0

