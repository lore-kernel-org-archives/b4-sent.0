From: fangez <quic_fangez@quicinc.com>
Date: Mon, 14 Oct 2024 17:47:27 +0800
Subject: [PATCH 1/6] arm64: defconfig: Enable SX150X
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241014-add_display_support_for_qcs615-v1-1-4efa191dbdd4@quicinc.com>
References: <20241014-add_display_support_for_qcs615-v1-0-4efa191dbdd4@quicinc.com>
In-Reply-To: <20241014-add_display_support_for_qcs615-v1-0-4efa191dbdd4@quicinc.com>
To: kernel@quicinc.com, quic_lliu6@quicinc.com, quic_fangez@quicinc.com, 
 quic_xiangxuy@quicinc.com
Cc: linux-arm-msm@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728899259; l=655;
 i=quic_fangez@quicinc.com; s=20241014; h=from:subject:message-id;
 bh=2oL5VRIgrDO2dMYMSsbMFqFY/afbcI/s90GaKevkxFE=;
 b=N7GvkedBJSFbgSnJZKVagff/qigmGINyMf44K8RHHSACNGxZKqi7ny0vi3HcL+rVrUj85sYOP
 qQOBT35qyxsBZOdTCfg8jAtARN5h6woDtft2VVmwXm5G1+ynndYjdnr
X-Developer-Key: i=quic_fangez@quicinc.com; a=ed25519;
 pk=tJv8Cz0npA34ynt53o5GaQfBC0ySFhyb2FGj+V2Use4=
X-Endpoint-Received: by B4 Relay for quic_fangez@quicinc.com/20241014 with auth_id=245
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: lliu6 <quic_lliu6@quicinc.com>

Enable SX150X pinctrl driver.

Signed-off-by: lliu6 <quic_lliu6@quicinc.com>
---
 arch/arm64/configs/defconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/configs/defconfig b/arch/arm64/configs/defconfig
index 76f3a6ee93e979e9e39cb0283699a2753b0dddf4..13ff005ebe0e9cfcf171b08add24465d0ab94f05 100644
--- a/arch/arm64/configs/defconfig
+++ b/arch/arm64/configs/defconfig
@@ -630,6 +630,7 @@ CONFIG_PINCTRL_SM8350=y
 CONFIG_PINCTRL_SM8450=y
 CONFIG_PINCTRL_SM8550=y
 CONFIG_PINCTRL_SM8650=y
+CONFIG_PINCTRL_SX150X=y
 CONFIG_PINCTRL_X1E80100=y
 CONFIG_PINCTRL_QCOM_SPMI_PMIC=y
 CONFIG_PINCTRL_LPASS_LPI=m

-- 
2.25.1

