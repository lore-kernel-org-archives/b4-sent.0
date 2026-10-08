From: Igor Velkov <iav@iav.lv>
Subject: [PATCH v2 0/3] mmc: meson-gx: honour the busy timeout for R1b
 commands
Date: Thu, 08 Oct 2026 14:27:58 +0000
Message-Id: <20261008-meson-gx-busy-timeout-v2-0-8bde1adfb5b4@iav.lv>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAG6ox2oC/3WNyw6CMBBFf4XM2jF9KIIr/8OwgDLAJEJNWxoI4
 d+tJC5dnpPcczfw5Jg83LMNHEX2bKcE6pSBGeqpJ+Q2MSihcinEFUfydsJ+wWb2KwYeyc4Bb1S
 Q7lrTaNKQtm9HHS9H91klHtgH69bjJsqv/RWLP8UoUWJbqk6bvDAXUT64judXhGrf9w+yu03Zt
 wAAAA==
To: Ulf Hansson <ulfh@kernel.org>
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 linux-mmc@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1673; i=iav@iav.lv;
 h=from:subject:message-id; bh=XXv4CjnLsE/u9Me7mkTlw60K2Njx2d7DLdS4d2h8YEk=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFnHVxTvt9+wJ/f5porj+RKPPrsVFjXvZSw+YBL0w/Ok2
 u03ycrxHaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAi72YzMswt51abeH67T/N7
 lS+/trDK+h1azJ63cMY85zDTuhLXcy8Y/vCWJSkUnQ/PN7U1vM5492uc+/oiaX++W1wr4xO/b79
 mxgYA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For a command without data the driver programs a fixed 1024 ms into the
CMD_CFG timeout field and does not tell the core how long the controller
can wait for busy. Erase and cache flush then fail with -110 on eMMC.

Tested on ODROID-N2+ (S922X), 256 GB eMMC, btrfs root with discard=async,
Armbian builds in docker as load. Without the patches (7.3-rc6): 262
errors in 3 h and 68 in 2.5 h in two runs; the first came 4 and 43 min
into the build. With the patches (7.3-rc6): 0 in 2.4 h. On 7.1 with the
previous eMMC module a synthetic test (20 GiB write + fstrim) gave 48
errors without the patches, 0 and 0 with them.

The timeout is rounded up to a power of two: the field holds powers of
two only, and the timeout is a lower bound. MMC_CAP_WAIT_WHILE_BUSY is
not set: I have not checked that the controller waits for busy on every
R1b command, HS400 switches included.

---
Changes in v2:
- Split into three patches, as Neil asked: name the limit of the
  timeout field, program the R1b timeout from cmd->busy_timeout, report
  max_busy_timeout.
- Link to v1: https://lore.kernel.org/r/20261008-meson-gx-busy-timeout-v1-1-d92f3c68c409@iav.lv

---
Igor Velkov (3):
      mmc: meson-gx: name the limit of the CMD_CFG timeout field
      mmc: meson-gx: honour the busy timeout for R1b commands
      mmc: meson-gx: report the longest busy wait the controller can do

 drivers/mmc/host/meson-gx-mmc.c | 22 ++++++++++++++++++++--
 1 file changed, 20 insertions(+), 2 deletions(-)
---
base-commit: fd9af27f6c2319713bb23832066585f8a59a1771
change-id: 20261005-meson-gx-busy-timeout-7e8e3fdcb3e3

Best regards,
-- 
Igor Velkov <iav@iav.lv>

