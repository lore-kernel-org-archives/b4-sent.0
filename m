From: David Heidelberg <david@ixit.cz>
Date: Sun, 30 Aug 2026 00:23:27 +0200
Subject: [PATCH 4/4] configs: qcom: enable QMP USB3-DP combo PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-b4-sdm845-usb-gadget-v1-4-9f20e842d628@ixit.cz>
References: <20260830-b4-sdm845-usb-gadget-v1-0-9f20e842d628@ixit.cz>
In-Reply-To: <20260830-b4-sdm845-usb-gadget-v1-0-9f20e842d628@ixit.cz>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 David Heidelberg <david@ixit.cz>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Peng Fan <peng.fan@nxp.com>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Federico Amedeo Izzo <federico@izzo.pro>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Quentin Schulz <quentin.schulz@cherry.de>, phone-devel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1041; i=david@ixit.cz;
 h=from:subject:message-id; bh=+1d4BTHteqIRt7GUekOg8l3SKZOkytAi29bL4pgGHWA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqk1vezUgRAXSMNhLkvZpC4upz6ah3U4IDJT6WA
 V11YExWTZeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapNb3gAKCRBgAj/E00kg
 cmxuD/0fhWvNHp1IWIdKuSkCKvDggkizofzUBFwEf2MD2KsG7whj3d4ioz7TSHpoiPRZvyiBmg9
 rUIVzVJooz5iDxkKnGJJzIuaQRpwt/wJeVJy5ERXD1Y7KarRZVzD5y3+WBKT7Frgp1laS//cHQh
 UOsx6auVgkVOMV+g3LzXjLaji/g3/pPkahIoBCUKv9Nr1tIJf02Fxop+w/2O7iZwLUGK2wI9LZu
 0vmQmisCPgNlHxi6ERBMT/YKjn/FFXZuv8PmmXID1iHAmsYkx6DGx2xVImHao+UbTirJ2C4r0v1
 btPoCrMLzfN2COmqvF2R1OtqAtoRUrE/nZRbeKehrgyTd7gUXqWkflK29oXF3BRTj1aMDlFQsc1
 CnD9sFlHlY2k01U52OM1Xhlu8d0JGiXED4n9ImLE+XHTtQADxwpdRLRwRriN4AqC0UvQGQNIm0l
 xIXNRgI3hoBxJcOETlD4+4PzloAL5PEn0ZypItl4vMf6AMaRcTKfusnctCu0issWK5zpJKwr1/H
 K08pGqfAprITTM06ttkT0+U6M0+jh+ZqnZyNh7N0dPAZVY7NkIIp58U0jwQ2dajf7hd2TBKxWR0
 1eZXYGy797dcwi+l2wpZf+OQE2tuMqHlaDqr32t0kJRCmic3Kc/g7YSGLhGi4VouwB5qm3l2Dba
 z/qXoLb4mZCU3cA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SDM845 boards need this PHY to bring up their USB controller, and
without it in the defconfig the driver is silently left out of the
build, so the PHY never binds and USB gadget mode fails with:

  dwc3-generic-peripheral usb@a600000: failed to enable ep0out

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

