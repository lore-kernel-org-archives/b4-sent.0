From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH 0/4] Input: adp5588-keys: refactor adp5588_read()
Date: Wed, 02 Oct 2024 12:51:49 +0200
Message-Id: <20241002-fix-adp5588-read-refactor-v1-0-28800f1b9773@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAMUl/WYC/x2MQQqAMAwEvyI5G6jFSvAr4iG0qeai0ooI4t8NX
 gaGYfeBKkWlwtg8UOTSqvtm0rUNxJW3RVCTOXjn+845j1lv5HSEQIRFOBkyx3MvyBQiEefeDR5
 sf1jR+/+e5vf9AMKkss1rAAAA
To: Michael Hennerich <michael.hennerich@analog.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727866310; l=923;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=Yh1n+IyXFeGoq0Rey8jtPpnhyiu8CFDzwyDYipT9LSE=;
 b=nmuQuFkUGdTvt0zytS9JIXPB4T5Oi8sX2RdFiFtfn01vGElhdYPuJ0Qe/0Ie9SUGmAFLC0OEV
 fvUq03Fq+hlDCzfaQM3GZsGefHnS7JOri556dp2Wai06ccBYSmXyiZz
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi Dmitry,

As suggested by you in [1], here it goes a small series to make sure we
check for error codes in adp5588_read() plus a following patch
refactoring the function.

In addition a couple more commits doing a simple conversion to
dev_err_probe() and a sanity check for IRQ presence (when the keymap is
to be used).

[1]: https://lore.kernel.org/linux-input/Zu0vq0ogr2HzXWv7@google.com/

---
Nuno Sa (4):
      Input: adp5588-keys: bail on returned error
      Input: adp5588-keys: refactor adp5589_read()
      Input: adp5588-keys: error out if no IRQ is given
      Input: adp5588-keys: make use of dev_err_probe()

 drivers/input/keyboard/adp5588-keys.c | 151 +++++++++++++++++++---------------
 1 file changed, 86 insertions(+), 65 deletions(-)
---
base-commit: c684771630e64bc39bddffeb65dd8a6612a6b249
change-id: 20241002-fix-adp5588-read-refactor-a85c88af4062
--

Thanks!
- Nuno Sá

