From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/4] Various CCS fixes
Date: Mon, 23 Nov 2026 13:02:38 +0100
Message-Id: <20261123-ccs-clanked-fixes-v1-0-fb2bcc87a517@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBCF4auQWTtJWxDRqxAWdBhw0FTSAUJCu
 DtVl19e/reDchRWeGQ7RF5F5RMS7CUDerZhYJQuGZxxpbUuRyJFerfhxR32srFiae7em9u1MK6
 C1E2Rf0PK6uZvXfzINH+P4DhOO72qOXUAAAA=
X-Change-ID: 20261123-ccs-clanked-fixes-609bb0754028
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: linux-media@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=710; i=david@ixit.cz;
 h=from:subject:message-id; bh=4jS0zlegs14tBmkkYCWRgSBLMv0d0gpAy+CK0t+l2YY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrBCtfByf8u82W7vlbkVnFhTNe/cXBz1IUYhXn2
 yz+6AEZUB2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawQrXwAKCRBgAj/E00kg
 ctwOEACv/n/56lzpRaDfQ02SNgDw42EkAfeayv8QApQ3JtYtLDI0uSkPpdsVmHOpy1qwEqUkwyJ
 Ej5jib+hHeVNu06xElYdDb0OhEts93Mj9PnlygaLYXwrdncjpJh0JMrGUhKesnnbzPcK/f33YPL
 NjCYn2PAQfassOsT0j6mo1A3bOwrtoG6bOCYKQe8m2I/OSnIsP0GchJ1vQSrf2mcTTJZCdWSMeJ
 DqfzQhvyoHQDc2V8HPgQoMdLCAW+4OtwQXu99U0vCTWt8B9CGK3XALVjkwMCZk3ndyerUjrxI+y
 s7Lq4jZdCX3LBf0dIewH6pUHmAOO69hINjgI1HhqHP9FX9IQx6/Pk78C/axpwV2ZtcDRd2TLT/k
 Cd3fXDWggbetSF+l8piRRF09ZIgTcOnc4AgM6xs4HPGszQsK0ALiF7uco8SA5L0sPMDiGgAp9/e
 mkb9NJb0bEp1zi3NBzwjGCJTWJVznLIThegXZejHZmGE+MGlQIKOFkOAiozmwKwQmQBDRBORHra
 g2hu0OMObB7dOb1Aw8mHhRTiFFYGFVFenzJbUPnGpLeM4FQJol8HwZxLwW1sfl55wveTbkEUtt2
 YfEitwyyce8HoWdIqjnfo6UTZXomjrYfJ/bEijWi6McHitGO2/L2YdO38U63dDtb1luIpGS5ycv
 UlB496SNCdcmZ8A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

First two seems to be no-brainers. Next two seems to be correct too.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (4):
      media: ccs: Use dev_dbg() instead of dev_err() in ccs_enum_mbus_code()
      media: ccs: Fix sub-device index in ccs_cleanup()
      media: ccs: Update PLL and blanking limits when pixel_array crop changes
      media: ccs: Set V4L2_CTRL_FLAG_MODIFY_LAYOUT on flip controls

 drivers/media/i2c/ccs/ccs-core.c | 14 +++++++++++---
 1 file changed, 11 insertions(+), 3 deletions(-)
---
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20261123-ccs-clanked-fixes-609bb0754028

Best regards,
--  
David Heidelberg <david@ixit.cz>

