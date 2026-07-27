From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Subject: [PATCH v2 0/3] gpu: nova-core: Move PFB and PBUS register
Date: Mon, 27 Jul 2026 17:51:50 +0200
Message-Id: <20260727-nova-core-regs-split-v2-0-21b5e6e32ea5@nanonej.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCMBBG4auUWTvQJtSKVxEXMfmtI5KUmbYIp
 Xc36vJbvLeRQQVG52YjxSomJVe4Q0PxEfIIllRNrnXHdnAd57IGjkXBitHYppfMnAbvTz50fY9
 ENZ0Ud3n/tpfr37bcnojz90X7/gFKh1LLeAAAAA==
X-Change-ID: 20260721-nova-core-regs-split-d73383a155ed
To: Danilo Krummrich <dakr@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, Alice Ryhl <aliceryhl@google.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: nova-gpu@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, daniel.almeida@collabora.com, 
 Antonin Malzieu Ridolfi <dev@nanonej.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1686; i=dev@nanonej.com;
 h=from:subject:message-id; bh=XnAq5QeK6zIJiazPwKAtAy73Gab7jM6F+MrIWRRwkC8=;
 b=owEBbQKS/ZANAwAKAWaH8SMKFRX9AcsmYgBqZ36YAcsEqTnVG6xnAMibZxcqJhuuMeD8QllvW
 b5ro1dvOvCJAjMEAAEKAB0WIQSDtk+wfJEhL1KFIn1mh/EjChUV/QUCamd+mAAKCRBmh/EjChUV
 /UAaD/90AAHMJHa+FgHnCldsVTgm9qSxevFs+4D4RdvqNRZgayHjAtPc1gMGddQrmGKWQaQYhC4
 LZK7JDRzGZWpEqEhBWZXhhGX8m8Ezp2G1q8ixlrqS5OKZ63/shseLhz8EfWf7OiqLa7uNkjZuJn
 rPRRX7nvdNG+z99E8nnQFKvxKwe05adBw2ubogo6KxQE/QiOL9UXQvGHMhucl1UQ5L9gzkoho4A
 VU5bhRmTPuqZIppZWAOJi+kA4wtBdtQq3TcjdguXNX/CF67oWpSk/h5HhYXd3q2kjnb/chc9uyQ
 6yzMVLVVw7I9N8PIpjhQShZzfQwgiaXQVFAMOuz+6SiTNY1ANT0lp9NCqpbAcavmbY0E8dhediK
 HNv58xJsusDK2kAWpOa9QGHk1mgLJfTWDGvWeP/J3GMfEZNsAMm+M1FOz0Ev49lHasbNWc10tna
 uObrxgNTnFKJkXYsHmqDmVeG96Tye6DkF14OwMgAkH0SwK3+c+zafOOkH1IPpxLjYIegTu8A/Vc
 GwWeSxBwsK8Lpw7DOOcYkqt27eCgvscu1VLeE4ZmIVfHr/3PIKQ9b/To85us+k33OhGssvURkS9
 azH35kvpDzK2gIJR1vQ+Lc1giTzwPLQEaWxr0eows4P8XryHKntag4V2P1nK3uPfxh02eJsLOf6
 veFWeQhCnAaXAvw==
X-Developer-Key: i=dev@nanonej.com; a=openpgp;
 fpr=83B64FB07C91212F5285227D6687F1230A1515FD
X-Endpoint-Received: by B4 Relay for dev@nanonej.com/default with auth_id=825
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Split part of the registers definitions grouped in nova root register file to
belonging modules whom actually use them.
Add WPR2 range query function to fb module.

To: Danilo Krummrich <dakr@kernel.org>
To: Alexandre Courbot <acourbot@nvidia.com>
To: Alice Ryhl <aliceryhl@google.com>
To: David Airlie <airlied@gmail.com>
To: Simona Vetter <simona@ffwll.ch>
Cc: nova-gpu@lists.linux.dev
Cc: dri-devel@lists.freedesktop.org
Cc: linux-kernel@vger.kernel.org
Cc: daniel.almeida@collabora.com

Suggested-by: Alexandre Courbot <acourbot@nvidia.com>
Suggested-by: Danilo Krummrich <dakr@kernel.org>
Signed-off-by: Antonin Malzieu Ridolfi <dev@nanonej.com>
---
Antonin Malzieu Ridolfi (3):
      gpu: nova-core: Add function to query WPR2 range
      gpu: nova-core: Move PFB registers definitions
      gpu: nova-core: Move one PBUS register definition

 drivers/gpu/nova-core/fb.rs            |  14 ++++
 drivers/gpu/nova-core/fb/hal/ga100.rs  |   8 +-
 drivers/gpu/nova-core/fb/hal/gb100.rs  |   6 +-
 drivers/gpu/nova-core/fb/hal/gb202.rs  |   6 +-
 drivers/gpu/nova-core/fb/hal/gh100.rs  |   6 +-
 drivers/gpu/nova-core/fb/hal/tu102.rs  |   8 +-
 drivers/gpu/nova-core/fb/regs.rs       | 132 ++++++++++++++++++++++++++++++++-
 drivers/gpu/nova-core/gsp/hal/tu102.rs |  56 +++++++-------
 drivers/gpu/nova-core/gsp/regs.rs      |  11 +++
 drivers/gpu/nova-core/regs.rs          | 132 ---------------------------------
 10 files changed, 203 insertions(+), 176 deletions(-)
---
base-commit: 6dcbb4b1320fa91fee349462a52bb69135f2e45e
change-id: 20260721-nova-core-regs-split-d73383a155ed

Best regards,
--  
Antonin Malzieu Ridolfi <dev@nanonej.com>

