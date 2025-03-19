From: Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>
Date: Tue, 18 Mar 2025 22:11:37 -0500
Subject: [PATCH] arm64: defconfig: Enable USB retimer and redriver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250318-xelite-retimer-redriver-v1-1-b3e85a37d294@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIAOg12mcC/x2MSQqAQBADvyJ9dkDH3a+IB3WiNrjRIyKIf7fxl
 BRU8pCHMDzVwUOCiz3vm0IcBjTM3TbBsFMmG9ksSuLS3Fj4hBGcvEI0nfClpbB9mqvgqtySrg/
 ByPf/3LTv+wG9RjTJaQAAAA==
X-Change-ID: 20250318-xelite-retimer-redriver-72b46318d962
To: Catalin Marinas <catalin.marinas@arm.com>, 
 Will Deacon <will@kernel.org>, andersson@kernel.org
Cc: Abel Vesa <abel.vesa@linaro.org>, linux-arm-msm@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742353900; l=1300;
 i=bjorn.andersson@oss.qualcomm.com; s=20250318; h=from:subject:message-id;
 bh=xRKqtaffSGX6Pjvc76vk0LWObAmQZMRTKBjP4UwTEzw=;
 b=Ilmlg9Ibvz3XH1u7sHItyqo0EvVlOztOyFwXe0QY5EL4PoQ3fG04ma3H4a+kPHGcJiDdNdsXI
 mtCbAkXJSrHDMh8WKqLwGa1D7rgtQzEq8O5nIjRiu3pOy0p6HnKDzu2
X-Developer-Key: i=bjorn.andersson@oss.qualcomm.com; a=ed25519;
 pk=rD3O9C9Erg+mUPBRBNw91AGaIaDVqquHZbnn6N6xh6s=
X-Endpoint-Received: by B4 Relay for bjorn.andersson@oss.qualcomm.com/20250318 with auth_id=362
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Several boards based on the Qualcomm X Elite platform uses the NXP
PTN3222 USB redriver and the Parade PS883x USB Type-C retimer. Without
these USB, and in some cases display, doesn't probe successfully, so
enable them.

Signed-off-by: Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>
---
 arch/arm64/configs/defconfig | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm64/configs/defconfig b/arch/arm64/configs/defconfig
index e8dfbe22db68d9aa24df5af0786a2eeb8f33bf3c..5bb8f09422a22116781169611482179b10798c14 100644
--- a/arch/arm64/configs/defconfig
+++ b/arch/arm64/configs/defconfig
@@ -1153,6 +1153,7 @@ CONFIG_TYPEC_HD3SS3220=m
 CONFIG_TYPEC_MUX_FSA4480=m
 CONFIG_TYPEC_MUX_GPIO_SBU=m
 CONFIG_TYPEC_MUX_NB7VPQ904M=m
+CONFIG_TYPEC_MUX_PS883X=m
 CONFIG_TYPEC_MUX_WCD939X_USBSS=m
 CONFIG_TYPEC_DP_ALTMODE=m
 CONFIG_MMC=y
@@ -1573,6 +1574,7 @@ CONFIG_RESET_RZG2L_USBPHY_CTRL=y
 CONFIG_RESET_TI_SCI=y
 CONFIG_PHY_XGENE=y
 CONFIG_PHY_CAN_TRANSCEIVER=m
+CONFIG_PHY_NXP_PTN3222=m
 CONFIG_PHY_SUN4I_USB=y
 CONFIG_PHY_CADENCE_TORRENT=m
 CONFIG_PHY_CADENCE_DPHY_RX=m

---
base-commit: c4d4884b67802c41fd67399747165d65c770621a
change-id: 20250318-xelite-retimer-redriver-72b46318d962

Best regards,
-- 
Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>

