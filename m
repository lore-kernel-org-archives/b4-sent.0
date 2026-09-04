From: David Heidelberg <david@ixit.cz>
Date: Fri, 04 Sep 2026 19:53:47 +0200
Subject: [PATCH v2 4/4] configs: qcom: enable QMP USB3-DP combo PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260904-b4-sdm845-usb-gadget-v2-4-cf1baa65a6d4@ixit.cz>
References: <20260904-b4-sdm845-usb-gadget-v2-0-cf1baa65a6d4@ixit.cz>
In-Reply-To: <20260904-b4-sdm845-usb-gadget-v2-0-cf1baa65a6d4@ixit.cz>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Peng Fan <peng.fan@nxp.com>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Federico Amedeo Izzo <federico@izzo.pro>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Quentin Schulz <quentin.schulz@cherry.de>, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1098; i=david@ixit.cz;
 h=from:subject:message-id; bh=mxpWgs1cNiJ065iRuJH0M7lM5/w0wLWaEBrcuJ5E9S4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqmwWsQ3P6+DzLXZDk2gCub7kJuIUW3iDrS/F1B
 3P650IXTz2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapsFrAAKCRBgAj/E00kg
 cuyfEACA42HNsoYti3oBe6ToQm1nKJpRk1CBVP6vz5P+dVLCCNVQEubJmNEWIWiiGRdGW3E+FSo
 47dl2/7jtOaTR2PSqp/TBJhEZVETR7F2s/UhUNPB9KuT2SkFPdDXNzZBcLNVaPqB4/RjwBbt81J
 0PGRelkgFhft7TLDxezTCdm7Kr4f0noBzMnPrpSkWZ7NHVGLGDAb+Wpcfiqw2pixgj76whANbIq
 CHW3DJySIrku/aNQe3CQ8jtCpE21JZOXVhzP3JkPqwoavRt6lo6CZQYWg6rTFAfKeUzvknlJ5zg
 23W6aVJN0vFuH562r/iv109H06FH/AG4BZxPnzsL/Q8UpHNmgTMjbMPwWS/6aZZXgJ2UF+W0m5l
 eoe/fdzJ5MvIyZ/WrBBqVNs56pC4qQpiLzX8agxaQJjjcs1oHCWAFxslKfnyuan8quz/6k7rfh0
 FWiP38f25GsUp+VXLv6W54C6foVQ7ayGQlLCrJsSI3TGGhhr1sQ8O7PnxqZoSqBnP1nmik0RpCP
 QVw05BhoTYxwWpfZRcMfwQ2q/TuY7RdRY6L4GZvnhMnSwwASew/YDmZHVYiVSEryx5yDIZ73MZk
 t7ZFVhoa5L/lpNU4+/2ixbw3amdrhv+C5lcrOdk44p2fNyv8ihfHTRrkz9I7JcGRk/lhPjqaaJA
 ZDAU1/bvzX3zI6w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SDM845 boards need this PHY to bring up their USB controller, and
without it in the defconfig the driver is silently left out of the
build, so the PHY never binds and USB gadget mode fails with:

  dwc3-generic-peripheral usb@a600000: failed to enable ep0out

Reviewed-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 configs/qcom_defconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/configs/qcom_defconfig b/configs/qcom_defconfig
index b0d0f51b1c0..880edcb504b 100644
--- a/configs/qcom_defconfig
+++ b/configs/qcom_defconfig
@@ -104,16 +104,17 @@ CONFIG_MMC_SDHCI_MSM=y
 CONFIG_DM_MDIO=y
 CONFIG_DM_ETH_PHY=y
 CONFIG_DWC_ETH_QOS=y
 CONFIG_DWC_ETH_QOS_QCOM=y
 CONFIG_RGMII=y
 CONFIG_PHY_MICREL=y
 CONFIG_PHY_MICREL_KSZ90X1=y
 CONFIG_PHY=y
+CONFIG_PHY_QCOM_QMP_COMBO=y
 CONFIG_PHY_QCOM_QMP_UFS=y
 CONFIG_PHY_QCOM_QUSB2=y
 CONFIG_PHY_QCOM_USB_SNPS_FEMTO_V2=y
 CONFIG_PHY_QCOM_SNPS_EUSB2=y
 CONFIG_PINCTRL=y
 CONFIG_PINCONF=y
 CONFIG_PINCTRL_QCOM_GENERIC=y
 CONFIG_QCOM_RPMH_POWER_DOMAIN=y

-- 
2.55.0

