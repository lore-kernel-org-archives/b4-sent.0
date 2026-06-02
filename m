From: Sam Day <me@samcday.com>
Date: Tue, 02 Jun 2026 17:19:02 +1000
Subject: [PATCH v2 6/6] qcom_defconfig: enable spin-table support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260602-msm8916-smp-support-v2-6-792e53dac374@samcday.com>
References: <20260602-msm8916-smp-support-v2-0-792e53dac374@samcday.com>
In-Reply-To: <20260602-msm8916-smp-support-v2-0-792e53dac374@samcday.com>
To: Tom Rini <trini@konsulko.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Mark Kettenis <mark.kettenis@xs4all.nl>, Sumit Garg <sumit.garg@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, 
 Casey Connolly <casey.connolly@linaro.org>, Simon Glass <sjg@chromium.org>, 
 Kory Maincent <kory.maincent@bootlin.com>, Yao Zi <me@ziyao.cc>, 
 Peng Fan <peng.fan@nxp.com>, Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Stefan Roese <stefan.roese@mailbox.org>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Philip Molloy <philip.molloy@analog.com>, 
 Michael Trimarchi <michael@amarulasolutions.com>, 
 Michal Simek <michal.simek@amd.com>, Sughosh Ganu <sughosh.ganu@arm.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780384740; l=837;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=JBe/3QC1XSzM8/O/Jv6md0nTkxH4aiJxUpl4YZWZBAY=;
 b=VGslOqegYXPEEEck7Bb4se+LYcgRGY/5+kDgmwhrjJA5xcUglZjA93p5OUjgNcqZuB9OnutKg
 ujnVZyyNIcqBpoHnrx0taac8sGE2P5ec+qS2AJwTU33uwKrWH18dJcL
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is used by MSM8916 to bring secondary cores online when no PSCI
support is available.

Signed-off-by: Sam Day <me@samcday.com>
---
 configs/qcom_defconfig | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/configs/qcom_defconfig b/configs/qcom_defconfig
index d0d54ec5a70..95897fe977e 100644
--- a/configs/qcom_defconfig
+++ b/configs/qcom_defconfig
@@ -1,4 +1,6 @@
 CONFIG_ARM=y
+CONFIG_ARMV8_MULTIENTRY=y
+CONFIG_ARMV8_SPIN_TABLE=y
 CONFIG_SKIP_LOWLEVEL_INIT=y
 CONFIG_POSITION_INDEPENDENT=y
 CONFIG_SYS_INIT_SP_BSS_OFFSET=0x180000
@@ -52,6 +54,7 @@ CONFIG_OF_LIVE=y
 CONFIG_OF_UPSTREAM_BUILD_VENDOR=y
 CONFIG_ENV_USE_DEFAULT_ENV_TEXT_FILE=y
 CONFIG_ENV_DEFAULT_ENV_TEXT_FILE="board/qualcomm/default.env"
+CONFIG_QCOM_SCM=y
 CONFIG_BUTTON_QCOM_PMIC=y
 CONFIG_CLK=y
 CONFIG_CLK_STUB=y

-- 
2.54.0

