From: Sam Day <me@samcday.com>
Date: Tue, 02 Jun 2026 18:45:47 +1000
Subject: [PATCH 2/2] board: qualcomm: phone: enable
 CMD_FASTBOOT_ABORT_KEYED
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260602-fastboot-abort-keyed-v1-2-414aac5a06b8@samcday.com>
References: <20260602-fastboot-abort-keyed-v1-0-414aac5a06b8@samcday.com>
In-Reply-To: <20260602-fastboot-abort-keyed-v1-0-414aac5a06b8@samcday.com>
To: u-boot@lists.denx.de, Sumit Garg <sumit.garg@kernel.org>, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 "Kory Maincent (TI.com)" <kory.maincent@bootlin.com>, 
 Mikhail Kshevetskiy <mikhail.kshevetskiy@iopsys.eu>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, Heiko Schocher <hs@nabladev.com>, 
 Andrew Goodbody <andrew.goodbody@linaro.org>, 
 Peter Robinson <pbrobinson@gmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780389946; l=1663;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=IUiHS+xJ+tA2nulvCQsv/z2sshe+2rZKg/R5HJhxRC8=;
 b=swba8dP0cm4VV969e7smt/K37ZkDuIfrmK7q9nv+3jrJEq6AbVd9TmqmhWgb0qJi0RxQ8B9gt
 JMt7/2Z1xhNCJZ2UZPS3JHkPBPwsTzdLr5dQwByTago08b1VdEUp7y2
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Thus users are able to exit from fastboot by pressing a key.

It's also possible to bail out by running `fastboot continue` from the
host, but it's nice to be consistent with UMS. Also convenient to be
able to bailout during testing if USB isn't working properly.

Signed-off-by: Sam Day <me@samcday.com>
---
 board/qualcomm/qcom-phone.config | 1 +
 board/qualcomm/qcom-phone.env    | 2 +-
 2 files changed, 2 insertions(+), 1 deletion(-)

diff --git a/board/qualcomm/qcom-phone.config b/board/qualcomm/qcom-phone.config
index d24094eefdd..1387aa1dfa2 100644
--- a/board/qualcomm/qcom-phone.config
+++ b/board/qualcomm/qcom-phone.config
@@ -13,6 +13,7 @@ CONFIG_FASTBOOT_BUF_ADDR=0x1A000000
 CONFIG_USB_FUNCTION_FASTBOOT=y
 CONFIG_USB_FUNCTION_ACM=y
 CONFIG_CMD_UMS_ABORT_KEYED=y
+CONFIG_CMD_FASTBOOT_ABORT_KEYED=y
 
 # Record all console output and let it be dumped via fastboot
 CONFIG_CONSOLE_RECORD=y
diff --git a/board/qualcomm/qcom-phone.env b/board/qualcomm/qcom-phone.env
index e91ae3ecdfb..566ce3c01ea 100644
--- a/board/qualcomm/qcom-phone.env
+++ b/board/qualcomm/qcom-phone.env
@@ -32,7 +32,7 @@ menucmd=setenv bootcmd run menucmd; bootmenu -1
 bootmenu_0=Boot=bootefi bootmgr; pause
 bootmenu_1=Enable serial console gadget=run serial_gadget
 bootmenu_2=Enable USB mass storage=echo "Press any key to exit UMS mode"; ums 0 scsi 0
-bootmenu_3=Enable fastboot mode=run fastboot
+bootmenu_3=Enable fastboot mode=echo "Press any key to exit fastboot mode"; run fastboot
 # Disabling bootretry means we'll just drop the shell
 bootmenu_4=Drop to shell=setenv bootretry -1
 bootmenu_5=Reset device=reset

-- 
2.54.0

