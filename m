From: Sam Day <me@samcday.com>
Subject: [PATCH v2 0/2] Fastboot abort key support
Date: Fri, 19 Jun 2026 09:54:59 +1000
Message-Id: <20260619-fastboot-abort-keyed-v2-0-684e53949a42@samcday.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WPz07EIBDGX6Xh7BiglHZ78j1MD8MwuER3UcDGZ
 tN3F7sHvXn8ZvL9+d1E4Ry5iLm7icxrLDFdm9APnaAzXl8Yom9aaKmttFJDwFJdShXQpVzhlTf
 2oKQ1TGTH0bNo1vfMIX4dsc9L0+dYasrb0bKqn+s/gasCCUYZRBpQWjc9FbyQx+2R0kUs+70j8
 8dnW1zvRcJhYWj/S6xzp3iSzC3CKLJKBzmM04in3jkOhi0brVmfvBJ/SRv4MUsNv7N8IqCa34C
 gD0hjP6iJAs+NY9n3b0P5eF1BAQAA
X-Change-ID: 20260602-fastboot-abort-keyed-1064ecc677de
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
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Simon Glass <sjg@chromium.org>, 
 Ariel D'Alessandro <ariel.dalessandro@collabora.com>, 
 Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781826900; l=1491;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=nHFgMFWwOjqnmFmXMHbQRHkLSvdLTzaO1FJbdAgIDKg=;
 b=J+c3y3ps5WmNZMurdORBM1TxLo06lKhr+kYvcnrko8Sd6EKNfIG61ZkuUd9WSD0123ypeIBXs
 M5lqFhtgfEsCZCD5K9IEP9bCExaTM5qfz8JrJK06b31DbK8xn34a52y
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

UMS already offers CONFIG_CMD_UMS_ABORT_KEYED, which makes it possible
to bail out of that mode by pressing any button, rather than only
responding to ctrl-c. This is particularly useful for phones, where it's
not possible (yet... hmmmmm...) to send a ctrl-c command with the
available phone buttons.

This simple patch series introduces equivalent behaviour for fastboot,
and enables it in the qcom-phone.config fragment where it's most useful.

Signed-off-by: Sam Day <me@samcday.com>
---
Changes in v2:
- Fixed helpstring for new kconfig option to span 2 lines, in order
  to please checkpatch.pl
- Added a note about the new config option to doc/android/fastboot.rst
- Link to v1: https://lore.kernel.org/r/20260602-fastboot-abort-keyed-v1-0-414aac5a06b8@samcday.com

---
Sam Day (2):
      cmd: fastboot: Add keyed abort option
      board: qualcomm: phone: enable CMD_FASTBOOT_ABORT_KEYED

 board/qualcomm/qcom-phone.config | 1 +
 board/qualcomm/qcom-phone.env    | 2 +-
 cmd/Kconfig                      | 7 +++++++
 cmd/fastboot.c                   | 9 ++++++++-
 doc/android/fastboot.rst         | 4 ++++
 5 files changed, 21 insertions(+), 2 deletions(-)
---
base-commit: 1e80ee41441c612f05787a93bbef4e6e422e29d1
change-id: 20260602-fastboot-abort-keyed-1064ecc677de
prerequisite-change-id: 20260615-fastboot-doc-ctrl-c-3fac73518cfe:v1
prerequisite-patch-id: b948dead04c3a24a47a8d8dd7f03590565a8ff6c

Best regards,
-- 
Sam Day <me@samcday.com>

