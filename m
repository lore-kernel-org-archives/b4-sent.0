From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH 0/3] iio: addac: ad74413r: minor improvements
Date: Wed, 16 Oct 2024 16:21:58 +0200
Message-Id: <20241016-dev-ad74413r-minor-improv-v1-0-13c9c769237d@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAbMD2cC/x3MQQqEMAxA0atI1hNoNDjiVWQWOolOFraSQhHEu
 1tm+Rb/X5DVTTOMzQWuxbKlWEGvBr6/OW6KJtXQhpYpUI+iBWd5M1PnuFtMjrYfngrKsISehLn
 jAWp/uK52/t/T574floPJ7WsAAAA=
To: linux-iio@vger.kernel.org
Cc: Cosmin Tanislav <cosmin.tanislav@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729088521; l=602;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=Nuvxba6glBIPMK9JE7/jPpniFHYRMPEJCRIpZ014R2A=;
 b=pYpN9jjSalNp3z4sZ8TG7wu49h9ql2KLJKULCYaqoLSasV2VuASRAeZ4iYcmggQMb418DS929
 aOsiGzfHyI1AignLcW1X3bY2ukWg6YQwVunkUOAFaaWyYraXEGS1xmI
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Minor improvements handling locking, reset gpio and vref voltage. No
functional changes intended.

---
Nuno Sa (3):
      iio: addac: ad74413r: drop reset_gpio from struct ad74413r_state
      iio: addac: ad74413r: use devm_regulator_get_enable_read_voltage()
      iio: addac: ad74413r: simplify with cleanup.h

 drivers/iio/addac/ad74413r.c | 81 ++++++++++++++++----------------------------
 1 file changed, 30 insertions(+), 51 deletions(-)
---
base-commit: c3e9df514041ec6c46be83801b1891392f4522f7
change-id: 20241016-dev-ad74413r-minor-improv-d8b061d44348
--

Thanks!
- Nuno Sá

