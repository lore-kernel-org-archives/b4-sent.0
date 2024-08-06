From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH 0/2] docs: abi: document the debugfs interface for ad9467
Date: Tue, 06 Aug 2024 15:10:38 +0200
Message-Id: <20240806-dev-ad-debugfs-doc-v1-0-153b882a3f01@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAM4gsmYC/x2MMQqAMAwAvyKZDUQppfoVcbAmapYqLYpQ+neL0
 3HDXYYkUSXB2GSI8mjSM1Tp2gbWYwm7oHJ16Kk35Mgiy4MLV/h73xLyueJAbL01TJ13UMMryqb
 vP53mUj6GgSxQZAAAAA==
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722949842; l=632;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=nfxPSXplyGVnflmFeS9tVUFmre4uy9WUcl/Fa2uMweA=;
 b=gDJqGvofzuYYb/rEiY9j5AE1QKY6/SGLwL4w+8qKL6ynC5lFJw91Yq6X36c4oiCjErN4GUf7F
 Q5tdVrMQLG0BLWzYnEzd2twibzsMXUAn35pTxlIub0jYCR5pZIM4gGj
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi Jonathan,

Here it goes the follow up for the ad9467 debugfs interface. While at
it, I realized there was no entry in MAINTAINERS for this driver so the
first patch is about that.

---
Nuno Sa (2):
      MAINTAINERS: add entry for ad9467
      ABI: debugfs-iio-ad9467: document the debugfs interface

 Documentation/ABI/testing/debugfs-iio-ad9467 | 39 ++++++++++++++++++++++++++++
 MAINTAINERS                                  | 10 +++++++
 2 files changed, 49 insertions(+)
---
base-commit: 593737c18ae789dc6e4b493510a0c00977972e2e
change-id: 20240806-dev-ad-debugfs-doc-90d6b64d01b8
--

Thanks!
- Nuno Sá

