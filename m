From: Felix Huang <akafelixab@gmail.com>
Date: Fri, 27 Nov 2026 19:24:15 -0500
Subject: [PATCH] staging: greybus: fw-management: align arguments with open
 parenthesis
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-greybus-align-v1-1-4c096948e389@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQoCIRCA4VdZ5pygQha9yrIHx0abCFucXArx3
 XPr+B3+v4FQYRK4TA0KbSz8zAPmMEG4+ZxI8XUYrLbOGHtSqdAHqyj/4JSVJxciotHHM8Jo1kK
 R37/fvPwtFe8UXvsEev8CEtL9hHEAAAA=
X-Change-ID: 20261127-greybus-align-ae6cfbb1058b
To: Viresh Kumar <vireshk@kernel.org>, Johan Hovold <johan@kernel.org>, 
 Alex Elder <elder@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: greybus-dev@lists.linaro.org, linux-staging@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Felix Huang <akafelixab@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795825455; l=1034;
 i=akafelixab@gmail.com; s=20261128; h=from:subject:message-id;
 bh=bV3yrVUkPxaiyVgqWFbAJcZtTTIA3l0sqstU+Ydq4Ro=;
 b=G17OpiUeKCCH6aduwjBU/mi2O6l/6IIBdQHIYUZAo44nX+oZyGRpp7/Gk7l2R3PZ+KfVJvIE6
 ZDuXm2NfGvxB4D+AxZXByWu56WTml0ygmAp+0vO25oiXmkv4tfMZ+Jc
X-Developer-Key: i=akafelixab@gmail.com; a=ed25519;
 pk=Axl3BM1UWa+m0/AWcEhRIdIk/WY9FnY4wZkyQn64uVY=
X-Endpoint-Received: by B4 Relay for akafelixab@gmail.com/20261128 with auth_id=1670
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Align multi-line function call arguments with the opening parenthesis
to adhere to the Linux kernel coding style and fix checkpatch.pl
alignment checks.

Signed-off-by: Felix Huang <akafelixab@gmail.com>
---
 drivers/staging/greybus/fw-management.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/staging/greybus/fw-management.c b/drivers/staging/greybus/fw-management.c
index 5d01da6b6..e20e9136c 100644
--- a/drivers/staging/greybus/fw-management.c
+++ b/drivers/staging/greybus/fw-management.c
@@ -434,7 +434,8 @@ static int fw_mgmt_ioctl(struct fw_mgmt *fw_mgmt, unsigned int cmd,
 			return -EFAULT;
 
 		ret = fw_mgmt_load_and_validate_operation(fw_mgmt,
-				intf_load.load_method, intf_load.firmware_tag);
+							  intf_load.load_method,
+							  intf_load.firmware_tag);
 		if (ret)
 			return ret;
 

---
base-commit: 8aa842d51d1a03532cc9be3ca4077c67fd73f268
change-id: 20261127-greybus-align-ae6cfbb1058b

Best regards,
--  
Felix Huang <akafelixab@gmail.com>

