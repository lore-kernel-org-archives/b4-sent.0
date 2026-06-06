From: Sam Day <me@samcday.com>
Date: Sat, 06 Jun 2026 18:47:42 +1000
Subject: [PATCH 11/11] qcom_defconfig: enable reboot modes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260606-pm8916-pon-v1-11-170c9cbe5099@samcday.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780735669; l=957;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=6f1OuGxeonujGdNlEVh+jzf0dFHrklDHSXYNPJd0nUY=;
 b=SchQyc/uCwUW+6VAAh/iwLzH4Zz5t7R+sJErLbjFAKI6460+mJ0LRYVOqig8ufvAcU6Lo7Ri2
 jD5Y9w9RNMRBL06ujbgesZLAkMam279shW8hP/+mPBqVzNtTbksUiNz
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now that there's a PM8916 PON reboot-mode driver, it's worth enabling
the reboot-mode DM uclass. Additionally the newly introduced fastboot
support for setting reboot modes is enabled.

Signed-off-by: Sam Day <me@samcday.com>
---
 configs/qcom_defconfig | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/configs/qcom_defconfig b/configs/qcom_defconfig
index c7bc6829014..736a9424c3a 100644
--- a/configs/qcom_defconfig
+++ b/configs/qcom_defconfig
@@ -80,6 +80,7 @@ CONFIG_SYS_DFU_DATA_BUF_SIZE=0x200000
 CONFIG_USB_FUNCTION_FASTBOOT=y
 CONFIG_FASTBOOT_BUF_ADDR=0x0
 CONFIG_FASTBOOT_FLASH=y
+CONFIG_FASTBOOT_REBOOT_MODE=y
 CONFIG_FASTBOOT_FLASH_MMC_DEV=0
 CONFIG_FASTBOOT_MMC_USER_SUPPORT=y
 CONFIG_MSM_GPIO=y
@@ -124,6 +125,7 @@ CONFIG_PMIC_QCOM=y
 CONFIG_DM_REGULATOR=y
 CONFIG_DM_REGULATOR_FIXED=y
 CONFIG_DM_REGULATOR_QCOM_RPMH=y
+CONFIG_DM_REBOOT_MODE=y
 CONFIG_DM_RNG=y
 CONFIG_RNG_MSM=y
 CONFIG_SCSI=y

-- 
2.54.0

