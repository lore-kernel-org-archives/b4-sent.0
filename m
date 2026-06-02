From: Sam Day <me@samcday.com>
Subject: [PATCH 0/2] Fastboot abort key support
Date: Tue, 02 Jun 2026 18:45:45 +1000
Message-Id: <20260602-fastboot-abort-keyed-v1-0-414aac5a06b8@samcday.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBG4avErBswCYOuEi1M/2oIMlSiiO6et
 PwW7z2UEAWJ+uqhiFOShL2gqStyq90XsPhi0kobZZTm2aY8hZDZTiFm3nDDc6NMC+dM13lQSY+
 IWa5/O4zv+wGi5dQDZgAAAA==
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
 Marek Vasut <marek.vasut+renesas@mailbox.org>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780389946; l=1019;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=iaRIsY33Ndd9v8P2Thk9pCPOpGrkJAVRITfOvq9GnVI=;
 b=qh6aeuYYBLHbxvLfRsocQdbLMLlcbuCm3/5jInncObnmKqacdRIso4oi34vRyIxnNKSlvj3Mx
 8J/IR1OFRXtBYtAJFlDff2JHyiHfAzAotvi3hqCVhW3OTTmUYPj5xZi
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
Sam Day (2):
      cmd: fastboot: Add keyed abort option
      board: qualcomm: phone: enable CMD_FASTBOOT_ABORT_KEYED

 board/qualcomm/qcom-phone.config | 1 +
 board/qualcomm/qcom-phone.env    | 2 +-
 cmd/Kconfig                      | 6 ++++++
 cmd/fastboot.c                   | 9 ++++++++-
 4 files changed, 16 insertions(+), 2 deletions(-)
---
base-commit: 30b77f6aa146c96b831cb4ece038130b655b6a41
change-id: 20260602-fastboot-abort-keyed-1064ecc677de

Best regards,
-- 
Sam Day <me@samcday.com>

