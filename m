From: Sam Day <me@samcday.com>
Date: Sat, 06 Jun 2026 18:47:37 +1000
Subject: [PATCH 06/11] qcom_defconfig: enable poweroff command
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260606-pm8916-pon-v1-6-170c9cbe5099@samcday.com>
References: <20260606-pm8916-pon-v1-0-170c9cbe5099@samcday.com>
In-Reply-To: <20260606-pm8916-pon-v1-0-170c9cbe5099@samcday.com>
To: u-boot@lists.denx.de, Sumit Garg <sumit.garg@kernel.org>, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, 
 Casey Connolly <casey.connolly@linaro.org>, Peng Fan <peng.fan@nxp.com>, 
 Leo Yu-Chi Liang <ycliang@andestech.com>, Anshul Dalal <anshuld@ti.com>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Justin Klaassen <justin@tidylabs.net>, 
 Jamie Gibbons <jamie.gibbons@microchip.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Andrew Goodbody <andrew.goodbody@linaro.org>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Mateus Lima Alves <mateuslima.ti@gmail.com>, 
 Sughosh Ganu <sughosh.ganu@arm.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 George Chan <gchan9527@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Peter Robinson <pbrobinson@gmail.com>, 
 Ariel D'Alessandro <ariel.dalessandro@collabora.com>, 
 Dmitrii Merkurev <dimorinny@google.com>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780735669; l=1014;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=en+3MOfQE8c2egWvrIqQwiU2u2zLLqoqXQuKxKUBc9g=;
 b=P7be6G2ghnbJXa6073vcAkyh34g2aE4z2GBIryu5F6wGv+kZJT7U9j5c66DcQ6eMZsWIFxUqz
 jLLaQLidaJ9Cjnw4NQeWY20JxzlnVySyubdaz2Cl6IJMgRUPlcV4wOt
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With the newly introduced PM8916 PON driver and support in PSHOLD
driver, the poweroff command now works on MSM8916 devices.

This should also work on any more recent qcom SoC with a functional PSCI
implementation in TZ. I confirmed that is the case on my google-sargo
and oneplus-fajita, at least.

Signed-off-by: Sam Day <me@samcday.com>
---
 configs/qcom_defconfig | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/configs/qcom_defconfig b/configs/qcom_defconfig
index c5649b9b746..c7bc6829014 100644
--- a/configs/qcom_defconfig
+++ b/configs/qcom_defconfig
@@ -38,6 +38,7 @@ CONFIG_CMD_DFU=y
 CONFIG_CMD_GPIO=y
 CONFIG_CMD_I2C=y
 CONFIG_CMD_MMC=y
+CONFIG_CMD_POWEROFF=y
 CONFIG_CMD_UFS=y
 CONFIG_CMD_USB=y
 CONFIG_CMD_USB_MASS_STORAGE=y
@@ -135,6 +136,7 @@ CONFIG_SPMI_MSM=y
 CONFIG_SYSINFO=y
 CONFIG_SYSINFO_SMBIOS=y
 CONFIG_SYSRESET_CMD_RESET_ARGS=y
+CONFIG_SYSRESET_CMD_POWEROFF=y
 CONFIG_SYSRESET_QCOM_PSCI=y
 CONFIG_SYSRESET_QCOM_PSHOLD=y
 CONFIG_USB=y

-- 
2.54.0

